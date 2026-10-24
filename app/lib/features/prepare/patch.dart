import '../../models/cooking_plan.dart';
import '../../models/provenance.dart';
import '../../models/recipe.dart';

/// Substitution patch operations (Phase 3A, docs/DECISIONS.md #40).
///
/// Plain data from a small fixed set, so the effective recipe and plan are always
/// "original + accepted operations" and any substitution can be undone exactly. Same
/// semantics as the backend (`backend/app/services/patching.py`); both are checked against
/// `shared/fixtures/patch_example.json`. Operations are kept as their JSON maps.
typedef PatchOp = Map<String, dynamic>;

class PatchException implements Exception {
  const PatchException(this.message);
  final String message;
  @override
  String toString() => 'PatchException($message)';
}

/// Applies [ops] in order. Unknown ids throw [PatchException].
(Recipe, CookingPlan) applyPatch(Recipe recipe, CookingPlan plan, List<PatchOp> ops) {
  final (r, p) = _apply(recipe, plan, ops);
  return (r!, p);
}

/// The plan effects of [ops] only (mid-cooking patches inside the engine, which has no recipe).
CookingPlan applyPatchToPlan(CookingPlan plan, List<PatchOp> ops) => _apply(null, plan, ops).$2;

/// The recipe effects of [ops] only (names and amounts shown while cooking).
Recipe applyPatchToRecipe(Recipe recipe, List<PatchOp> ops) {
  const recipeOps = {'replace_ingredient', 'omit_ingredient', 'replace_equipment', 'omit_equipment'};
  final (r, _) = _apply(recipe, const CookingPlan(steps: []), [for (final o in ops) if (recipeOps.contains(o['op'])) o]);
  return r!;
}

(Recipe?, CookingPlan) _apply(Recipe? recipe, CookingPlan plan, List<PatchOp> ops) {
  var r = recipe;
  var p = plan;

  Ingredient ingredient(String id) =>
      r!.ingredients.firstWhere((i) => i.id == id, orElse: () => throw PatchException('unknown ingredient $id'));
  Equipment equipment(String id) =>
      r!.equipment.firstWhere((e) => e.id == id, orElse: () => throw PatchException('unknown equipment $id'));
  PlanStep step(String id) => p.stepById(id) ?? (throw PatchException('unknown step $id'));
  Quantity? quantity(Object? json) => json == null ? null : Quantity.fromJson(json as Map<String, dynamic>);

  void updateIngredient(Ingredient updated) =>
      r = r!.copyWith(ingredients: [for (final i in r!.ingredients) i.id == updated.id ? updated : i]);
  void updateEquipment(Equipment updated) =>
      r = r!.copyWith(equipment: [for (final e in r!.equipment) e.id == updated.id ? updated : e]);
  void updateStep(PlanStep updated) =>
      p = p.copyWith(steps: [for (final s in p.steps) s.id == updated.id ? updated : s]);

  for (final op in ops) {
    switch (op['op']) {
      case 'replace_ingredient':
        if (r == null) continue;
        final i = ingredient(op['ingredient_id'] as String);
        updateIngredient(i.copyWith(
          substitutedFor: i.substitutedFor ?? i.name,
          name: op['name'] as String,
          omitted: false,
          quantity: op['quantity'] == null ? i.quantity : quantity(op['quantity']),
        ));
      case 'omit_ingredient':
        final id = op['ingredient_id'] as String;
        if (r != null) updateIngredient(ingredient(id).copyWith(omitted: true));
        p = p.copyWith(steps: [
          for (final s in p.steps)
            s.copyWith(
              ingredientUses: [for (final u in s.ingredientUses) if (u.ingredientId != id) u],
              ingredientIds: [for (final i in s.ingredientIds) if (i != id) i],
            ),
        ]);
      case 'replace_equipment':
        if (r == null) continue;
        final e = equipment(op['equipment_id'] as String);
        updateEquipment(e.copyWith(substitutedFor: e.substitutedFor ?? e.name, name: op['name'] as String, omitted: false));
      case 'omit_equipment':
        final id = op['equipment_id'] as String;
        if (r != null) updateEquipment(equipment(id).copyWith(omitted: true));
        p = p.copyWith(steps: [
          for (final s in p.steps) s.copyWith(equipmentIds: [for (final e in s.equipmentIds) if (e != id) e]),
        ]);
      case 'set_ingredient_use':
        final id = op['ingredient_id'] as String;
        if (r != null) ingredient(id);
        final s = step(op['step_id'] as String);
        final q = quantity(op['quantity']);
        final has = s.ingredientUses.any((u) => u.ingredientId == id);
        updateStep(s.copyWith(
          ingredientUses: has
              ? [for (final u in s.ingredientUses) u.ingredientId == id ? u.copyWith(quantity: q) : u]
              : [...s.ingredientUses, IngredientUse(ingredientId: id, quantity: q)],
          ingredientIds: s.ingredientIds.contains(id) ? s.ingredientIds : [...s.ingredientIds, id],
        ));
      case 'set_step_text':
        updateStep(step(op['step_id'] as String).copyWith(instructionHe: op['instruction_he'] as String));
      case 'add_step_note':
        final s = step(op['step_id'] as String);
        final note = op['note_he'] as String;
        if (!s.notesHe.contains(note)) updateStep(s.copyWith(notesHe: [...s.notesHe, note]));
      case 'set_timer_seconds':
        final id = op['timer_id'] as String;
        final seconds = op['seconds'] as int;
        final max = op['max_seconds'] as int?;
        PlanTimer edit(PlanTimer t) => t.copyWith(
              seconds: seconds,
              maxSeconds: max != null && max > seconds ? max : null,
              provenance: Provenance.inferred,
            );
        if (!p.timersById.containsKey(id)) throw PatchException('unknown timer $id');
        p = p.copyWith(
          steps: [
            for (final s in p.steps) s.copyWith(timers: [for (final t in s.timers) t.id == id ? edit(t) : t]),
          ],
          prepTasks: [
            for (final t in p.prepTasks) t.timer?.id == id ? t.copyWith(timer: edit(t.timer!)) : t,
          ],
        );
      case 'set_step_safety':
        final s = step(op['step_id'] as String);
        final confirm = op['confirm_completion'] as bool? ?? false;
        updateStep(s.copyWith(
          warningsHe: [for (final w in op['warnings_he'] as List? ?? const []) w as String],
          donenessCueHe: op['doneness_cue_he'] as String?,
          actions: [
            for (final a in s.actions)
              a.completesStep ? a.copyWith(confirmPolicy: confirm ? ConfirmPolicy.alwaysAsk : ConfirmPolicy.autoOk) : a,
          ],
        ));
      default:
        throw PatchException('unknown op ${op['op']}');
    }
  }
  return (r, p);
}
