import 'package:anyone_can_cook/features/assistant/assistant_controller.dart';
import 'package:anyone_can_cook/features/assistant/voice.dart';
import 'package:anyone_can_cook/features/assistant/voice_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android/iOS recognition errors map to what the cook can do', () {
    expect(PlatformSpeechRecognizer.issueFor('error_network'), VoiceIssue.network);
    expect(PlatformSpeechRecognizer.issueFor('error_server_disconnected'), VoiceIssue.network);
    expect(PlatformSpeechRecognizer.issueFor('error_no_match'), VoiceIssue.noSpeech);
    expect(PlatformSpeechRecognizer.issueFor('error_speech_timeout'), VoiceIssue.noSpeech);
    expect(PlatformSpeechRecognizer.issueFor('error_insufficient_permissions'), VoiceIssue.permissionDenied);
    expect(PlatformSpeechRecognizer.issueFor('error_language_unavailable'), VoiceIssue.hebrewUnsupported);
    expect(PlatformSpeechRecognizer.issueFor('error_busy'), VoiceIssue.other);
  });

  test('spoken yes / no answers a pending confirmation; anything else is a new request', () {
    for (final yes in ['כן', 'כן בבקשה', 'בטח', 'אישור', 'כן.', 'קדימה!']) {
      expect(yesOrNo(yes), isTrue, reason: yes);
    }
    for (final no in ['לא', 'לא תודה', 'עזוב', 'בטל']) {
      expect(yesOrNo(no), isFalse, reason: no);
    }
    for (final other in ['כמה זמן נשאר?', 'לא יודע כמה מלח', 'סיימתי']) {
      expect(yesOrNo(other), isNull, reason: other);
    }
  });
}
