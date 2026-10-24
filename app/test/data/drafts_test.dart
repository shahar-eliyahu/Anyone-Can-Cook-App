import 'package:anyone_can_cook/core/db/database.dart';
import 'package:anyone_can_cook/data/recipe_repository.dart';
import 'package:anyone_can_cook/models/provenance.dart';
import 'package:anyone_can_cook/models/recipe_analysis.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sample.dart';

RecipeAnalysis sampleAnalysis() => RecipeAnalysis(
      isRecipe: true,
      source: const RecipeSourceInfo(type: SourceType.text),
      sourceText: 'טקסט המתכון',
      recipe: loadSampleBundle().recipe,
      questions: const [
        Question(id: 'q1', textHe: 'באיזו תבנית?', whyHe: 'זה משנה את הזמן', kind: QuestionKind.text, category: GapCategory.equipment),
      ],
    );

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late RecipeRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clock = FakeClock();
    repo = RecipeRepository(db, clock.call);
  });
  tearDown(() => db.close());

  test('drafts are stored with their analysis but not listed until approved', () async {
    final id = await repo.saveDraft(sampleAnalysis(), contentHash: 'h1', imagePath: '/tmp/x.jpg');
    expect(await repo.watchRecipes().first, isEmpty);
    expect(await repo.watchDrafts().first, hasLength(1));
    final row = (await repo.getRecipe(id))!;
    expect(row.isDraft, isTrue);
    expect(row.analysis!.questions.single.id, 'q1');
    expect(row.recipe, loadSampleBundle().recipe);
    expect((await repo.findByContentHash('h1'))!.id, id);
  });

  test('a draft plan survives until approval; approval lists the recipe and clears the photo', () async {
    final id = await repo.saveDraft(sampleAnalysis(), imagePath: '/tmp/x.jpg');
    await repo.saveDraftPlan(id, loadSampleBundle().plan);
    expect((await repo.draftPlan(id))!.plan, loadSampleBundle().plan);
    expect(await repo.latestApprovedPlan(id), isNull);

    await repo.approvePlan(id, loadSampleBundle().plan);
    final row = (await repo.getRecipe(id))!;
    expect(row.status, RecipeStatus.ready);
    expect(row.sourceImagePath, isNull);
    expect(await repo.draftPlan(id), isNull);
    expect(await repo.latestApprovedPlan(id), isNotNull);
    expect(await repo.watchRecipes().first, hasLength(1));
  });

  test('approving a new plan supersedes the old one and clears the out-of-date flag', () async {
    final id = await repo.saveBundle(loadSampleBundle(), sourceType: 'sample');
    final first = (await repo.latestApprovedPlan(id))!;
    final analysis = sampleAnalysis();
    await repo.updateAnalysis(id, analysis, planStale: true);
    expect((await repo.getRecipe(id))!.planStale, isTrue);

    final edited = loadSampleBundle().plan.copyWith(advanceNoticeHe: 'חדש');
    await repo.approvePlan(id, edited);
    final latest = (await repo.latestApprovedPlan(id))!;
    expect(latest.plan.advanceNoticeHe, 'חדש');
    expect(latest.basedOnPlanId, first.id);
    expect((await repo.getPlan(first.id))!.status, PlanStatus.superseded);
    expect((await repo.getRecipe(id))!.planStale, isFalse);
  });

  test('discarding and purging drafts returns their photos for deletion', () async {
    final a = await repo.saveDraft(sampleAnalysis(), imagePath: '/tmp/a.jpg');
    await repo.saveDraftPlan(a, loadSampleBundle().plan);
    expect(await repo.discardDraft(a), '/tmp/a.jpg');
    expect(await repo.getRecipe(a), isNull);

    await repo.saveDraft(sampleAnalysis(), imagePath: '/tmp/old.jpg');
    clock.advance(const Duration(days: 8));
    final fresh = await repo.saveDraft(sampleAnalysis(), imagePath: '/tmp/new.jpg');
    expect(await repo.purgeOldDrafts(), ['/tmp/old.jpg']);
    expect((await repo.watchDrafts().first).map((r) => r.id), [fresh]);
  });

  test('approved recipes are never purged or discarded as drafts', () async {
    final id = await repo.saveBundle(loadSampleBundle(), sourceType: 'sample');
    clock.advance(const Duration(days: 30));
    expect(await repo.purgeOldDrafts(), isEmpty);
    expect(await repo.discardDraft(id), isNull);
    expect(await repo.getRecipe(id), isNotNull);
  });

  test('legacy Phase 1 rows have no analysis but still decode their recipe', () async {
    final id = await repo.saveBundle(loadSampleBundle(), sourceType: 'sample');
    final row = (await repo.getRecipe(id))!;
    expect(row.analysis, isNull);
    expect(row.recipe.ingredients.first.quantity!.provenance, Provenance.original);
  });
}
