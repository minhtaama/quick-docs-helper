import 'package:flutter/material.dart';

/// Widget Wrapper chuẩn hóa cho toàn bộ các Panel nội dung bên phải trong SideBarPage.
class Panel extends StatelessWidget {
  /// Nội dung chính của Panel
  final Widget child;

  /// Thanh tiêu đề hoặc Header tùy biến ở đầu Panel
  final Widget? header;

  /// Màu nền của Panel (mặc định lấy theo theme)
  final Color? backgroundColor;

  /// Khoảng đệm bên trong Panel
  final EdgeInsetsGeometry? padding;

  /// Cờ hiển thị trạng thái đang tải dữ liệu
  final bool isLoading;

  const Panel({
    super.key,
    required this.child,
    this.header,
    this.backgroundColor,
    this.padding,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.surface;

    return Container(
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[
            header!,
            Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.15),
            ),
          ],
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : (padding != null
                    ? Padding(padding: padding!, child: child)
                    : child),
          ),
        ],
      ),
    );
  }
}
