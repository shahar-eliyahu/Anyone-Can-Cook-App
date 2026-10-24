import 'package:anyone_can_cook/features/import/plan_edits.dart';
import 'package:anyone_can_cook/models/cooking_plan.dart';
import 'package:anyone_can_cook/models/provenance.dart';
import 'package:anyone_can_cook/models/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

Quantity q(double amount, String unit, String display, [Provenance p = Provenance.original]) =>
    Quantity(amount: amount, unit: unit, display: display, provenance: p);

final recipe = Recipe(
  title: 'עוגה',
  ingredients: [
    Ingredient(id: 'i1', name: 'קמח', quantity: q(2, 'כוסות', '2 כוסות')),
    Ingredient(id: 'i2', name: 'סוכר', quantity: q(1, 'כוס', '1 כוס')),
  ],
  sourceSteps: const [SourceStep(id: 'src1', text: 'מערבבים ואופים 30 דקות.')],
);

final plan = CookingPlan(
  steps: [
    PlanStep(
      id: 's1',
      title: 'בלילה',
      instructionHe: 'מערבבים בקערה את הסוכר עם הביצים.',
      ingredientUses: [
        IngredientUse(ingredientId: 'i1', quantity: q(2, 'כוסות', '2 כוסות')),
        IngredientUse(ingredientId: 'i2', quantity: q(0.5, 'כוס', '1/2 כוס')),
      ],
      actions: const [StepAction(id: 'a1', type: ActionType.done, labelHe: 'סיימתי', completesStep: true)],
      timers: const [
        PlanTimer(id: 't1', labelHe: 'אפייה', seconds: 1800, provenance: Provenance.inferred, noteHe: 'הערכה'),
      ],
    ),
  ],
  prepTasks: const [
    PrepTask(
      id: 'p1',
      kind: PrepKind.preheatOven,
      textHe: 'חימום תנור',
      timer: PlanTimer(id: 'tp1', labelHe: 'חימום', seconds: 900, provenance: Provenance.original),
    ),
  ],
);

void main() {
  test('parses amounts, fractions and amount-less quantities', () {
    expect(parseQuantity('1/2 כפית'), const Quantity(amount: 0.5, unit: 'כפית', display: '1/2 כפית', provenance: Provenance.user));
    expect(parseQuantity('1,5 ק"ג').amount, 1.5);
    expect(parseQuantity('קורט').amount, isNull);
  });

  test('a full-amount change flows into the step and keeps the plan current', () {
    final e = editIngredient(recipe, plan, 'i1', name: 'קמח', amountDisplay: '3 כוסות');
    expect(e.outdated, isFalse);
    expect(e.recipe.ingredients.first.quantity, q(3, 'כוסות', '3 כוסות', Provenance.user));
    expect(e.plan.steps.single.ingredientUses.first.quantity!.display, '3 כוסות');
  });

  test('a change to an ingredient split across steps makes the plan outdated', () {
    final e = editIngredient(recipe, plan, 'i2', name: 'סוכר', amountDisplay: '2 כוסות');
    expect(e.outdated, isTrue);
    expect(e.plan.steps.single.ingredientUses.last.quantity!.display, '1/2 כוס'); // not guessed
  });

  test('renaming an ingredient the instructions mention makes the plan outdated', () {
    expect(editIngredient(recipe, plan, 'i2', name: 'סילאן', amountDisplay: '1 כוס').outdated, isTrue);
    expect(editIngredient(recipe, plan, 'i1', name: 'קמח מלא', amountDisplay: '2 כוסות').outdated, isFalse);
  });

  test('instructions that state the old amount make the plan outdated', () {
    final p = plan.copyWith(steps: [plan.steps.single.copyWith(instructionHe: 'מוסיפים 2 כוסות קמח.')]);
    expect(editIngredient(recipe, p, 'i1', name: 'קמח', amountDisplay: '3 כוסות').outdated, isTrue);
  });

  test('correcting an original instruction always makes the plan outdated', () {
    final e = editSourceStep(recipe, plan, 'src1', 'מערבבים ואופים 40 דקות.');
    expect(e.outdated, isTrue);
    expect(e.recipe.sourceSteps.single.text, 'מערבבים ואופים 40 דקות.');
  });

  test('timer and temperature corrections become user values', () {
    var p = editTimer(plan, 't1', seconds: 2400, maxSeconds: 3000);
    expect(p.timersById['t1'], const PlanTimer(
      id: 't1', labelHe: 'אפייה', seconds: 2400, maxSeconds: 3000, provenance: Provenance.user));
    p = editTimer(p, 't1', seconds: 2400, maxSeconds: 1200); // an end before the check time is dropped
    expect(p.timersById['t1']!.maxSeconds, isNull);
    p = editTimer(p, 'tp1', seconds: 600);
    expect(p.prepTasks.single.timer!.seconds, 600);
    p = editTemperature(p, 's1', 175);
    expect(p.steps.single.temperature, const Temperature(value: 175, provenance: Provenance.user));
  });

  test('every value not from the original recipe is listed for review', () {
    final values = reviewValues(recipe, plan);
    expect(values.map((v) => (v.runtimeType, v.provenance)), [(TimerValue, Provenance.inferred)]);
    final edited = editIngredient(recipe, plan, 'i1', name: 'קמח', amountDisplay: '3 כוסות');
    expect(reviewValues(edited.recipe, editTimer(edited.plan, 'tp1', seconds: 600)).map((v) => v.runtimeType),
        [IngredientValue, TimerValue, TimerValue]);
  });
}
