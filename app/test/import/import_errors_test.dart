import 'package:anyone_can_cook/core/api_client.dart';
import 'package:anyone_can_cook/features/import/import_errors.dart';
import 'package:anyone_can_cook/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/ui_helpers.dart' show developerWords;

void main() {
  test('import errors and loading texts use plain Hebrew, never developer terms', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('he'));
    const codes = [
      'offline', 'timeout', 'rate_limited', 'ai_rate_limited', 'ai_quota_exhausted', 'ai_unavailable',
      'daily_limit', 'too_large', 'unsupported_media', 'invalid_url', 'fetch_failed', 'site_blocked',
      'no_recipe_found', 'not_a_recipe', 'unsafe_to_plan', 'invalid_ai_output', 'not_configured',
      'unauthorized', 'server_error', 'something_new',
    ];
    final texts = [
      for (final c in codes) importErrorText(l10n, ApiFailure(c)),
      importErrorText(l10n, const ApiFailure('ai_rate_limited', retryAfterSeconds: 90)),
      l10n.importStageReading,
      l10n.importStagePlanning,
      l10n.importStageSlow,
    ];
    for (final t in texts) {
      for (final w in developerWords) {
        expect(t.contains(w), isFalse, reason: '"$t" contains "$w"');
      }
      expect(RegExp(r'\b[1-5]\d\d\b').hasMatch(t), isFalse, reason: 'no HTTP status codes: "$t"');
    }
  });
}
