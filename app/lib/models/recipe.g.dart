// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Quantity _$QuantityFromJson(Map<String, dynamic> json) => _Quantity(
  amount: (json['amount'] as num?)?.toDouble(),
  amountMax: (json['amount_max'] as num?)?.toDouble(),
  unit: json['unit'] as String?,
  display: json['display'] as String,
  provenance: $enumDecode(_$ProvenanceEnumMap, json['provenance']),
);

Map<String, dynamic> _$QuantityToJson(_Quantity instance) => <String, dynamic>{
  'amount': instance.amount,
  'amount_max': instance.amountMax,
  'unit': instance.unit,
  'display': instance.display,
  'provenance': _$ProvenanceEnumMap[instance.provenance]!,
};

const _$ProvenanceEnumMap = {
  Provenance.original: 'original',
  Provenance.inferred: 'inferred',
  Provenance.answered: 'answered',
  Provenance.user: 'user',
};

_Ingredient _$IngredientFromJson(Map<String, dynamic> json) => _Ingredient(
  id: json['id'] as String,
  name: json['name'] as String,
  quantity: json['quantity'] == null
      ? null
      : Quantity.fromJson(json['quantity'] as Map<String, dynamic>),
  preparation: json['preparation'] as String?,
  group: json['group'] as String?,
  optional: json['optional'] as bool? ?? false,
);

Map<String, dynamic> _$IngredientToJson(_Ingredient instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'quantity': instance.quantity?.toJson(),
      'preparation': instance.preparation,
      'group': instance.group,
      'optional': instance.optional,
    };

_Equipment _$EquipmentFromJson(Map<String, dynamic> json) => _Equipment(
  id: json['id'] as String,
  name: json['name'] as String,
  provenance:
      $enumDecodeNullable(_$ProvenanceEnumMap, json['provenance']) ??
      Provenance.original,
);

Map<String, dynamic> _$EquipmentToJson(_Equipment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'provenance': _$ProvenanceEnumMap[instance.provenance]!,
    };

_SourceStep _$SourceStepFromJson(Map<String, dynamic> json) =>
    _SourceStep(id: json['id'] as String, text: json['text'] as String);

Map<String, dynamic> _$SourceStepToJson(_SourceStep instance) =>
    <String, dynamic>{'id': instance.id, 'text': instance.text};

_Servings _$ServingsFromJson(Map<String, dynamic> json) => _Servings(
  amount: (json['amount'] as num).toDouble(),
  unit: json['unit'] as String,
  provenance: $enumDecode(_$ProvenanceEnumMap, json['provenance']),
);

Map<String, dynamic> _$ServingsToJson(_Servings instance) => <String, dynamic>{
  'amount': instance.amount,
  'unit': instance.unit,
  'provenance': _$ProvenanceEnumMap[instance.provenance]!,
};

_Recipe _$RecipeFromJson(Map<String, dynamic> json) => _Recipe(
  schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
  title: json['title'] as String,
  description: json['description'] as String?,
  servings: json['servings'] == null
      ? null
      : Servings.fromJson(json['servings'] as Map<String, dynamic>),
  ingredients: (json['ingredients'] as List<dynamic>)
      .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
      .toList(),
  equipment:
      (json['equipment'] as List<dynamic>?)
          ?.map((e) => Equipment.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  sourceSteps:
      (json['source_steps'] as List<dynamic>?)
          ?.map((e) => SourceStep.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$RecipeToJson(_Recipe instance) => <String, dynamic>{
  'schema_version': instance.schemaVersion,
  'title': instance.title,
  'description': instance.description,
  'servings': instance.servings?.toJson(),
  'ingredients': instance.ingredients.map((e) => e.toJson()).toList(),
  'equipment': instance.equipment.map((e) => e.toJson()).toList(),
  'source_steps': instance.sourceSteps.map((e) => e.toJson()).toList(),
};
