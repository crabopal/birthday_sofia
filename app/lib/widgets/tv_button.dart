import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class TvButton extends StatefulWidget {
  const TvButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.autofocus = false,
    this.primary = true,
    this.enabled = true,
    this.focusNode,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool autofocus;
  final bool primary;
  final bool enabled;
  final FocusNode? focusNode;

  @override
  State<TvButton> createState() => _TvButtonState();
}

class _TvButtonState extends State<TvButton> {
  bool _focused = false;

  void _activate() {
    if (!widget.enabled || widget.onPressed == null) return;
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onPressed != null;
    final bg = !enabled
        ? const Color(0xFFCFD8DC)
        : widget.primary
            ? PoliColors.robocarRed
            : PoliColors.hellyBlue;
    final border = _focused
        ? PoliColors.focusRing
        : (widget.primary ? const Color(0xFFB71C1C) : const Color(0xFF1565C0));
    final fg = enabled ? Colors.white : PoliColors.inkSoft;

    return FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: enabled,
      onShowFocusHighlight: (show) {
        if (_focused != show) setState(() => _focused = show);
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _activate();
            return null;
          },
        ),
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? _activate : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: _focused ? 4 : 3),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: PoliColors.amberYellow.withValues(alpha: 0.55),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 12,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
