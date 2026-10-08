import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A single editable variable card.
///
/// Each variable exposes the two required input affordances:
///  * a smooth [Slider] for fast adjustments, and
///  * a numeric [TextField] (number keyboard) for precise entry.
///
/// The widget is fully controlled by its parent: it renders [value] and reports
/// user gestures through [onChanged]. The internal [TextEditingController] is
/// only used for display and is refreshed from [value] via [didUpdateWidget] -
/// but never while the field has focus, so the cursor is never hijacked and no
/// edit/rebuild feedback loop can occur.
class VariableControl extends StatefulWidget {
  const VariableControl({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.accent,
    this.icon,
    this.decimals = 1,
    this.sliderMax,
    this.divisions,
    this.hint,
  });

  final String label;
  final String unit;
  final double value;
  final double min;
  final double max;
  final int decimals;

  /// Optional separate upper bound for the slider (defaults to [max]).
  final double? sliderMax;
  final double? divisions;
  final ValueChanged<double> onChanged;
  final Color accent;
  final IconData? icon;
  final String? hint;

  @override
  State<VariableControl> createState() => _VariableControlState();
}

class _VariableControlState extends State<VariableControl> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _focused = false;

  double get _sliderMax => widget.sliderMax ?? widget.max;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant VariableControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;
    // Mirror the model into the field. When the field is focused we do *not*
    // bail out blindly: a focused text field can still be driven externally
    // (e.g. while dragging the slider, or when another variable reactively
    // recomputes this one), so we only preserve the user's text if it already
    // represents the new value.
    _syncController(force: !_focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _format(double value) => value.toStringAsFixed(widget.decimals);

  /// Largest difference between a user's raw input and its formatted form
  /// (e.g. `"5"` vs `"5.0"`), used to tell "still typing" apart from an
  /// external change.
  double get _formatTolerance {
    double tolerance = 0.5;
    for (int i = 0; i < widget.decimals; i++) {
      tolerance /= 10;
    }
    return tolerance;
  }

  /// Writes [widget.value] into the text field.
  ///
  /// With [force] the field is always overwritten. Otherwise the write is
  /// skipped when the current text already parses to the new value (within the
  /// formatting tolerance), which keeps the cursor stable while the user types.
  void _syncController({bool force = true}) {
    final String text = _format(widget.value);
    if (_controller.text == text) return;
    if (!force) {
      final double? parsed = double.tryParse(
        _controller.text.replaceAll(',', '.'),
      );
      if (parsed != null && (parsed - widget.value).abs() <= _formatTolerance) {
        return;
      }
    }
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _handleFocusChange() {
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
    // On blur snap the text back to the canonical, formatted model value.
    if (!_focusNode.hasFocus) _syncController();
  }

  void _handleText(String raw) {
    final double? parsed = double.tryParse(raw.replaceAll(',', '.'));
    if (parsed == null) return;
    widget.onChanged(parsed.clamp(widget.min, widget.max));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final double sliderValue = widget.value.clamp(widget.min, _sliderMax);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerLow
            : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _focused
              ? widget.accent
              : scheme.outlineVariant.withValues(alpha: 0.5),
          width: _focused ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (_focused ? widget.accent : Colors.black).withValues(
              alpha: _focused ? 0.14 : 0.05,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(widget.icon, size: 18, color: widget.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 118,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textAlign: TextAlign.right,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  textInputAction: TextInputAction.done,
                  onChanged: _handleText,
                  onSubmitted: (_) => _focusNode.unfocus(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    suffixText: widget.unit,
                    suffixStyle: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.55,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.accent, width: 1.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: widget.accent,
              thumbColor: widget.accent,
              overlayColor: widget.accent.withValues(alpha: 0.14),
              inactiveTrackColor: widget.accent.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: sliderValue,
              min: widget.min,
              max: _sliderMax,
              divisions: widget.divisions?.round(),
              onChangeStart: (_) => _focusNode.unfocus(),
              onChanged: widget.onChanged,
            ),
          ),
          if (widget.hint != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                widget.hint!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
