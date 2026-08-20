import 'package:flutter/material.dart';

enum AppButtonVariant {
  primary,
  secondary, // outlined
  tonal,
  text,
}

/// Widget nút bấm dùng chung chuẩn hoá trong toàn bộ ứng dụng (DRY)
class AppButton extends StatelessWidget {
  final String? label;
  final Widget? labelWidget;
  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isDanger;
  final bool isCompact;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? iconSize;
  final double? fontSize;
  final FontWeight? fontWeight;
  final String? tooltip;
  final double? width;
  final double? height;

  const AppButton({
    super.key,
    this.label,
    this.labelWidget,
    this.icon,
    this.iconWidget,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isDanger = false,
    this.isCompact = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.padding,
    this.borderRadius,
    this.iconSize,
    this.fontSize,
    this.fontWeight,
    this.tooltip,
    this.width,
    this.height,
  });

  /// Nút chính (FilledButton)
  const AppButton.primary({
    super.key,
    this.label,
    this.labelWidget,
    this.icon,
    this.iconWidget,
    this.onPressed,
    this.isLoading = false,
    this.isDanger = false,
    this.isCompact = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.padding,
    this.borderRadius,
    this.iconSize,
    this.fontSize,
    this.fontWeight,
    this.tooltip,
    this.width,
    this.height,
  }) : variant = AppButtonVariant.primary;

  /// Nút viền ngoài (OutlinedButton)
  const AppButton.outlined({
    super.key,
    this.label,
    this.labelWidget,
    this.icon,
    this.iconWidget,
    this.onPressed,
    this.isLoading = false,
    this.isDanger = false,
    this.isCompact = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.padding,
    this.borderRadius,
    this.iconSize,
    this.fontSize,
    this.fontWeight,
    this.tooltip,
    this.width,
    this.height,
  }) : variant = AppButtonVariant.secondary;

  /// Nút phụ nền mờ / tonal (FilledButton.tonal)
  const AppButton.tonal({
    super.key,
    this.label,
    this.labelWidget,
    this.icon,
    this.iconWidget,
    this.onPressed,
    this.isLoading = false,
    this.isDanger = false,
    this.isCompact = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.padding,
    this.borderRadius,
    this.iconSize,
    this.fontSize,
    this.fontWeight,
    this.tooltip,
    this.width,
    this.height,
  }) : variant = AppButtonVariant.tonal;

  /// Nút dạng chữ không viền (TextButton)
  const AppButton.text({
    super.key,
    this.label,
    this.labelWidget,
    this.icon,
    this.iconWidget,
    this.onPressed,
    this.isLoading = false,
    this.isDanger = false,
    this.isCompact = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.padding,
    this.borderRadius,
    this.iconSize,
    this.fontSize,
    this.fontWeight,
    this.tooltip,
    this.width,
    this.height,
  }) : variant = AppButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Tính toán màu sắc mặc định dựa theo variant và isDanger
    Color? effBgColor = backgroundColor;
    Color? effFgColor = foregroundColor;
    Color? effBorderColor = borderColor;

    if (isDanger) {
      if (variant == AppButtonVariant.primary) {
        effBgColor ??= Colors.redAccent;
        effFgColor ??= Colors.white;
      } else if (variant == AppButtonVariant.secondary) {
        effFgColor ??= Colors.redAccent;
        effBorderColor ??= Colors.redAccent;
      } else if (variant == AppButtonVariant.text ||
          variant == AppButtonVariant.tonal) {
        effFgColor ??= Colors.redAccent;
      }
    }

    final double effIconSize = iconSize ?? (isCompact ? 15.0 : 18.0);
    final double effBorderRadius = borderRadius ?? 8.0;
    final EdgeInsetsGeometry effPadding =
        padding ??
        (isCompact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 10));

    // Widget icon
    Widget? effIcon;
    if (isLoading) {
      effIcon = SizedBox(
        width: effIconSize,
        height: effIconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color:
              effFgColor ??
              (variant == AppButtonVariant.primary
                  ? Colors.white
                  : theme.colorScheme.primary),
        ),
      );
    } else if (iconWidget != null) {
      effIcon = iconWidget;
    } else if (icon != null) {
      effIcon = Icon(icon, size: effIconSize, color: effFgColor);
    }

    // Widget text / label
    Widget? effLabel;
    if (labelWidget != null) {
      effLabel = labelWidget;
    } else if (label != null) {
      effLabel = Text(
        label!,
        style: TextStyle(
          fontSize: fontSize ?? (isCompact ? 13.0 : 14.0),
          fontWeight: fontWeight ?? FontWeight.w500,
          color: effFgColor,
        ),
      );
    }

    final VoidCallback? callback = isLoading ? null : onPressed;

    Widget buttonWidget;

    switch (variant) {
      case AppButtonVariant.primary:
        final style = FilledButton.styleFrom(
          backgroundColor: effBgColor,
          foregroundColor: effFgColor,
          padding: effPadding,
          visualDensity: isCompact
              ? VisualDensity.compact
              : VisualDensity.standard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effBorderRadius),
            side: effBorderColor != null
                ? BorderSide(color: effBorderColor)
                : BorderSide.none,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            final fg = effFgColor ?? Colors.white;
            if (states.contains(WidgetState.pressed)) {
              return fg.withValues(alpha: 0.25);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return fg.withValues(alpha: 0.12);
            }
            return null;
          }),
        );

        if (effIcon != null && effLabel != null) {
          buttonWidget = FilledButton.icon(
            onPressed: callback,
            icon: effIcon,
            label: effLabel,
            style: style,
          );
        } else if (effIcon != null) {
          buttonWidget = FilledButton(
            onPressed: callback,
            style: style,
            child: effIcon,
          );
        } else {
          buttonWidget = FilledButton(
            onPressed: callback,
            style: style,
            child: effLabel ?? const SizedBox.shrink(),
          );
        }
        break;

      case AppButtonVariant.secondary:
        final secBaseColor = (effBgColor ?? (effFgColor ?? theme.colorScheme.primary))
            .withValues(alpha: 1.0);
        final style = OutlinedButton.styleFrom(
          backgroundColor: effBgColor,
          foregroundColor: effFgColor,
          padding: effPadding,
          visualDensity: isCompact
              ? VisualDensity.compact
              : VisualDensity.standard,
          side: BorderSide(
            color:
                effBorderColor ??
                (effFgColor ??
                    theme.colorScheme.outline.withValues(alpha: 0.5)),
            width: 1.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effBorderRadius),
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.pressed)) {
              return secBaseColor.withValues(alpha: 0.22);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return secBaseColor.withValues(alpha: 0.10);
            }
            return null;
          }),
        );

        if (effIcon != null && effLabel != null) {
          buttonWidget = OutlinedButton.icon(
            onPressed: callback,
            icon: effIcon,
            label: effLabel,
            style: style,
          );
        } else if (effIcon != null) {
          buttonWidget = OutlinedButton(
            onPressed: callback,
            style: style,
            child: effIcon,
          );
        } else {
          buttonWidget = OutlinedButton(
            onPressed: callback,
            style: style,
            child: effLabel ?? const SizedBox.shrink(),
          );
        }
        break;

      case AppButtonVariant.tonal:
        final tonalBaseColor = (effBgColor ??
                (effFgColor ?? theme.colorScheme.secondaryContainer))
            .withValues(alpha: 1.0);
        final style = FilledButton.styleFrom(
          backgroundColor: effBgColor,
          foregroundColor: effFgColor,
          padding: effPadding,
          visualDensity: isCompact
              ? VisualDensity.compact
              : VisualDensity.standard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effBorderRadius),
            side: effBorderColor != null
                ? BorderSide(color: effBorderColor)
                : BorderSide.none,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.pressed)) {
              return tonalBaseColor.withValues(alpha: 0.25);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return tonalBaseColor.withValues(alpha: 0.15);
            }
            return null;
          }),
        );

        if (effIcon != null && effLabel != null) {
          buttonWidget = FilledButton.tonalIcon(
            onPressed: callback,
            icon: effIcon,
            label: effLabel,
            style: style,
          );
        } else if (effIcon != null) {
          buttonWidget = FilledButton.tonal(
            onPressed: callback,
            style: style,
            child: effIcon,
          );
        } else {
          buttonWidget = FilledButton.tonal(
            onPressed: callback,
            style: style,
            child: effLabel ?? const SizedBox.shrink(),
          );
        }
        break;

      case AppButtonVariant.text:
        final textBaseColor = (effBgColor ?? (effFgColor ?? theme.colorScheme.primary))
            .withValues(alpha: 1.0);
        final style = TextButton.styleFrom(
          backgroundColor: effBgColor,
          foregroundColor: effFgColor,
          padding: effPadding,
          visualDensity: isCompact
              ? VisualDensity.compact
              : VisualDensity.standard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effBorderRadius),
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.pressed)) {
              return textBaseColor.withValues(alpha: 0.20);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return textBaseColor.withValues(alpha: 0.10);
            }
            return null;
          }),
        );

        if (effIcon != null && effLabel != null) {
          buttonWidget = TextButton.icon(
            onPressed: callback,
            icon: effIcon,
            label: effLabel,
            style: style,
          );
        } else if (effIcon != null) {
          buttonWidget = TextButton(
            onPressed: callback,
            style: style,
            child: effIcon,
          );
        } else {
          buttonWidget = TextButton(
            onPressed: callback,
            style: style,
            child: effLabel ?? const SizedBox.shrink(),
          );
        }
        break;
    }

    if (tooltip != null && tooltip!.isNotEmpty) {
      buttonWidget = Tooltip(message: tooltip!, child: buttonWidget);
    }

    if (isFullWidth) {
      buttonWidget = SizedBox(
        width: double.infinity,
        height: height,
        child: buttonWidget,
      );
    } else if (width != null || height != null) {
      buttonWidget = SizedBox(
        width: width,
        height: height,
        child: buttonWidget,
      );
    }

    return buttonWidget;
  }
}

/// Widget nút Icon bấm dùng chung chuẩn hoá trong toàn bộ ứng dụng
class AppIconButton extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool isOutlined;
  final bool isDanger;
  final double size;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;

  const AppIconButton({
    super.key,
    this.icon,
    this.iconWidget,
    this.onPressed,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.isOutlined = false,
    this.isDanger = false,
    this.size = 18.0,
    this.padding,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    Color? effColor = color;
    if (isDanger) {
      effColor ??= Colors.redAccent;
    }

    final Widget effIcon =
        iconWidget ?? Icon(icon, size: size, color: effColor);

    final iconBaseColor = (backgroundColor ?? (effColor ?? Theme.of(context).colorScheme.primary))
        .withValues(alpha: 1.0);

    Widget btn;
    if (isOutlined) {
      btn = IconButton.outlined(
        onPressed: onPressed,
        icon: effIcon,
        tooltip: tooltip,
        padding: padding,
        constraints: constraints,
        style: OutlinedButton.styleFrom(
          foregroundColor: effColor,
          backgroundColor: backgroundColor,
          side: BorderSide(
            color:
                borderColor ??
                (isDanger ? Colors.redAccent : Colors.grey.shade400),
            width: 1,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.pressed)) {
              return iconBaseColor.withValues(alpha: 0.22);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return iconBaseColor.withValues(alpha: 0.12);
            }
            return null;
          }),
        ),
      );
    } else {
      btn = IconButton(
        onPressed: onPressed,
        icon: effIcon,
        tooltip: tooltip,
        color: effColor,
        padding: padding,
        constraints: constraints,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.pressed)) {
              return iconBaseColor.withValues(alpha: 0.22);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return iconBaseColor.withValues(alpha: 0.12);
            }
            return null;
          }),
        ),
      );
    }

    return btn;
  }
}
