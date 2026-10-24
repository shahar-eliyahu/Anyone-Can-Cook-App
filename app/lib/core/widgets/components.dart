import 'package:flutter/material.dart';

import '../motion.dart';
import '../theme.dart';
import 'motion_widgets.dart';

enum NoteKind { info, tip, warning, safety, success }

/// A short message inside a screen: information, a tip (warm beige), a warning, a safety
/// note or a success. Colour plus icon, never colour alone.
class NoteBanner extends StatelessWidget {
  const NoteBanner(this.text, {super.key, this.kind = NoteKind.info, this.title, this.icon, this.child});

  final String text;
  final NoteKind kind;
  final String? title;
  final IconData? icon;

  /// Extra content under the text (a checkbox, a button).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final (Color bg, Color fg, Color accent, IconData defaultIcon) = switch (kind) {
      NoteKind.info => (theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer, p.brandBlue, Icons.info_outline_rounded),
      NoteKind.tip => (p.beige, p.onBeige, p.wood, Icons.lightbulb_outline_rounded),
      NoteKind.warning => (p.timerDoneContainer, p.onTimerDoneContainer, p.timerDone, Icons.error_outline_rounded),
      NoteKind.safety => (theme.colorScheme.errorContainer, theme.colorScheme.onErrorContainer, theme.colorScheme.error, Icons.health_and_safety_outlined),
      NoteKind.success => (p.successContainer, const Color(0xFF1C4A2F), p.success, Icons.check_circle_outline_rounded),
    };
    // A Material surface (not a coloured box) so checkboxes and list tiles inside keep their ink.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs + 2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.input),
        child: Padding(
          padding: const EdgeInsets.all(Space.m + 2),
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Space.m,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon ?? defaultIcon, color: accent, size: 22)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                if (title case final t?) Text(t, style: theme.textTheme.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w700)),
                if (text.isNotEmpty) Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: fg)),
                ?child,
              ],
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}

/// A calm empty state: an icon in a soft circle, one line of title, one of help, one action.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xl),
        child: Appear(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: Space.m,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: AppColors.softBlue, shape: BoxShape.circle),
                child: Icon(icon, size: 34, color: AppColors.primary),
              ),
              Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (message case final m?)
                Text(m, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ?action,
            ],
          ),
        ),
      ),
    );
  }
}

/// The one main action of a screen as a large, friendly card (home's "מתכון חדש").
class PrimaryActionCard extends StatelessWidget {
  const PrimaryActionCard({super.key, required this.icon, required this.title, this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      child: Material(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(Radii.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.l + 2, vertical: Space.l + 2),
            child: Row(
              spacing: Space.l,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), shape: BoxShape.circle),
                  child: Icon(icon, color: theme.colorScheme.onPrimary, size: 28),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimary)),
                      if (subtitle case final s?)
                        Text(s, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary.withValues(alpha: 0.88))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact fact: servings, total time, active time.
class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.s - 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Radii.chip),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: Space.s - 2,
        children: [
          Icon(icon, size: 18, color: AppColors.brandBlue),
          Flexible(child: Text(label, style: theme.textTheme.labelLarge)),
        ],
      ),
    );
  }
}

/// A recipe (or history entry) in a list: title, a quiet second line, a favourite star,
/// and an arrow pointing the way forward (left in Hebrew: `chevron_right` mirrors in RTL).
class RecipeTile extends StatelessWidget {
  const RecipeTile({
    super.key,
    required this.title,
    this.subtitle,
    this.favorite = false,
    this.leadingIcon = Icons.restaurant_menu_rounded,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool favorite;
  final IconData leadingIcon;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(Radii.chip)),
          child: Icon(leadingIcon, color: AppColors.primary),
        ),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (favorite) Icon(Icons.star_rounded, color: context.palette.woodLight, semanticLabel: '★'),
            ?trailing,
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

/// Real progress of a long operation: each stage that actually finished gets a check; the
/// current one shows soft dots. No percentages, nothing simulated (docs/DESIGN.md §7.3).
class StageLoader extends StatelessWidget {
  const StageLoader({super.key, required this.stages, required this.current, this.note, this.action});

  final List<String> stages;

  /// Index of the stage in progress; earlier stages are done.
  final int current;
  final String? note;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Card(
        color: theme.colorScheme.surfaceContainerLowest,
        child: Padding(
          padding: const EdgeInsets.all(Space.l + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Space.m,
            children: [
              for (final (i, s) in stages.indexed)
                AnimatedOpacity(
                  duration: Motion.of(context, Motion.medium),
                  opacity: i > current ? 0.45 : 1,
                  child: Row(
                    spacing: Space.m,
                    children: [
                      SizedBox(
                        width: 28,
                        child: AnimatedSwitcher(
                          duration: Motion.of(context, Motion.medium),
                          transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                          child: i < current
                              ? Icon(Icons.check_circle_rounded, key: const ValueKey('done'), color: context.palette.success)
                              : i == current
                                  ? const ThinkingDots(key: ValueKey('now'), size: 6)
                                  : Icon(Icons.circle_outlined, key: const ValueKey('later'), size: 18, color: theme.colorScheme.outline),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          s,
                          style: i == current
                              ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
                              : theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              if (note case final n?)
                Text(n, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ?action,
            ],
          ),
        ),
      ),
    );
  }
}

/// A themed yes/no question; true only when the cook confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  String? title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: title == null ? null : Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelLabel)),
          FilledButton(
            style: destructive ? FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError) : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return ok ?? false;
}
