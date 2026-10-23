import '../models/recipe_bundle.dart';
import 'recipe_repository.dart';
import 'settings_repository.dart';

const sampleRecipeAsset = 'assets/recipes/sample_recipe.json';

/// Saves the bundled sample recipe once, on first run. A deleted sample stays
/// deleted. Returns the new recipe id, or null if it was seeded before.
Future<String?> seedSampleRecipe({
  required RecipeRepository recipes,
  required SettingsRepository settings,
  required Future<String> Function(String asset) loadAsset,
}) async {
  if (await settings.get(SettingKeys.sampleRecipeSeeded) != null) return null;
  final bundle = RecipeBundle.decode(await loadAsset(sampleRecipeAsset));
  final id = await recipes.saveBundle(bundle, sourceType: 'sample');
  await settings.set(SettingKeys.sampleRecipeSeeded, id);
  return id;
}
