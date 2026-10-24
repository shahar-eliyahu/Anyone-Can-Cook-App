import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../cooking/cooking_controller.dart';
import 'assistant_models.dart';
import 'assistant_service.dart';
import 'voice.dart';

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

  Future<void> send(AssistantInput input) async {
    final text = input.text.trim();
    if (text.isEmpty || state.busy) return;
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
      final spoken = input.modality == InputModality.voice;
      if (reply.action != null && !reply.requiresConfirmation) {
        final result = await _service.execute(reply.action!, actions);
        _say(result, speak: spoken);
      } else {
        _say(reply, pending: reply.action == null ? null : reply, speak: spoken);
      }
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<void> approve() async {
    final pending = state.pending;
    if (pending?.action == null || state.busy) return;
    state = state.copyWith(clearPending: true, busy: true);
    try {
      _say(await _service.execute(pending!.action!, _cooking.assistantActions));
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  void reject() {
    if (state.pending == null) return;
    final text = _rejectedText;
    state = state.copyWith(clearPending: true, messages: [...state.messages, ChatMessage(fromUser: false, textHe: text)]);
  }

  String get _rejectedText => lookupAppLocalizations(const Locale('he')).remyRejected;

  /// What speech recognition delivers: the same pipeline as typed text.
  Future<void> sendSpoken(String transcript) => send(AssistantInput(transcript, modality: InputModality.voice));

  void _say(AssistantReply reply, {AssistantReply? pending, bool speak = false}) {
    state = state.copyWith(
      messages: [...state.messages, ChatMessage(fromUser: false, textHe: reply.answerHe, speechHe: reply.speechHe)],
      pending: pending,
    );
    // Spoken requests get spoken answers (silent until a text-to-speech engine is added).
    if (speak) ref.read(speechSynthesizerProvider).speak(reply.speechHe);
  }
}

final assistantControllerProvider =
    NotifierProvider.autoDispose.family<AssistantController, AssistantState, String>(AssistantController.new);
