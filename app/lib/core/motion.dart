import 'package:flutter/material.dart';

/// Motion tokens (docs/DESIGN.md §7). Everything animated asks [Motion.reduced] first:
/// with the system's "remove animations" setting on, movement becomes a short fade or
/// nothing at all.
abstract final class Motion {
  static const short = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const long = Duration(milliseconds: 350);

  static const enter = Easing.emphasizedDecelerate;
  static const exit = Easing.emphasizedAccelerate;
  static const standard = Easing.standard;

  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [d], or zero when the cook asked for less motion.
  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;
}

/// Shared-axis page transition that follows the reading direction: a new page arrives from
/// the side the text flows toward (the left in Hebrew) and back reverses it. Reduced
/// motion: a short crossfade.
class DirectionalPageTransitionsBuilder extends PageTransitionsBuilder {
  const DirectionalPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Motion.long;

  @override
  Duration get reverseTransitionDuration => Motion.medium;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Motion.reduced(context)) {
      return FadeTransition(opacity: CurvedAnimation(parent: animation, curve: const Interval(0, 0.5)), child: child);
    }
    // In RTL "forward" moves leftward: the incoming page starts slightly to the left.
    final sign = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    final enter = CurvedAnimation(parent: animation, curve: Motion.enter, reverseCurve: Motion.exit);
    final leave = CurvedAnimation(parent: secondaryAnimation, curve: Motion.enter, reverseCurve: Motion.exit);
    return SlideTransition(
      position: Tween(begin: Offset.zero, end: Offset(-0.06 * sign, 0)).animate(leave),
      child: FadeTransition(
        opacity: Tween(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(parent: secondaryAnimation, curve: const Interval(0, 0.4)),
        ),
        child: SlideTransition(
          position: Tween(begin: Offset(0.08 * sign, 0), end: Offset.zero).animate(enter),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: const Interval(0.1, 0.7)),
            child: child,
          ),
        ),
      ),
    );
  }
}
