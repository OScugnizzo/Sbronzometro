import 'package:flutter/material.dart';

/// Hero card that surfaces the resulting alcohol units.
///
/// Provides immediate visual feedback while the user drags a slider or types:
///  * the gradient background animates between "risk" bands,
///  * the number itself tweens to its new value, and
///  * an animated meter fills proportionally to the units.
class ResultCard extends StatelessWidget {
  const ResultCard({super.key, required this.units, required this.grams});

  final double units;
  final double grams;

  /// Units mapped to the full width of the meter.
  static const double _meterFullScale = 10.0;

  /// Risk band derived purely from the current units (for colour feedback).
  static _Band _bandFor(double units) {
    if (units < 0.001) {
      return const _Band(
        label: 'Nessun alcol',
        colors: [Color(0xFF3F8E5A), Color(0xFF2E7D32)],
      );
    }
    if (units < 2) {
      return const _Band(
        label: 'Basso',
        colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
      );
    }
    if (units < 4) {
      return const _Band(
        label: 'Moderato',
        colors: [Color(0xFFF9A825), Color(0xFFEF6C00)],
      );
    }
    if (units < 6) {
      return const _Band(
        label: 'Alto',
        colors: [Color(0xFFF4511E), Color(0xFFD84315)],
      );
    }
    return const _Band(
      label: 'Molto alto',
      colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final _Band band = _bandFor(units);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: band.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: band.colors.last.withValues(alpha: 0.35),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Unità alcoliche',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  band.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // Tween the numeric value so changes feel fluid rather than abrupt.
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: units),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    style: const TextStyle(
                      fontSize: 58,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -1.5,
                      color: Colors.white,
                    ),
                    child: Text(value.toStringAsFixed(2)),
                  );
                },
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'AU',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${grams.toStringAsFixed(1)} g di alcol puro',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          _AnimatedMeter(fraction: (units / _meterFullScale).clamp(0.0, 1.0)),
        ],
      ),
    );
  }
}

/// Rounded track that fills according to the current units.
class _AnimatedMeter extends StatelessWidget {
  const _AnimatedMeter({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: fraction),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Stack(
              children: [
                Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Container(
                  height: 7,
                  width: constraints.maxWidth * value,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Band {
  const _Band({required this.label, required this.colors});

  final String label;
  final List<Color> colors;
}
