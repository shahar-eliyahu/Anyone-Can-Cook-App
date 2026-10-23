import '../../../models/cooking_plan.dart';
import '../../../models/recipe.dart';

/// Structural checks the CookingEngine relies on. Returns a list of problems
/// (empty when the plan is valid). Messages are for developers and logs.
List<String> validatePlan(CookingPlan plan, {Recipe? recipe}) {
  final errors = <String>[];
  final stepIds = <String>{};
  final timerIds = <String>{};

  for (final step in plan.steps) {
    if (!stepIds.add(step.id)) errors.add('duplicate step id ${step.id}');
    for (final t in step.timers) {
      if (!timerIds.add(t.id)) errors.add('duplicate timer id ${t.id}');
    }
  }
  for (final p in plan.prepTasks) {
    if (p.timer != null && !timerIds.add(p.timer!.id)) {
      errors.add('duplicate timer id ${p.timer!.id}');
    }
  }

  for (final step in plan.steps) {
    final actionIds = <String>{};
    for (final a in step.actions) {
      if (!actionIds.add(a.id)) errors.add('${step.id}: duplicate action id ${a.id}');
      if (a.startsTimer != null && !step.timers.any((t) => t.id == a.startsTimer)) {
        errors.add('${step.id}.${a.id}: starts unknown timer ${a.startsTimer}');
      }
    }
    final completing = step.actions.where((a) => a.completesStep).toList();
    if (completing.length != 1) {
      errors.add('${step.id}: needs exactly one completing action');
    } else if (step.actions.last != completing.single) {
      errors.add('${step.id}: completing action must be last');
    } else if (completing.single.startsTimer != null) {
      errors.add('${step.id}: completing action cannot start a timer');
    }
    for (final dep in step.dependsOn) {
      if (dep == step.id) errors.add('${step.id}: depends on itself');
      if (!stepIds.contains(dep)) errors.add('${step.id}: unknown dependency $dep');
    }
  }

  if (_hasCycle(plan)) errors.add('dependency cycle');

  final prepIds = <String>{};
  for (final p in plan.prepTasks) {
    if (!prepIds.add(p.id)) errors.add('duplicate prep task id ${p.id}');
    if (p.neededByStep != null && !stepIds.contains(p.neededByStep)) {
      errors.add('${p.id}: unknown needed_by_step ${p.neededByStep}');
    }
    if (p.surface.withStep != null && !stepIds.contains(p.surface.withStep)) {
      errors.add('${p.id}: unknown surface.with_step ${p.surface.withStep}');
    }
  }

  if (recipe != null) {
    final ingredientIds = {for (final i in recipe.ingredients) i.id};
    final equipmentIds = {for (final e in recipe.equipment) e.id};
    final sourceIds = {for (final s in recipe.sourceSteps) s.id};
    for (final step in plan.steps) {
      for (final id in step.ingredientIds) {
        if (!ingredientIds.contains(id)) errors.add('${step.id}: unknown ingredient $id');
      }
      for (final id in step.equipmentIds) {
        if (!equipmentIds.contains(id)) errors.add('${step.id}: unknown equipment $id');
      }
      for (final id in step.sourceRefs) {
        if (!sourceIds.contains(id)) errors.add('${step.id}: unknown source step $id');
      }
    }
  }
  return errors;
}

bool _hasCycle(CookingPlan plan) {
  final deps = {for (final s in plan.steps) s.id: s.dependsOn};
  final visiting = <String>{};
  final visited = <String>{};

  bool visit(String id) {
    if (visited.contains(id)) return false;
    if (!visiting.add(id)) return true;
    for (final dep in deps[id] ?? const <String>[]) {
      if (deps.containsKey(dep) && visit(dep)) return true;
    }
    visiting.remove(id);
    visited.add(id);
    return false;
  }

  return deps.keys.any(visit);
}
