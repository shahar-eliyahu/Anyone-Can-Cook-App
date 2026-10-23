import 'package:anyone_can_cook/features/cooking/engine/plan_validator.dart';
import 'package:anyone_can_cook/models/cooking_plan.dart';
import 'package:anyone_can_cook/models/provenance.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sample.dart';

void main() {
  final bundle = loadSampleBundle();
  final plan = bundle.plan;

  CookingPlan withStep(int index, PlanStep Function(PlanStep) change) => plan
      .copyWith(steps: [for (var i = 0; i < plan.steps.length; i++) i == index ? change(plan.steps[i]) : plan.steps[i]]);

  test('the sample plan is valid', () {
    expect(validatePlan(plan, recipe: bundle.recipe), isEmpty);
  });

  test('detects dependency cycles and unknown dependencies', () {
    final cyclic = withStep(0, (s) => s.copyWith(dependsOn: ['s5']));
    expect(validatePlan(cyclic), contains('dependency cycle'));
    final unknown = withStep(0, (s) => s.copyWith(dependsOn: ['nope']));
    expect(validatePlan(unknown), contains('s1: unknown dependency nope'));
  });

  test('requires exactly one completing action, placed last', () {
    final none = withStep(1, (s) => s.copyWith(
          actions: [s.actions.single.copyWith(completesStep: false)],
        ));
    expect(validatePlan(none), contains('s2: needs exactly one completing action'));

    final notLast = withStep(0, (s) => s.copyWith(actions: s.actions.reversed.toList()));
    expect(validatePlan(notLast), contains('s1: completing action must be last'));
  });

  test('timer references must exist and be unique', () {
    final badRef = withStep(2, (s) => s.copyWith(
          actions: [s.actions[0].copyWith(startsTimer: 'missing'), s.actions[1]],
        ));
    expect(validatePlan(badRef), contains('s3.a1: starts unknown timer missing'));

    final duplicate = withStep(4, (s) => s.copyWith(timers: [
          s.timers.single.copyWith(id: 't1'),
        ], actions: [
          s.actions[0].copyWith(startsTimer: 't1'),
          s.actions[1],
        ]));
    expect(validatePlan(duplicate), contains('duplicate timer id t1'));
  });

  test('ingredient and equipment references are checked against the recipe', () {
    final bad = withStep(0, (s) => s.copyWith(ingredientIds: ['i99']));
    expect(
      validatePlan(bad, recipe: bundle.recipe),
      contains('s1: unknown ingredient i99'),
    );
  });

  test('prep tasks must reference existing steps', () {
    final bad = plan.copyWith(prepTasks: [
      const PrepTask(
        id: 'p9',
        kind: PrepKind.other,
        textHe: 'x',
        neededByStep: 'nope',
        timer: PlanTimer(id: 'tx', labelHe: 'x', seconds: 60, provenance: Provenance.inferred),
      ),
    ]);
    expect(validatePlan(bad), contains('p9: unknown needed_by_step nope'));
  });
}
