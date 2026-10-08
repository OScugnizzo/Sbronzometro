import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sbronzometro/main.dart';
import 'package:sbronzometro/models/alcohol_calculator.dart';
import 'package:sbronzometro/screens/home_screen.dart';
import 'package:sbronzometro/theme/app_theme.dart';
import 'package:sbronzometro/widgets/variable_control.dart';

void main() {
  group('AlcoholCalculator three-way reactive logic', () {
    test('derives units from ABV and volume using the density formula', () {
      final AlcoholCalculator c = AlcoholCalculator(
        abvPercent: 5,
        volumeMl: 330,
      );
      // (330 * 0.05 * 0.8) / 12 = 1.1 AU
      expect(c.units, closeTo(330 * 0.05 * 0.8 / 12, 1e-9));
      expect(c.alcoholGrams, closeTo(c.units * 12, 1e-9));
    });

    test('editing ABV holds volume and recomputes units', () {
      final AlcoholCalculator c = AlcoholCalculator(
        abvPercent: 5,
        volumeMl: 330,
      );
      c.setAbvPercent(12.5);
      expect(c.volumeMl, 330);
      expect(c.units, closeTo(330 * 0.125 * 0.8 / 12, 1e-9));
    });

    test('editing volume holds ABV and recomputes units', () {
      final AlcoholCalculator c = AlcoholCalculator(
        abvPercent: 5,
        volumeMl: 330,
      );
      c.setVolumeMl(500);
      expect(c.abvPercent, 5);
      expect(c.units, closeTo(500 * 0.05 * 0.8 / 12, 1e-9));
    });

    test('editing units holds ABV and derives volume', () {
      final AlcoholCalculator c = AlcoholCalculator(
        abvPercent: 5,
        volumeMl: 330,
      );
      c.setUnits(2);
      expect(c.abvPercent, 5);
      expect(c.volumeMl, closeTo(2 * 12 / (5 / 100 * 0.8), 1e-6));
      expect(c.units, closeTo(2, 1e-9));
    });

    test('values are clamped to their supported ranges', () {
      final AlcoholCalculator c = AlcoholCalculator();
      c.setAbvPercent(250);
      expect(c.abvPercent, AlcoholCalculator.maxAbvPercent);
      c.setVolumeMl(-10);
      expect(c.volumeMl, AlcoholCalculator.minVolumeMl);
    });

    test('each single edit notifies listeners exactly once', () {
      final AlcoholCalculator c = AlcoholCalculator();
      int notifications = 0;
      c.addListener(() => notifications++);
      c.setVolumeMl(500);
      expect(notifications, 1);
    });

    test('applyPreset updates every variable with a single notification', () {
      final AlcoholCalculator c = AlcoholCalculator();
      int notifications = 0;
      c.addListener(() => notifications++);
      c.applyPreset(abvPercent: 40, volumeMl: 40);
      expect(c.abvPercent, 40);
      expect(c.volumeMl, 40);
      expect(c.units, closeTo(40 * 0.4 * 0.8 / 12, 1e-9));
      expect(notifications, 1);
    });
  });

  testWidgets('home screen exposes the three reactive controls', (
    WidgetTester tester,
  ) async {
    final AlcoholCalculator c = AlcoholCalculator(abvPercent: 5, volumeMl: 330);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: HomeScreen(calculator: c),
      ),
    );

    expect(find.text('Gradazione alcolica'), findsOneWidget);
    expect(find.text('Volume'), findsOneWidget);
    expect(find.text('Unità alcoliche'), findsWidgets);
    expect(find.byType(TextField), findsNWidgets(3));

    // Typing into the volume field updates the model (and therefore the units).
    await tester.enterText(find.byType(TextField).at(1), '500');
    await tester.pump();
    expect(c.volumeMl, 500);
    expect(c.units, closeTo(500 * 0.05 * 0.8 / 12, 1e-6));
  });

  testWidgets('app shows the animated splash before the home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SbronzometroApp());

    // Splash wordmark is visible first.
    expect(find.text('Sbronzometro'), findsOneWidget);
    expect(find.text('Gradazione alcolica'), findsNothing);

    await tester.pumpAndSettle();

    // After the intro completes we land on the main UI.
    expect(find.text('Gradazione alcolica'), findsOneWidget);
  });

  testWidgets('external changes update the field even while it is focused', (
    WidgetTester tester,
  ) async {
    double value = 5.0;
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              rebuild = setState;
              return VariableControl(
                label: 'Gradazione alcolica',
                unit: '%',
                value: value,
                min: 0,
                max: 100,
                decimals: 1,
                accent: Colors.orange,
                onChanged: (double v) => setState(() => value = v),
              );
            },
          ),
        ),
      ),
    );

    // Focus the field so it is in the "user is editing" state.
    await tester.tap(find.byType(TextField));
    await tester.pump();

    // A slider drag / reactive recalculation changes the value elsewhere.
    // The field must still mirror it.
    rebuild(() => value = 20.0);
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '20.0',
    );
  });
}
