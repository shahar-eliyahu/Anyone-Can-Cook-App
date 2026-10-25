import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../data/providers.dart';
import '../../data/settings_repository.dart';

/// One message of a conversation with Remy.
class ChatMessage {
  const ChatMessage({required this.fromUser, required this.textHe, String? speechHe, this.options = const [], this.recipeId})
      : speechHe = speechHe ?? textHe;
  final bool fromUser;
  final String textHe;

  /// What text-to-speech says for this message.
  final String speechHe;

  /// Recipe creation: the dishes Remy offered, and the draft he created.
  final List<String> options;
  final String? recipeId;

  Map<String, Object?> toJson() => {
        'u': fromUser,
        't': textHe,
        if (speechHe != textHe) 's': speechHe,
        if (options.isNotEmpty) 'o': options,
        'r': ?recipeId,
      };

  static ChatMessage fromJson(Map<String, dynamic> j) => ChatMessage(
        fromUser: j['u'] == true,
        textHe: j['t'] as String,
        speechHe: j['s'] as String?,
        options: [for (final o in j['o'] as List? ?? const []) o as String],
        recipeId: j['r'] as String?,
      );
}

/// Remy's memory of the current recipe (docs/DECISIONS.md #81): one conversation per recipe or
/// draft, shared by preparation and cooking, kept on the device (survives closing the sheet,
/// leaving the screen and restarting the app), bounded to [maxMessages], forgotten after
/// [forgetAfter] without activity, and cleared when the recipe is finished, abandoned,
/// deleted or its draft discarded. Never the recipe itself: the saved recipe and plan stay the
/// source of truth. A recipe-creation conversation (DECISIONS #86) is stored the same way under
/// its own id, with the preferences gathered so far ([loadContext]); the draft it creates gets
/// that id, so discarding the draft ends the conversation too.
class ConversationStore {
  ConversationStore(this._settings, this._clock);

  final SettingsRepository _settings;
  final DateTime Function() _clock;

  static const maxMessages = 20;
  static const forgetAfter = Duration(hours: 12);

  static String keyFor(String recipeId) => 'remy_chat:$recipeId';

  Future<List<ChatMessage>> load(String recipeId) async =>
      [for (final m in (await _read(recipeId))?['m'] as List? ?? const []) ChatMessage.fromJson(m as Map<String, dynamic>)];

  /// What a recipe-creation conversation gathered so far (servings, time, diet...); empty otherwise.
  Future<Map<String, Object?>> loadContext(String recipeId) async =>
      ((await _read(recipeId))?['c'] as Map<String, dynamic>?) ?? const {};

  Future<Map<String, dynamic>?> _read(String recipeId) async {
    final raw = await _settings.get(keyFor(recipeId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.tryParse(data['at'] as String? ?? '');
      if (at == null || _clock().toUtc().difference(at) > forgetAfter) {
        await clear(recipeId);
        return null;
      }
      for (final m in data['m'] as List) {
        ChatMessage.fromJson(m as Map<String, dynamic>); // a damaged conversation is dropped whole
      }
      return data;
    } on FormatException {
      await clear(recipeId);
      return null;
    } on TypeError {
      await clear(recipeId);
      return null;
    }
  }

  Future<void> save(String recipeId, List<ChatMessage> messages, {Map<String, Object?> context = const {}}) async {
    if (messages.isEmpty) return clear(recipeId);
    final kept = messages.length > maxMessages ? messages.sublist(messages.length - maxMessages) : messages;
    await _settings.set(
      keyFor(recipeId),
      jsonEncode({
        'at': _clock().toUtc().toIso8601String(),
        'm': [for (final m in kept) m.toJson()],
        if (context.isNotEmpty) 'c': context,
      }),
    );
  }

  Future<void> clear(String recipeId) => _settings.delete(keyFor(recipeId));
}

final conversationStoreProvider = Provider<ConversationStore>(
  (ref) => ConversationStore(ref.watch(settingsRepositoryProvider), ref.watch(clockProvider)),
);

/// Ends a recipe's conversation (finish, abandon, delete, discard) without touching anything else.
Future<void> forgetConversation(SettingsRepository settings, String recipeId) =>
    settings.delete(ConversationStore.keyFor(recipeId));

