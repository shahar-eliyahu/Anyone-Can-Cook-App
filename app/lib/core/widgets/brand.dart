import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme.dart';

/// The official logo (docs/branding/logo.png), small: a rounded-square mark. Never stretched,
/// recoloured or used as a large hero image (docs/DESIGN.md §2.4).
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.24),
          child: Image.asset(
            'assets/branding/logo_mark.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            // The logo's own blue while the image loads (or if it can't).
            errorBuilder: (_, _, _) => ColoredBox(color: AppColors.brandBlue, child: SizedBox.square(dimension: size)),
            frameBuilder: (context, child, frame, sync) => frame == null && !sync
                ? ColoredBox(color: AppColors.brandBlue, child: SizedBox.square(dimension: size))
                : child,
          ),
        ),
      );
}

/// Home's header: the mark, the app name large, one friendly line, and a thin wood rule.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Space.s, bottom: Space.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: Space.l,
        children: [
          const LogoMark(size: 56),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(l10n.appTitle, style: theme.textTheme.displaySmall?.copyWith(color: AppColors.onSoftBlue)),
                ),
                const SizedBox(height: Space.xs),
                Container(width: 40, height: 3, decoration: BoxDecoration(color: AppColors.woodLight, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: Space.s),
                Text(greeting, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
