import 'package:anyone_can_cook/features/assistant/command_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CommandKind? kind(String s) => parseCommand(s)?.kind;

  test('next / done, in many everyday phrasings (and with the wake word)', () {
    for (final s in ['הבא', 'לשלב הבא', 'סיימתי', 'גמרתי!', 'מוכן', 'רמי, הבא', 'היי רמי סיימתי לחתוך את הירקות', 'בבקשה לשלב הבא']) {
      expect(kind(s), CommandKind.next, reason: s);
    }
  });

  test('back / undo', () {
    for (final s in ['חזרה', 'אחורה', 'תבטל', 'בטל את זה', 'שלב קודם', 'טעות']) {
      expect(kind(s), CommandKind.back, reason: s);
    }
  });

  test('time left, what now, help, pause, resume', () {
    expect(kind('כמה זמן נשאר?'), CommandKind.timeLeft);
    expect(kind('מתי לבדוק את העוף?'), CommandKind.timeLeft);
    expect(kind('מה עכשיו?'), CommandKind.whatNow);
    expect(kind('עזרה'), CommandKind.help);
    expect(kind('איך יודעים שזה מוכן?'), CommandKind.help);
    expect(kind('תעצור את הטיימר'), CommandKind.pauseTimer);
    expect(kind('המשך את הטיימר'), CommandKind.resumeTimer);
  });

  test('extend a timer by a spoken duration', () {
    int? seconds(String s) => parseCommand(s)?.seconds;
    expect(kind('תוסיף 5 דקות'), CommandKind.extendTimer);
    expect(seconds('תוסיף 5 דקות'), 300);
    expect(seconds('תוסיף עוד שתי דקות לאורז'), 120);
    expect(seconds('עוד דקה'), 60);
    expect(seconds('תאריך בדקה וחצי'), 90);
    expect(seconds('תוסיף רבע שעה'), 900);
    expect(seconds('תוסיף חצי שעה'), 1800);
    expect(seconds('עוד 30 שניות'), 30);
    expect(seconds('תוסיף שעה'), 3600);
  });

  test('a reported real-world action vs. an intention', () {
    final done = parseCommand('הכנסתי את העוגה לתנור')!;
    expect((done.kind, done.intention), (CommandKind.reportedAction, false));
    final later = parseCommand('אני עומד להכניס לתנור')!;
    expect((later.kind, later.intention), (CommandKind.reportedAction, true));
    expect(parseCommand('הדלקתי את התנור')!.kind, CommandKind.reportedAction);
  });

  test('questions that need reasoning go to Remy', () {
    for (final s in ['מה זה לקפל?', 'למה הבצק דביק?', 'אין לי חמאה', 'מה עושים אם זה שורף למטה?', 'אפשר להשתמש בשמן במקום חמאה?']) {
      expect(parseCommand(s), isNull, reason: s);
    }
  });

  test('stems match conjugations: report ↔ imperative', () {
    expect(stemsOf('הדלקתי את התנור'), stemsOf('הדליקו את התנור על 200 מעלות').take(2).toList());
    expect(stemsOf('הכנסתי את העוגה לתנור').toSet().containsAll(stemsOf('הכנסתי לתנור')), isTrue);
  });
}
