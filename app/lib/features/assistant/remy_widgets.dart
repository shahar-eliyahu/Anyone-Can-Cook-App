import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'assistant_models.dart';
import 'assistant_sheet.dart';
import 'voice.dart';

/// Remy's face is a hat: a small white chef's hat from the logo on soft blue, inside a thin
/// wood ring. An original mark, deliberately not a character (docs/DESIGN.md §6.1).
class RemyAvatar extends StatelessWidget {
  const RemyAvatar({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.softBlue,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.woodLight, width: size >= 36 ? 2 : 1.5),
          ),
          child: CustomPaint(painter: _HatPainter()),
        ),
      );
}

class _HatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final fill = Paint()..color = Colors.white;
    final line = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeJoin = StrokeJoin.round;

    // Three puffs over a tall crown and a band: the silhouette of the logo's hat.
    final puffs = Path()
      ..addOval(Rect.fromCircle(center: Offset(w * 0.33, h * 0.38), radius: w * 0.14))
      ..addOval(Rect.fromCircle(center: Offset(w * 0.5, h * 0.29), radius: w * 0.17))
      ..addOval(Rect.fromCircle(center: Offset(w * 0.67, h * 0.38), radius: w * 0.14));
    final crown = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.33, h * 0.38, w * 0.67, h * 0.76), Radius.circular(w * 0.05)));
    final hat = Path.combine(PathOperation.union, puffs, crown);
    canvas.drawPath(hat, fill);
    canvas.drawPath(hat, line);

    // The band, in the logo's blue.
    final band = RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.33, h * 0.64, w * 0.67, h * 0.76), Radius.circular(w * 0.05));
    canvas.drawRRect(band, Paint()..color = AppColors.brandBlue);
    canvas.drawRRect(band, line);
  }

  @override
  bool shouldRepaint(_HatPainter oldDelegate) => false;
}

/// The way to Remy, always labelled. A tap is "talking to Remy": he opens already listening
/// (where the phone can listen). A long press opens him quietly, to read or type.
class RemyButton extends ConsumerWidget {
  const RemyButton({super.key, required this.scope, this.label});

  final RemyScope scope;

  /// "רמי" by default; "שאלו את רמי" where there is room.
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final canListen = ref.watch(speechRecognizerProvider) != null;
    final theme = Theme.of(context);
    return Tooltip(
      message: l10n.remyTitle,
      // The label is visible; a long press opens Remy quietly, not the tooltip.
      triggerMode: TooltipTriggerMode.manual,
      child: Semantics(
        button: true,
        label: l10n.remyTitle,
        excludeSemantics: true,
        child: Material(
          color: theme.colorScheme.primaryContainer,
          shape: StadiumBorder(side: BorderSide(color: AppColors.brandBlue.withValues(alpha: 0.35))),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => showAssistantSheet(context, scope, listen: canListen),
            onLongPress: () => showAssistantSheet(context, scope),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(Space.s, Space.xs, Space.l, Space.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: Space.s,
                  children: [
                    const RemyAvatar(size: 36),
                    Text(
                      label ?? l10n.remyOpen,
                      style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
