// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlanTimer _$PlanTimerFromJson(Map<String, dynamic> json) => _PlanTimer(
  id: json['id'] as String,
  labelHe: json['label_he'] as String,
  seconds: (json['seconds'] as num).toInt(),
  provenance: $enumDecode(_$ProvenanceEnumMap, json['provenance']),
  noteHe: json['note_he'] as String?,
);

Map<String, dynamic> _$PlanTimerToJson(_PlanTimer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label_he': instance.labelHe,
      'seconds': instance.seconds,
      'provenance': _$ProvenanceEnumMap[instance.provenance]!,
      'note_he': instance.noteHe,
    };

const _$ProvenanceEnumMap = {
  Provenance.original: 'original',
  Provenance.inferred: 'inferred',
  Provenance.answered: 'answered',
  Provenance.user: 'user',
};

_StepAction _$StepActionFromJson(Map<String, dynamic> json) => _StepAction(
  id: json['id'] as String,
  type: $enumDecode(_$ActionTypeEnumMap, json['type']),
  labelHe: json['label_he'] as String,
  startsTimer: json['starts_timer'] as String?,
  completesStep: json['completes_step'] as bool? ?? false,
  confirmPolicy:
      $enumDecodeNullable(_$ConfirmPolicyEnumMap, json['confirm_policy']) ??
      ConfirmPolicy.autoOk,
);

Map<String, dynamic> _$StepActionToJson(_StepAction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ActionTypeEnumMap[instance.type]!,
      'label_he': instance.labelHe,
      'starts_timer': instance.startsTimer,
      'completes_step': instance.completesStep,
      'confirm_policy': _$ConfirmPolicyEnumMap[instance.confirmPolicy]!,
    };

const _$ActionTypeEnumMap = {
  ActionType.start: 'start',
  ActionType.done: 'done',
  ActionType.inOven: 'in_oven',
  ActionType.outOfOven: 'out_of_oven',
  ActionType.custom: 'custom',
};

const _$ConfirmPolicyEnumMap = {
  ConfirmPolicy.autoOk: 'auto_ok',
  ConfirmPolicy.alwaysAsk: 'always_ask',
};

_Temperature _$TemperatureFromJson(Map<String, dynamic> json) => _Temperature(
  value: (json['value'] as num).toInt(),
  unit:
      $enumDecodeNullable(_$TemperatureUnitEnumMap, json['unit']) ??
      TemperatureUnit.celsius,
  provenance: $enumDecode(_$ProvenanceEnumMap, json['provenance']),
);

Map<String, dynamic> _$TemperatureToJson(_Temperature instance) =>
    <String, dynamic>{
      'value': instance.value,
      'unit': _$TemperatureUnitEnumMap[instance.unit]!,
      'provenance': _$ProvenanceEnumMap[instance.provenance]!,
    };

const _$TemperatureUnitEnumMap = {
  TemperatureUnit.celsius: 'C',
  TemperatureUnit.fahrenheit: 'F',
};

_Minutes _$MinutesFromJson(Map<String, dynamic> json) => _Minutes(
  value: (json['value'] as num).toInt(),
  provenance: $enumDecode(_$ProvenanceEnumMap, json['provenance']),
  noteHe: json['note_he'] as String?,
);

Map<String, dynamic> _$MinutesToJson(_Minutes instance) => <String, dynamic>{
  'value': instance.value,
  'provenance': _$ProvenanceEnumMap[instance.provenance]!,
  'note_he': instance.noteHe,
};

_PlanStep _$PlanStepFromJson(Map<String, dynamic> json) => _PlanStep(
  id: json['id'] as String,
  title: json['title'] as String,
  instructionHe: json['instruction_he'] as String,
  sourceRefs:
      (json['source_refs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  ingredientIds:
      (json['ingredient_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  equipmentIds:
      (json['equipment_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  dependsOn:
      (json['depends_on'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  kind: $enumDecodeNullable(_$StepKindEnumMap, json['kind']) ?? StepKind.active,
  parallelOk: json['parallel_ok'] as bool? ?? false,
  actions: (json['actions'] as List<dynamic>)
      .map((e) => StepAction.fromJson(e as Map<String, dynamic>))
      .toList(),
  timers:
      (json['timers'] as List<dynamic>?)
          ?.map((e) => PlanTimer.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  temperature: json['temperature'] == null
      ? null
      : Temperature.fromJson(json['temperature'] as Map<String, dynamic>),
  donenessCueHe: json['doneness_cue_he'] as String?,
  warningsHe:
      (json['warnings_he'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$PlanStepToJson(_PlanStep instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'instruction_he': instance.instructionHe,
  'source_refs': instance.sourceRefs,
  'ingredient_ids': instance.ingredientIds,
  'equipment_ids': instance.equipmentIds,
  'depends_on': instance.dependsOn,
  'kind': _$StepKindEnumMap[instance.kind]!,
  'parallel_ok': instance.parallelOk,
  'actions': instance.actions.map((e) => e.toJson()).toList(),
  'timers': instance.timers.map((e) => e.toJson()).toList(),
  'temperature': instance.temperature?.toJson(),
  'doneness_cue_he': instance.donenessCueHe,
  'warnings_he': instance.warningsHe,
};

const _$StepKindEnumMap = {
  StepKind.active: 'active',
  StepKind.passive: 'passive',
};

_PrepSurface _$PrepSurfaceFromJson(Map<String, dynamic> json) => _PrepSurface(
  withStep: json['with_step'] as String?,
  atStart: json['at_start'] as bool? ?? false,
);

Map<String, dynamic> _$PrepSurfaceToJson(_PrepSurface instance) =>
    <String, dynamic>{
      'with_step': instance.withStep,
      'at_start': instance.atStart,
    };

_PrepTask _$PrepTaskFromJson(Map<String, dynamic> json) => _PrepTask(
  id: json['id'] as String,
  kind: $enumDecode(_$PrepKindEnumMap, json['kind']),
  textHe: json['text_he'] as String,
  neededByStep: json['needed_by_step'] as String?,
  leadMinutes: json['lead_minutes'] == null
      ? null
      : Minutes.fromJson(json['lead_minutes'] as Map<String, dynamic>),
  surface: json['surface'] == null
      ? const PrepSurface(atStart: true)
      : PrepSurface.fromJson(json['surface'] as Map<String, dynamic>),
  timer: json['timer'] == null
      ? null
      : PlanTimer.fromJson(json['timer'] as Map<String, dynamic>),
  confirmPolicy:
      $enumDecodeNullable(_$ConfirmPolicyEnumMap, json['confirm_policy']) ??
      ConfirmPolicy.autoOk,
);

Map<String, dynamic> _$PrepTaskToJson(_PrepTask instance) => <String, dynamic>{
  'id': instance.id,
  'kind': _$PrepKindEnumMap[instance.kind]!,
  'text_he': instance.textHe,
  'needed_by_step': instance.neededByStep,
  'lead_minutes': instance.leadMinutes?.toJson(),
  'surface': instance.surface.toJson(),
  'timer': instance.timer?.toJson(),
  'confirm_policy': _$ConfirmPolicyEnumMap[instance.confirmPolicy]!,
};

const _$PrepKindEnumMap = {
  PrepKind.preheatOven: 'preheat_oven',
  PrepKind.boilWater: 'boil_water',
  PrepKind.miseEnPlace: 'mise_en_place',
  PrepKind.thaw: 'thaw',
  PrepKind.other: 'other',
};

_CookingPlan _$CookingPlanFromJson(Map<String, dynamic> json) => _CookingPlan(
  schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
  steps: (json['steps'] as List<dynamic>)
      .map((e) => PlanStep.fromJson(e as Map<String, dynamic>))
      .toList(),
  prepTasks:
      (json['prep_tasks'] as List<dynamic>?)
          ?.map((e) => PrepTask.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$CookingPlanToJson(_CookingPlan instance) =>
    <String, dynamic>{
      'schema_version': instance.schemaVersion,
      'steps': instance.steps.map((e) => e.toJson()).toList(),
      'prep_tasks': instance.prepTasks.map((e) => e.toJson()).toList(),
    };
