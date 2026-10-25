import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_scaffold.dart';
import '../../l10n/app_localizations.dart';
import '../assistant/assistant_controller.dart';
import '../assistant/assistant_models.dart';
import '../assistant/assistant_sheet.dart';
import 'recipe_creation_service.dart';

/// "רמי יציע מתכון" (docs/DESIGN.md §16): the same chat as Remy's sheet, text first, on a screen
/// of its own. [conversationId] continues a given conversation (back from a draft's review);
/// otherwise the last unfinished one, or a new one. When Remy creates a recipe, its review opens.
class RemyCreateScreen extends ConsumerStatefulWidget {
  const RemyCreateScreen({super.key, this.conversationId});

  final String? conversationId;

  @override
  ConsumerState<RemyCreateScreen> createState() => _RemyCreateScreenState();
}

class _RemyCreateScreenState extends ConsumerState<RemyCreateScreen> {
  late String? _id = widget.conversationId;

  RecipeCreationService get _service => ref.read(recipeCreationServiceProvider);

  @override
  void initState() {
    super.initState();
    if (_id == null) {
      _service.currentConversation().then((id) {
        if (mounted) setState(() => _id = id);
      });
    }
  }

  void _openRecipe(String id) => context.push('/drafts/$id/preview?from=chat');

  Future<void> _startOver() async {
    final fresh = await _service.startOver(_id!);
    if (mounted) setState(() => _id = fresh);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = _id;
    if (id != null) {
      // A new recipe from Remy opens its review at once (the chat keeps a link to it).
      ref.listen(assistantControllerProvider(RemyScope.creation(id)), (before, now) {
        final last = now.messages.lastOrNull;
        if (last?.recipeId != null && before?.messages.lastOrNull != last && before?.messages.isNotEmpty == true) {
          _openRecipe(last!.recipeId!);
        }
      });
    }
    return AppScaffold(
      title: l10n.createTitle,
      actions: [
        if (id != null)
          IconButton(tooltip: l10n.createNewChat, onPressed: _startOver, icon: const Icon(Icons.add_comment_outlined)),
      ],
      body: id == null
          ? const Center(child: CircularProgressIndicator())
          : AssistantPanel(key: ValueKey(id), scope: RemyScope.creation(id), embedded: true, onOpenRecipe: _openRecipe),
    );
  }
}
