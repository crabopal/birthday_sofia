import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Rounded character portrait: white rim only as окантовка, sky-blue fill
/// clipped to the same round shape (no white corner wedges).
class CharPortraitFrame extends StatelessWidget {
  const CharPortraitFrame({
    super.key,
    required this.size,
    required this.child,
    this.borderWidth = 3,
    this.radiusFactor = 0.18,
    this.margin,
    this.shadowColor,
  });

  final double size;
  final Widget child;
  final double borderWidth;
  final double radiusFactor;
  final EdgeInsetsGeometry? margin;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final outerR = BorderRadius.circular(size * radiusFactor);
    final innerSize = (size - borderWidth * 2).clamp(1.0, size);
    final innerR = BorderRadius.circular(innerSize * radiusFactor);

    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: outerR,
        boxShadow: [
          BoxShadow(
            color: (shadowColor ?? Colors.black).withValues(alpha: 0.22),
            blurRadius: size > 70 ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(borderWidth),
      child: ClipRRect(
        borderRadius: innerR,
        clipBehavior: Clip.antiAlias,
        child: ColoredBox(
          color: PoliColors.charCardBg,
          child: child,
        ),
      ),
    );
  }
}
