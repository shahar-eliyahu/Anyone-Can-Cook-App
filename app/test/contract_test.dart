import 'dart:convert';
import 'dart:io';

import 'package:anyone_can_cook/features/cooking/engine/plan_validator.dart';
import 'package:anyone_can_cook/models/cooking_plan.dart';
import 'package:anyone_can_cook/models/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sample.dart';

Set<String> _keys(Object? json) => switch (json) {
      Map() => {
          for (final e in json.entries) ...{e.key as String, ..._keys(e.value)},
        },
      List() => {for (final v in json) ..._keys(v)},
      _ => {},
    };

Set<String> _schemaProperties(String path) {
  final schema = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final names = <String>{};
  void walk(Object? node) {
    if (node is Map) {
      final props = node['properties'];
      if (props is Map) names.addAll(props.keys.cast<String>());
      node.values.forEach(walk);
    } else if (node is List) {
      node.forEach(walk);
    }
  }

  walk(schema);
  return names;
}

void main() {
  test('bundled asset is identical to the shared fixture', () {
    expect(
      File(assetFixturePath).readAsStringSync(),
      File(sharedFixturePath).readAsStringSync(),
    );
  });

  test('shared fixture parses into the Dart models and passes validation', () {
    final bundle = loadSampleBundle();
    expect(bundle.recipe.title, isNotEmpty);
    expect(bundle.plan.steps, hasLength(5));
    expect(validatePlan(bundle.plan, recipe: bundle.recipe), isEmpty);
  });

  test('models survive a JSON round trip', () {
    final bundle = loadSampleBundle();
    final plan = CookingPlan.fromJson(
      jsonDecode(jsonEncode(bundle.plan.toJson())) as Map<String, dynamic>,
    );
    final recipe = Recipe.fromJson(
      jsonDecode(jsonEncode(bundle.recipe.toJson())) as Map<String, dynamic>,
    );
    expect(plan, bundle.plan);
    expect(recipe, bundle.recipe);
  });

  test('every key the Dart models emit exists in the backend JSON Schema', () {
    final bundle = loadSampleBundle();
    final planKeys = _keys(jsonDecode(jsonEncode(bundle.plan.toJson())));
    final recipeKeys = _keys(jsonDecode(jsonEncode(bundle.recipe.toJson())));
    expect(
      planKeys.difference(_schemaProperties('../shared/schema/cooking_plan.schema.json')),
      isEmpty,
    );
    expect(
      recipeKeys.difference(_schemaProperties('../shared/schema/recipe.schema.json')),
      isEmpty,
    );
  });
}
