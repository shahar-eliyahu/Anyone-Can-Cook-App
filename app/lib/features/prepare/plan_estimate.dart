import '../../models/cooking_plan.dart';

/// A rough time estimate for the overview, computed on the device from the plan.
class PlanEstimate {
  const PlanEstimate({required this.totalMinutes, required this.activeMinutes});

  /// The longest chain of dependent steps: hands-on minutes plus waiting timers.
  final int totalMinutes;

  /// Hands-on minutes over all steps.
  final int activeMinutes;
}

/// Minutes assumed for a step without an `estimated_active_minutes`.
const defaultActiveMinutes = 5;

PlanEstimate estimatePlan(CookingPlan plan) {
  int active(PlanStep s) => s.estimatedActiveMinutes?.value ?? defaultActiveMinutes;
  int duration(PlanStep s) => active(s) + (s.timers.fold(0, (sum, t) => sum + t.seconds) / 60).ceil();

  final finish = <String, int>{};
  int finishOf(PlanStep s, Set<String> visiting) {
    if (finish[s.id] case final f?) return f;
    if (!visiting.add(s.id)) return duration(s); // a cycle can't happen in a validated plan
    var start = 0;
    for (final dep in s.dependsOn) {
      if (plan.stepById(dep) case final d?) {
        final f = finishOf(d, visiting);
        if (f > start) start = f;
      }
    }
    return finish[s.id] = start + duration(s);
  }

  final total = plan.steps.fold(0, (m, s) {
    final f = finishOf(s, <String>{});
    return f > m ? f : m;
  });
  return PlanEstimate(
    totalMinutes: total,
    activeMinutes: plan.steps.fold(0, (sum, s) => sum + active(s)),
  );
}
