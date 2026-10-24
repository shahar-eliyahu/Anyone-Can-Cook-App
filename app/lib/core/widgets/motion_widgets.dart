import 'package:flutter/material.dart';

import '../motion.dart';
import '../theme.dart';

/// Gently brings an element in (fade + a short rise) when it first appears. [index] staggers
/// items of a list a little. Reduced motion: shown at once.
class Appear extends StatefulWidget {
  const Appear({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<Appear> createState() => _AppearState();
}

class _AppearState extends State<Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    // The stagger is part of one animation (no timers), capped so long lists don't wait.
    final delay = (widget.index.clamp(0, 5)) * 40;
    final total = delay + Motion.medium.inMilliseconds;
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: total));
    _t = CurvedAnimation(parent: _c, curve: Interval(delay / total, 1, curve: Motion.enter));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.value = 1;
    } else if (_c.value == 0 && !_c.isAnimating) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _t,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(_t),
          child: widget.child,
        ),
      );
}

/// Draws attention a few times, then rests (a finished timer). Reduced motion: no movement;
/// the colour change around it carries the message.
class AttentionPulse extends StatefulWidget {
  const AttentionPulse({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<AttentionPulse> createState() => _AttentionPulseState();
}

class _AttentionPulseState extends State<AttentionPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(AttentionPulse old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  void _sync() {
    if (widget.active && !Motion.reduced(context)) {
      _c.repeat(reverse: true, count: 6); // three pulses
    } else {
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.035).animate(CurvedAnimation(parent: _c, curve: Motion.standard)),
        child: widget.child,
      );
}

/// Three soft dots: "working on it". Runs for a bounded time; reduced motion shows them still.
class ThinkingDots extends StatefulWidget {
  const ThinkingDots({super.key, this.color, this.size = 8});

  final Color? color;
  final double size;

  @override
  State<ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<ThinkingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Motion.reduced(context) && !_c.isAnimating) _c.repeat(count: 40);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.brandBlue;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          spacing: widget.size * 0.6,
          children: [
            for (var i = 0; i < 3; i++)
              Opacity(
                opacity: _c.isAnimating ? 0.3 + 0.7 * _wave(_c.value, i) : 0.6,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static double _wave(double t, int i) {
    final x = (t - i * 0.18) % 1.0;
    return x < 0.5 ? x * 2 : (1 - x) * 2;
  }
}

/// A slow breathing ring behind its child while [active] (the microphone listening).
/// Bounded; reduced motion shows a still ring.
class BreathingRing extends StatefulWidget {
  const BreathingRing({super.key, required this.active, required this.child, this.color});

  final bool active;
  final Widget child;
  final Color? color;

  @override
  State<BreathingRing> createState() => _BreathingRingState();
}

class _BreathingRingState extends State<BreathingRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(BreathingRing old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  void _sync() {
    if (widget.active && !Motion.reduced(context)) {
      // Recognition stops by itself within about 20 seconds; the ring never runs longer.
      _c.repeat(reverse: true, count: 16);
    } else {
      _c.value = widget.active ? 0.5 : 0;
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.brandBlue;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: widget.active
              ? [BoxShadow(color: color.withValues(alpha: 0.28), spreadRadius: 3 + 7 * _c.value, blurRadius: 4)]
              : const [],
        ),
        child: child,
      ),
    );
  }
}

/// A placeholder block while content loads (static under reduced motion, a soft fade otherwise).
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.height = 16, this.width, this.radius = 8});

  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Motion.reduced(context) && !_c.isAnimating) _c.repeat(reverse: true, count: 30);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: FadeTransition(
          opacity: Tween(begin: 0.55, end: 1.0).animate(_c),
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(widget.radius)),
          ),
        ),
      );
}
