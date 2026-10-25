import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/ids.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../data/settings_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/recipe.dart';
import '../../models/recipe_analysis.dart';
import '../assistant/assistant_models.dart';
import '../assistant/assistant_service.dart';
import '../assistant/conversation_store.dart';
import '../import/import_service.dart';

/// Creating a recipe with Remy (stage recipe_creation, docs/DECISIONS.md #85–#87).
///
/// One server call per message, never retried. Remy answers, offers a few dishes, or returns a
/// recipe; a recipe is checked again here and stored as a DRAFT with the conversation's id (a
/// later "בלי חלב" replaces that draft). Nothing becomes the cook's recipe until they review it
/// and save it, and saving plans it through the usual /plan pipeline and its checks.
class RecipeCreationService {
  RecipeCreationService({required this.api, required this.recipes, required this.settings, required this.store, required this.imports});

  final ApiClient api;
  final RecipeRepository recipes;
  final SettingsRepository settings;
  final ConversationStore store;
  final ImportService imports;

  AppLocalizations get _l10n => lookupAppLocalizations(const Locale('he'));

  /// The conversation "רמי יציע מתכון" continues: the last one while it has messages and hasn't
  /// produced a draft yet; otherwise a new one.
  Future<String> currentConversation() async {
    final id = await settings.get(SettingKeys.remyCreation);
    if (id != null && id.isNotEmpty && await recipes.getRecipe(id) == null && (await store.load(id)).isNotEmpty) return id;
    return _fresh();
  }

  /// "שיחה חדשה": forgets a conversation that has no draft (a draft keeps its own) and starts over.
  Future<String> startOver(String id) async {
    if (await recipes.getRecipe(id) == null) await store.clear(id);
    return _fresh();
  }

  Future<String> _fresh() async {
    final id = newId();
    await settings.set(SettingKeys.remyCreation, id);
    return id;
  }

  /// One message from the cook; returns Remy's reply and the preferences to remember with this
  /// conversation (only this conversation's: never other recipes or app state).
  Future<(AssistantReply, Map<String, Object?>)> turn(
    String id,
    AssistantInput input, {
    List<ChatTurn> history = const [],
    Map<String, Object?> preferences = const {},
  }) async {
    final l10n = _l10n;
    if (!AssistantService.intelligible(input.text)) return (AssistantReply(answerHe: l10n.remyDidntCatch), preferences);
    final row = await recipes.getRecipe(id);
    final draft = row != null && row.isDraft ? row.analysis?.recipe : null;
    final RecipeCreationResult res;
    try {
      res = await api.createRecipeTurn(
        messageHe: input.text.trim(),
        modality: input.modality.name,
        preferences: preferences,
        history: AssistantService.historyPayload(history),
        currentRecipe: draft == null ? null : _summary(draft),
      );
    } on ApiFailure catch (e) {
      final text = e.code == 'offline' || e.code == 'timeout'
          ? l10n.createOffline
          : e.code == 'invalid_ai_output'
              ? l10n.createInvalid
              : l10n.createUnavailable;
      return (AssistantReply(answerHe: text, source: ReplySource.ai), preferences);
    }
    final remembered = res.preferences.isEmpty ? preferences : res.preferences;
    final analysis = res.analysis;
    if (res.kind == 'recipe') {
      if (analysis == null || !usable(analysis) || (row != null && !row.isDraft)) {
        return (AssistantReply(answerHe: l10n.createInvalid, source: ReplySource.ai), remembered);
      }
      final info = CreationInfo(totalMinutes: res.totalMinutes, tipsHe: res.tipsHe);
      if (row == null) {
        await recipes.saveDraft(analysis, id: id, creation: info);
      } else {
        await recipes.updateAnalysis(id, analysis, creation: info, planStale: true);
      }
      if (await settings.get(SettingKeys.remyCreation) == id) await settings.delete(SettingKeys.remyCreation);
      return (AssistantReply(answerHe: res.answerHe, speechHe: res.speechHe, recipeId: id, source: ReplySource.ai), remembered);
    }
    return (
      AssistantReply(
        answerHe: res.answerHe,
        speechHe: res.speechHe,
        options: res.kind == 'options' && res.options.length >= 2 ? res.options.take(4).toList() : const [],
        source: ReplySource.ai,
      ),
      remembered,
    );
  }

  /// What the app accepts as a recipe draft (the server checked it already; this is the
  /// device's own check before anything is stored).
  static bool usable(RecipeAnalysis a) {
    final r = a.recipe;
    if (!a.isRecipe || r == null || a.source.type != SourceType.remy) return false;
    if (r.title.trim().isEmpty || r.ingredients.isEmpty || r.sourceSteps.isEmpty) return false;
    final ids = [...r.ingredients.map((i) => i.id), ...r.equipment.map((e) => e.id), ...r.sourceSteps.map((s) => s.id)];
    if (ids.toSet().length != ids.length) return false;
    return r.ingredients.every((i) => i.name.trim().isNotEmpty && (i.quantity?.amount ?? 1) > 0) &&
        r.sourceSteps.every((s) => s.text.trim().isNotEmpty);
  }

  /// The draft being changed, short: its title, ingredients and steps.
  static Map<String, Object?> _summary(Recipe r) {
    String cut(String s, int n) => s.length > n ? s.substring(0, n) : s;
    return {
      'title': cut(r.title, 120),
      'ingredients_he': [
        for (final i in r.ingredients.take(40)) cut(i.quantity == null ? i.name : '${i.name}: ${i.quantity!.display}', 120),
      ],
      'steps_he': [for (final s in r.sourceSteps.take(25)) cut(s.text, 400)],
    };
  }

  /// Saving the reviewed draft: one /plan call (validated on the device), then it becomes the
  /// cook's recipe like any import. The creation conversation ends here: the saved recipe starts
  /// its own conversation with Remy (DECISIONS #86).
  Future<void> save(String id) async {
    var row = (await recipes.getRecipe(id))!;
    if (await recipes.draftPlan(id) == null || row.planStale) await imports.generatePlan(id);
    row = (await recipes.getRecipe(id))!;
    final plan = (await recipes.draftPlan(id))!.plan;
    await imports.approve(id, plan, row.analysis!);
    await store.clear(id);
  }

  /// The cook's edits before saving; the recipe is planned again when saved.
  Future<void> updateRecipe(String id, Recipe recipe) async {
    final row = (await recipes.getRecipe(id))!;
    await recipes.updateAnalysis(id, row.analysis!.copyWith(recipe: recipe), planStale: true);
  }

  Future<void> discard(String id) async {
    await imports.discard(id); // the draft and its conversation
    if (await settings.get(SettingKeys.remyCreation) == id) await settings.delete(SettingKeys.remyCreation);
  }
}

final recipeCreationServiceProvider = Provider<RecipeCreationService>(
  (ref) => RecipeCreationService(
    api: ref.watch(apiClientProvider),
    recipes: ref.watch(recipeRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    store: ref.watch(conversationStoreProvider),
    imports: ref.watch(importServiceProvider),
  ),
);
