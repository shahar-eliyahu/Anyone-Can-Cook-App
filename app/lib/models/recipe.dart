import 'package:freezed_annotation/freezed_annotation.dart';

import 'provenance.dart';

part 'recipe.freezed.dart';
part 'recipe.g.dart';

@freezed
abstract class Quantity with _$Quantity {
  const factory Quantity({
    double? amount,
    double? amountMax,
    String? unit,
    required String display,
    required Provenance provenance,
    Confidence? confidence,
    @Default([]) List<String> sourceIds,
    String? noteHe,
  }) = _Quantity;

  factory Quantity.fromJson(Map<String, dynamic> json) =>
      _$QuantityFromJson(json);
}

@freezed
abstract class Ingredient with _$Ingredient {
  const factory Ingredient({
    required String id,
    required String name,
    Quantity? quantity,
    String? preparation,
    String? group,
    @Default(false) bool optional,
  }) = _Ingredient;

  factory Ingredient.fromJson(Map<String, dynamic> json) =>
      _$IngredientFromJson(json);
}

@freezed
abstract class Equipment with _$Equipment {
  const factory Equipment({
    required String id,
    required String name,
    @Default(Provenance.original) Provenance provenance,
  }) = _Equipment;

  factory Equipment.fromJson(Map<String, dynamic> json) =>
      _$EquipmentFromJson(json);
}

@freezed
abstract class SourceStep with _$SourceStep {
  const factory SourceStep({required String id, required String text}) =
      _SourceStep;

  factory SourceStep.fromJson(Map<String, dynamic> json) =>
      _$SourceStepFromJson(json);
}

@freezed
abstract class Servings with _$Servings {
  const factory Servings({
    required double amount,
    required String unit,
    required Provenance provenance,
  }) = _Servings;

  factory Servings.fromJson(Map<String, dynamic> json) =>
      _$ServingsFromJson(json);
}

@freezed
abstract class Recipe with _$Recipe {
  const factory Recipe({
    @Default(1) int schemaVersion,
    required String title,
    String? description,
    Servings? servings,
    required List<Ingredient> ingredients,
    @Default([]) List<Equipment> equipment,
    @Default([]) List<SourceStep> sourceSteps,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
}
