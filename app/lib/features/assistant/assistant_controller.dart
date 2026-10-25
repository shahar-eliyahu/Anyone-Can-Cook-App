import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/clock.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../cooking/cooking_controller.dart';
import '../create/recipe_creation_service.dart';
import '../prepare/preparation.dart';
import '../prepare/preparation_service.dart';
import 'assistant_models.dart';
import 'assistant_service.dart';
import 'command_parser.dart';
import 'conversation_store.dart';

export 'conversation_store.dart' show ChatMessage;

class AssistantState {
  const AssistantState({this.messages = const [], this.pending, this.busy = false, this.context = const {}});
  final List<ChatMessage> messages;

  /// A reply waiting for the cook's approval ("כן" / "לא").
  final AssistantReply? pending;
  final bool busy;

  /// Recipe creation: the preferences gathered in this conversation (servings, time, diet...).
  final Map<String, Object?> context;

  AssistantState copyWith({
    List<ChatMessage>? messages,
    AssistantReply? pending,
    bool clearPending = false,
    bool? busy,
    Map<String, Object?>? context,
  }) =>
      AssistantState(
        messages: messages ?? this.messages,
        pending: clearPending ? null : pending ?? this.pending,
        busy: busy ?? this.busy,
        context: context ?? this.context,
      );
}

final assistantServiceProvider = Provider<AssistantService>((ref) => AssistantService(ref.watch(apiClientProvider)));

/// Remy's conversation about the current recipe (docs/DECISIONS.md #81). The scope says what
/// Remy may do (act on a cooking session, or only answer before cooking); the conversation
/// itself belongs to the recipe, so preparation and cooking continue the same one, and it is
/// restored from [ConversationStore] whenever the sheet opens again. The single entry point
/// [send] serves typed and spoken requests.
class AssistantController extends Notifier<AssistantState> {
  AssistantController(this.scope);

  final RemyScope scope;
  String get sessionId => scope.id;

  /// The recipe this conversation is about (a session's recipe, or the recipe itself).
  late final Future<String?> _recipeId = _resolveRecipe();

  /// Remembered messages are loaded before the first request is answered.
  late final Future<void> _loaded = _load();
  Future<void> _saving = Future.value();

  @override
  AssistantState build() {
    unawaited(_loaded);
    return const AssistantState();
  }

  AssistantService get _service => ref.read(assistantServiceProvider);
  CookingController get _cooking => ref.read(cookingControllerProvider(sessionId).notifier);
  ConversationStore get _store => ref.read(conversationStoreProvider);

  /// A creation conversation is its own key (the draft it creates shares it).
  Future<String?> _resolveRecipe() async =>
      scope.isSession ? (await ref.read(sessionRepositoryProvider).getSession(scope.id))?.recipeId : scope.id;

  Future<void> _load() async {
    final recipeId = await _recipeId;
    if (recipeId == null || !ref.mounted) return;
    final remembered = await _store.load(recipeId);
    final context = scope.isCreation ? await _store.loadContext(recipeId) : const <String, Object?>{};
    if (!ref.mounted || remembered.isEmpty) return;
    state = state.copyWith(messages: [...remembered, ...state.messages], context: {...context, ...state.context});
  }

  /// Saves after every change, in order (each save writes the whole bounded conversation).
  void _remember() {
    final messages = state.messages;
    final context = state.context;
    _saving = _saving.then((_) async {
      final recipeId = await _recipeId;
      if (recipeId != null) await _store.save(recipeId, messages, context: context);
    });
  }

  /// The conversation sent with a request: the recent turns only (the service trims further).
  List<ChatTurn> get _history => [for (final m in state.messages) ChatTurn(fromUser: m.fromUser, textHe: m.textHe)];

  /// One message from the cook, typed or spoken. Returns what Remy answered (the voice
  /// controller reads it aloud), or null when nothing was sent.
  Future<AssistantReply?> send(AssistantInput input) async {
    final text = input.text.trim();
    if (text.isEmpty || state.busy) return null;
    await _loaded;
    if (!ref.mounted) return null;
    // A pending confirmation can be answered in words: "כן" / "לא".
    if (state.pending != null) {
      switch (yesOrNo(text)) {
        case true:
          _addUser(text);
          return approve();
        case false:
          _addUser(text);
          return reject();
        case null:
      }
    }
    final history = _history;
    _addUser(text, busy: true);
    if (scope.isCreation) return _sendForCreation(input, history);
    if (!scope.isSession) return _sendAboutRecipe(input, history);
    try {
      final view = await ref.read(cookingControllerProvider(sessionId).future);
      final actions = _cooking.assistantActions;
      final reply = await _service.interpret(
        input,
        state: actions.state,
        recipe: view.displayRecipe,
        now: actions.now(),
        history: history,
        context: {'stage': 'cooking', ...await _preparationContext(view.recipeRow.id)},
      );
      if (reply.action != null && !reply.requiresConfirmation) {
        return _say(await _service.execute(reply.action!, actions));
      }
      return _say(reply, pending: reply.action == null ? null : reply);
    } finally {
      if (ref.mounted) state = state.copyWith(busy: false);
    }
  }

  Future<AssistantReply?> approve() async {
    final pending = state.pending;
    if (pending?.action == null || state.busy) return null;
    state = state.copyWith(clearPending: true, busy: true);
    try {
      return _say(await _service.execute(pending!.action!, _cooking.assistantActions));
    } finally {
      if (ref.mounted) state = state.copyWith(busy: false);
    }
  }

  AssistantReply? reject() {
    if (state.pending == null) return null;
    state = state.copyWith(clearPending: true);
    return _say(AssistantReply(answerHe: lookupAppLocalizations(const Locale('he')).remyRejected));
  }

  /// Before cooking: questions about the recipe only (never an action to approve).
  Future<AssistantReply?> _sendAboutRecipe(AssistantInput input, List<ChatTurn> history) async {
    try {
      final view = await ref.read(preparationServiceProvider).load(scope.id);
      final plan = view?.plan;
      if (view == null || plan == null) {
        return _say(AssistantReply(answerHe: lookupAppLocalizations(const Locale('he')).remyUnavailable));
      }
      final reply = await _service.interpretForPreparation(
        input,
        plan: plan,
        recipe: view.recipe,
        now: ref.read(clockProvider)().toUtc(),
        history: history,
        context: {'stage': 'preparation', ..._summary(view)},
      );
      return _say(reply);
    } finally {
      if (ref.mounted) state = state.copyWith(busy: false);
    }
  }

  /// Creating a recipe: options, a draft to review, or an answer (nothing is saved as a recipe here).
  Future<AssistantReply?> _sendForCreation(AssistantInput input, List<ChatTurn> history) async {
    try {
      final (reply, preferences) = await ref
          .read(recipeCreationServiceProvider)
          .turn(scope.id, input, history: history, preferences: state.context);
      if (ref.mounted) state = state.copyWith(context: preferences);
      return _say(reply);
    } finally {
      if (ref.mounted) state = state.copyWith(busy: false);
    }
  }

  /// What the cook decided while preparing, from the saved preparation (never from the chat):
  /// what is still missing, what is used instead, what is left out.
  Future<Map<String, Object?>> _preparationContext(String recipeId) async {
    final view = await ref.read(preparationServiceProvider).load(recipeId);
    return view == null ? const {} : _summary(view);
  }

  static Map<String, Object?> _summary(PrepView view) {
    final recipe = view.recipe;
    final prep = view.prep;
    final missing = [
      for (final i in recipe.ingredients)
        if (prep.statusOf(i.id) == ItemStatus.missing && prep.substitutionFor(ItemKind.ingredient, i.id) == null && !i.omitted)
          i.name,
      for (final e in recipe.equipment)
        if (prep.statusOf(e.id) == ItemStatus.missing && prep.substitutionFor(ItemKind.equipment, e.id) == null && !e.omitted)
          e.name,
    ];
    final instead = [
      for (final i in recipe.ingredients)
        if (i.substitutedFor case final o? when o != i.name && !i.omitted) {'instead_of': o, 'using': i.name},
      for (final e in recipe.equipment)
        if (e.substitutedFor case final o? when o != e.name && !e.omitted) {'instead_of': o, 'using': e.name},
    ];
    final notUsed = [for (final i in recipe.ingredients) if (i.omitted) i.substitutedFor ?? i.name];
    if (missing.isEmpty && instead.isEmpty && notUsed.isEmpty) return const {};
    return {
      'preparation': {
        if (missing.isNotEmpty) 'missing': missing,
        if (instead.isNotEmpty) 'substitutions': instead,
        if (notUsed.isNotEmpty) 'not_used': notUsed,
      },
    };
  }

  /// What speech recognition delivers: the same pipeline as typed text.
  Future<AssistantReply?> sendSpoken(String transcript) =>
      send(AssistantInput(transcript, modality: InputModality.voice));

  void _addUser(String text, {bool busy = false}) {
    state = state.copyWith(messages: _bounded([...state.messages, ChatMessage(fromUser: true, textHe: text)]), busy: busy ? true : null, clearPending: busy);
    _remember();
  }

  AssistantReply _say(AssistantReply reply, {AssistantReply? pending}) {
    if (!ref.mounted) return reply;
    state = state.copyWith(
      messages: _bounded([
        ...state.messages,
        ChatMessage(fromUser: false, textHe: reply.answerHe, speechHe: reply.speechHe, options: reply.options, recipeId: reply.recipeId),
      ]),
      pending: pending,
    );
    _remember();
    return reply;
  }

  static List<ChatMessage> _bounded(List<ChatMessage> messages) => messages.length > ConversationStore.maxMessages
      ? messages.sublist(messages.length - ConversationStore.maxMessages)
      : messages;
}

/// "כן" → true, "לא" → false, anything else → null (a new request).
bool? yesOrNo(String text) {
  final s = normalizeCommand(text);
  const yes = {'כן', 'כן בבקשה', 'אישור', 'מאשר', 'מאשרת', 'בטח', 'נכון', 'בסדר', 'תעשה את זה', 'תעשי את זה', 'קדימה', 'yes', 'ok'};
  const no = {'לא', 'לא תודה', 'עזוב', 'עזבי', 'לא צריך', 'אל תעשה', 'אל תעשי', 'בטל', 'no'};
  if (yes.contains(s)) return true;
  if (no.contains(s)) return false;
  return null;
}

final assistantControllerProvider =
    NotifierProvider.autoDispose.family<AssistantController, AssistantState, RemyScope>(AssistantController.new);
