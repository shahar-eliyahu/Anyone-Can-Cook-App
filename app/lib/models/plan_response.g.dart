// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlanResponse _$PlanResponseFromJson(Map<String, dynamic> json) =>
    _PlanResponse(
      plan: CookingPlan.fromJson(json['plan'] as Map<String, dynamic>),
      warningsHe:
          (json['warnings_he'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      limitationsHe:
          (json['limitations_he'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      sources:
          (json['sources'] as List<dynamic>?)
              ?.map((e) => ReferenceSource.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PlanResponseToJson(_PlanResponse instance) =>
    <String, dynamic>{
      'plan': instance.plan.toJson(),
      'warnings_he': instance.warningsHe,
      'limitations_he': instance.limitationsHe,
      'sources': instance.sources.map((e) => e.toJson()).toList(),
    };
