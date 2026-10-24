/// Local-first understanding of the cook's Hebrew (Phase 3B, refined in 3D): no network,
/// no AI. Typed text and recognized speech use the same parser.
///
/// Not exact phrases: words are matched by families (synonyms and verb forms), with a
/// one-letter tolerance for longer words (typos, transcription slips). The parser only
/// classifies; `AssistantService` resolves a command against the live cooking state and
/// decides whether to act, ask, or hand the message to Remy (Gemini) as a fallback.
library;

enum CommandKind {
  next,
  back,
  timeLeft,
  whatNow,
  nextStepPreview,
  help,
  pauseTimer,
  resumeTimer,
  extendTimer,
  reportedAction,
  ingredientAmount,
  temperature,
  stepIngredients,
  stepsLeft,
}

class ParsedCommand {
  const ParsedCommand(
    this.kind, {
    required this.normalized,
    this.seconds,
    this.intention = false,
    this.uncertain = false,
    this.fuzzy = false,
    this.subject,
  });

  final CommandKind kind;

  /// The cleaned-up text (for matching action labels, timers and ingredients).
  final String normalized;

  /// For [CommandKind.extendTimer]: the duration asked for.
  final int? seconds;

  /// For [CommandKind.reportedAction]: ABOUT to do it ("אני עומד להכניס") — never a confirmation.
  final bool intention;

  /// The cook sounded unsure ("אולי צריך עוד 5 דקות?"): ask before acting.
  final bool uncertain;

  /// Recognized only through a near match (a typo or transcription slip): ask before acting.
  final bool fuzzy;

  /// For [CommandKind.ingredientAmount]: the words naming the ingredient.
  final String? subject;

  bool get needsConfirmation => uncertain || fuzzy;
}

const _wakeWords = ['היי רמי', 'הי רמי', 'שלום רמי', 'רמי'];
const _fillers = ['בבקשה', 'אפשר', 'תגיד לי', 'תגידי לי', 'תגיד', 'תגידי', 'יאללה', 'אוקיי', 'אוקי', 'טוב', 'רגע', 'אז', 'נו'];

/// Lowercase, no niqqud or punctuation, common transcription forms unified, no wake word
/// or filler words.
String normalizeCommand(String text) {
  var s = text
      .replaceAll(RegExp('[֑-ׇ]'), '')
      .replaceAll(RegExp(r'''[.,!?;:'"״׳()\-–—]'''), ' ')
      .toLowerCase()
      .replaceAllMapped(RegExp(r'(\d)\s*(דק|דק׳)(\s|$)'), (m) => '${m[1]} דקות${m[3]}')
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
  if (RegExp(r'(^| )חצי דקה').hasMatch(s)) return 30;
  final m = RegExp(r'(\d+(?:\.\d+)?|חמש עשרה|[א-ת]+)?\s*(דקות|דקה|שניות|שנייה|שניה|שעות|שעה)( וחצי)?').firstMatch(s);
  if (m == null) return null;
  final unit = m.group(2)!;
  final perUnit = unit.startsWith('ש') ? (unit.startsWith('שע') ? 3600 : 1) : 60;
  final word = m.group(1);
  if (word == 'כמה') return null; // "כמה דקות" is a question, not a duration
  var count = 1.0; // "עוד דקה", "שעה"
  if (word != null) {
    // "בחמש דקות", "לשתי דקות": a prefix letter before the number word.
    final bare = word.length > 2 && 'בלו'.contains(word[0]) ? word.substring(1) : word;
    count = double.tryParse(word) ?? _numberWords[word]?.toDouble() ?? _numberWords[bare]?.toDouble() ?? 1;
  }
  if (m.group(3) != null) count += 0.5;
  final seconds = (count * perUnit).round();
  return seconds > 0 ? seconds : null;
}

// ---- word families ------------------------------------------------------------------------------

const _nextWords = [
  'הבא', 'הבאה', 'הלאה', 'קדימה', 'ממשיכים', 'נמשיך', 'סיימתי', 'סיימנו', 'סיימת', 'גמרתי', 'גמרנו',
  'הסתיים', 'מוכן', 'מוכנה', 'מוכנים', 'בוצע', 'עשיתי', 'עשינו', 'next', 'done',
];
const _backWords = [
  'חזרה', 'חזור', 'תחזור', 'תחזרי', 'נחזור', 'אחורה', 'בטל', 'תבטל', 'תבטלי', 'לבטל', 'ביטול',
  'טעות', 'טעיתי', 'תחזיר', 'תחזירי', 'undo', 'back',
];
const _pauseWords = ['עצור', 'תעצור', 'תעצרי', 'לעצור', 'השהה', 'תשהה', 'השהיה', 'תקפיא', 'להשהות'];
const _resumeWords = ['המשך', 'תמשיך', 'תמשיכי', 'להמשיך', 'תפעיל', 'תפעילי', 'הפעל'];
const _extendWords = [
  'תוסיף', 'תוסיפי', 'הוסף', 'להוסיף', 'תאריך', 'תאריכי', 'הארך', 'להאריך', 'תן', 'תני', 'עוד', 'תשאיר',
];
const _helpWords = ['עזרה', 'תעזור', 'תעזרי', 'עזור', 'הסבר', 'תסביר', 'תסבירי'];
const _uncertainty = ['אולי', 'נראה לי', 'לא בטוח', 'לא בטוחה', 'כנראה', 'יכול להיות', 'חושב ש', 'חושבת ש'];
const _intentionWords = [
  'עומד', 'עומדת', 'הולך', 'הולכת', 'אכניס', 'נכניס', 'אשים', 'נשים', 'אניח', 'נניח', 'אדליק', 'נדליק',
  'רוצה', 'אמור', 'אמורה', 'תיכף', 'מיד', 'בקרוב',
];
const _knownReportVerbs = [
  'הכנסתי', 'שמתי', 'הנחתי', 'כיסיתי', 'הדלקתי', 'הוספתי', 'העברתי', 'התחלתי', 'הרתחתי', 'יצקתי',
  'פיזרתי', 'סגרתי', 'הוצאתי', 'כיביתי', 'הפכתי', 'טיגנתי', 'אפיתי', 'בישלתי', 'חיממתי', 'ערבבתי',
  'הכנסנו', 'שמנו', 'הנחנו', 'הוצאנו', 'כיסינו', 'הדלקנו', 'הרתחנו', 'התחלנו',
];

/// Messages that need reasoning go to Remy even if they contain a command word.
const _reasoning = ['מה זה', 'למה', 'אין לי', 'אין לנו', 'במקום', 'תחליף', 'מה עושים אם', 'מה קורה אם', 'אפשר להשתמש', 'שורף', 'דביק', 'נשרף'];

int _distance(String a, String b) {
  if ((a.length - b.length).abs() > 1) return 2;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = [i, ...List.filled(b.length, 0)];
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost].reduce((x, y) => x < y ? x : y);
    }
    prev = cur;
  }
  return prev[b.length];
}

/// 0: exact word (also after one prefix letter: "שסיימתי", "והבא"); 1: near (one letter off,
/// words of 5+ letters — shorter words are too easily confused, e.g. מוכר/מוכן); null: none.
int? _match(List<String> tokens, List<String> family) {
  int? best;
  for (final token in tokens) {
    final forms = [token, if (token.length > 3 && 'שוהבלכמ'.contains(token[0])) token.substring(1)];
    for (final t in forms) {
      for (final w in family) {
        if (t == w) return 0;
        if (t.length >= 5 && w.length >= 5 && _distance(t, w) == 1) best = 1;
      }
    }
  }
  return best;
}

bool _has(String s, List<String> phrases) => phrases.any((p) => RegExp('(^| )$p( |\$)').hasMatch(s) || (p.contains(' ') && s.contains(p)));

/// Classifies a cook's message, or null when it isn't something the app understands
/// confidently on its own (then Remy may interpret it).
ParsedCommand? parseCommand(String text) {
  final asked = text.trim().endsWith('?');
  final s = normalizeCommand(text);
  if (s.isEmpty) return null;
  final tokens = s.split(' ');
  final uncertain = _has(s, _uncertainty);
  ParsedCommand cmd(CommandKind k, {int? seconds, bool intention = false, bool fuzzy = false, String? subject}) =>
      ParsedCommand(k, normalized: s, seconds: seconds, intention: intention, uncertain: uncertain, fuzzy: fuzzy, subject: subject);

  if (_reasoning.any(s.contains)) return null;

  // Time questions (before extensions: "עוד כמה דקות נשארו?" asks, it doesn't extend).
  if (_has(s, ['כמה זמן', 'כמה נשאר', 'כמה עוד', 'עוד כמה', 'כמה דקות', 'מה עם הטיימר', 'מה מצב הטיימר', 'איפה הטיימר', 'מתי לבדוק', 'מתי זה מוכן', 'מתי זה נגמר', 'מתי נגמר'])) {
    return cmd(CommandKind.timeLeft);
  }
  // Extend: a duration plus an extend word ("תן לזה עוד 4 דקות", "צריך עוד דקה"); "עוד קצת" has
  // no duration — the service suggests the plan's re-check time and asks.
  if (_match(tokens, _extendWords) case final m?) {
    if (parseDuration(s) case final seconds?) return cmd(CommandKind.extendTimer, seconds: seconds, fuzzy: m == 1);
    if (_has(s, ['עוד קצת', 'עוד טיפה', 'עוד קצת זמן'])) return cmd(CommandKind.extendTimer, fuzzy: true);
  }
  if (_has(s, ['כמה שלבים'])) return cmd(CommandKind.stepsLeft);
  if (_has(s, ['כמה מעלות', 'איזה חום', 'באיזה חום', 'באיזו טמפרטורה', 'איזו טמפרטורה', 'מה הטמפרטורה', 'טמפרטורה'])) {
    return cmd(CommandKind.temperature);
  }
  if (_has(s, ['מה השלב הבא', 'מה אחרי זה', 'מה בהמשך', 'מה יהיה אחר כך', 'מה אחר כך', 'מה הבא'])) {
    return cmd(CommandKind.nextStepPreview);
  }
  if (_has(s, ['מה עכשיו', 'מה השלב', 'מה עושים עכשיו', 'מה עושים', 'איפה אנחנו', 'באיזה שלב', 'מה אני צריך לעשות', 'מה אני צריכה לעשות'])) {
    return cmd(CommandKind.whatNow);
  }
  if (_has(s, ['מה צריך לשלב', 'אילו מצרכים', 'מה המצרכים', 'מה צריך עכשיו', 'מה צריך לזה'])) {
    return cmd(CommandKind.stepIngredients);
  }
  // "כמה מלח?" / "כמה שמן צריך" — an amount from the saved recipe.
  final amount = RegExp(r'(^| )כמה ([א-ת][א-ת ]*)').firstMatch(s);
  if (amount != null) {
    final subject = amount.group(2)!.replaceAll(RegExp(r' ?(צריך|צריכה|שמים|לשים|להוסיף|יש|בדיוק)( |$)'), ' ').trim();
    if (subject.isNotEmpty) return cmd(CommandKind.ingredientAmount, subject: subject);
  }
  if (_match(tokens, _helpWords) == 0 || _has(s, ['לא הבנתי', 'איך יודעים', 'איך אני יודע', 'איך אדע', 'איך עושים', 'עזרה בשלב'])) {
    return cmd(CommandKind.help);
  }
  final timerWord = _has(s, ['טיימר', 'הטיימר', 'שעון', 'השעון']);
  if (_match(tokens, _pauseWords) case final m?) {
    if (timerWord || tokens.length <= 2) return cmd(CommandKind.pauseTimer, fuzzy: m == 1);
  }
  if (timerWord) {
    if (_match(tokens, _resumeWords) case final m?) return cmd(CommandKind.resumeTimer, fuzzy: m == 1);
  }
  if (_match(tokens, _backWords) case final m? when !_has(s, ['טיימר'])) {
    return cmd(CommandKind.back, fuzzy: m == 1);
  }
  if (_has(s, ['שלב קודם', 'לשלב הקודם', 'לא התכוונתי', 'זה היה בטעות'])) return cmd(CommandKind.back);
  // A real-world action reported (past tense) or about to happen (intention).
  final intention = _has(s, _intentionWords) || _has(s, ['צריך ל', 'עוד מעט']);
  final reports = _match(tokens, _knownReportVerbs) != null ||
      tokens.any((t) => t.length >= 4 && (t.endsWith('תי') || t.endsWith('נו')) && !const {'מתי', 'אותי', 'שלנו', 'אותנו', 'לנו', 'שלי'}.contains(t));
  // "סיימתי" also ends like a report: an exact next-word means "next".
  final exactNext = _match(tokens, _nextWords) == 0;
  if (reports && !exactNext) return cmd(CommandKind.reportedAction, intention: intention);
  if (intention && _has(s, ['להכניס', 'לשים', 'להניח', 'להדליק', 'להוציא', 'לכסות'])) {
    return cmd(CommandKind.reportedAction, intention: true);
  }
  if (_match(tokens, _nextWords) case final m?) {
    // "מוכן?" asks whether it's ready — answer with the step's cue, don't move on.
    if (asked && tokens.length <= 3) return cmd(CommandKind.help);
    return cmd(CommandKind.next, fuzzy: m == 1);
  }
  if (_has(s, ['לשלב הבא', 'שלב הבא', 'תעביר'])) return cmd(CommandKind.next);
  if (reports) return cmd(CommandKind.reportedAction, intention: intention);
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
