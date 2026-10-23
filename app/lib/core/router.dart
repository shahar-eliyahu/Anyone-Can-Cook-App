import 'package:go_router/go_router.dart';

import '../features/cooking/cooking_screen.dart';
import '../features/cooking/finish_screen.dart';
import '../features/history/history_detail_screen.dart';
import '../features/history/history_screen.dart';
import '../features/kitchen/kitchen_screen.dart';
import '../features/recipes/plan_review_screen.dart';
import '../features/recipes/recipe_detail_screen.dart';
import '../features/recipes/recipes_screen.dart';
import '../features/settings/settings_screen.dart';

GoRouter createRouter({String initialLocation = '/'}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', builder: (context, state) => const KitchenScreen()),
        GoRoute(
          path: '/recipes',
          builder: (context, state) =>
              RecipesScreen(favoritesOnly: state.uri.queryParameters['favorites'] == '1'),
        ),
        GoRoute(
          path: '/recipes/:id',
          builder: (context, state) => RecipeDetailScreen(recipeId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/recipes/:id/plan',
          builder: (context, state) => PlanReviewScreen(recipeId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/cook/:id',
          builder: (context, state) => CookingScreen(sessionId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/cook/:id/finish',
          builder: (context, state) => FinishScreen(sessionId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
        GoRoute(
          path: '/history/:id',
          builder: (context, state) => HistoryDetailScreen(sessionId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      ],
    );
