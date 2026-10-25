import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content_hash.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../data/session_repository.dart';
import '../../models/recipe.dart';
import '../../models/recipe_analysis.dart';
import '../../models/recipe_bundle.dart';
import '../prepare/plan_estimate.dart';
import '../prepare/preparation.dart';
import '../prepare/preparation_service.dart';

const catalogAsset = 'assets/recipes/catalog.json';

enum CatalogCategory { quick, chicken, pasta, baking, breakfast, vegetarian, desserts }

/// One recipe of the bundled catalog: the same recipe and plan as any saved recipe
/// ([RecipeBundle]), plus the categories it is browsed by.
class CatalogEntry {
  const CatalogEntry({required this.id, required this.categories, required this.bundle, required this.version});

  final String id;
  final Set<CatalogCategory> categories;
  final RecipeBundle bundle;

  /// Changes when an app update changes this recipe, so the device's working copy follows it.
  final String version;

  Recipe get recipe => bundle.recipe;
  PlanEstimate get estimate => estimatePlan(bundle.plan);

  /// Finds the working copy on this device (`recipes.content_hash`).
  String get contentHash => 'builtin:$id:$version';
}

/// The recipes that ship with the app (docs/DECISIONS.md #84): read-only, bundled as
/// `assets/recipes/catalog.json`, browsed without any network.
class BuiltinCatalog {
  const BuiltinCatalog(this.entries);

  factory BuiltinCatalog.decode(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    return BuiltinCatalog([
      for (final r in data['recipes'] as List)
        if (r case final Map<String, dynamic> m)
          CatalogEntry(
            id: m['id'] as String,
            categories: {
              for (final c in m['categories'] as List) ?CatalogCategory.values.asNameMap()[c],
            },
            bundle: RecipeBundle.fromJson(m),
            version: textHash(jsonEncode([m['recipe'], m['plan']])).substring(0, 12),
          ),
    ]);
  }

  final List<CatalogEntry> entries;

  CatalogEntry? byId(String id) => entries.where((e) => e.id == id).firstOrNull;

  /// Title or ingredient search ("עוף", "שוקולד"), optionally within one category.
  List<CatalogEntry> search({String query = '', CatalogCategory? category}) {
    final q = query.trim();
    return [
      for (final e in entries)
        if ((category == null || e.categories.contains(category)) &&
            (q.isEmpty || e.recipe.title.contains(q) || e.recipe.ingredients.any((i) => i.name.contains(q))))
          e,
    ];
  }
}

/// Reads a bundled asset (tests read the file synchronously instead).
final assetLoaderProvider = Provider<Future<String> Function(String)>((ref) => rootBundle.loadString);

final builtinCatalogProvider = FutureProvider<BuiltinCatalog>(
  (ref) async => BuiltinCatalog.decode(await ref.watch(assetLoaderProvider)(catalogAsset)),
);

/// Built-in recipes on this device. Opening one makes (or reuses) its working copy: a row with
/// status `builtin`, never listed with the cook's own recipes, that the usual overview,
/// preparation and cooking use like any recipe. The bundled recipe itself never changes; saving
/// to "המתכונים שלי" makes a separate personal copy, which is the one to edit.
class BuiltinRecipes {
  BuiltinRecipes({required this.recipes, required this.sessions});

  final RecipeRepository recipes;
  final SessionRepository sessions;

  /// The working copy's recipe id. A copy left untouched since its last cooking ended starts
  /// fresh again (the bundled recipe, no preparation); one being prepared or cooked is kept.
  Future<String> open(CatalogEntry entry) async {
    final row = await recipes.findByContentHash(entry.contentHash);
    if (row == null || !row.isBuiltin) {
      return recipes.saveBundle(entry.bundle, sourceType: 'builtin', status: RecipeStatus.builtin, contentHash: entry.contentHash);
    }
    final active = await sessions.activeSession();
    final ended = await sessions.lastEndedAt(row.id);
    if (active?.recipeId != row.id && ended != null && !row.updatedAt.isAfter(ended)) {
      await recipes.approvePlan(
        row.id,
        entry.bundle.plan,
        analysis: RecipeAnalysis(isRecipe: true, source: const RecipeSourceInfo(type: SourceType.sample), recipe: entry.recipe),
      );
      await recipes.savePreparation(row.id, const Preparation());
    }
    return row.id;
  }

  /// Saves what the cook sees (with their preparation) as their own recipe; returns its id.
  Future<String> copyToMyRecipes(String builtinId) async {
    final row = (await recipes.getRecipe(builtinId))!;
    final plan = (await recipes.latestApprovedPlan(builtinId))!;
    return recipes.saveBundle(
      RecipeBundle(recipe: PreparationService.analysisOf(row).recipe!, plan: plan.plan),
      sourceType: 'builtin',
      analysisJson: row.analysisJson,
    );
  }
}

final builtinRecipesProvider = Provider<BuiltinRecipes>(
  (ref) => BuiltinRecipes(recipes: ref.watch(recipeRepositoryProvider), sessions: ref.watch(sessionRepositoryProvider)),
);
