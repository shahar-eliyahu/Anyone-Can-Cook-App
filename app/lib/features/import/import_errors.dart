import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';

/// Hebrew text for an import failure (backend `error_code`, or offline/timeout).
String importErrorText(AppLocalizations l10n, Object error) {
  final code = error is ApiFailure ? error.code : '';
  return switch (code) {
    'offline' => l10n.errOffline,
    'timeout' => l10n.errTimeout,
    'rate_limited' => l10n.errRateLimited,
    'ai_rate_limited' || 'ai_unavailable' => l10n.errAiBusy,
    'daily_limit' => l10n.errDailyLimit,
    'too_large' => l10n.errTooLarge,
    'unsupported_media' => l10n.errUnsupportedImage,
    'invalid_url' => l10n.errInvalidUrl,
    'fetch_failed' => l10n.errFetchFailed,
    'site_blocked' => l10n.errSiteBlocked,
    'no_recipe_found' => l10n.errNoRecipeFound,
    'not_a_recipe' => l10n.importNotRecipe,
    'unsafe_to_plan' => l10n.errUnsafeToPlan,
    'invalid_ai_output' => l10n.errInvalidAiOutput,
    'not_configured' || 'unauthorized' => l10n.errNotConfigured,
    _ => l10n.errGeneric,
  };
}
