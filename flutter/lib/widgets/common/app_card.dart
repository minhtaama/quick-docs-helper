import 'package:flutter/material.dart';

/// Widget Card dùng chung chuẩn hoá trong toàn bộ ứng dụng (DRY)
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final double? elevation;
  final Color? color;
  final Color? selectedColor;
  final Color? borderColor;
  final Color? selectedBorderColor;
  final double? borderWidth;
  final double? selectedBorderWidth;
  final bool isFilled;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.padding = const EdgeInsets.all(12.0),
    this.margin = const EdgeInsets.only(bottom: 8.0),
    this.borderRadius = 8.0,
    this.elevation,
    this.color,
    this.selectedColor,
    this.borderColor,
    this.selectedBorderColor,
    this.borderWidth,
    this.selectedBorderWidth,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final double effRadius = borderRadius ?? 8.0;
    final double effElevation = elevation ?? (isSelected ? 2.0 : 0.0);

    // Tính toán màu nền
    Color effColor;
    if (isSelected) {
      effColor =
          selectedColor ??
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.75);
    } else if (color != null) {
      effColor = color!;
    } else if (isFilled) {
      effColor = theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.25,
      );
    } else {
      effColor = theme.colorScheme.surface;
    }

    // Tính toán màu viền
    final Color effBorderColor = isSelected
        ? (selectedBorderColor ?? primaryColor)
        : (borderColor ?? theme.colorScheme.outline.withValues(alpha: 0.15));

    final double effBorderWidth = isSelected
        ? (selectedBorderWidth ?? 1.5)
        : (borderWidth ?? 1.0);

    Widget content = padding != null
        ? Padding(padding: padding!, child: child)
        : child;

    if (onTap != null || onLongPress != null) {
      content = InkWell(
        borderRadius: BorderRadius.circular(effRadius),
        onTap: onTap,
        onLongPress: onLongPress,
        child: content,
      );
    }

    return Card(
      elevation: effElevation,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(effRadius),
        side: BorderSide(color: effBorderColor, width: effBorderWidth),
      ),
      color: effColor,
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}
