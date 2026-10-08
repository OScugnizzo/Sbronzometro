import 'package:flutter/foundation.dart';

/// Core domain model for **Sbronzometro**.
///
/// The three editable variables are linked by a single equation:
///
/// ```
/// AU = (volumeMl * (abvPercent / 100) * ethanolDensity) / gramsPerUnit
/// ```
///
/// Because one equation links three unknowns, only **two** values are ever
/// independent. To keep the system mathematically consistent the calculator
/// always treats the freshly edited variable as the source of truth, holds one
/// of the other two fixed, and derives the remaining one.
///
/// Editing contract (the "3-way reactive" behaviour):
///
/// | Edited variable | Held constant | Derived variable |
/// |-----------------|---------------|------------------|
/// | ABV (% Vol)     | Volume        | AU               |
/// | Volume (ml)     | ABV           | AU               |
/// | AU              | ABV           | Volume           |
///
/// The model extends [ChangeNotifier] so the UI can rebuild itself through a
/// single [ListenableBuilder] whenever any variable changes.
class AlcoholCalculator extends ChangeNotifier {
  /// Creates the calculator and derives the initial alcohol units from the
  /// supplied [abvPercent] and [volumeMl].
  AlcoholCalculator({
    double abvPercent = defaultAbvPercent,
    double volumeMl = defaultVolumeMl,
  }) : _abvPercent = abvPercent.clamp(minAbvPercent, maxAbvPercent),
       _volumeMl = volumeMl.clamp(minVolumeMl, maxVolumeMl) {
    _units = _unitsFrom(abvPercent: _abvPercent, volumeMl: _volumeMl);
  }

  // -- Physical constants ---------------------------------------------------

  /// Density of pure ethanol in g/ml.
  static const double ethanolDensity = 0.8;

  /// Grams of pure alcohol contained in one Standard Unit (AU / Unità Alcolica).
  static const double gramsPerUnit = 12.0;

  // -- Value ranges ---------------------------------------------------------

  static const double minAbvPercent = 0.0;
  static const double maxAbvPercent = 100.0;

  static const double minVolumeMl = 0.0;
  static const double maxVolumeMl = 2000.0;

  static const double minUnits = 0.0;

  /// Upper bound chosen so that the extreme combination (2000 ml @ 100 % Vol,
  /// i.e. ~133 AU) is representable.
  static const double maxUnits = 150.0;

  // -- Defaults -------------------------------------------------------------

  static const double defaultAbvPercent = 5.0;
  static const double defaultVolumeMl = 330.0;

  double _abvPercent;
  double _volumeMl;
  late double _units;

  /// Re-entrancy lock.
  ///
  /// Recomputing one variable updates a second and calls [notifyListeners].
  /// The UI responds by writing the new value into its text controllers; without
  /// a guard a controller write could be mistaken for a user edit, fed back into
  /// the model and produce an **infinite recalculation loop**. While
  /// [_recalculating] is `true` any incoming mutation is ignored, so a single
  /// user gesture always yields exactly one coherent update.
  bool _recalculating = false;

  // -- Read-only state ------------------------------------------------------

  /// Alcohol by volume as a percentage (e.g. 5.0 for a 5 % beer).
  double get abvPercent => _abvPercent;

  /// Beverage volume in millilitres.
  double get volumeMl => _volumeMl;

  /// Standard alcohol units (AU).
  double get units => _units;

  /// Mass of pure alcohol in grams for the current state (1 AU = 12 g).
  double get alcoholGrams => _units * gramsPerUnit;

  // -- Derivation helpers ---------------------------------------------------

  /// Forward formula: (ml * %Vol/100 * 0.8) / 12.
  double _unitsFrom({required double abvPercent, required double volumeMl}) =>
      (volumeMl * (abvPercent / 100.0) * ethanolDensity) / gramsPerUnit;

  /// Inverse formula: given the units and a fixed ABV, recover the volume (ml).
  double _volumeFrom({required double units, required double abvPercent}) {
    final double denominator = (abvPercent / 100.0) * ethanolDensity;
    // A 0 % Vol drink contains no alcohol at any volume.
    if (denominator <= 0) {
      return _volumeMl;
    }
    return (units * gramsPerUnit) / denominator;
  }

  // -- Public reactive API --------------------------------------------------

  /// Sets the ABV; the volume is **held** and the AU are recomputed.
  void setAbvPercent(double value) {
    _mutate(() {
      final double next = value.clamp(minAbvPercent, maxAbvPercent);
      if (next == _abvPercent) return;
      _abvPercent = next;
      // ABV + Volume -> AU.
      _units = _unitsFrom(abvPercent: _abvPercent, volumeMl: _volumeMl);
    });
  }

  /// Sets the volume; the ABV is **held** and the AU are recomputed.
  void setVolumeMl(double value) {
    _mutate(() {
      final double next = value.clamp(minVolumeMl, maxVolumeMl);
      if (next == _volumeMl) return;
      _volumeMl = next;
      // Volume + ABV -> AU.
      _units = _unitsFrom(abvPercent: _abvPercent, volumeMl: _volumeMl);
    });
  }

  /// Sets the alcohol units; the ABV is **held** and the volume is recomputed.
  ///
  /// If the requested units would require a volume beyond the supported range
  /// the volume is clamped and the AU are snapped to the closest achievable
  /// value so the three variables stay consistent. At 0 % Vol no amount of
  /// volume can add alcohol, so the units collapse to zero.
  void setUnits(double value) {
    _mutate(() {
      final double next = value.clamp(minUnits, maxUnits);
      if (next == _units) return;
      if (_abvPercent <= 0) {
        _units = 0;
        return;
      }
      // AU + ABV -> Volume.
      final double derivedVolume = _volumeFrom(
        units: next,
        abvPercent: _abvPercent,
      ).clamp(minVolumeMl, maxVolumeMl);
      _volumeMl = derivedVolume;
      // Re-derive from the (possibly clamped) volume so state stays consistent.
      _units = _unitsFrom(abvPercent: _abvPercent, volumeMl: _volumeMl);
    });
  }

  /// Applies a named drink preset in a single locked transaction so the UI only
  /// rebuilds once.
  void applyPreset({required double abvPercent, required double volumeMl}) {
    if (_recalculating) return;
    _recalculating = true;
    try {
      _abvPercent = abvPercent.clamp(minAbvPercent, maxAbvPercent);
      _volumeMl = volumeMl.clamp(minVolumeMl, maxVolumeMl);
      _units = _unitsFrom(abvPercent: _abvPercent, volumeMl: _volumeMl);
      notifyListeners();
    } finally {
      _recalculating = false;
    }
  }

  /// Restores the default 330 ml / 5 % Vol drink.
  void reset() =>
      applyPreset(abvPercent: defaultAbvPercent, volumeMl: defaultVolumeMl);

  /// Runs [change] behind the re-entrancy lock and notifies listeners exactly
  /// once. Mutations arriving while the lock is held are dropped.
  void _mutate(VoidCallback change) {
    if (_recalculating) return;
    _recalculating = true;
    try {
      change();
      notifyListeners();
    } finally {
      _recalculating = false;
    }
  }
}
