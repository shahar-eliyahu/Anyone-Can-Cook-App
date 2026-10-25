import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../data/providers.dart';
import '../../data/settings_repository.dart';

/// One message of a conversation with Remy.
class ChatMessage {
  const ChatMessage({required this.fromUser, required this.textHe, String? speechHe}) : speechHe = speechHe ?? textHe;
  final bool fromUser;
  final String textHe;

  /// What text-to-speech says for this message.
  final String speechHe;

  Map<String, Object?> toJson() => {'u': fromUser, 't': textHe, if (speechHe != textHe) 's': speechHe};

  static ChatMessage fromJson(Map<String, dynamic> j) =>
      ChatMessage(fromUser: j['u'] == true, textHe: j['t'] as String, speechHe: j['s'] as String?);
}

/// Remy's memory of the current recipe (docs/DECISIONS.md #81): one conversation per recipe or
/// draft, shared by preparation and cooking, kept on the device (survives closing the sheet,
/// leaving the screen and restarting the app), bounded to [maxMessages], forgotten after
/// [forgetAfter] without activity, and cleared when the recipe is finished, abandoned,
/// deleted or its draft discarded. Never the recipe itself: the saved recipe and plan stay the
/// source of truth.
class ConversationStore {
  ConversationStore(this._settings, this._clock);

  final SettingsRepository _settings;
  final DateTime Function() _clock;

  static const maxMessages = 20;
  static const forgetAfter = Duration(hours: 12);

  static String keyFor(String recipeId) => 'remy_chat:$recipeId';

  Future<List<ChatMessage>> load(String recipeId) async {
    final raw = await _settings.get(keyFor(recipeId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.tryParse(data['at'] as String? ?? '');
      if (at == null || _clock().toUtc().difference(at) > forgetAfter) {
        await clear(recipeId);
        return const [];
      }
      return [for (final m in data['m'] as List) ChatMessage.fromJson(m as Map<String, dynamic>)];
    } on FormatException {
      await clear(recipeId);
      return const [];
    } on TypeError {
      await clear(recipeId);
      return const [];
    }
  }

  Future<void> save(String recipeId, List<ChatMessage> messages) async {
    if (messages.isEmpty) return clear(recipeId);
    final kept = messages.length > maxMessages ? messages.sublist(messages.length - maxMessages) : messages;
    await _settings.set(
      keyFor(recipeId),
      jsonEncode({'at': _clock().toUtc().toIso8601String(), 'm': [for (final m in kept) m.toJson()]}),
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

