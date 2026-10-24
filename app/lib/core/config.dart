/// Backend base URL, set at build time:
/// `flutter run --dart-define=API_BASE_URL=https://…`
/// Defaults to the local backend as seen from the Android emulator.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

/// Abuse deterrent sent as `X-App-Token` (must match `APP_CLIENT_TOKEN` on the
/// server). Set at build time with `--dart-define=APP_CLIENT_TOKEN=…`; never
/// committed. It ships inside the app, so it is not a secret or authentication.
const String appClientToken = String.fromEnvironment('APP_CLIENT_TOKEN');
