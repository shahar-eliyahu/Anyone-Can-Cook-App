/// Deterministic recognition of simple Hebrew cooking commands (Phase 3B): no network,
/// no AI. Typed text now and recognized speech later use the same parser.
///
/// The parser only classifies; [AssistantService] resolves a command against the live
/// cooking state and decides whether to act, propose or just answer.
library;

enum CommandKind { next, back, timeLeft, whatNow, help, pauseTimer, resumeTimer, extendTimer, reportedAction }

class ParsedCommand {
  const ParsedCommand(this.kind, {required this.normalized, this.seconds, this.intention = false});
  final CommandKind kind;

  /// The cleaned-up text (for matching action labels and timer names).
  final String normalized;

  /// For [CommandKind.extendTimer]: the duration the cook asked for.
  final int? seconds;

  /// For [CommandKind.reportedAction]: the cook said they're ABOUT to do it ("אני עומד
  /// להכניס"), so nothing may be confirmed.
  final bool intention;
}

const _wakeWords = ['היי רמי', 'הי רמי', 'רמי'];
const _fillers = ['בבקשה', 'אפשר', 'תגיד לי', 'תגידי לי', 'תגיד', 'תגידי', 'יאללה', 'אוקיי', 'טוב'];

/// Lowercase, no niqqud or punctuation, no wake word or filler words.
String normalizeCommand(String text) {
  var s = text
      .replaceAll(RegExp('[֑-ׇ]'), '')
      .replaceAll(RegExp(r'''[.,!?;:'"״׳()\-–—]'''), ' ')
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  for (final w in _wakeWords) {
    if (s.startsWith('$w ') || s == w) s = s.substring(w.length).trim();
  }
  for (final f in _fillers) {
    s = s.replaceAll(RegExp('(^| )$f( |\$)'), ' ').trim();
  }
  return s.replaceAll(RegExp(r'\s+'), ' ');
}

const _numberWords = {
  'אחת': 1, 'אחד': 1, 'שתיים': 2, 'שתי': 2, 'שניים': 2, 'שני': 2, 'שלוש': 3, 'שלושה': 3,
  'ארבע': 4, 'ארבעה': 4, 'חמש': 5, 'חמישה': 5, 'שש': 6, 'שישה': 6, 'שבע': 7, 'שבעה': 7,
  'שמונה': 8, 'תשע': 9, 'תשעה': 9, 'עשר': 10, 'עשרה': 10, 'חמש עשרה': 15, 'עשרים': 20, 'שלושים': 30,
};

/// "5 דקות", "שתי דקות", "דקה וחצי", "רבע שעה", "חצי שעה", "שעה", "30 שניות" → seconds.
int? parseDuration(String s) {
  if (RegExp(r'(^| )רבע שעה').hasMatch(s)) return 900;
  if (RegExp(r'(^| )חצי שעה').hasMatch(s)) return 1800;
  final m = RegExp(r'(\d+(?:\.\d+)?|חמש עשרה|[א-ת]+)?\s*(דקות|דקה|דק|שניות|שנייה|שניה|שעות|שעה)( וחצי)?').firstMatch(s);
  if (m == null) return null;
  final unit = m.group(2)!;
  final perUnit = unit.startsWith('ש') ? (unit.startsWith('שע') ? 3600 : 1) : 60;
  final word = m.group(1);
  double? count;
  if (word == null) {
    count = 1; // "עוד דקה", "שעה"
  } else if (double.tryParse(word) case final n?) {
    count = n;
  } else if (_numberWords[word] case final n?) {
    count = n.toDouble();
  } else {
    count = 1; // "עוד דקה" with a leading verb captured as the word
  }
  if (m.group(3) != null) count += 0.5;
  final seconds = (count * perUnit).round();
  return seconds > 0 ? seconds : null;
}

bool _any(String s, List<String> phrases) => phrases.any(s.contains);

bool _isOneOf(String s, List<String> phrases) => phrases.contains(s);

// Past-tense reports of a real-world action ("הכנסתי", "שמתי"…).
final _reportVerbs = RegExp(r'(^| )(הכנסתי|שמתי|הנחתי|כיסיתי|הדלקתי|הוספתי|העברתי|התחלתי|הרתחתי|יצקתי|פיזרתי|סגרתי|הוצאתי|כיביתי|הפכתי|טיגנתי|אפיתי|בישלתי|הרתחנו|הכנסנו|שמנו|הנחנו|הוצאנו|כיסינו|הדלקנו)( |$)');
// Intentions: about to do it — never a confirmation.
final _intentionWords = RegExp(r'(^| )(עומד|עומדת|הולך|הולכת|אכניס|נכניס|אשים|נשים|צריך|צריכה|רוצה|אמור|אמורה|עוד מעט|תיכף)( |$)');

/// Classifies a cook's message, or null when it isn't a simple command (ask Remy).
ParsedCommand? parseCommand(String text) {
  final s = normalizeCommand(text);
  if (s.isEmpty) return null;
  ParsedCommand cmd(CommandKind k, {int? seconds, bool intention = false}) =>
      ParsedCommand(k, normalized: s, seconds: seconds, intention: intention);

  // Questions that need reasoning go to Remy even if they contain a keyword.
  if (_any(s, ['מה זה', 'למה', 'מה אפשר', 'במקום', 'אין לי', 'תחליף', 'מה עושים אם'])) return null;

  if (_any(s, ['תוסיף', 'תוסיפי', 'הוסף', 'להוסיף', 'תאריך', 'הארך', 'להאריך', 'תן עוד', 'עוד '])) {
    if (parseDuration(s) case final seconds?) return cmd(CommandKind.extendTimer, seconds: seconds);
  }
  if (_any(s, ['כמה זמן', 'כמה נשאר', 'מתי לבדוק', 'מתי זה מוכן', 'מתי זה נגמר', 'כמה עוד'])) {
    return cmd(CommandKind.timeLeft);
  }
  if (_any(s, ['עצור טיימר', 'עצור את הטיימר', 'תעצור', 'השהה', 'תשהה', 'השהיה'])) return cmd(CommandKind.pauseTimer);
  if (_any(s, ['המשך טיימר', 'תמשיך את הטיימר', 'המשך את הטיימר', 'להמשיך את הטיימר', 'תפעיל שוב'])) {
    return cmd(CommandKind.resumeTimer);
  }
  if (_any(s, ['מה עכשיו', 'מה השלב', 'מה עושים עכשיו', 'מה הלאה', 'איפה אני', 'באיזה שלב'])) return cmd(CommandKind.whatNow);
  if (_isOneOf(s, ['עזרה', 'תעזור', 'תעזרי', 'הסבר', 'תסביר', 'לא הבנתי', 'help']) ||
      _any(s, ['איך יודעים', 'איך אני יודע', 'איך אדע', 'עזרה בשלב', 'עזור לי'])) {
    return cmd(CommandKind.help);
  }
  if (_isOneOf(s, ['חזרה', 'אחורה', 'חזור', 'תחזור', 'שלב קודם', 'לשלב הקודם', 'קודם', 'בטל', 'תבטל', 'ביטול', 'טעות', 'undo', 'back']) ||
      s.startsWith('בטל ') || s.startsWith('תבטל ') || s.startsWith('חזור ') || s.startsWith('חזרה ')) {
    return cmd(CommandKind.back);
  }
  if (_reportVerbs.hasMatch(s) || _intentionWords.hasMatch(s) && _any(s, ['להכניס', 'לשים', 'להניח', 'להדליק', 'להוציא'])) {
    return cmd(CommandKind.reportedAction, intention: _intentionWords.hasMatch(s));
  }
  if (_isOneOf(s, ['הבא', 'לשלב הבא', 'שלב הבא', 'הלאה', 'קדימה', 'סיימתי', 'גמרתי', 'סיימנו', 'מוכן', 'זה מוכן', 'מוכן לשלב הבא', 'בוצע', 'עשיתי', 'next', 'done']) ||
      s.contains('לשלב הבא') || s.startsWith('סיימתי') || s.startsWith('גמרתי') || s.startsWith('סיימנו')) {
    return cmd(CommandKind.next);
  }
  return null;
}

/// Word stems for matching a report ("הדלקתי את התנור") with an action label or prep task
/// ("הדליקו את התנור"): one Hebrew prefix (ה, ו, ב, ל, מ, ש, כ) removed, the vowel letters ו/י
/// dropped after the first letter (so conjugations share a stem: דלק, כנס, תנר), the first
/// three letters kept. Stop words, numbers and very short words are skipped. In order.
List<String> stemsOf(String text) {
  const stop = {'את', 'על', 'עם', 'של', 'זה', 'לתוך', 'אני', 'כבר', 'עכשיו', 'גם', 'רק', 'הכל', 'הכול'};
  final result = <String>[];
  for (var w in normalizeCommand(text).split(' ')) {
    if (stop.contains(w) || RegExp(r'\d').hasMatch(w)) continue;
    if (w.length > 3 && 'הובלמשכ'.contains(w[0])) w = w.substring(1);
    if (w.isEmpty) continue;
    w = w[0] + w.substring(1).replaceAll(RegExp('[וי]'), '');
    if (w.length < 2) continue;
    final stem = w.length > 3 ? w.substring(0, 3) : w;
    if (!result.contains(stem)) result.add(stem);
  }
  return result;
}
