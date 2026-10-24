import '../../models/cooking_plan.dart';
import '../../models/provenance.dart';
import '../../models/recipe.dart';

/// Corrections made on the review screen. Every edited value becomes
/// [Provenance.user]. An edit the plan can't absorb exactly (for example a
/// partial amount used in a step, or instructions that mention the old value)
/// reports `outdated`, and the plan must then be regenerated or re-checked
/// before it can be approved or cooked (docs/DECISIONS.md #24).
typedef RecipeEdit = ({Recipe recipe, CookingPlan plan, bool outdated});

/// "2 כוסות" → amount 2, unit "כוסות"; "1/2 כפית" → 0.5; "קורט" → no amount.
Quantity parseQuantity(String display) {
  final text = display.trim();
  final match = RegExp(r'^(\d+(?:[.,]\d+)?)(?:\s*/\s*(\d+))?\s*(.*)$').firstMatch(text);
  double? amount;
  String? unit;
  if (match != null) {
    amount = double.parse(match.group(1)!.replaceAll(',', '.'));
    if (match.group(2) case final d?) amount = amount / double.parse(d);
    final rest = match.group(3)!.trim();
    unit = rest.isEmpty ? null : rest;
  }
  return Quantity(amount: amount, unit: unit, display: text, provenance: Provenance.user);
}

bool _sameQuantity(Quantity a, Quantity b) =>
    a.display.trim() == b.display.trim() || (a.amount != null && a.amount == b.amount && a.unit == b.unit);

RecipeEdit editIngredient(
  Recipe recipe,
  CookingPlan plan,
  String ingredientId, {
  required String name,
  required String amountDisplay,
}) {
  final old = recipe.ingredients.firstWhere((i) => i.id == ingredientId);
  final newName = name.trim().isEmpty ? old.name : name.trim();
  final oldQ = old.quantity;
  final quantityChanged = amountDisplay.trim() != (oldQ?.display.trim() ?? '');
  final newQ = !quantityChanged ? oldQ : (amountDisplay.trim().isEmpty ? null : parseQuantity(amountDisplay));
  var outdated = false;

  bool mentions(String needle) => needle.isNotEmpty &&
      plan.steps.any((s) => s.instructionHe.contains(needle) || s.title.contains(needle));
  if (newName != old.name && mentions(old.name)) outdated = true;

  final steps = <PlanStep>[];
  for (final s in plan.steps) {
    final uses = <IngredientUse>[];
    for (final u in s.ingredientUses) {
      if (u.ingredientId == ingredientId && quantityChanged && u.quantity != null) {
        if (oldQ != null && newQ != null && _sameQuantity(u.quantity!, oldQ)) {
          uses.add(u.copyWith(quantity: newQ)); // the step uses the full amount
          continue;
        }
        outdated = true; // a partial amount: only a new plan can split it again
      }
      uses.add(u);
    }
    steps.add(s.copyWith(ingredientUses: uses));
  }
  if (quantityChanged && oldQ != null && mentions(oldQ.display.trim())) outdated = true;

  return (
    recipe: recipe.copyWith(ingredients: [
      for (final i in recipe.ingredients)
        i.id == ingredientId ? i.copyWith(name: newName, quantity: newQ) : i,
    ]),
    plan: plan.copyWith(steps: steps),
    outdated: outdated,
  );
}

/// Corrects an original instruction; the plan was built from it, so it is outdated.
RecipeEdit editSourceStep(Recipe recipe, CookingPlan plan, String sourceStepId, String text) => (
      recipe: recipe.copyWith(sourceSteps: [
        for (final s in recipe.sourceSteps) s.id == sourceStepId ? s.copyWith(text: text.trim()) : s,
      ]),
      plan: plan,
      outdated: true,
    );

PlanTimer _editTimer(PlanTimer t, int seconds, int? maxSeconds) => t.copyWith(
      seconds: seconds,
      maxSeconds: maxSeconds != null && maxSeconds > seconds ? maxSeconds : null,
      provenance: Provenance.user,
      confidence: null,
      noteHe: null, // the AI's note explained its estimate, which no longer applies
    );

/// Changes when a step or prep timer says "time to check" (and its optional range end).
CookingPlan editTimer(CookingPlan plan, String timerId, {required int seconds, int? maxSeconds}) => plan.copyWith(
      steps: [
        for (final s in plan.steps)
          s.copyWith(timers: [
            for (final t in s.timers) t.id == timerId ? _editTimer(t, seconds, maxSeconds) : t,
          ]),
      ],
      prepTasks: [
        for (final p in plan.prepTasks)
          p.timer?.id == timerId ? p.copyWith(timer: _editTimer(p.timer!, seconds, maxSeconds)) : p,
      ],
    );

CookingPlan editTemperature(CookingPlan plan, String stepId, int celsius) => plan.copyWith(steps: [
      for (final s in plan.steps)
        s.id == stepId
            ? s.copyWith(
                temperature: Temperature(value: celsius, unit: TemperatureUnit.celsius, provenance: Provenance.user),
              )
            : s,
    ]);

CookingPlan editStepInstruction(CookingPlan plan, String stepId, String text) => plan.copyWith(steps: [
      for (final s in plan.steps) s.id == stepId ? s.copyWith(instructionHe: text.trim()) : s,
    ]);

/// A value that did not come straight from the original recipe.
sealed class ReviewValue {
  const ReviewValue(this.provenance, this.note);
  final Provenance provenance;
  final String? note;
}

class IngredientValue extends ReviewValue {
  IngredientValue(this.ingredient) : super(ingredient.quantity!.provenance, ingredient.quantity!.noteHe);
  final Ingredient ingredient;
}

class TimerValue extends ReviewValue {
  TimerValue(this.timer) : super(timer.provenance, timer.noteHe);
  final PlanTimer timer;
}

class TemperatureValue extends ReviewValue {
  TemperatureValue(this.step) : super(step.temperature!.provenance, null);
  final PlanStep step;
}

class LeadValue extends ReviewValue {
  LeadValue(this.prep) : super(prep.leadMinutes!.provenance, prep.leadMinutes!.noteHe);
  final PrepTask prep;
}

/// Everything in the recipe and plan whose provenance is not `original`.
List<ReviewValue> reviewValues(Recipe recipe, CookingPlan plan) => [
      for (final i in recipe.ingredients)
        if (i.quantity != null && i.quantity!.provenance != Provenance.original) IngredientValue(i),
      for (final s in plan.steps) ...[
        if (s.temperature != null && s.temperature!.provenance != Provenance.original) TemperatureValue(s),
        for (final t in s.timers)
          if (t.provenance != Provenance.original) TimerValue(t),
      ],
      for (final p in plan.prepTasks) ...[
        if (p.timer != null && p.timer!.provenance != Provenance.original) TimerValue(p.timer!),
        if (p.leadMinutes != null && p.leadMinutes!.provenance != Provenance.original) LeadValue(p),
      ],
    ];
