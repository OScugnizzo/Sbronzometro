import 'package:flutter/material.dart';

import 'drink_logo.dart';

/// Elegant animated splash screen.
///
/// The drink mark scales/fades in with a gentle overshoot, the wordmark and
/// tagline follow shortly after, and a determinate progress bar fills while the
/// app boots. When the animation completes [onFinished] is invoked so the root
/// widget can cross-fade to the main UI.
///
/// All colours are pulled from the active [ThemeData], so the splash follows the
/// system light/dark setting just like the rest of the app.
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key, required this.onFinished});

  /// Called once the intro animation has finished.
  final VoidCallback onFinished;

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 2600),
          )
          ..addStatusListener((AnimationStatus status) {
            if (status == AnimationStatus.completed) widget.onFinished();
          })
          ..forward();

    // Staggered entrance: the mark first, then the wordmark, then the tagline.
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 0.65, curve: Curves.easeOut),
    );
    _subtitleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.8, curve: Curves.easeOut),
    );
    _glowPulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    final List<Color> background = isDark
        ? const [Color(0xFF1B1310), Color(0xFF0C0908)]
        : const [Color(0xFFFFF7F1), Color(0xFFFFE4CE)];
    final Color markBackground = isDark
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainerLowest;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: background,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Soft pulsing glow behind the mark.
                      Transform.scale(
                        scale: _glowPulse.value,
                        child: Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primary.withValues(
                              alpha: 0.12 * _logoFade.value,
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: _logoFade.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: markBackground,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 30,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: const DrinkLogo(size: 116),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Opacity(
                    opacity: _titleFade.value,
                    child: Text(
                      'Sbronzometro',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: _subtitleFade.value,
                    child: Text(
                      'Calcola le tue unità alcoliche',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Opacity(
                    opacity: _subtitleFade.value,
                    child: SizedBox(
                      width: 130,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _controller.value,
                          minHeight: 4,
                          backgroundColor: scheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            scheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
