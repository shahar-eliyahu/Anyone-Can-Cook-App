import 'package:freezed_annotation/freezed_annotation.dart';

import 'provenance.dart';

part 'cooking_plan.freezed.dart';
part 'cooking_plan.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum ActionType { start, done, inOven, outOfOven, custom }

@JsonEnum(fieldRename: FieldRename.snake)
enum ConfirmPolicy { autoOk, alwaysAsk }

@JsonEnum(fieldRename: FieldRename.snake)
enum StepKind { active, passive }

@JsonEnum(fieldRename: FieldRename.snake)
enum PrepKind { preheatOven, boilWater, miseEnPlace, thaw, other }

enum TemperatureUnit {
  @JsonValue('C')
  celsius,
  @JsonValue('F')
  fahrenheit,
}

@freezed
abstract class PlanTimer with _$PlanTimer {
  const factory PlanTimer({
    required String id,
    required String labelHe,
    required int seconds,
    required Provenance provenance,
    String? noteHe,
  }) = _PlanTimer;

  factory PlanTimer.fromJson(Map<String, dynamic> json) =>
      _$PlanTimerFromJson(json);
}

@freezed
abstract class StepAction with _$StepAction {
  const factory StepAction({
    required String id,
    required ActionType type,
    required String labelHe,
    String? startsTimer,
    @Default(false) bool completesStep,
    @Default(ConfirmPolicy.autoOk) ConfirmPolicy confirmPolicy,
  }) = _StepAction;

  factory StepAction.fromJson(Map<String, dynamic> json) =>
      _$StepActionFromJson(json);
}

@freezed
abstract class Temperature with _$Temperature {
  const factory Temperature({
    required int value,
    @Default(TemperatureUnit.celsius) TemperatureUnit unit,
    required Provenance provenance,
  }) = _Temperature;

  factory Temperature.fromJson(Map<String, dynamic> json) =>
      _$TemperatureFromJson(json);
}

@freezed
abstract class Minutes with _$Minutes {
  const factory Minutes({
    required int value,
    required Provenance provenance,
    String? noteHe,
  }) = _Minutes;

  factory Minutes.fromJson(Map<String, dynamic> json) =>
      _$MinutesFromJson(json);
}

@freezed
abstract class PlanStep with _$PlanStep {
  const PlanStep._();

  const factory PlanStep({
    required String id,
    required String title,
    required String instructionHe,
    @Default([]) List<String> sourceRefs,
    @Default([]) List<String> ingredientIds,
    @Default([]) List<String> equipmentIds,
    @Default([]) List<String> dependsOn,
    @Default(StepKind.active) StepKind kind,
    @Default(false) bool parallelOk,
    required List<StepAction> actions,
    @Default([]) List<PlanTimer> timers,
    Temperature? temperature,
    String? donenessCueHe,
    @Default([]) List<String> warningsHe,
  }) = _PlanStep;

  factory PlanStep.fromJson(Map<String, dynamic> json) =>
      _$PlanStepFromJson(json);

  StepAction? actionById(String actionId) {
    for (final a in actions) {
      if (a.id == actionId) return a;
    }
    return null;
  }
}

@freezed
abstract class PrepSurface with _$PrepSurface {
  const factory PrepSurface({String? withStep, @Default(false) bool atStart}) =
      _PrepSurface;

  factory PrepSurface.fromJson(Map<String, dynamic> json) =>
      _$PrepSurfaceFromJson(json);
}

@freezed
abstract class PrepTask with _$PrepTask {
  const factory PrepTask({
    required String id,
    required PrepKind kind,
    required String textHe,
    String? neededByStep,
    Minutes? leadMinutes,
    @Default(PrepSurface(atStart: true)) PrepSurface surface,
    PlanTimer? timer,
    @Default(ConfirmPolicy.autoOk) ConfirmPolicy confirmPolicy,
  }) = _PrepTask;

  factory PrepTask.fromJson(Map<String, dynamic> json) =>
      _$PrepTaskFromJson(json);
}

@freezed
abstract class CookingPlan with _$CookingPlan {
  const CookingPlan._();

  const factory CookingPlan({
    @Default(1) int schemaVersion,
    required List<PlanStep> steps,
    @Default([]) List<PrepTask> prepTasks,
  }) = _CookingPlan;

  factory CookingPlan.fromJson(Map<String, dynamic> json) =>
      _$CookingPlanFromJson(json);

  PlanStep? stepById(String id) {
    for (final s in steps) {
      if (s.id == id) return s;
    }
    return null;
  }

  PrepTask? prepTaskById(String id) {
    for (final p in prepTasks) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Every timer in the plan (step timers and prep-task timers), by id.
  Map<String, PlanTimer> get timersById => {
        for (final s in steps)
          for (final t in s.timers) t.id: t,
        for (final p in prepTasks)
          if (p.timer != null) p.timer!.id: p.timer!,
      };
}
