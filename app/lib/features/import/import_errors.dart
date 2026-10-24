import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';

/// Hebrew text for an import failure (backend `error_code`, or offline/timeout).
/// A wait time is shown only when the server stated one (Retry-After); otherwise the
/// text never promises when the service will be back.
String importErrorText(AppLocalizations l10n, Object error) {
  final failure = error is ApiFailure ? error : null;
  return switch (failure?.code ?? '') {
    'offline' => l10n.errOffline,
    'timeout' => l10n.errTimeout,
    'rate_limited' => l10n.errRateLimited,
    'ai_rate_limited' => switch (failure!.retryAfterSeconds) {
        final s? when s > 0 => l10n.errAiBusyRetryIn((s / 60).ceil()),
        _ => l10n.errAiBusy,
      },
    'ai_quota_exhausted' => l10n.errAiQuota,
    'ai_unavailable' => l10n.errAiUnavailable,
    'daily_limit' => l10n.errDailyLimit,
    'too_large' => l10n.errTooLarge,
    'unsupported_media' => l10n.errUnsupportedImage,
    'invalid_url' => l10n.errInvalidUrl,
    'fetch_failed' => l10n.errFetchFailed,
    'site_blocked' => switch (failure!.site) {
        final site? => l10n.errSiteBlockedNamed(site),
        _ => l10n.errSiteBlocked,
      },
    'link_unresolved' => l10n.errLinkUnresolved,
    'no_recipe_found' => l10n.errNoRecipeFound,
    'not_a_recipe' => l10n.importNotRecipe,
    'unsafe_to_plan' => l10n.errUnsafeToPlan,
    'invalid_ai_output' => l10n.errInvalidAiOutput,
    'not_configured' || 'unauthorized' => l10n.errNotConfigured,
    _ => l10n.errGeneric,
  };
}

/// A link that couldn't be read: the cook gets alternatives (paste the recipe text, or copy
/// the full address the shared link led to).
bool isUnreadableLink(Object error) =>
    error is ApiFailure && const {'site_blocked', 'link_unresolved', 'no_recipe_found', 'fetch_failed'}.contains(error.code);

/// Failures where the same request can succeed later: offer "נסו שוב" and keep the input.
bool isRetryable(Object error) =>
    error is ApiFailure &&
    const {
      'offline',
      'timeout',
      'rate_limited',
      'ai_rate_limited',
      'ai_quota_exhausted',
      'ai_unavailable',
      'daily_limit',
      'fetch_failed',
      'server_error',
      'invalid_ai_output',
    }.contains(error.code);
