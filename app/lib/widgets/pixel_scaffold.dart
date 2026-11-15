import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'scanlines.dart';

/// Full-bleed rescue-city backdrop with optional character decorations.
class PixelScaffold extends StatelessWidget {
  const PixelScaffold({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.showCharacters = true,
    this.dimContent = false,
  });

  final Widget child;
  final String? title;
  final Widget? trailing;
  final bool showCharacters;
  final bool dimContent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _CityBackdrop(),
          if (showCharacters) const _CharacterStrip(),
          if (dimContent)
            Container(color: Colors.black.withValues(alpha: 0.18)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null || trailing != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                    child: Row(
                      children: [
                        if (title != null)
                          Expanded(
                            child: Text(
                              title!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'PressStart2P',
                                fontSize: 16,
                                height: 1.6,
                                color: PoliColors.ink,
                                shadows: [
                                  Shadow(color: Colors.white, blurRadius: 8),
                                ],
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        if (trailing != null) trailing!,
                      ],
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: showCharacters ? 100 : 8),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
          const ScanlinesOverlay(),
        ],
      ),
    );
  }
}

class _CityBackdrop extends StatelessWidget {
  const _CityBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [PoliColors.skyTop, PoliColors.skyBottom],
            ),
          ),
        ),
        Opacity(
          opacity: 0.55,
          child: Image.asset(
            'assets/images/bg/city.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        // Soft wash so UI text stays readable
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.25),
                Colors.white.withValues(alpha: 0.55),
                const Color(0xFFFFF3D6).withValues(alpha: 0.75),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _CharacterStrip extends StatelessWidget {
  const _CharacterStrip();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: SizedBox(
          height: 110,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              _CharSprite('assets/images/chars/poli_red.jpg', 96),
              _CharSprite('assets/images/chars/amber_yellow.jpg', 88),
              _CharSprite('assets/images/chars/helly_blue.jpg', 96),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharSprite extends StatelessWidget {
  const _CharSprite(this.path, this.size);

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ColoredBox(
          color: PoliColors.panelDeep,
          child: Icon(Icons.directions_car, color: PoliColors.robocarRed, size: size * 0.45),
        ),
      ),
    );
  }
}

/// Soft panel for content on the bright city backdrop.
class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: (color ?? PoliColors.panel).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PoliColors.panelBorder, width: 3),
        boxShadow: [
          BoxShadow(
            color: PoliColors.robocarRed.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
