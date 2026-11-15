import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'char_portrait_frame.dart';

/// Full-bleed rescue-city backdrop with optional character decorations.
class PixelScaffold extends StatelessWidget {
  const PixelScaffold({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.showCharacters = false,
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
      // Keep controls reachable when the soft keyboard opens on phones.
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _CityBackdrop(),
          if (dimContent)
            const IgnorePointer(
              child: ColoredBox(color: Color(0x2E000000)),
            ),
          // Content first so it always receives focus / taps.
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
                    // Leave room for decorative strip without covering controls.
                    padding: EdgeInsets.only(bottom: showCharacters ? 96 : 8),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
          // Decorative only — never steals focus or pointer events.
          if (showCharacters)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ExcludeFocus(
                child: IgnorePointer(
                  child: _CharacterStrip(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CityBackdrop extends StatelessWidget {
  const _CityBackdrop();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [PoliColors.skyTop, PoliColors.skyBottom],
            ),
          ),
        ),
        _CityImage(),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x40FFFFFF),
                Color(0x8CFFFFFF),
                Color(0xBFFFF3D6),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _CityImage extends StatelessWidget {
  const _CityImage();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Image.asset(
        'assets/images/bg/city.jpg',
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

class _CharacterStrip extends StatelessWidget {
  const _CharacterStrip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: const [
          _CharSprite('assets/images/chars/poli.jpg', 84),
          _CharSprite('assets/images/chars/roy.jpg', 84),
          _CharSprite('assets/images/chars/amber.jpg', 84),
          _CharSprite('assets/images/chars/helly.jpg', 84),
        ],
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
    return CharPortraitFrame(
      size: size,
      borderWidth: 3,
      radiusFactor: 0.14,
      margin: const EdgeInsets.only(bottom: 6),
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => ColoredBox(
          color: PoliColors.panelDeep,
          child: Icon(
            Icons.directions_car,
            color: PoliColors.robocarRed,
            size: size * 0.45,
          ),
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
