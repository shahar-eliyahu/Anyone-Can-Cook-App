import '../core/db/database.dart';

abstract final class SettingKeys {
  static const sampleRecipeSeeded = 'sample_recipe_seeded';
  static const importPrivacyAccepted = 'import_privacy_accepted';
  static const pendingImport = 'pending_import';
  static const handsFree = 'hands_free';
}

class SettingsRepository {
  SettingsRepository(this._db, this._clock);

  final AppDatabase _db;
  final DateTime Function() _clock;

  Future<String?> get(String key) async => (await (_db.select(_db.appSettings)
            ..where((s) => s.key.equals(key)))
          .getSingleOrNull())
      ?.value;

  Future<void> set(String key, String value) =>
      _db.into(_db.appSettings).insertOnConflictUpdate(AppSettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: _clock().toUtc(),
          ));
}
