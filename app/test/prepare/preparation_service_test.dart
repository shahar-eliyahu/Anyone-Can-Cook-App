import 'package:anyone_can_cook/core/api_client.dart';
import 'package:anyone_can_cook/core/db/database.dart';
import 'package:anyone_can_cook/data/recipe_repository.dart';
import 'package:anyone_can_cook/data/session_repository.dart';
import 'package:anyone_can_cook/features/prepare/preparation.dart';
import 'package:anyone_can_cook/features/prepare/preparation_service.dart';
import 'package:anyone_can_cook/models/recipe_analysis.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/sample.dart';

SubstitutionProposal aiAnswer({String verdict = 'works', List<Map<String, dynamic>>? ops}) => SubstitutionProposal(
      verdict: verdict,
      explanationHe: 'אפשר.',
      replacementNameHe: 'שמן קנולה',
      source: SubstitutionSource.ai,
      ops: ops ??
          [
            {'op': 'replace_ingredient', 'ingredient_id': 'i3', 'name': 'שמן קנולה'},
            {'op': 'add_step_note', 'step_id': 's1', 'note_he': 'במקום שמן זית: שמן קנולה'},
          ],
    );

void main() {
  late AppDatabase db;
  late RecipeRepository recipes;
  late SessionRepository sessions;
  late FakeApi api;
  late PreparationService service;
  final clock = FakeClock();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    recipes = RecipeRepository(db, clock.call);
    sessions = SessionRepository(db, clock.call);
    api = FakeApi();
    service = PreparationService(recipes: recipes, sessions: sessions, api: api);
  });
  tearDown(() => db.close());

  Future<String> savedSample() => recipes.saveBundle(loadSampleBundle(), sourceType: 'sample');

  test('marks are saved without touching the plan', () async {
    final id = await savedSample();
    final before = (await recipes.latestApprovedPlan(id))!.id;
    await service.setStatus(id, 'i1', ItemStatus.have);
    await service.setStatus(id, 'e2', ItemStatus.missing);
    await service.markAllHave(id);
    final prep = (await recipes.getRecipe(id))!.preparation;
    expect(prep.statusOf('i1'), ItemStatus.have);
    expect(prep.statusOf('e2'), ItemStatus.missing); // "have all" doesn't override a missing mark
    expect(prep.statusOf('i8'), ItemStatus.have);
    expect((await recipes.latestApprovedPlan(id))!.id, before);
  });

  test('the local table answers first; the server only when needed', () async {
    final id = await savedSample();
    final view = (await service.load(id))!;
    // Olive oil has no local rule → one server call.
    api.substitutions.add(aiAnswer());
    final p = await service.propose(view, ItemKind.ingredient, 'i3', noteHe: 'יש לי שמן קנולה');
    expect(p.source, SubstitutionSource.ai);
    expect(api.calls, ['substitute']);
    expect(api.lastSubstituteNote, 'יש לי שמן קנולה');
  });

  test('accepting updates recipe and plan together as a new approved version; undo restores exactly', () async {
    final id = await savedSample();
    final original = (await recipes.latestApprovedPlan(id))!;
    await service.accept(id, ItemKind.ingredient, 'i3', aiAnswer());

    final row = (await recipes.getRecipe(id))!;
    final oil = row.recipe.ingredients.firstWhere((i) => i.id == 'i3');
    expect((oil.name, oil.substitutedFor), ('שמן קנולה', 'שמן זית'));
    final v2 = (await recipes.latestApprovedPlan(id))!;
    expect(v2.id, isNot(original.id));
    expect(v2.basedOnPlanId, original.id);
    expect(v2.plan.stepById('s1')!.notesHe, ['במקום שמן זית: שמן קנולה']);
    final prep = row.preparation;
    expect(prep.substitutions.single.labelHe, 'שמן קנולה');
    expect(prep.statusOf('i3'), ItemStatus.missing);

    await service.undo(id, prep.substitutions.single.id);
    final back = (await recipes.getRecipe(id))!;
    expect(back.recipe.ingredients.firstWhere((i) => i.id == 'i3').name, 'שמן זית');
    expect((await recipes.latestApprovedPlan(id))!.plan, original.plan);
    expect(back.preparation.substitutions, isEmpty);
  });

  test('several substitutions: undoing the first keeps the second', () async {
    final id = await savedSample();
    await service.accept(id, ItemKind.ingredient, 'i3', aiAnswer());
    final view = (await service.load(id))!;
    final garlicLike = service.proposeLocally(view, ItemKind.equipment, 'e4'); // no local rule for a bowl
    expect(garlicLike, isNull);
    await service.accept(id, ItemKind.equipment, 'e4', aiAnswer(ops: [
      {'op': 'replace_equipment', 'equipment_id': 'e4', 'name': 'סיר גדול'},
    ]));
    final first = (await recipes.getRecipe(id))!.preparation.substitutions.first;
    await service.undo(id, first.id);
    final row = (await recipes.getRecipe(id))!;
    expect(row.recipe.ingredients.firstWhere((i) => i.id == 'i3').name, 'שמן זית');
    expect(row.recipe.equipment.firstWhere((e) => e.id == 'e4').name, 'סיר גדול');
  });

  test('a draft keeps a draft plan (approval happens when cooking starts)', () async {
    final bundle = loadSampleBundle();
    final id = await recipes.saveDraft(RecipeAnalysis(
      isRecipe: true, source: const RecipeSourceInfo(type: SourceType.text), sourceText: 'x', recipe: bundle.recipe,
    ));
    await recipes.saveDraftPlan(id, bundle.plan);
    await service.accept(id, ItemKind.ingredient, 'i3', aiAnswer());
    final row = (await recipes.getRecipe(id))!;
    expect(row.isDraft, isTrue);
    expect(await recipes.latestApprovedPlan(id), isNull);
    expect((await recipes.draftPlan(id))!.plan.stepById('s1')!.notesHe, isNotEmpty);
    expect(row.analysis!.recipe!.ingredients.firstWhere((i) => i.id == 'i3').name, 'שמן קנולה');
  });

  test('answers without a usable change, invalid patches and active sessions are refused', () async {
    final id = await savedSample();
    expect(() => service.accept(id, ItemKind.ingredient, 'i3', aiAnswer(verdict: 'no_substitute', ops: [])),
        throwsA(isA<SubstitutionFailed>()));
    expect(() => service.accept(id, ItemKind.ingredient, 'i3', aiAnswer(ops: [
          {'op': 'add_step_note', 'step_id': 's99', 'note_he': 'x'},
        ])), throwsA(isA<SubstitutionFailed>().having((e) => e.reason, 'reason', 'invalid_patch')));
    final plan = (await recipes.latestApprovedPlan(id))!;
    await sessions.startSession(recipeId: id, planId: plan.id);
    expect((await service.load(id))!.cookingNow, isTrue);
    expect(() => service.accept(id, ItemKind.ingredient, 'i3', aiAnswer()),
        throwsA(isA<SubstitutionFailed>().having((e) => e.reason, 'reason', 'cooking_now')));
  });

  test('advanced editing locks earlier substitutions (kept, no longer undoable)', () async {
    final id = await savedSample();
    await service.accept(id, ItemKind.ingredient, 'i3', aiAnswer());
    await service.lockAfterAdvancedEdit(id);
    final prep = (await recipes.getRecipe(id))!.preparation;
    expect(prep.substitutions.single.locked, isTrue);
    expect(prep.baseRecipe, isNull);
    expect(() => service.undo(id, prep.substitutions.single.id), throwsA(isA<SubstitutionFailed>()));
  });

  test('editing the analysis keeps the preparation and plan review', () async {
    final id = await savedSample();
    await service.setStatus(id, 'i1', ItemStatus.have);
    final row = (await recipes.getRecipe(id))!;
    await recipes.updateAnalysis(id, PreparationService.analysisOf(row));
    await recipes.approvePlan(id, (await recipes.latestApprovedPlan(id))!.plan, analysis: PreparationService.analysisOf(row));
    expect((await recipes.getRecipe(id))!.preparation.statusOf('i1'), ItemStatus.have);
  });

  test('the server being unavailable surfaces as ApiFailure (nothing changes)', () async {
    final id = await savedSample();
    api.substitutions.add(const ApiFailure('ai_quota_exhausted'));
    final view = (await service.load(id))!;
    await expectLater(service.propose(view, ItemKind.ingredient, 'i3'), throwsA(isA<ApiFailure>()));
    expect((await recipes.getRecipe(id))!.preparation.substitutions, isEmpty);
  });

  test('a saved recipe with unapproved advanced edits: the overview and substitutions use the approved plan', () async {
    final id = await savedSample();
    final approved = (await recipes.latestApprovedPlan(id))!.plan;
    final edited = approved.copyWith(advanceNoticeHe: 'עריכה שלא אושרה');
    await recipes.saveDraftPlan(id, edited);
    expect((await service.load(id))!.plan, approved);
    await service.accept(id, ItemKind.ingredient, 'i3', aiAnswer());
    expect((await recipes.latestApprovedPlan(id))!.plan.advanceNoticeHe, isNull);
  });
}
