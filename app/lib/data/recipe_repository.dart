import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/db/database.dart';
import '../core/ids.dart';
import '../models/cooking_plan.dart';
import '../models/recipe.dart';
import '../models/recipe_bundle.dart';

class RecipeHasActiveSessionException implements Exception {
  const RecipeHasActiveSessionException();
}

extension RecipeRowX on RecipeRow {
  String get displayTitle =>
      (customTitle?.trim().isNotEmpty ?? false) ? customTitle!.trim() : title;

  /// The original recipe, decoded from `analysis_json`.
  Recipe get recipe => Recipe.fromJson(
        (jsonDecode(analysisJson!) as Map<String, dynamic>)['recipe']
            as Map<String, dynamic>,
      );
}

extension PlanRowX on PlanRow {
  CookingPlan get plan =>
      CookingPlan.fromJson(jsonDecode(planJson) as Map<String, dynamic>);
}

/// Saved recipes and their approved plans (stored separately, versioned).
class RecipeRepository {
  RecipeRepository(this._db, this._clock);

  final AppDatabase _db;
  final DateTime Function() _clock;

  DateTime _now() => _clock().toUtc();

  /// Saves an analyzed recipe and its approved plan. Returns the recipe id.
  Future<String> saveBundle(
    RecipeBundle bundle, {
    required String sourceType,
    String? sourceText,
    String? sourceUrl,
  }) async {
    final recipeId = newId();
    final now = _now();
    await _db.transaction(() async {
      await _db.into(_db.recipes).insert(RecipesCompanion.insert(
            id: recipeId,
            createdAt: now,
            updatedAt: now,
            title: bundle.recipe.title,
            sourceType: sourceType,
            sourceText: Value(sourceText),
            sourceUrl: Value(sourceUrl),
            analysisJson: Value(jsonEncode({'recipe': bundle.recipe.toJson()})),
            analysisSchemaVersion: Value(bundle.recipe.schemaVersion),
          ));
      await _db.into(_db.plans).insert(PlansCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            recipeId: recipeId,
            planJson: jsonEncode(bundle.plan.toJson()),
            planSchemaVersion: bundle.plan.schemaVersion,
            status: 'approved',
            approvedAt: Value(now),
          ));
    });
    return recipeId;
  }

  Stream<List<RecipeRow>> watchRecipes({
    bool favoritesOnly = false,
    String query = '',
  }) {
    final q = _db.select(_db.recipes)..where((r) => r.deletedAt.isNull());
    if (favoritesOnly) q.where((r) => r.isFavorite.equals(true));
    final text = query.trim();
    if (text.isNotEmpty) {
      q.where((r) => r.title.contains(text) | r.customTitle.contains(text));
    }
    q.orderBy([(r) => OrderingTerm.desc(r.updatedAt)]);
    return q.watch();
  }

  Stream<RecipeRow?> watchRecipe(String id) => (_db.select(_db.recipes)
        ..where((r) => r.id.equals(id) & r.deletedAt.isNull()))
      .watchSingleOrNull();

  Future<RecipeRow?> getRecipe(String id) => (_db.select(_db.recipes)
        ..where((r) => r.id.equals(id) & r.deletedAt.isNull()))
      .getSingleOrNull();

  Future<PlanRow?> latestApprovedPlan(String recipeId) => (_db.select(_db.plans)
        ..where((p) =>
            p.recipeId.equals(recipeId) &
            p.status.equals('approved') &
            p.deletedAt.isNull())
        ..orderBy([(p) => OrderingTerm.desc(p.approvedAt)])
        ..limit(1))
      .getSingleOrNull();

  Future<PlanRow?> getPlan(String id) =>
      (_db.select(_db.plans)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<void> rename(String id, String newTitle) =>
      (_db.update(_db.recipes)..where((r) => r.id.equals(id))).write(
        RecipesCompanion(
          customTitle: Value(newTitle.trim().isEmpty ? null : newTitle.trim()),
          updatedAt: Value(_now()),
        ),
      );

  Future<void> setFavorite(String id, bool favorite) =>
      (_db.update(_db.recipes)..where((r) => r.id.equals(id))).write(
        RecipesCompanion(isFavorite: Value(favorite), updatedAt: Value(_now())),
      );

  /// Soft-deletes a recipe with its plans and history. Returns the deletion
  /// timestamp, which [restore] uses to undo exactly this deletion.
  Future<DateTime> softDelete(String id) async {
    final now = _now();
    await _db.transaction(() async {
      final active = await (_db.select(_db.cookingSessions)
            ..where((s) =>
                s.recipeId.equals(id) &
                s.status.equals('in_progress') &
                s.deletedAt.isNull()))
          .get();
      if (active.isNotEmpty) throw const RecipeHasActiveSessionException();
      final tombstone = Value<DateTime?>(now);
      await (_db.update(_db.recipes)..where((r) => r.id.equals(id)))
          .write(RecipesCompanion(deletedAt: tombstone, updatedAt: Value(now)));
      await (_db.update(_db.plans)
            ..where((p) => p.recipeId.equals(id) & p.deletedAt.isNull()))
          .write(PlansCompanion(deletedAt: tombstone, updatedAt: Value(now)));
      await (_db.update(_db.cookingSessions)
            ..where((s) => s.recipeId.equals(id) & s.deletedAt.isNull()))
          .write(CookingSessionsCompanion(deletedAt: tombstone, updatedAt: Value(now)));
    });
    return now;
  }

  /// Undoes [softDelete]: restores rows deleted at [deletedAt].
  Future<void> restore(String id, DateTime deletedAt) async {
    final now = _now();
    const clear = Value<DateTime?>(null);
    await _db.transaction(() async {
      await (_db.update(_db.recipes)
            ..where((r) => r.id.equals(id) & r.deletedAt.equals(deletedAt)))
          .write(RecipesCompanion(deletedAt: clear, updatedAt: Value(now)));
      await (_db.update(_db.plans)
            ..where((p) => p.recipeId.equals(id) & p.deletedAt.equals(deletedAt)))
          .write(PlansCompanion(deletedAt: clear, updatedAt: Value(now)));
      await (_db.update(_db.cookingSessions)
            ..where((s) => s.recipeId.equals(id) & s.deletedAt.equals(deletedAt)))
          .write(CookingSessionsCompanion(deletedAt: clear, updatedAt: Value(now)));
    });
  }
}
