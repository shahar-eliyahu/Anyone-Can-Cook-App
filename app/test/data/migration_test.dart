import 'dart:io';

import 'package:anyone_can_cook/core/db/database.dart';
import 'package:anyone_can_cook/data/recipe_repository.dart';
import 'package:anyone_can_cook/data/session_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sample.dart';

void main() {
  test('a Phase 1 (v1) database migrates to v2 and keeps every recipe, plan, session and event', () async {
    final dir = Directory.systemTemp.createTempSync('acc_migration');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final clock = FakeClock();

    // Build a database, then turn it into exactly what Phase 1 stored (v1 schema).
    var db = AppDatabase(NativeDatabase(file));
    final recipes = RecipeRepository(db, clock.call);
    final sessions = SessionRepository(db, clock.call);
    final recipeId = await recipes.saveBundle(loadSampleBundle(), sourceType: 'sample');
    await recipes.setFavorite(recipeId, true);
    final plan = (await recipes.latestApprovedPlan(recipeId))!;
    final session = await sessions.startSession(recipeId: recipeId, planId: plan.id);
    await db.customStatement('ALTER TABLE recipes DROP COLUMN status');
    await db.customStatement('ALTER TABLE recipes DROP COLUMN content_hash');
    await db.customStatement('PRAGMA user_version = 1');
    await db.close();

    // Reopen with the current app: the migration runs.
    db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final migrated = RecipeRepository(db, clock.call);
    final row = (await migrated.getRecipe(recipeId))!;
    expect(row.status, RecipeStatus.ready);
    expect(row.contentHash, isNull);
    expect(row.isFavorite, isTrue);
    expect(row.recipe, loadSampleBundle().recipe);
    expect((await migrated.latestApprovedPlan(recipeId))!.plan, loadSampleBundle().plan);
    expect(await migrated.watchRecipes().first, hasLength(1));
    final s = SessionRepository(db, clock.call);
    expect((await s.activeSession())!.id, session.id);
    expect(await s.loadEvents(session.id), hasLength(1));
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 2);
  });
}
