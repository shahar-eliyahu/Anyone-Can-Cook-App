import 'package:go_router/go_router.dart';

import '../features/catalog/catalog_screen.dart';
import '../features/cooking/cooking_screen.dart';
import '../features/cooking/finish_screen.dart';
import '../features/create/create_hub_screen.dart';
import '../features/create/recipe_preview_screen.dart';
import '../features/create/remy_create_screen.dart';
import '../features/history/history_detail_screen.dart';
import '../features/history/history_screen.dart';
import '../features/import/clarify_screen.dart';
import '../features/import/import_screen.dart';
import '../features/import/review_screen.dart';
import '../features/kitchen/kitchen_screen.dart';
import '../features/recipes/plan_review_screen.dart';
import '../features/prepare/recipe_overview_screen.dart';
import '../features/recipes/recipes_screen.dart';
import '../features/settings/settings_screen.dart';

/// Every page is nested under home, so `go()` to any location (a notification, the menu,
/// the end of a flow) still leaves a back stack that ends at home: a back arrow is always
/// there and Android back never closes the app from inside a flow (docs/DESIGN.md §3.1).
GoRouter createRouter({String initialLocation = '/'}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const KitchenScreen(),
          routes: [
            GoRoute(
              path: 'recipes',
              builder: (context, state) =>
                  RecipesScreen(favoritesOnly: state.uri.queryParameters['favorites'] == '1'),
            ),
            GoRoute(
              path: 'recipes/:id',
              builder: (context, state) => RecipeOverviewScreen(recipeId: state.pathParameters['id']!),
              routes: [
                GoRoute(
                  path: 'plan',
                  builder: (context, state) => PlanReviewScreen(recipeId: state.pathParameters['id']!),
                ),
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => ReviewScreen(recipeId: state.pathParameters['id']!, editing: true),
                ),
              ],
            ),
            GoRoute(path: 'new', builder: (context, state) => const CreateHubScreen()),
            GoRoute(path: 'catalog', builder: (context, state) => const CatalogScreen()),
            GoRoute(
              path: 'create',
              builder: (context, state) => RemyCreateScreen(conversationId: state.uri.queryParameters['id']),
            ),
            GoRoute(path: 'import', builder: (context, state) => const ImportScreen()),
            GoRoute(
              path: 'drafts/:id/preview',
              builder: (context, state) => RecipePreviewScreen(
                draftId: state.pathParameters['id']!,
                fromChat: state.uri.queryParameters['from'] == 'chat',
              ),
            ),
            GoRoute(
              path: 'drafts/:id/clarify',
              builder: (context, state) => ClarifyScreen(draftId: state.pathParameters['id']!, planError: state.extra),
            ),
            GoRoute(
              path: 'drafts/:id/review',
              builder: (context, state) => ReviewScreen(recipeId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: 'cook/:id',
              builder: (context, state) => CookingScreen(sessionId: state.pathParameters['id']!),
            ),
            // A sibling of the cooking page: back from "finished" goes home, not into a done session.
            GoRoute(
              path: 'cook/:id/finish',
              builder: (context, state) => FinishScreen(sessionId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: 'history',
              builder: (context, state) => const HistoryScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => HistoryDetailScreen(sessionId: state.pathParameters['id']!),
                ),
              ],
            ),
            GoRoute(path: 'settings', builder: (context, state) => const SettingsScreen()),
          ],
        ),
      ],
    );
