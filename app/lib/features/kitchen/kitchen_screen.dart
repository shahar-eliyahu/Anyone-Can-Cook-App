import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/clock.dart';
import '../../core/db/database.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/motion_widgets.dart';
import '../../data/providers.dart';
import '../../data/recipe_repository.dart';
import '../../l10n/app_localizations.dart';
import '../cooking/cooking_controller.dart';
import '../import/drafts_card.dart';
import 'backend_status.dart';

/// A few recipes for home: favourites first, then the most recently changed.
final _recentRecipesProvider = StreamProvider.autoDispose<List<RecipeRow>>(
  (ref) => ref.watch(recipeRepositoryProvider).watchRecipes().map(
        (rows) => ([...rows]..sort((a, b) => (b.isFavorite ? 1 : 0) - (a.isFavorite ? 1 : 0))).take(4).toList(),
      ),
);

/// Home ("המטבח שלי", docs/DESIGN.md §4): the name and a welcome, the one main action,
/// a few saved recipes, and cooking in progress only when there is some. Nothing technical.
class KitchenScreen extends ConsumerWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ref.watch(healthProvider); // wakes the server quietly; nothing is shown
    final session = ref.watch(activeSessionProvider).value;
    final recent = ref.watch(_recentRecipesProvider).value;

    return AppScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xxl),
        children: [
          BrandHeader(greeting: l10n.homeGreeting),
          if (session != null) ...[
            Appear(child: _ActiveSessionCard(sessionId: session.id)),
            const SizedBox(height: Space.m),
          ],
          Appear(
            index: 1,
            child: PrimaryActionCard(
              icon: Icons.add_rounded,
              title: l10n.newRecipe,
              subtitle: l10n.newRecipeSubtitle,
              onTap: () => context.push('/import'),
            ),
          ),
          const Appear(index: 2, child: DraftsCard()),
          SectionTitle(
            l10n.myRecipes,
            trailing: TextButton(onPressed: () => context.push('/recipes'), child: Text(l10n.allRecipesLink)),
          ),
          if (recent != null && recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.s),
              child: Text(l10n.homeEmptyRecipes, style: Theme.of(context).textTheme.bodyMedium),
            ),
          for (final (i, r) in (recent ?? const <RecipeRow>[]).indexed)
            Appear(
              index: 3 + i,
              child: RecipeTile(
                title: r.displayTitle,
                subtitle: r.sourceType == 'sample' ? l10n.sampleRecipeLabel : null,
                favorite: r.isFavorite,
                onTap: () => context.push('/recipes/${r.id}'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Cooking in progress: which recipe, how far, the nearest timer, and one way back in.
class _ActiveSessionCard extends ConsumerWidget {
  const _ActiveSessionCard({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final view = ref.watch(cookingControllerProvider(sessionId)).value;
    final now = (ref.watch(tickerProvider).value ?? ref.read(clockProvider)()).toUtc();
    final state = view?.state;
    final timers = state?.activeTimers(now) ?? const [];
    final nearest = timers.isEmpty ? null : (timers.toList()..sort((a, b) => a.remaining(now).compareTo(b.remaining(now)))).first;
    final done = state?.doneStepCount ?? 0;
    final total = state?.plan.steps.length ?? 0;

    void open() => context.push('/cook/$sessionId');

    return Card(
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card)),
      child: InkWell(
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.all(Space.l + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Space.s,
            children: [
              Row(
                spacing: Space.s,
                children: [
                  Icon(Icons.local_fire_department_rounded, color: context.palette.wood, size: 20),
                  Text(l10n.cookingNowTitle, style: theme.textTheme.labelLarge?.copyWith(color: context.palette.wood)),
                ],
              ),
              Text(
                view?.recipeRow.displayTitle ?? l10n.continueCooking,
                style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer),
              ),
              if (state != null && total > 0) ...[
                Text(
                  state.isComplete ? l10n.allStepsDone : l10n.stepOfTotal(done + 1 > total ? total : done + 1, total),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                ),
                LinearProgressIndicator(value: done / total, semanticsLabel: l10n.progressLabel),
              ],
              if (nearest != null)
                Row(
                  spacing: Space.s,
                  children: [
                    Icon(Icons.timer_outlined, size: 20, color: theme.colorScheme.onPrimaryContainer),
                    Expanded(
                      child: Text(
                        nearest.isFinished(now)
                            ? '${nearest.labelHe}: ${l10n.timerCheckDue}'
                            : '${nearest.labelHe}: ${ltr(formatDuration(nearest.remaining(now)))}',
                        style: theme.textTheme.titleSmall?.copyWith(fontFeatures: tabularFigures),
                      ),
                    ),
                  ],
                ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(onPressed: open, child: Text(l10n.continueCookingCta)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
