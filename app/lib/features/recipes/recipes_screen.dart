import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/widgets/app_scaffold.dart';
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.searchRecipes,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(l10n.allRecipes),
                  selected: !_favoritesOnly,
                  onSelected: (_) => setState(() => _favoritesOnly = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('⭐ ${l10n.favorites}'),
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
                  return Center(
                    child: Text(_favoritesOnly ? l10n.noFavorites : l10n.noRecipes),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final r in rows)
                      Card(
                        child: ListTile(
                          title: Text(r.displayTitle),
                          subtitle: r.sourceType == 'sample' ? Text(l10n.sampleRecipeLabel) : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (r.isFavorite) const Icon(Icons.star, color: Colors.amber),
                              const Icon(Icons.chevron_left),
                            ],
                          ),
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
