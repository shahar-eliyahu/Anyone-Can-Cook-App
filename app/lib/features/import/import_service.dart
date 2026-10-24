import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/content_hash.dart';
import '../../core/db/database.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../data/settings_repository.dart';
import '../../models/cooking_plan.dart';
import '../../models/recipe_analysis.dart';
import '../cooking/engine/plan_validator.dart';
import 'image_store.dart';

enum ImportStage { reading, planning }

sealed class ImportOutcome {
  const ImportOutcome();
}

class ImportNotRecipe extends ImportOutcome {
  const ImportNotRecipe(this.reasonHe);
  final String? reasonHe;
}

/// The draft has questions that need the cook's input before planning.
class ImportNeedsAnswers extends ImportOutcome {
  const ImportNeedsAnswers(this.draftId);
  final String draftId;
}

/// A plan was generated and saved as a draft plan; next is review.
class ImportPlanReady extends ImportOutcome {
  const ImportPlanReady(this.draftId);
  final String draftId;
}

/// The recipe was read and saved as a draft, but generating the plan failed (e.g. the
/// AI quota ran out in between). Retrying needs only the plan call, not a new analysis.
class ImportPlanFailed extends ImportOutcome {
  const ImportPlanFailed(this.draftId, this.error);
  final String draftId;
  final Object error;
}

/// The input of an import that hasn't gone through yet (offline, AI quota used up…),
/// kept so nothing typed, pasted or photographed is lost. Cleared once a draft exists.
class PendingImport {
  const PendingImport({this.text, this.url, this.imagePath});

  factory PendingImport.of(ImportSource s) => PendingImport(text: s.text, url: s.url, imagePath: s.imagePath);

  factory PendingImport.fromJson(Map<String, dynamic> j) =>
      PendingImport(text: j['text'] as String?, url: j['url'] as String?, imagePath: j['image_path'] as String?);

  final String? text;
  final String? url;
  final String? imagePath;

  Map<String, dynamic> toJson() => {'text': text, 'url': url, 'image_path': imagePath};
}

/// What the user wants to import. Built by the import screen (or, later, by
/// recipe discovery: a chosen search result is just a [ImportSource.url]).
class ImportSource {
  const ImportSource.text(String this.text) : type = SourceType.text, url = null, imagePath = null, imageBytes = null;
  const ImportSource.url(String this.url) : type = SourceType.url, text = null, imagePath = null, imageBytes = null;
  const ImportSource.image(String this.imagePath, Uint8List this.imageBytes)
      : type = SourceType.image,
        text = null,
        url = null;

  final SourceType type;
  final String? text;
  final String? url;
  final String? imagePath;
  final Uint8List? imageBytes;

  String get hash => switch (type) {
        SourceType.text => textHash(text!),
        SourceType.url => textHash(url!),
        _ => contentHash(imageBytes!),
      };
}

class ImportService {
  ImportService({required this.api, required this.recipes, required this.images, required this.settings});

  final ApiClient api;
  final RecipeRepository recipes;
  final ImageStore images;
  final SettingsRepository settings;

  Future<PendingImport?> pendingInput() async {
    final raw = await settings.get(SettingKeys.pendingImport);
    return raw == null || raw.isEmpty ? null : PendingImport.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> savePending(PendingImport input) => settings.set(SettingKeys.pendingImport, jsonEncode(input.toJson()));

  Future<void> clearPending() => settings.set(SettingKeys.pendingImport, '');

  /// A recipe or draft already imported from the same source.
  Future<RecipeRow?> findDuplicate(ImportSource source) => recipes.findByContentHash(source.hash);

  /// Analyze → save draft → (questions ? stop : generate the plan).
  ///
  /// The input is kept as pending until a draft exists, so a failure (offline, AI quota
  /// used up…) loses nothing; the photo stays for a retry. Nothing is retried automatically.
  Future<ImportOutcome> analyze(ImportSource source, {void Function(ImportStage)? onStage}) async {
    onStage?.call(ImportStage.reading);
    await savePending(PendingImport.of(source));
    final analysis = switch (source.type) {
      SourceType.text => await api.analyzeText(source.text!),
      SourceType.url => await api.analyzeUrl(source.url!),
      _ => await api.analyzeImage(source.imageBytes!),
    };
    if (!analysis.isRecipe || analysis.recipe == null) {
      await images.delete(source.imagePath);
      await clearPending();
      return ImportNotRecipe(analysis.notRecipeReasonHe);
    }
    final draftId = await recipes.saveDraft(
      analysis,
      sourceText: source.type == SourceType.text ? source.text : analysis.sourceText,
      imagePath: source.imagePath,
      contentHash: source.hash,
    );
    await clearPending(); // the draft now holds the input
    if (analysis.questions.isNotEmpty) return ImportNeedsAnswers(draftId);
    onStage?.call(ImportStage.planning);
    try {
      await generatePlan(draftId);
    } catch (e) {
      return ImportPlanFailed(draftId, e);
    }
    return ImportPlanReady(draftId);
  }

  /// Stores the cook's answers ("לא יודע/ת" included) and generates the plan.
  Future<void> submitAnswers(String draftId, List<Answer> answers) async {
    final row = (await recipes.getRecipe(draftId))!;
    await recipes.updateAnalysis(draftId, row.analysis!.copyWith(answers: answers));
    await generatePlan(draftId);
  }

  /// One /plan call; the result is validated again on the device before it can be shown.
  Future<void> generatePlan(String recipeId) async {
    final row = (await recipes.getRecipe(recipeId))!;
    final analysis = row.analysis!;
    final response = await api.plan(analysis);
    final problems = validatePlan(response.plan, recipe: analysis.recipe);
    if (problems.isNotEmpty) throw const ApiFailure('invalid_ai_output');
    await recipes.saveDraftPlan(recipeId, response.plan, response: response);
    await recipes.setPlanStale(recipeId, false);
  }

  /// Approves the reviewed (possibly corrected) plan and recipe; deletes the photo.
  Future<void> approve(String recipeId, CookingPlan plan, RecipeAnalysis analysis) async {
    final row = (await recipes.getRecipe(recipeId))!;
    await recipes.approvePlan(recipeId, plan, analysis: analysis);
    await images.delete(row.sourceImagePath);
  }

  Future<void> discard(String draftId) async => images.delete(await recipes.discardDraft(draftId));

  /// Startup cleanup: expired drafts, their photos, and photos neither a draft nor
  /// the pending (not yet sent) import refers to.
  Future<void> cleanup() async {
    for (final path in await recipes.purgeOldDrafts()) {
      await images.delete(path);
    }
    final drafts = await recipes.watchDrafts().first;
    final pending = (await pendingInput())?.imagePath;
    await images.deleteAllExcept({for (final d in drafts) ?d.sourceImagePath, ?pending});
  }
}

final importServiceProvider = Provider<ImportService>(
  (ref) => ImportService(
    api: ref.watch(apiClientProvider),
    recipes: ref.watch(recipeRepositoryProvider),
    images: ref.watch(imageStoreProvider),
    settings: ref.watch(settingsRepositoryProvider),
  ),
);

final _link = RegExp('https?://[^\\s<>"\u200e\u200f]+', caseSensitive: false);

/// The first web address in what the cook pasted. Sharing from a phone often copies a title
/// with the link ("עוגת ביסקוויטים… https://share.google/…"); trailing punctuation is dropped.
String? findLink(String text) {
  final m = _link.firstMatch(text);
  return m?.group(0)?.replaceFirst(RegExp('[.,;:!?)\\]\u05f3\u05f4]+\$'), '');
}
