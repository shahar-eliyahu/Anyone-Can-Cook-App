import 'package:anyone_can_cook/core/db/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  final now = DateTime.utc(2026, 10, 24, 12);

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> insertRecipe(String id) => db.into(db.recipes).insert(
        RecipesCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          title: 'עוגת שוקולד',
          sourceType: 'text',
        ),
      );

  test('schema v1 creates all tables', () async {
    expect(db.schemaVersion, 2); // v2 (Phase 2): recipes.status, recipes.content_hash
    final names = db.allTables.map((t) => t.actualTableName).toSet();
    expect(names, {
      'recipes',
      'plans',
      'cooking_sessions',
      'session_events',
      'app_settings',
    });
  });

  test('recipe → plan → session → event round trip with sync columns',
      () async {
    await insertRecipe('r1');
    await db.into(db.plans).insert(PlansCompanion.insert(
          id: 'p1',
          createdAt: now,
          updatedAt: now,
          recipeId: 'r1',
          planJson: '{}',
          planSchemaVersion: 1,
          status: 'approved',
        ));
    await db.into(db.cookingSessions).insert(CookingSessionsCompanion.insert(
          id: 's1',
          createdAt: now,
          updatedAt: now,
          recipeId: 'r1',
          planId: 'p1',
          status: 'in_progress',
          startedAt: now,
        ));
    await db.into(db.sessionEvents).insert(SessionEventsCompanion.insert(
          id: 'e1',
          createdAt: now,
          updatedAt: now,
          sessionId: 's1',
          seq: 1,
          type: 'SessionStarted',
          payloadJson: '{}',
          payloadSchemaVersion: 1,
          at: now,
        ));

    final recipe = await db.select(db.recipes).getSingle();
    expect(recipe.title, 'עוגת שוקולד');
    expect(recipe.isFavorite, isFalse);
    expect(recipe.planStale, isFalse);
    expect(recipe.ownerId, isNull);
    expect(recipe.deletedAt, isNull);
    expect(await db.select(db.sessionEvents).get(), hasLength(1));
  });

  test('foreign keys are enforced', () async {
    expect(
      () => db.into(db.plans).insert(PlansCompanion.insert(
            id: 'p1',
            createdAt: now,
            updatedAt: now,
            recipeId: 'missing',
            planJson: '{}',
            planSchemaVersion: 1,
            status: 'approved',
          )),
      throwsA(isA<SqliteException>()),
    );
  });

  test('event sequence numbers are unique per session', () async {
    await insertRecipe('r1');
    await db.into(db.plans).insert(PlansCompanion.insert(
          id: 'p1',
          createdAt: now,
          updatedAt: now,
          recipeId: 'r1',
          planJson: '{}',
          planSchemaVersion: 1,
          status: 'approved',
        ));
    await db.into(db.cookingSessions).insert(CookingSessionsCompanion.insert(
          id: 's1',
          createdAt: now,
          updatedAt: now,
          recipeId: 'r1',
          planId: 'p1',
          status: 'in_progress',
          startedAt: now,
        ));
    SessionEventsCompanion event(String id) => SessionEventsCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          sessionId: 's1',
          seq: 1,
          type: 'SessionStarted',
          payloadJson: '{}',
          payloadSchemaVersion: 1,
          at: now,
        );
    await db.into(db.sessionEvents).insert(event('e1'));
    expect(
      () => db.into(db.sessionEvents).insert(event('e2')),
      throwsA(isA<SqliteException>()),
    );
  });

  test('app settings store key-value pairs', () async {
    await db.into(db.appSettings).insert(AppSettingsCompanion.insert(
          key: 'agent_action_mode',
          value: 'auto_when_clear',
          updatedAt: now,
        ));
    final row = await (db.select(db.appSettings)
          ..where((s) => s.key.equals('agent_action_mode')))
        .getSingle();
    expect(row.value, 'auto_when_clear');
  });
}
