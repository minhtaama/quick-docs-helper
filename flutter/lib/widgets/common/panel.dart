import 'package:flutter/material.dart';
import 'app_button.dart';
import 'app_container.dart';

/// Chế độ hiển thị của Panel dựa theo bối cảnh trong SideBarPage
enum PanelMode {
  desktop, // Hiển thị trong cột phải Desktop -> Vẽ AppBar như Header của Panel bên trong Column
  mobileDetail, // Hiển thị toàn màn hình chi tiết Mobile -> Tự sinh Scaffold với AppBar riêng
  mobileTabs, // Hiển thị bên trong TabBarView Mobile -> Ẩn AppBar của Panel để tránh trùng lặp
}

/// Scope truyền bối cảnh từ SideBarPage xuống cho Panel
class PanelScope extends InheritedWidget {
  final PanelMode mode;
  final VoidCallback? onMobileBack;

  const PanelScope({
    super.key,
    required this.mode,
    this.onMobileBack,
    required super.child,
  });

  static PanelScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PanelScope>();
  }

  @override
  bool updateShouldNotify(PanelScope oldWidget) =>
      mode != oldWidget.mode || onMobileBack != oldWidget.onMobileBack;
}

/// Widget Wrapper chuẩn hóa cho toàn bộ các Panel nội dung bên phải trong SideBarPage.
class Panel extends StatelessWidget {
  /// Widget tùy biến thanh tiêu đề của Panel (khi được truyền, sẽ thay thế cho appBarIcon và appBarTitle)
  final Widget? customAppBar;

  /// Icon đại diện hiển thị trên AppBar của Panel (khi không dùng customAppBar)
  final IconData? appBarIcon;

  /// Tiêu đề hiển thị trên AppBar của Panel (khi không dùng customAppBar)
  final String? appBarTitle;

  /// Các nút thao tác (actions) trên AppBar của Panel
  final List<Widget>? appBarActions;

  /// Nội dung chính của Panel
  final Widget child;

  /// Màu nền của Panel (mặc định lấy theo theme)
  final Color? backgroundColor;

  /// Khoảng đệm bên trong Panel
  final EdgeInsetsGeometry? padding;

  /// Cờ hiển thị trạng thái đang tải dữ liệu
  final bool isLoading;

  const Panel({
    super.key,
    this.customAppBar,
    this.appBarIcon,
    this.appBarTitle,
    this.appBarActions,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.isLoading = false,
  });

  PreferredSizeWidget? _buildAppBar(
    BuildContext context,
    PanelMode mode,
    VoidCallback? onMobileBack,
  ) {
    if (customAppBar == null &&
        appBarTitle == null &&
        appBarIcon == null &&
        appBarActions == null) {
      return null;
    }

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    // Nút Back implicit luôn xuất hiện khi ở mobileDetail
    Widget? leadingWidget;

    if (mode == PanelMode.mobileDetail) {
      if (onMobileBack != null) {
        leadingWidget = AppIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Quay lại danh sách',
          onPressed: onMobileBack,
        );
      }
    } else if (customAppBar == null && appBarIcon != null) {
      leadingWidget = Icon(
        appBarIcon,
        size: 20,
        color: primaryColor.withValues(alpha: 0.8),
      );
    }

    // Nội dung tiêu đề: ưu tiên customAppBar nếu có
    final Widget? titleWidget =
        customAppBar != null && mode == PanelMode.desktop
        ? customAppBar
        : (appBarTitle != null
              ? Text(
                  appBarTitle!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                )
              : null);

    return AppBar(
      automaticallyImplyLeading: false,
      leading: leadingWidget,
      title: titleWidget,
      actions: appBarActions,
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: leadingWidget == null ? 16.0 : 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.surface;
    final scope = PanelScope.maybeOf(context);
    final mode = scope?.mode ?? PanelMode.desktop;

    final bodyContent = isLoading
        ? const Center(child: CircularProgressIndicator())
        : (padding != null ? Padding(padding: padding!, child: child) : child);

    // Trường hợp 1: Màn hình chi tiết Mobile -> Tạo Scaffold với AppBar riêng của Panel
    if (mode == PanelMode.mobileDetail) {
      final panelAppBar = _buildAppBar(context, mode, scope?.onMobileBack);

      return Scaffold(
        backgroundColor: bgColor,
        appBar: panelAppBar,
        body: bodyContent,
      );
    }

    // Trường hợp 2: Mobile Tabs -> Ẩn AppBar của Panel (do SideBarPage + TabBar đã đảm nhiệm)
    if (mode == PanelMode.mobileTabs) {
      return AppContainer(color: bgColor, child: bodyContent);
    }

    // Trường hợp 3: Desktop -> Hiển thị AppBar/Header bên trong cột phải (tắt automaticallyImplyLeading)
    final panelAppBar = _buildAppBar(context, mode, null);

    return AppContainer(
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (panelAppBar != null) panelAppBar,
          Expanded(child: bodyContent),
        ],
      ),
    );
  }
}
