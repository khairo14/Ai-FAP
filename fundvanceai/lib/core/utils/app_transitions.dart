import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Custom page routes
// ---------------------------------------------------------------------------

/// Slide-from-right page transition (iOS-style) with a subtle fade overlay.
/// Use this for forward navigation within a feature section.
///
/// ```dart
/// Navigator.push(context, SlidePageRoute(page: SomeScreen()));
/// ```
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  SlidePageRoute({required Widget page, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideTween = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            final fadeTween = CurveTween(curve: const Interval(0.0, 0.5));

            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

/// Fade-scale page transition — ideal for modal / bottom-sheet style screens.
///
/// ```dart
/// Navigator.push(context, FadeScalePageRoute(page: SomeSheet()));
/// ```
class FadeScalePageRoute<T> extends PageRouteBuilder<T> {
  FadeScalePageRoute({required Widget page, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeTween = CurveTween(curve: Curves.easeInOut);
            final scaleTween = Tween<double>(begin: 0.92, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            return FadeTransition(
              opacity: animation.drive(fadeTween),
              child: ScaleTransition(
                scale: animation.drive(scaleTween),
                child: child,
              ),
            );
          },
        );
}

// ---------------------------------------------------------------------------
// Animated content wrappers
// ---------------------------------------------------------------------------

/// Wraps [child] in a fade-in animation that plays once when the widget is
/// first inserted into the tree. Great for list screen content appearance.
///
/// ```dart
/// FadeInWidget(child: MyList())
/// ```
class FadeInWidget extends StatefulWidget {
  const FadeInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: widget.curve);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

/// Fade + slide-up animation for individual list items.
/// Wrap each item in this widget and vary [delay] by index for a staggered
/// entrance.
///
/// ```dart
/// FadeSlideItem(
///   delay: Duration(milliseconds: index * 40),
///   child: MyCard(),
/// )
/// ```
class FadeSlideItem extends StatefulWidget {
  const FadeSlideItem({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 350),
    this.slideOffset = const Offset(0, 0.06),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset slideOffset;

  @override
  State<FadeSlideItem> createState() => _FadeSlideItemState();
}

class _FadeSlideItemState extends State<FadeSlideItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

/// Smoothly switches between children using a fade transition.
/// Drop-in replacement for conditional rendering blocks.
///
/// ```dart
/// AnimatedContentSwitcher(
///   tag: provider.isLoading,
///   child: provider.isLoading ? ShimmerView() : ContentView(),
/// )
/// ```
class AnimatedContentSwitcher extends StatelessWidget {
  const AnimatedContentSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: child,
    );
  }
}
