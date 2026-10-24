import 'dart:convert';
import 'dart:io';

import 'package:anyone_can_cook/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hebrew copy uses no dashes as separators (docs/DESIGN.md §9): a comma, a period or a
/// colon instead. Hyphens inside words ("כ-5") stay.
void main() {
  test('no dash separators in any Hebrew string', () {
    final arb = jsonDecode(File('lib/l10n/app_he.arb').readAsStringSync()) as Map<String, dynamic>;
    final offenders = [
      for (final MapEntry(:key, :value) in arb.entries)
        if (!key.startsWith('@') && value is String && RegExp(r'[—–]|\s-\s').hasMatch(value)) '$key: $value',
    ];
    expect(offenders, isEmpty);
  });

  test('no dash separators in Hebrew text written in code', () {
    final literal = RegExp(r'''(['"])(?:(?!\1).)*?\s[—–-]\s(?:(?!\1).)*?\1''');
    final hebrew = RegExp(r'[֐-׿]');
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.contains('l10n') || f.path.endsWith('.g.dart') || f.path.endsWith('.freezed.dart')) {
        continue;
      }
      for (final (i, line) in f.readAsLinesSync().indexed) {
        if (line.trimLeft().startsWith('//')) continue;
        for (final m in literal.allMatches(line)) {
          if (hebrew.hasMatch(m.group(0)!) || m.group(0)!.contains(r'${')) offenders.add('${f.path}:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('text from people or the AI is shown without dash separators', () {
    expect(tidyHe('לקפל — לערבב בעדינות מלמטה למעלה'), 'לקפל, לערבב בעדינות מלמטה למעלה');
    expect(tidyHe('מלח – לפי הטעם'), 'מלח, לפי הטעם');
    expect(tidyHe('כ-5 דקות'), 'כ-5 דקות');
    expect(tidyHe('בלי שינוי'), 'בלי שינוי');
  });
}
