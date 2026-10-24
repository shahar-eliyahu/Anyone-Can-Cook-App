import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/db/database.dart';
import '../../core/ids.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../data/session_repository.dart';
import '../../models/cooking_plan.dart';
import '../../models/recipe.dart';
import '../../models/recipe_analysis.dart';
import '../cooking/engine/plan_validator.dart';
import 'local_substitutions.dart';
import 'patch.dart';
import 'preparation.dart';

/// Everything the overview needs for one recipe (a draft or a saved recipe).
class PrepView {
  const PrepView({
    required this.row,
    required this.analysis,
    required this.plan,
    required this.prep,
    required this.cookingNow,
  });

  final RecipeRow row;

  /// The effective recipe (with accepted substitutions), never null here.
  final RecipeAnalysis analysis;

  /// The plan that will be cooked: a draft's plan, or a saved recipe's approved plan
  /// (unapproved advanced edits are not used here).
  final CookingPlan? plan;
  final Preparation prep;

  /// A cooking session of this recipe is in progress: preparation is read-only.
  final bool cookingNow;

  Recipe get recipe => analysis.recipe!;
}

class SubstitutionFailed implements Exception {
  const SubstitutionFailed(this.reason);
  final String reason;
}

/// Preparation before cooking (Phase 3A): what the cook has, what is missing, and
/// substitutions applied consistently to the recipe and the plan (docs/DECISIONS.md #40).
class PreparationService {
  PreparationService({required this.recipes, required this.sessions, required this.api});

  final RecipeRepository recipes;
  final SessionRepository sessions;
  final ApiClient api;

  Future<PrepView?> load(String recipeId) async {
    final row = await recipes.getRecipe(recipeId);
    if (row == null) return null;
    final active = await sessions.activeSession();
    return PrepView(
      row: row,
      analysis: analysisOf(row),
      plan: (row.isDraft
              ? await recipes.draftPlan(recipeId) ?? await recipes.latestApprovedPlan(recipeId)
              : await recipes.latestApprovedPlan(recipeId) ?? await recipes.draftPlan(recipeId))
          ?.plan,
      prep: row.preparation,
      cookingNow: active?.recipeId == recipeId,
    );
  }

  /// Recipes saved before Phase 2 (the sample) have no stored analysis.
  static RecipeAnalysis analysisOf(RecipeRow row) =>
      row.analysis ??
      RecipeAnalysis(
        isRecipe: true,
        source: const RecipeSourceInfo(type: SourceType.sample),
        sourceText: row.sourceText ?? '',
        recipe: row.recipe,
      );

  Future<void> setStatus(String recipeId, String itemId, ItemStatus status) async {
    final row = (await recipes.getRecipe(recipeId))!;
    final prep = row.preparation;
    await recipes.savePreparation(recipeId, prep.copyWith(items: {...prep.items, itemId: status}));
  }

  /// "יש לי הכול": every ingredient and piece of equipment not already handled.
  Future<void> markAllHave(String recipeId) async {
    final row = (await recipes.getRecipe(recipeId))!;
    final prep = row.preparation;
    final recipe = analysisOf(row).recipe!;
    final items = {...prep.items};
    for (final id in [for (final i in recipe.ingredients) i.id, for (final e in recipe.equipment) e.id]) {
      if (items[id] != ItemStatus.missing) items[id] = ItemStatus.have;
    }
    await recipes.savePreparation(recipeId, prep.copyWith(items: items));
  }

  /// A local answer when the table has a reliable one; otherwise one server call
  /// (throws [ApiFailure] when offline, rate-limited, …).
  Future<SubstitutionProposal> propose(PrepView view, ItemKind kind, String targetId, {String? noteHe}) async {
    final local = localSubstitution(
      recipe: view.recipe, plan: view.plan!, kind: kind, targetId: targetId, userNoteHe: noteHe,
    );
    if (local != null) return local;
    return api.substitute(recipe: view.recipe, plan: view.plan!, kind: kind, targetId: targetId, noteHe: noteHe);
  }

  /// A local answer only (no network), e.g. to show one as soon as the sheet opens.
  SubstitutionProposal? proposeLocally(PrepView view, ItemKind kind, String targetId) =>
      localSubstitution(recipe: view.recipe, plan: view.plan!, kind: kind, targetId: targetId);

  Future<void> accept(String recipeId, ItemKind kind, String targetId, SubstitutionProposal proposal) async {
    if (!proposal.canApply) throw const SubstitutionFailed('nothing_to_apply');
    final view = (await load(recipeId))!;
    if (view.cookingNow) throw const SubstitutionFailed('cooking_now');
    final prep = view.prep;
    final baseRecipe = prep.baseRecipe ?? view.recipe;
    final basePlan = prep.basePlan ?? view.plan!;
    final name = kind == ItemKind.ingredient
        ? view.recipe.ingredients.firstWhere((i) => i.id == targetId).name
        : view.recipe.equipment.firstWhere((e) => e.id == targetId).name;
    final omitted = proposal.ops.any((o) => o['op'] == 'omit_ingredient' || o['op'] == 'omit_equipment');
    final substitution = Substitution(
      id: newId(),
      kind: kind,
      targetId: targetId,
      targetName: name,
      labelHe: proposal.replacementNameHe ?? (omitted ? 'בלי $name' : name),
      verdict: proposal.verdict,
      source: proposal.source,
      ops: proposal.ops,
      effectsHe: proposal.effectsHe,
    );
    final next = prep.copyWith(
      substitutions: [...prep.substitutions, substitution],
      baseRecipe: baseRecipe,
      basePlan: basePlan,
      items: {...prep.items, targetId: ItemStatus.missing},
    );
    await _store(recipeId, view, next);
  }

  /// Undo one accepted substitution: everything is rebuilt from the original.
  Future<void> undo(String recipeId, String substitutionId) async {
    final view = (await load(recipeId))!;
    if (view.cookingNow) throw const SubstitutionFailed('cooking_now');
    final prep = view.prep;
    final target = prep.substitutions.where((s) => s.id == substitutionId).firstOrNull;
    if (target == null || target.locked || prep.baseRecipe == null) throw const SubstitutionFailed('not_undoable');
    await _store(recipeId, view, prep.copyWith(substitutions: [for (final s in prep.substitutions) if (s.id != substitutionId) s]));
  }

  /// After advanced editing, the edited recipe becomes the new original: earlier
  /// substitutions stay visible but are no longer undoable (they're part of it now).
  Future<void> lockAfterAdvancedEdit(String recipeId) async {
    final row = (await recipes.getRecipe(recipeId))!;
    final prep = row.preparation;
    if (prep.baseRecipe == null && prep.substitutions.every((s) => s.locked)) return;
    await recipes.savePreparation(
      recipeId,
      prep.copyWith(substitutions: [for (final s in prep.substitutions) s.lock()], clearBase: true),
    );
  }

  Future<void> _store(String recipeId, PrepView view, Preparation prep) async {
    (Recipe, CookingPlan) effective;
    try {
      effective = prep.effective()!;
    } on PatchException {
      throw const SubstitutionFailed('invalid_patch');
    }
    final (recipe, plan) = effective;
    if (validatePlan(plan, recipe: recipe).isNotEmpty) throw const SubstitutionFailed('invalid_plan');
    await recipes.applyPreparation(
      recipeId,
      analysis: view.analysis.copyWith(recipe: recipe),
      plan: plan,
      prep: prep,
    );
  }
}

final preparationServiceProvider = Provider<PreparationService>(
  (ref) => PreparationService(
    recipes: ref.watch(recipeRepositoryProvider),
    sessions: ref.watch(sessionRepositoryProvider),
    api: ref.watch(apiClientProvider),
  ),
);
