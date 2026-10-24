import 'dart:typed_data';

import 'package:anyone_can_cook/core/api_client.dart';
import 'package:anyone_can_cook/core/db/database.dart';
import 'package:anyone_can_cook/data/recipe_repository.dart';
import 'package:anyone_can_cook/features/import/import_service.dart';
import 'package:anyone_can_cook/models/plan_response.dart';
import 'package:anyone_can_cook/models/recipe_analysis.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/sample.dart';

RecipeAnalysis analysisWith({List<Question> questions = const [], bool isRecipe = true}) => RecipeAnalysis(
      isRecipe: isRecipe,
      notRecipeReasonHe: isRecipe ? null : 'זה לא מתכון',
      source: const RecipeSourceInfo(type: SourceType.text),
      sourceText: 'טקסט',
      recipe: isRecipe ? loadSampleBundle().recipe : null,
      questions: questions,
    );

const question = Question(
  id: 'q1', textHe: 'באיזו תבנית?', whyHe: 'משנה את הזמן', kind: QuestionKind.text, category: GapCategory.equipment,
);

void main() {
  late AppDatabase db;
  late FakeApi api;
  late FakeImageStore images;
  late RecipeRepository recipes;
  late ImportService service;
  final planResponse = PlanResponse(
    plan: loadSampleBundle().plan,
    warningsHe: const ['אזהרה'],
    limitationsHe: const ['מגבלה'],
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    api = FakeApi();
    images = FakeImageStore();
    recipes = RecipeRepository(db, FakeClock().call);
    service = ImportService(api: api, recipes: recipes, images: images);
  });
  tearDown(() => db.close());

  test('a text recipe without questions is analyzed and planned: exactly 2 calls', () async {
    api.analyses.add(analysisWith());
    api.plans.add(planResponse);
    final stages = <ImportStage>[];
    final outcome = await service.analyze(const ImportSource.text('מתכון'), onStage: stages.add);
    final id = (outcome as ImportPlanReady).draftId;
    expect(api.calls, ['analyzeText', 'plan']);
    expect(stages, [ImportStage.reading, ImportStage.planning]);
    final row = (await recipes.getRecipe(id))!;
    expect(row.isDraft, isTrue);
    expect(row.sourceText, 'מתכון');
    expect((await recipes.draftPlan(id))!.plan, loadSampleBundle().plan);
    expect(row.planReview.warningsHe, ['אזהרה']);
    expect(row.planReview.limitationsHe, ['מגבלה']);
  });

  test('questions stop before planning; "I don\'t know" answers then plan', () async {
    api.analyses.add(analysisWith(questions: [question]));
    api.plans.add(planResponse);
    final outcome = await service.analyze(const ImportSource.text('מתכון'));
    final id = (outcome as ImportNeedsAnswers).draftId;
    expect(api.calls, ['analyzeText']);
    await service.submitAnswers(id, const [Answer(questionId: 'q1', unknown: true)]);
    expect(api.calls, ['analyzeText', 'plan']);
    expect(api.lastPlanRequest!.answers.single.unknown, isTrue);
    expect((await recipes.getRecipe(id))!.analysis!.answers.single.questionId, 'q1');
  });

  test('not a recipe: nothing is kept, the photo is deleted', () async {
    api.analyses.add(analysisWith(isRecipe: false));
    final outcome = await service.analyze(ImportSource.image('/images/p.jpg', Uint8List.fromList([1, 2, 3])));
    expect((outcome as ImportNotRecipe).reasonHe, 'זה לא מתכון');
    expect(images.deleted, ['/images/p.jpg']);
    expect(await recipes.watchDrafts().first, isEmpty);
  });

  test('a failed photo import keeps nothing', () async {
    api.analyses.add(const ApiFailure('ai_rate_limited', retryAfterSeconds: 60));
    await expectLater(
      service.analyze(ImportSource.image('/images/p.jpg', Uint8List.fromList([1]))),
      throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'ai_rate_limited')),
    );
    expect(images.deleted, ['/images/p.jpg']);
    expect(await recipes.watchDrafts().first, isEmpty);
  });

  test('an invalid plan from the server is rejected on the device', () async {
    final broken = loadSampleBundle().plan.copyWith(steps: [
      loadSampleBundle().plan.steps.first.copyWith(dependsOn: ['missing']),
    ]);
    api.analyses.add(analysisWith());
    api.plans.add(PlanResponse(plan: broken));
    await expectLater(service.analyze(const ImportSource.text('x')), throwsA(isA<ApiFailure>()));
    final draft = (await recipes.watchDrafts().first).single;
    expect(await recipes.draftPlan(draft.id), isNull);
  });

  test('re-importing the same source is detected', () async {
    api.analyses.add(analysisWith());
    api.plans.add(planResponse);
    await service.analyze(const ImportSource.text('  עוף   בתנור '));
    expect(await service.findDuplicate(const ImportSource.text('עוף בתנור')), isNotNull);
    expect(await service.findDuplicate(const ImportSource.text('מרק')), isNull);
  });

  test('approval keeps the recipe and the corrected plan, and deletes the photo', () async {
    api.analyses.add(analysisWith());
    api.plans.add(planResponse);
    final outcome = await service.analyze(ImportSource.image('/images/p.jpg', Uint8List.fromList([9])));
    final id = (outcome as ImportPlanReady).draftId;
    final corrected = loadSampleBundle().plan.copyWith(advanceNoticeHe: 'תוקן');
    await service.approve(id, corrected, (await recipes.getRecipe(id))!.analysis!);
    final row = (await recipes.getRecipe(id))!;
    expect(row.status, RecipeStatus.ready);
    expect(row.sourceImagePath, isNull);
    expect(images.deleted, ['/images/p.jpg']);
    expect((await recipes.latestApprovedPlan(id))!.plan.advanceNoticeHe, 'תוקן');
  });

  test('discard and cleanup remove drafts and photos', () async {
    api.analyses.add(analysisWith(questions: [question]));
    final kept = (await service.analyze(ImportSource.image('/images/1.jpg', Uint8List.fromList([1])))) as ImportNeedsAnswers;
    images.saved.addAll({'/images/1.jpg', '/images/orphan.jpg'});
    await service.cleanup();
    expect(images.deleted, ['/images/orphan.jpg']);
    await service.discard(kept.draftId);
    expect(images.deleted.last, '/images/1.jpg');
    expect(await recipes.getRecipe(kept.draftId), isNull);
  });
}
