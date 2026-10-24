/// "היי רמי" heard; [command] is what followed it ("היי רמי, סיימתי" → "סיימתי"), empty
/// when the cook only called him.
class WakeMatch {
  const WakeMatch(this.command);
  final String command;
}

const _names = {'רמי', 'רמיי', 'ראמי', 'remy', 'rami', 'ramy'};
const _greetings = {'היי', 'הי', 'האי', 'אהלן', 'שלום', 'יא', 'נו', 'hey', 'hi', 'ok', 'אוקיי'};

/// Remy's name at the start of an utterance, optionally after a short greeting (speech
/// recognition writes "היי רמי", "הי רמי", "רמי," and sometimes glues them: "הירמי").
/// Anything else, including "רמי" in the middle of a sentence, is not a call.
WakeMatch? detectWake(String text) {
  // Not normalizeCommand: that one drops Remy's name, which is exactly what we look for.
  final words = text
      .replaceAll(RegExp('[֑-ׇ]'), '')
      .replaceAll(RegExp(r'''[.,!?;:'"״׳()\-–—…]'''), ' ')
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  for (var i = 0; i < words.length && i < 3; i++) {
    final w = words[i];
    final glued = _greetings.any((g) => w.startsWith(g) && _names.contains(w.substring(g.length)));
    if (_names.contains(w) || glued) return WakeMatch(words.sublist(i + 1).join(' '));
    if (!_greetings.contains(w)) return null;
  }
  return null;
}
