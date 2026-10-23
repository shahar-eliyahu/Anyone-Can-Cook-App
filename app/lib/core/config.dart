/// Backend base URL, set at build time:
/// `flutter run --dart-define=API_BASE_URL=https://…`
/// Defaults to the local backend as seen from the Android emulator.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);
