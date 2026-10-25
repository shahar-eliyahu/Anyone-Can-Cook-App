import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'builtin_catalog.dart';

/// The built-in recipes (docs/DECISIONS.md #84): search by title or ingredient and one
/// category at a time. Opening one shows the usual recipe overview, ready to prepare and cook.
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  String _query = '';
  CatalogCategory? _category;
  bool _opening = false;

  Future<void> _open(CatalogEntry entry) async {
    if (_opening) return;
    _opening = true;
    final router = GoRouter.of(context);
    try {
      final id = await ref.read(builtinRecipesProvider).open(entry);
      router.push('/recipes/$id');
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(builtinCatalogProvider).value;
    final shown = catalog?.search(query: _query, category: _category);
    final labels = {
      CatalogCategory.quick: l10n.catQuick,
      CatalogCategory.chicken: l10n.catChicken,
      CatalogCategory.pasta: l10n.catPasta,
      CatalogCategory.baking: l10n.catBaking,
      CatalogCategory.breakfast: l10n.catBreakfast,
      CatalogCategory.vegetarian: l10n.catVegetarian,
      CatalogCategory.desserts: l10n.catDesserts,
    };

    return AppScaffold(
      title: l10n.catalogTitle,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.s),
            child: TextField(
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: l10n.catalogSearch),
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: Row(
              spacing: Space.s,
              children: [
                ChoiceChip(label: Text(l10n.allRecipes), selected: _category == null, onSelected: (_) => setState(() => _category = null)),
                for (final c in CatalogCategory.values)
                  ChoiceChip(label: Text(labels[c]!), selected: _category == c, onSelected: (_) => setState(() => _category = c)),
              ],
            ),
          ),
          Expanded(
            child: shown == null
                ? const Center(child: CircularProgressIndicator())
                : shown.isEmpty
                    ? EmptyState(icon: Icons.search_off_rounded, title: l10n.catalogEmpty)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.xxl),
                        children: [
                          for (final (i, e) in shown.indexed)
                            Appear(
                              index: i,
                              child: RecipeTile(
                                title: e.recipe.title,
                                subtitle: [
                                  formatApproxDuration(e.estimate.totalMinutes, l10n),
                                  if (e.recipe.servings case final s?) '${_number(s.amount)} ${s.unit}',
                                  for (final c in CatalogCategory.values)
                                    if (e.categories.contains(c)) labels[c]!,
                                ].join(', '),
                                leadingIcon: _icon(e),
                                onTap: () => _open(e),
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  static IconData _icon(CatalogEntry e) => switch (e.categories) {
        final c when c.contains(CatalogCategory.desserts) => Icons.cake_outlined,
        final c when c.contains(CatalogCategory.baking) => Icons.bakery_dining_outlined,
        final c when c.contains(CatalogCategory.breakfast) => Icons.egg_alt_outlined,
        final c when c.contains(CatalogCategory.pasta) => Icons.ramen_dining_outlined,
        final c when c.contains(CatalogCategory.chicken) => Icons.set_meal_outlined,
        _ => Icons.restaurant_menu_rounded,
      };
}

String _number(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
