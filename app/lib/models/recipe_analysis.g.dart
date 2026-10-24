// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_analysis.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecipeSourceInfo _$RecipeSourceInfoFromJson(Map<String, dynamic> json) =>
    _RecipeSourceInfo(
      type: $enumDecode(_$SourceTypeEnumMap, json['type']),
      url: json['url'] as String?,
      siteName: json['site_name'] as String?,
      title: json['title'] as String?,
      retrievedAt: json['retrieved_at'] as String?,
    );

Map<String, dynamic> _$RecipeSourceInfoToJson(_RecipeSourceInfo instance) =>
    <String, dynamic>{
      'type': _$SourceTypeEnumMap[instance.type]!,
      'url': instance.url,
      'site_name': instance.siteName,
      'title': instance.title,
      'retrieved_at': instance.retrievedAt,
    };

const _$SourceTypeEnumMap = {
  SourceType.text: 'text',
  SourceType.image: 'image',
  SourceType.url: 'url',
  SourceType.sample: 'sample',
};

_ReferenceSource _$ReferenceSourceFromJson(Map<String, dynamic> json) =>
    _ReferenceSource(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String?,
      kind: $enumDecode(_$ReferenceKindEnumMap, json['kind']),
    );

Map<String, dynamic> _$ReferenceSourceToJson(_ReferenceSource instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'url': instance.url,
      'kind': _$ReferenceKindEnumMap[instance.kind]!,
    };

const _$ReferenceKindEnumMap = {
  ReferenceKind.foodSafetyReference: 'food_safety_reference',
  ReferenceKind.recipeSource: 'recipe_source',
};

_Question _$QuestionFromJson(Map<String, dynamic> json) => _Question(
  id: json['id'] as String,
  textHe: json['text_he'] as String,
  whyHe: json['why_he'] as String,
  kind: $enumDecode(_$QuestionKindEnumMap, json['kind']),
  options:
      (json['options'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  unitHe: json['unit_he'] as String?,
  category: $enumDecode(_$GapCategoryEnumMap, json['category']),
  required: json['required'] as bool? ?? false,
  affects:
      (json['affects'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$QuestionToJson(_Question instance) => <String, dynamic>{
  'id': instance.id,
  'text_he': instance.textHe,
  'why_he': instance.whyHe,
  'kind': _$QuestionKindEnumMap[instance.kind]!,
  'options': instance.options,
  'unit_he': instance.unitHe,
  'category': _$GapCategoryEnumMap[instance.category]!,
  'required': instance.required,
  'affects': instance.affects,
};

const _$QuestionKindEnumMap = {
  QuestionKind.choice: 'choice',
  QuestionKind.number: 'number',
  QuestionKind.text: 'text',
};

const _$GapCategoryEnumMap = {
  GapCategory.safety: 'safety',
  GapCategory.outcome: 'outcome',
  GapCategory.equipment: 'equipment',
  GapCategory.preference: 'preference',
  GapCategory.minor: 'minor',
};

_Answer _$AnswerFromJson(Map<String, dynamic> json) => _Answer(
  questionId: json['question_id'] as String,
  value: json['value'] as String?,
  unknown: json['unknown'] as bool? ?? false,
);

Map<String, dynamic> _$AnswerToJson(_Answer instance) => <String, dynamic>{
  'question_id': instance.questionId,
  'value': instance.value,
  'unknown': instance.unknown,
};

_Gap _$GapFromJson(Map<String, dynamic> json) => _Gap(
  id: json['id'] as String,
  field: json['field'] as String,
  category: $enumDecode(_$GapCategoryEnumMap, json['category']),
  resolution: $enumDecode(_$GapResolutionEnumMap, json['resolution']),
  questionId: json['question_id'] as String?,
  noteHe: json['note_he'] as String?,
);

Map<String, dynamic> _$GapToJson(_Gap instance) => <String, dynamic>{
  'id': instance.id,
  'field': instance.field,
  'category': _$GapCategoryEnumMap[instance.category]!,
  'resolution': _$GapResolutionEnumMap[instance.resolution]!,
  'question_id': instance.questionId,
  'note_he': instance.noteHe,
};

const _$GapResolutionEnumMap = {
  GapResolution.context: 'context',
  GapResolution.reference: 'reference',
  GapResolution.estimate: 'estimate',
  GapResolution.question: 'question',
  GapResolution.unresolved: 'unresolved',
};

_RecipeAnalysis _$RecipeAnalysisFromJson(Map<String, dynamic> json) =>
    _RecipeAnalysis(
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
      isRecipe: json['is_recipe'] as bool,
      notRecipeReasonHe: json['not_recipe_reason_he'] as String?,
      source: RecipeSourceInfo.fromJson(json['source'] as Map<String, dynamic>),
      sourceText: json['source_text'] as String? ?? '',
      recipe: json['recipe'] == null
          ? null
          : Recipe.fromJson(json['recipe'] as Map<String, dynamic>),
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map((e) => Question.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      answers:
          (json['answers'] as List<dynamic>?)
              ?.map((e) => Answer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      gaps:
          (json['gaps'] as List<dynamic>?)
              ?.map((e) => Gap.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sources:
          (json['sources'] as List<dynamic>?)
              ?.map((e) => ReferenceSource.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      assumptionsHe:
          (json['assumptions_he'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$RecipeAnalysisToJson(_RecipeAnalysis instance) =>
    <String, dynamic>{
      'schema_version': instance.schemaVersion,
      'is_recipe': instance.isRecipe,
      'not_recipe_reason_he': instance.notRecipeReasonHe,
      'source': instance.source.toJson(),
      'source_text': instance.sourceText,
      'recipe': instance.recipe?.toJson(),
      'questions': instance.questions.map((e) => e.toJson()).toList(),
      'answers': instance.answers.map((e) => e.toJson()).toList(),
      'gaps': instance.gaps.map((e) => e.toJson()).toList(),
      'sources': instance.sources.map((e) => e.toJson()).toList(),
      'assumptions_he': instance.assumptionsHe,
    };
