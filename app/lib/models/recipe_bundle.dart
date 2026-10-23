import 'dart:convert';

import 'cooking_plan.dart';
import 'recipe.dart';

/// A recipe together with its cooking plan, as in `shared/fixtures/*.json`.
class RecipeBundle {
  const RecipeBundle({required this.recipe, required this.plan});

  factory RecipeBundle.fromJson(Map<String, dynamic> json) => RecipeBundle(
        recipe: Recipe.fromJson(json['recipe'] as Map<String, dynamic>),
        plan: CookingPlan.fromJson(json['plan'] as Map<String, dynamic>),
      );

  factory RecipeBundle.decode(String source) =>
      RecipeBundle.fromJson(jsonDecode(source) as Map<String, dynamic>);

  final Recipe recipe;
  final CookingPlan plan;
}
