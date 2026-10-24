import 'package:freezed_annotation/freezed_annotation.dart';

import 'provenance.dart';
import 'recipe.dart';

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

@JsonEnum(fieldRename: FieldRename.snake)
enum WaitKind { cook, bake, rest, chill, freeze, proof, soak, marinate, other }

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
    /// When to check (the notification time).
    required int seconds,
    required Provenance provenance,
    String? noteHe,
    Confidence? confidence,
    @Default([]) List<String> sourceIds,
    WaitKind? waitKind,

    /// Optional end of a range ("60–90 minutes").
    int? maxSeconds,
    String? waitInfoHe,
    String? checkCueHe,

    /// Ids of real steps or prep tasks worth doing during this wait.
    @Default([]) List<String> suggestDuring,
    @Default([]) List<String> meanwhileTipsHe,

    /// How long "not ready — check again" waits.
    int? recheckSeconds,
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
    Confidence? confidence,
    @Default([]) List<String> sourceIds,
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
    Confidence? confidence,
  }) = _Minutes;

  factory Minutes.fromJson(Map<String, dynamic> json) =>
      _$MinutesFromJson(json);
}

/// The amount of a recipe ingredient used in one step.
@freezed
abstract class IngredientUse with _$IngredientUse {
  const factory IngredientUse({
    required String ingredientId,
    Quantity? quantity,
    String? noteHe,
  }) = _IngredientUse;

  factory IngredientUse.fromJson(Map<String, dynamic> json) =>
      _$IngredientUseFromJson(json);
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
    @Default([]) List<IngredientUse> ingredientUses,
    @Default([]) List<String> equipmentIds,
    @Default([]) List<String> dependsOn,
    @Default(StepKind.active) StepKind kind,
    @Default(false) bool parallelOk,
    required List<StepAction> actions,
    @Default([]) List<PlanTimer> timers,
    Temperature? temperature,
    String? donenessCueHe,

    /// Short help shown only on request ("עזרה").
    String? helpHe,

    /// Notes added by accepted substitutions ("במקום שמנת: …").
    @Default([]) List<String> notesHe,
    @Default([]) List<String> warningsHe,
    Minutes? estimatedActiveMinutes,
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

    /// One reminder `leadMinutes` before a wait gating [neededByStep] ends.
    @Default(false) bool remindBeforeNeeded,
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
    String? advanceNoticeHe,
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
