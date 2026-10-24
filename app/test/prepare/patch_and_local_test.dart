import 'dart:convert';
import 'dart:io';

import 'package:anyone_can_cook/features/prepare/local_substitutions.dart';
import 'package:anyone_can_cook/features/prepare/patch.dart';
import 'package:anyone_can_cook/features/prepare/plan_estimate.dart';
import 'package:anyone_can_cook/features/prepare/preparation.dart';
import 'package:anyone_can_cook/models/cooking_plan.dart';
import 'package:anyone_can_cook/models/provenance.dart';
import 'package:anyone_can_cook/models/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sample.dart';

Recipe recipeWith(List<Ingredient> ingredients, {List<Equipment> equipment = const [], String title = 'מתכון'}) =>
    loadSampleBundle().recipe.copyWith(title: title, ingredients: ingredients, equipment: equipment, sourceSteps: const []);

Quantity q(double amount, String unit) => Quantity(amount: amount, unit: unit, display: '$amount $unit', provenance: Provenance.original);

CookingPlan planUsing(String ingredientId, {String instruction = 'מערבבים הכול.', List<String> equipment = const []}) =>
    CookingPlan(steps: [
      PlanStep(
        id: 's1',
        title: 'שלב',
        instructionHe: instruction,
        ingredientIds: [ingredientId],
        ingredientUses: [IngredientUse(ingredientId: ingredientId, quantity: q(1, 'כוס'))],
        equipmentIds: equipment,
        actions: const [StepAction(id: 'a1', type: ActionType.done, labelHe: 'סיימתי', completesStep: true)],
      ),
    ]);

void main() {
  group('patch operations (shared fixture: same results as the backend)', () {
    test('patch_example.json', () {
      final fixture = jsonDecode(File('../shared/fixtures/patch_example.json').readAsStringSync()) as Map<String, dynamic>;
      final bundle = loadSampleBundle();
      final ops = [for (final o in fixture['ops'] as List) Map<String, dynamic>.from(o as Map)];
      final (recipe, plan) = applyPatch(bundle.recipe, bundle.plan, ops);
      final exp = fixture['expect'] as Map<String, dynamic>;
      for (final MapEntry(:key, :value) in (exp['ingredients'] as Map<String, dynamic>).entries) {
        final i = recipe.ingredients.firstWhere((x) => x.id == key);
        expect([i.name, i.substitutedFor, i.omitted, i.quantity?.display],
            [value['name'], value['substituted_for'], value['omitted'], value['quantity_display']]);
      }
      for (final MapEntry(:key, :value) in (exp['equipment'] as Map<String, dynamic>).entries) {
        final e = recipe.equipment.firstWhere((x) => x.id == key);
        expect([e.name, e.substitutedFor, e.omitted], [value['name'], value['substituted_for'], value['omitted']]);
      }
      final steps = exp['steps'] as Map<String, dynamic>;
      final s1 = plan.stepById('s1')!, s2 = plan.stepById('s2')!, s3 = plan.stepById('s3')!;
      expect({for (final u in s1.ingredientUses) u.ingredientId: u.quantity?.display}, steps['s1']['use_displays']);
      expect(s1.notesHe, steps['s1']['notes_he']);
      expect(s1.equipmentIds, steps['s1']['equipment_ids']);
      expect(s2.instructionHe, steps['s2']['instruction_he']);
      expect(s2.ingredientIds, steps['s2']['ingredient_ids']);
      expect(s3.warningsHe, steps['s3']['warnings_he']);
      expect(s3.donenessCueHe, steps['s3']['doneness_cue_he']);
      expect(s3.actions.last.confirmPolicy, ConfirmPolicy.autoOk);
      final t2 = plan.timersById['t2']!;
      expect([t2.seconds, t2.maxSeconds, t2.provenance], [1200, null, Provenance.inferred]);
    });

    test('unknown ids are refused', () {
      final b = loadSampleBundle();
      expect(() => applyPatch(b.recipe, b.plan, [{'op': 'add_step_note', 'step_id': 's99', 'note_he': 'x'}]),
          throwsA(isA<PatchException>()));
      expect(() => applyPatch(b.recipe, b.plan, [{'op': 'nope'}]), throwsA(isA<PatchException>()));
    });
  });

  group('local substitutions', () {
    test('cream → milk and butter, with adjusted amounts and a note on every step that uses it', () {
      final recipe = recipeWith([Ingredient(id: 'i1', name: 'שמנת מתוקה', quantity: q(1, 'כוס'))]);
      final p = localSubstitution(recipe: recipe, plan: planUsing('i1'), kind: ItemKind.ingredient, targetId: 'i1', userNoteHe: 'יש לי חלב')!;
      expect(p.verdict, 'changes_result');
      expect(p.source, SubstitutionSource.local);
      final (r, plan) = applyPatch(recipe, planUsing('i1'), p.ops);
      final cream = r.ingredients.single;
      expect(cream.name, 'חלב וחמאה');
      expect(cream.substitutedFor, 'שמנת מתוקה');
      expect(cream.quantity!.display, '¾ כוס חלב + ¼ כוס חמאה מומסת');
      expect(plan.steps.single.ingredientUses.single.quantity!.display, '¾ כוס חלב + ¼ כוס חמאה מומסת');
      expect(plan.steps.single.notesHe.single, startsWith('במקום שמנת מתוקה: חלב וחמאה'));
    });

    test('context matters: no milk for cream that must be whipped, no oil for butter in pastry', () {
      final cream = recipeWith([Ingredient(id: 'i1', name: 'שמנת מתוקה', quantity: q(1, 'כוס'))]);
      expect(localSubstitution(recipe: cream, plan: planUsing('i1', instruction: 'מקציפים לקצפת יציבה.'),
          kind: ItemKind.ingredient, targetId: 'i1'), isNull);
      final butter = recipeWith([Ingredient(id: 'i1', name: 'חמאה', quantity: q(100, 'גרם'))], title: 'עוגת שוקולד');
      final p = localSubstitution(recipe: butter, plan: planUsing('i1'), kind: ItemKind.ingredient, targetId: 'i1', userNoteHe: 'יש לי שמן');
      expect(p, isNull); // goes to the server, which reasons about the cake
    });

    test('what the cook says they have picks the rule; unknown offers go to the server', () {
      final honey = recipeWith([Ingredient(id: 'i1', name: 'דבש', quantity: q(2, 'כפות'))]);
      expect(localSubstitution(recipe: honey, plan: planUsing('i1'), kind: ItemKind.ingredient, targetId: 'i1', userNoteHe: 'יש לי סירופ מייפל')!
          .replacementNameHe, 'סירופ מייפל');
      expect(localSubstitution(recipe: honey, plan: planUsing('i1'), kind: ItemKind.ingredient, targetId: 'i1', userNoteHe: 'יש לי ריבה'), isNull);
    });

    test('garlic cloves become garlic powder in teaspoons', () {
      final garlic = recipeWith([Ingredient(id: 'i1', name: 'שיני שום', quantity: q(2, 'שיניים'))]);
      final p = localSubstitution(recipe: garlic, plan: planUsing('i1'), kind: ItemKind.ingredient, targetId: 'i1')!;
      final (r, _) = applyPatch(garlic, planUsing('i1'), p.ops);
      expect(r.ingredients.single.quantity!.display, '¼ כפית');
    });

    test('no kitchen scale: grams become cups and spoons, unknown ones are named', () {
      final recipe = recipeWith([
        Ingredient(id: 'i1', name: 'קמח לבן', quantity: q(280, 'גרם')),
        Ingredient(id: 'i2', name: 'סוכר', quantity: q(25, 'גרם')),
        Ingredient(id: 'i3', name: 'שוקולד מריר', quantity: q(100, 'גרם')),
      ], equipment: const [Equipment(id: 'e1', name: 'משקל מטבח')]);
      final p = localSubstitution(recipe: recipe, plan: planUsing('i1'), kind: ItemKind.equipment, targetId: 'e1')!;
      final (r, _) = applyPatch(recipe, planUsing('i1'), p.ops);
      expect(r.ingredients[0].quantity!.display, 'כ-2 כוסות (280.0 גרם)');
      expect(r.ingredients[1].quantity!.display, 'כ-2 כפות (25.0 גרם)');
      expect(r.ingredients[2].quantity!.display, '100.0 גרם');
      expect(p.verdict, 'changes_result');
      expect(p.effectsHe, contains('שוקולד מריר'));
      expect(r.equipment.single.name, 'כוסות וכפות מדידה');
    });

    test('no thermometer: honest signs-only wording, the cook still confirms', () {
      final b = loadSampleBundle();
      final recipe = b.recipe.copyWith(equipment: [...b.recipe.equipment, const Equipment(id: 'e9', name: 'מדחום')]);
      final s3 = b.plan.stepById('s3')!;
      final plan = b.plan.copyWith(steps: [
        for (final s in b.plan.steps)
          s.id == 's3' ? s3.copyWith(warningsHe: ['חתכו בחלק העבה. הבדיקה המדויקת: מדחום, לפחות 74°C.']) : s,
      ]);
      final p = localSubstitution(recipe: recipe, plan: plan, kind: ItemKind.equipment, targetId: 'e9')!;
      final (r, out) = applyPatch(recipe, plan, p.ops);
      final bake = out.stepById('s3')!;
      expect(bake.warningsHe.single, startsWith('בלי מדחום: חותכים בחלק העבה'));
      expect(bake.actions.last.confirmPolicy, ConfirmPolicy.alwaysAsk);
      expect(r.equipment.last.omitted, isTrue);
      expect(p.effectsHe, contains('פחות מדויקת'));
    });

    test('no mixer: by hand, with an honest note when whipping is involved', () {
      final recipe = recipeWith([Ingredient(id: 'i1', name: 'חלבונים', quantity: q(3, 'יחידות'))],
          equipment: const [Equipment(id: 'e1', name: 'מיקסר')]);
      final p = localSubstitution(recipe: recipe, plan: planUsing('i1', instruction: 'מקציפים לקצף.', equipment: ['e1']),
          kind: ItemKind.equipment, targetId: 'e1')!;
      expect(p.verdict, 'changes_result');
      final (_, plan) = applyPatch(recipe, planUsing('i1', equipment: ['e1']), p.ops);
      expect(plan.steps.single.notesHe.single, contains('בלי מיקסר'));
    });

    test('anything else is left to the server', () {
      final recipe = recipeWith([Ingredient(id: 'i1', name: 'שמרים', quantity: q(1, 'כף'))],
          equipment: const [Equipment(id: 'e1', name: 'תנור')]);
      expect(localSubstitution(recipe: recipe, plan: planUsing('i1'), kind: ItemKind.ingredient, targetId: 'i1'), isNull);
      expect(localSubstitution(recipe: recipe, plan: planUsing('i1'), kind: ItemKind.equipment, targetId: 'e1'), isNull);
    });

    test('amounts read naturally', () {
      expect([formatAmount(0.75), formatAmount(1.5), formatAmount(2), formatAmount(0.125), formatAmount(1.3)],
          ['¾', '1½', '2', '⅛', '1.3']);
    });
  });

  test('time estimate: the longest chain of steps, hands-on plus waiting', () {
    final e = estimatePlan(loadSampleBundle().plan);
    // s1 → s2 → s3 (45 min oven) → s5 (5 min rest), with active minutes from the plan.
    expect(e.totalMinutes, greaterThan(50));
    expect(e.totalMinutes, lessThan(120));
    expect(e.activeMinutes, greaterThan(0));
  });
}
