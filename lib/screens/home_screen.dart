import 'package:flutter/material.dart';

import '../models/alcohol_calculator.dart';
import '../widgets/drink_logo.dart';
import '../widgets/result_card.dart';
import '../widgets/variable_control.dart';

/// Main application screen.
///
/// Rebuilds through a single [ListenableBuilder] bound to [calculator]; any
/// edit to one variable updates the model, which notifies once and refreshes all
/// three controls plus the hero [ResultCard].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.calculator});

  final AlcoholCalculator calculator;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            const DrinkLogo(size: 30),
            const SizedBox(width: 12),
            const Text('Sbronzometro'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: calculator.reset,
            tooltip: 'Reimposta',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: calculator,
          builder: (BuildContext context, Widget? child) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                // Hero result - animates on every change.
                ResultCard(
                  units: calculator.units,
                  grams: calculator.alcoholGrams,
                ),
                const SizedBox(height: 26),

                const _SectionTitle('Parametri'),
                VariableControl(
                  label: 'Gradazione alcolica',
                  unit: '%',
                  value: calculator.abvPercent,
                  min: AlcoholCalculator.minAbvPercent,
                  max: AlcoholCalculator.maxAbvPercent,
                  divisions: 200,
                  decimals: 1,
                  accent: scheme.primary,
                  icon: Icons.percent_rounded,
                  hint: 'Birra ~5% · vino ~12% · superalcolici ~40%',
                  onChanged: calculator.setAbvPercent,
                ),
                VariableControl(
                  label: 'Volume',
                  unit: 'ml',
                  value: calculator.volumeMl,
                  min: AlcoholCalculator.minVolumeMl,
                  max: AlcoholCalculator.maxVolumeMl,
                  divisions: 400,
                  decimals: 0,
                  accent: scheme.tertiary,
                  icon: Icons.local_drink_rounded,
                  hint:
                      'Bicchiere ~150 ml · lattina ~330 ml · bottiglia ~750 ml',
                  onChanged: calculator.setVolumeMl,
                ),
                VariableControl(
                  label: 'Unità alcoliche',
                  unit: 'AU',
                  value: calculator.units,
                  min: AlcoholCalculator.minUnits,
                  max: AlcoholCalculator.maxUnits,
                  sliderMax: 20,
                  divisions: 200,
                  decimals: 2,
                  accent: scheme.secondary,
                  icon: Icons.speed_rounded,
                  hint: '1 AU ≈ 12 g di alcol puro',
                  onChanged: calculator.setUnits,
                ),
                const SizedBox(height: 10),

                const _SectionTitle('Preset rapidi'),
                _PresetList(calculator: calculator),
                const SizedBox(height: 28),

                // Formula reminder + dependency explanation.
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.functions_rounded,
                            size: 18,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Come funziona',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AU = (Volume × %Vol / 100 × 0,8) / 12',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Modifica una qualsiasi delle tre variabili: le altre due '
                        'si aggiornano in tempo reale mantenendo i valori '
                        'matematicamente coerenti.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PresetList extends StatelessWidget {
  const _PresetList({required this.calculator});

  final AlcoholCalculator calculator;

  static const List<_Preset> _presets = [
    _Preset('🍺', 'Birra', 5.0, 330),
    _Preset('🍻', 'Birra forte', 8.0, 500),
    _Preset('🍷', 'Vino', 12.5, 150),
    _Preset('🍹', 'Spritz', 9.0, 200),
    _Preset('🥃', 'Shot', 40.0, 40),
    _Preset('🍸', 'Cocktail', 15.0, 250),
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _presets.map((_Preset preset) {
        final double units =
            (preset.volumeMl *
                (preset.abvPercent / 100) *
                AlcoholCalculator.ethanolDensity) /
            AlcoholCalculator.gramsPerUnit;
        return ActionChip(
          backgroundColor: scheme.surfaceContainerLow,
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          avatar: Text(preset.emoji, style: const TextStyle(fontSize: 16)),
          label: Text('${preset.label} · ${units.toStringAsFixed(1)} AU'),
          onPressed: () => calculator.applyPreset(
            abvPercent: preset.abvPercent,
            volumeMl: preset.volumeMl,
          ),
        );
      }).toList(),
    );
  }
}

class _Preset {
  const _Preset(this.emoji, this.label, this.abvPercent, this.volumeMl);

  final String emoji;
  final String label;
  final double abvPercent;
  final double volumeMl;
}
