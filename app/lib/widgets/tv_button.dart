import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../input/input_router.dart';

import '../theme/app_theme.dart';

class TvButton extends StatefulWidget {
  const TvButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.autofocus = false,
    this.primary = true,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool autofocus;
  final bool primary;
  final bool enabled;

  @override
  State<TvButton> createState() => _TvButtonState();
}

class _TvButtonState extends State<TvButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onPressed != null;
    final bg = !enabled
        ? PoliColors.dimLetter
        : widget.primary
            ? PoliColors.robocarRed
            : PoliColors.road;
    final border = _focused
        ? PoliColors.focus
        : (widget.primary ? PoliColors.robocarRed : PoliColors.steel);

    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: (node, event) {
        if (!enabled) return KeyEventResult.ignored;
        if (event is KeyDownEvent && InputRouter.isSelect(event)) {
          widget.onPressed?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border, width: _focused ? 4 : 2),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: PoliColors.beaconYellow.withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 12,
              color: enabled ? PoliColors.cream : PoliColors.steel,
            ),
          ),
        ),
      ),
    );
  }
}
