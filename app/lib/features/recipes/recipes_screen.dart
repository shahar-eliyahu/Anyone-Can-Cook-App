import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../l10n/app_localizations.dart';

/// "המתכונים שלי" with a favorites filter and title search.
class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key, this.favoritesOnly = false});

  final bool favoritesOnly;

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  late bool _favoritesOnly = widget.favoritesOnly;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stream = ref
        .watch(recipeRepositoryProvider)
        .watchRecipes(favoritesOnly: _favoritesOnly, query: _query);

    return AppScaffold(
      title: _favoritesOnly ? l10n.favorites : l10n.myRecipes,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.s),
            child: TextField(
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: l10n.searchRecipes),
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: Wrap(
              spacing: Space.s,
              runSpacing: Space.xs,
              children: [
                ChoiceChip(
                  label: Text(l10n.allRecipes),
                  selected: !_favoritesOnly,
                  onSelected: (_) => setState(() => _favoritesOnly = false),
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.star_rounded, size: 18),
                  label: Text(l10n.favorites),
                  selected: _favoritesOnly,
                  onSelected: (_) => setState(() => _favoritesOnly = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<RecipeRow>>(
              stream: stream,
              builder: (context, snapshot) {
                final rows = snapshot.data;
                if (rows == null) return const Center(child: CircularProgressIndicator());
                if (rows.isEmpty) {
                  return EmptyState(
                    icon: _favoritesOnly ? Icons.star_outline_rounded : Icons.menu_book_outlined,
                    title: _query.trim().isNotEmpty
                        ? l10n.recipesSearchEmpty
                        : _favoritesOnly
                            ? l10n.noFavorites
                            : l10n.noRecipes,
                    action: _favoritesOnly || _query.trim().isNotEmpty
                        ? null
                        : FilledButton.icon(
                            onPressed: () => context.push('/new'),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(l10n.newRecipe),
                          ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.xxl),
                  children: [
                    for (final (i, r) in rows.indexed)
                      Appear(
                        index: i,
                        child: RecipeTile(
                          title: r.displayTitle,
                          subtitle: r.sourceType == 'sample' ? l10n.sampleRecipeLabel : null,
                          favorite: r.isFavorite,
                          onTap: () => context.push('/recipes/${r.id}'),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
