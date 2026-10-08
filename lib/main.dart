import 'package:flutter/material.dart';

import 'models/alcohol_calculator.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/animated_splash_screen.dart';

void main() {
  runApp(const SbronzometroApp());
}

/// Root widget.
///
/// Owns the [AlcoholCalculator] for the lifetime of the app and switches from
/// the animated splash screen to the main UI once the intro finishes. The
/// [AnimatedSwitcher] provides a smooth cross-fade between the two.
///
/// Light/dark theming is driven by [ThemeMode.system] so the whole app follows
/// the device setting.
class SbronzometroApp extends StatefulWidget {
  const SbronzometroApp({super.key});

  @override
  State<SbronzometroApp> createState() => _SbronzometroAppState();
}

class _SbronzometroAppState extends State<SbronzometroApp> {
  late final AlcoholCalculator _calculator;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _calculator = AlcoholCalculator();
  }

  @override
  void dispose() {
    _calculator.dispose();
    super.dispose();
  }

  void _handleSplashFinished() {
    if (!mounted) return;
    setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sbronzometro',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _showSplash
            ? AnimatedSplashScreen(
                key: const ValueKey<String>('splash'),
                onFinished: _handleSplashFinished,
              )
            : HomeScreen(
                key: const ValueKey<String>('home'),
                calculator: _calculator,
              ),
      ),
    );
  }
}
