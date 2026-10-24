import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../cooking/cooking_controller.dart';
import 'assistant_models.dart';
import 'assistant_service.dart';
import 'command_parser.dart';

class ChatMessage {
  const ChatMessage({required this.fromUser, required this.textHe, String? speechHe}) : speechHe = speechHe ?? textHe;
  final bool fromUser;
  final String textHe;

  /// What a future text-to-speech voice would say (Phase 3D).
  final String speechHe;
}

class AssistantState {
  const AssistantState({this.messages = const [], this.pending, this.busy = false});
  final List<ChatMessage> messages;

  /// A reply waiting for the cook's approval ("אישור" / "לא, תודה").
  final AssistantReply? pending;
  final bool busy;

  AssistantState copyWith({List<ChatMessage>? messages, AssistantReply? pending, bool clearPending = false, bool? busy}) =>
      AssistantState(
        messages: messages ?? this.messages,
        pending: clearPending ? null : pending ?? this.pending,
        busy: busy ?? this.busy,
      );
}

final assistantServiceProvider = Provider<AssistantService>((ref) => AssistantService(ref.watch(apiClientProvider)));

/// One conversation with Remy per cooking session (kept in memory while the session is
/// open). The single entry point [send] serves typed text now and speech in Phase 3D.
class AssistantController extends Notifier<AssistantState> {
  AssistantController(this.sessionId);

  final String sessionId;

  @override
  AssistantState build() => const AssistantState();

  AssistantService get _service => ref.read(assistantServiceProvider);
  CookingController get _cooking => ref.read(cookingControllerProvider(sessionId).notifier);

  /// One message from the cook, typed or spoken. Returns what Remy answered (the voice
  /// controller reads it aloud), or null when nothing was sent.
  Future<AssistantReply?> send(AssistantInput input) async {
    final text = input.text.trim();
    if (text.isEmpty || state.busy) return null;
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
    final history = [for (final m in state.messages) ChatTurn(fromUser: m.fromUser, textHe: m.textHe)];
    state = state.copyWith(
      messages: [...state.messages, ChatMessage(fromUser: true, textHe: text)],
      busy: true,
      clearPending: true,
    );
    try {
      final view = await ref.read(cookingControllerProvider(sessionId).future);
      final actions = _cooking.assistantActions;
      final reply = await _service.interpret(
        input,
        state: actions.state,
        recipe: view.displayRecipe,
        now: actions.now(),
        history: history,
      );
      if (reply.action != null && !reply.requiresConfirmation) {
        return _say(await _service.execute(reply.action!, actions));
      }
      return _say(reply, pending: reply.action == null ? null : reply);
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<AssistantReply?> approve() async {
    final pending = state.pending;
    if (pending?.action == null || state.busy) return null;
    state = state.copyWith(clearPending: true, busy: true);
    try {
      return _say(await _service.execute(pending!.action!, _cooking.assistantActions));
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  AssistantReply? reject() {
    if (state.pending == null) return null;
    state = state.copyWith(clearPending: true);
    return _say(AssistantReply(answerHe: lookupAppLocalizations(const Locale('he')).remyRejected));
  }

  /// What speech recognition delivers: the same pipeline as typed text.
  Future<AssistantReply?> sendSpoken(String transcript) =>
      send(AssistantInput(transcript, modality: InputModality.voice));

  void _addUser(String text) =>
      state = state.copyWith(messages: [...state.messages, ChatMessage(fromUser: true, textHe: text)]);

  AssistantReply _say(AssistantReply reply, {AssistantReply? pending}) {
    state = state.copyWith(
      messages: [...state.messages, ChatMessage(fromUser: false, textHe: reply.answerHe, speechHe: reply.speechHe)],
      pending: pending,
    );
    return reply;
  }
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
    NotifierProvider.autoDispose.family<AssistantController, AssistantState, String>(AssistantController.new);
