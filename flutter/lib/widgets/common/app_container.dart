import 'package:flutter/material.dart';

/// Widget Container dùng chung chuẩn hoá thiết kế trong toàn bộ ứng dụng (DRY)
class AppContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AlignmentGeometry? alignment;
  final BoxConstraints? constraints;
  final Color? color;
  final Color? borderColor;
  final double? borderWidth;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;
  final Decoration? decoration;

  const AppContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.alignment,
    this.constraints,
    this.color,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.boxShadow,
    this.clipBehavior = Clip.none,
    this.decoration,
  });

  /// Dạng Badge / Tag / Chip nhỏ (ví dụ: số thứ tự #1, nhãn đính kèm, badge đếm)
  const AppContainer.badge({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
    this.margin,
    this.alignment,
    this.constraints,
    this.color,
    this.borderColor,
    this.borderWidth,
    this.borderRadius = 4.0,
    this.boxShadow,
  })  : clipBehavior = Clip.none,
        decoration = null;

  /// Dạng Khung icon (Icon Box) bên trong các Card hoặc Sidebar Item
  const AppContainer.iconBox({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(8.0),
    this.margin,
    this.alignment,
    this.constraints,
    this.color,
    this.borderColor,
    this.borderWidth,
    this.borderRadius = 6.0,
    this.boxShadow,
  })  : clipBehavior = Clip.none,
        decoration = null;

  /// Dạng Banner thông báo / Khung thông tin rỗng (Notice / Banner / Empty State Box)
  const AppContainer.banner({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.only(top: 4.0),
    this.alignment,
    this.constraints,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius = 8.0,
    this.boxShadow,
  })  : clipBehavior = Clip.none,
        decoration = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Decoration? effDecoration;
    if (decoration != null) {
      effDecoration = decoration;
    } else if (color != null ||
        borderColor != null ||
        borderRadius != null ||
        boxShadow != null) {
      effDecoration = BoxDecoration(
        color: color,
        borderRadius: borderRadius != null
            ? BorderRadius.circular(borderRadius!)
            : null,
        border: (borderColor != null || borderWidth != null)
            ? Border.all(
                color: borderColor ??
                    theme.colorScheme.outline.withValues(alpha: 0.15),
                width: borderWidth ?? 1.0,
              )
            : null,
        boxShadow: boxShadow,
      );
    }

    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      alignment: alignment,
      constraints: constraints,
      decoration: effDecoration,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}
