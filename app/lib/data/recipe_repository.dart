import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/db/database.dart';
import '../core/ids.dart';
import '../models/cooking_plan.dart';
import '../models/recipe.dart';
import '../models/plan_response.dart';
import '../models/recipe_analysis.dart';
import '../models/recipe_bundle.dart';
import '../features/prepare/preparation.dart';

class RecipeHasActiveSessionException implements Exception {
  const RecipeHasActiveSessionException();
}

extension RecipeRowX on RecipeRow {
  String get displayTitle =>
      (customTitle?.trim().isNotEmpty ?? false) ? customTitle!.trim() : title;

  Map<String, dynamic> get _analysisMap =>
      jsonDecode(analysisJson!) as Map<String, dynamic>;

  /// The original recipe, decoded from `analysis_json`.
  Recipe get recipe =>
      Recipe.fromJson(_analysisMap['recipe'] as Map<String, dynamic>);

  /// The full analysis (Phase 2 imports); null for recipes saved without one.
  RecipeAnalysis? get analysis {
    final map = _analysisMap;
    return map.containsKey('source') ? RecipeAnalysis.fromJson(map) : null;
  }

  bool get isDraft => status == RecipeStatus.draft;

  /// A built-in recipe (the bundled catalog's working copy on this device).
  bool get isBuiltin => status == RecipeStatus.builtin;

  /// What Remy said about a recipe he created (stage recipe_creation): his time estimate and tips.
  CreationInfo get creation {
    final raw = analysisJson == null ? null : _analysisMap['creation'];
    if (raw is! Map<String, dynamic>) return const CreationInfo();
    return CreationInfo(
      totalMinutes: raw['total_minutes'] as int?,
      tipsHe: [for (final t in raw['tips_he'] as List? ?? const []) t as String],
    );
  }

  /// Warnings, limitations and sources returned with the latest generated plan.
  PlanReviewInfo get planReview {
    final review = _analysisMap['plan_review'];
    if (review is! Map<String, dynamic>) return const PlanReviewInfo();
    return PlanReviewInfo(
      warningsHe: [for (final w in review['warnings_he'] as List? ?? const []) w as String],
      limitationsHe: [for (final w in review['limitations_he'] as List? ?? const []) w as String],
      sources: [
        for (final s in review['sources'] as List? ?? const [])
          ReferenceSource.fromJson(s as Map<String, dynamic>),
      ],
    );
  }
}

extension RecipePreparationX on RecipeRow {
  /// The cook's preparation (have/missing, substitutions); empty when none was saved.
  Preparation get preparation {
    final raw = analysisJson == null ? null : (jsonDecode(analysisJson!) as Map<String, dynamic>)['preparation'];
    return raw is Map<String, dynamic> ? Preparation.fromJson(raw) : const Preparation();
  }
}

/// Keys kept in `analysis_json` next to the analysis itself; every write preserves them.
const _extraKeys = ['plan_review', 'preparation', 'creation'];

Map<String, dynamic> _withExtras(String? oldJson, Map<String, dynamic> map) {
  if (oldJson == null) return map;
  final old = jsonDecode(oldJson) as Map<String, dynamic>;
  for (final k in _extraKeys) {
    if (old[k] != null && !map.containsKey(k)) map[k] = old[k];
  }
  return map;
}

class CreationInfo {
  const CreationInfo({this.totalMinutes, this.tipsHe = const []});
  final int? totalMinutes;
  final List<String> tipsHe;

  Map<String, Object?> toJson() => {'total_minutes': ?totalMinutes, 'tips_he': tipsHe};
}

class PlanReviewInfo {
  const PlanReviewInfo({this.warningsHe = const [], this.limitationsHe = const [], this.sources = const []});
  final List<String> warningsHe;
  final List<String> limitationsHe;
  final List<ReferenceSource> sources;
}

abstract final class RecipeStatus {
  static const draft = 'draft';
  static const ready = 'ready';
  static const builtin = 'builtin';
}

abstract final class PlanStatus {
  static const draft = 'draft';
  static const approved = 'approved';
  static const superseded = 'superseded';
}

Map<String, dynamic> _json(RecipeAnalysis analysis) =>
    jsonDecode(jsonEncode(analysis.toJson())) as Map<String, dynamic>;

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
    String status = RecipeStatus.ready,
    String? contentHash,
    String? analysisJson,
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
            analysisJson: Value(analysisJson ?? jsonEncode({'recipe': bundle.recipe.toJson()})),
            analysisSchemaVersion: Value(bundle.recipe.schemaVersion),
            status: Value(status),
            contentHash: Value(contentHash),
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
    final q = _db.select(_db.recipes)
      ..where((r) => r.deletedAt.isNull() & r.status.equals(RecipeStatus.ready));
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

  // ---- Phase 2: imports, drafts, corrections --------------------------------

  /// Saves an analysis as a draft (not listed until a plan is approved).
  Future<String> saveDraft(
    RecipeAnalysis analysis, {
    String? id,
    String? sourceText,
    String? sourceUrl,
    String? imagePath,
    String? contentHash,
    CreationInfo? creation,
  }) async {
    id ??= newId();
    final now = _now();
    await _db.into(_db.recipes).insert(RecipesCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          title: analysis.recipe?.title ?? '',
          sourceType: analysis.source.type.name,
          sourceText: Value(sourceText ?? analysis.sourceText),
          sourceUrl: Value(sourceUrl ?? analysis.source.url),
          sourceImagePath: Value(imagePath),
          analysisJson: Value(jsonEncode({..._json(analysis), 'creation': ?creation?.toJson()})),
          analysisSchemaVersion: Value(analysis.schemaVersion),
          status: const Value(RecipeStatus.draft),
          contentHash: Value(contentHash),
        ));
    return id;
  }

  /// Replaces the stored analysis (keeping the latest plan review information).
  Future<void> updateAnalysis(String recipeId, RecipeAnalysis analysis, {bool? planStale, CreationInfo? creation}) async {
    final row = await (_db.select(_db.recipes)..where((r) => r.id.equals(recipeId))).getSingle();
    final map = _withExtras(row.analysisJson, {..._json(analysis), 'creation': ?creation?.toJson()});
    await (_db.update(_db.recipes)..where((r) => r.id.equals(recipeId))).write(RecipesCompanion(
      title: Value(analysis.recipe?.title ?? row.title),
      analysisJson: Value(jsonEncode(map)),
      planStale: planStale == null ? const Value.absent() : Value(planStale),
      updatedAt: Value(_now()),
    ));
  }

  /// Marks whether the plan no longer matches the (edited) recipe. A stale
  /// recipe cannot be cooked until its plan is regenerated or re-checked.
  Future<void> setPlanStale(String recipeId, bool stale) =>
      (_db.update(_db.recipes)..where((r) => r.id.equals(recipeId))).write(
        RecipesCompanion(planStale: Value(stale), updatedAt: Value(_now())),
      );

  /// The plan to review: the pending draft plan, else the latest approved one.
  Future<PlanRow?> reviewPlan(String recipeId) async =>
      await draftPlan(recipeId) ?? await latestApprovedPlan(recipeId);

  /// Stores a generated, not yet approved plan for a recipe (replacing any earlier draft).
  Future<String> saveDraftPlan(String recipeId, CookingPlan plan, {PlanResponse? response}) async {
    final now = _now();
    final id = newId();
    await _db.transaction(() async {
      if (response != null) {
        final row = (await getRecipe(recipeId))!;
        final map = jsonDecode(row.analysisJson!) as Map<String, dynamic>
          ..['plan_review'] = {
            'warnings_he': response.warningsHe,
            'limitations_he': response.limitationsHe,
            'sources': [for (final s in response.sources) s.toJson()],
          };
        await (_db.update(_db.recipes)..where((r) => r.id.equals(recipeId)))
            .write(RecipesCompanion(analysisJson: Value(jsonEncode(map))));
      }
      await (_db.delete(_db.plans)
            ..where((p) => p.recipeId.equals(recipeId) & p.status.equals(PlanStatus.draft)))
          .go();
      await _db.into(_db.plans).insert(PlansCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            recipeId: recipeId,
            planJson: jsonEncode(plan.toJson()),
            planSchemaVersion: plan.schemaVersion,
            status: PlanStatus.draft,
          ));
      await (_db.update(_db.recipes)..where((r) => r.id.equals(recipeId)))
          .write(RecipesCompanion(updatedAt: Value(now)));
    });
    return id;
  }

  Future<PlanRow?> draftPlan(String recipeId) => (_db.select(_db.plans)
        ..where((p) =>
            p.recipeId.equals(recipeId) & p.status.equals(PlanStatus.draft) & p.deletedAt.isNull())
        ..orderBy([(p) => OrderingTerm.desc(p.createdAt)])
        ..limit(1))
      .getSingleOrNull();

  /// Approves [plan] for [recipeId]: earlier approved plans become superseded,
  /// draft plans are removed, the recipe becomes ready and up to date, and the
  /// temporary photo reference is cleared (the caller deletes the file).
  Future<String> approvePlan(String recipeId, CookingPlan plan, {RecipeAnalysis? analysis}) async {
    final now = _now();
    final id = newId();
    await _db.transaction(() async {
      final previous = await latestApprovedPlan(recipeId);
      final row = await (_db.select(_db.recipes)..where((r) => r.id.equals(recipeId))).getSingle();
      await (_db.update(_db.plans)
            ..where((p) => p.recipeId.equals(recipeId) & p.status.equals(PlanStatus.approved)))
          .write(PlansCompanion(status: const Value(PlanStatus.superseded), updatedAt: Value(now)));
      await (_db.delete(_db.plans)
            ..where((p) => p.recipeId.equals(recipeId) & p.status.equals(PlanStatus.draft)))
          .go();
      await _db.into(_db.plans).insert(PlansCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            recipeId: recipeId,
            planJson: jsonEncode(plan.toJson()),
            planSchemaVersion: plan.schemaVersion,
            status: PlanStatus.approved,
            approvedAt: Value(now),
            basedOnPlanId: Value(previous?.id),
          ));
      await (_db.update(_db.recipes)..where((r) => r.id.equals(recipeId))).write(RecipesCompanion(
        // A built-in recipe's working copy stays built-in (a new plan version is still its own).
        status: row.isBuiltin ? const Value.absent() : const Value(RecipeStatus.ready),
        planStale: const Value(false),
        title: analysis?.recipe == null ? const Value.absent() : Value(analysis!.recipe!.title),
        analysisJson: analysis == null ? const Value.absent() : Value(jsonEncode(_withExtras(row.analysisJson, _json(analysis)))),
        sourceImagePath: const Value(null),
        updatedAt: Value(now),
      ));
    });
    return id;
  }

  /// Saves the cook's preparation (marks and substitutions) without touching the plan.
  Future<void> savePreparation(String recipeId, Preparation prep) => _db.transaction(() async {
        final row = await (_db.select(_db.recipes)..where((r) => r.id.equals(recipeId))).getSingle();
        final map = row.analysisJson == null
            ? <String, dynamic>{}
            : jsonDecode(row.analysisJson!) as Map<String, dynamic>;
        map['preparation'] = jsonDecode(jsonEncode(prep.toJson()));
        await (_db.update(_db.recipes)..where((r) => r.id.equals(recipeId)))
            .write(RecipesCompanion(analysisJson: Value(jsonEncode(map)), updatedAt: Value(_now())));
      });

  /// Stores the recipe and plan after substitutions changed (accepted or undone): a draft
  /// gets a new draft plan; a saved recipe gets a new approved plan version (sessions that
  /// already started keep the plan they started with).
  Future<void> applyPreparation(
    String recipeId, {
    required RecipeAnalysis analysis,
    required CookingPlan plan,
    required Preparation prep,
  }) =>
      _db.transaction(() async {
        final row = (await getRecipe(recipeId))!;
        if (row.isDraft) {
          await updateAnalysis(recipeId, analysis);
          await saveDraftPlan(recipeId, plan);
        } else {
          await approvePlan(recipeId, plan, analysis: analysis);
        }
        await savePreparation(recipeId, prep);
      });

  Stream<List<RecipeRow>> watchDrafts() => (_db.select(_db.recipes)
        ..where((r) => r.deletedAt.isNull() & r.status.equals(RecipeStatus.draft))
        ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]))
      .watch();

  /// A saved recipe or draft imported from the same source, if any.
  Future<RecipeRow?> findByContentHash(String hash) => (_db.select(_db.recipes)
        ..where((r) => r.contentHash.equals(hash) & r.deletedAt.isNull())
        ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)])
        ..limit(1))
      .getSingleOrNull();

  /// Permanently deletes a draft and its plans. Returns its photo path, if any.
  Future<String?> discardDraft(String recipeId) => _db.transaction(() async {
        final row = await (_db.select(_db.recipes)..where((r) => r.id.equals(recipeId))).getSingleOrNull();
        if (row == null || !row.isDraft) return null;
        await (_db.delete(_db.plans)..where((p) => p.recipeId.equals(recipeId))).go();
        await (_db.delete(_db.recipes)..where((r) => r.id.equals(recipeId))).go();
        return row.sourceImagePath;
      });

  /// Deletes drafts untouched for [maxAge]; returns their photo paths to delete.
  Future<List<String>> purgeOldDrafts({Duration maxAge = const Duration(days: 7)}) async {
    final cutoff = _now().subtract(maxAge);
    final old = await (_db.select(_db.recipes)
          ..where((r) => r.status.equals(RecipeStatus.draft) & r.updatedAt.isSmallerThanValue(cutoff)))
        .get();
    final images = <String>[];
    for (final r in old) {
      final image = await discardDraft(r.id);
      if (image != null) images.add(image);
    }
    return images;
  }
}
