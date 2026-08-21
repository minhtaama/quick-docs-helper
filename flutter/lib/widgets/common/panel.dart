import 'package:flutter/material.dart';
import 'app_button.dart';
import 'app_container.dart';

/// Chế độ hiển thị của Panel dựa theo bối cảnh trong SideBarPage
enum PanelMode {
  desktop, // Hiển thị trong cột phải Desktop -> Header co giãn linh hoạt
  mobileDetail, // Hiển thị toàn màn hình chi tiết Mobile -> Tự sinh Scaffold kèm nút Back
  mobileTabs, // Hiển thị bên trong TabBarView Mobile -> Ẩn Header của Panel
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

/// Header tùy biến co giãn thông minh cho Panel (tự động xuống dòng khi ở màn hình hẹp/mobile)
class _PanelHeader extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final Widget? customAppBar;

  const _PanelHeader({
    this.leading,
    this.title,
    this.actions,
    this.customAppBar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (customAppBar != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
        ),
        child: customAppBar!,
      );
    }

    if (title == null && leading == null && (actions == null || actions!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 680;

          final titleRow = Row(
            mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ],
              if (title != null)
                isCompact
                    ? Expanded(child: title!)
                    : Flexible(child: title!),
            ],
          );

          final actionsWidget = (actions != null && actions!.isNotEmpty)
              ? Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: isCompact ? WrapAlignment.end : WrapAlignment.start,
                  children: actions!,
                )
              : null;

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                titleRow,
                if (actionsWidget != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: actionsWidget,
                  ),
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleRow),
              if (actionsWidget != null) ...[
                const SizedBox(width: 12),
                actionsWidget,
              ],
            ],
          );
        },
      ),
    );
  }
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

  Widget _buildHeader(
    BuildContext context,
    PanelMode mode,
    VoidCallback? onMobileBack,
  ) {
    if (customAppBar == null &&
        appBarTitle == null &&
        appBarIcon == null &&
        appBarActions == null) {
      return const SizedBox.shrink();
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

    return _PanelHeader(
      leading: leadingWidget,
      title: titleWidget,
      actions: appBarActions,
      customAppBar: customAppBar != null && mode == PanelMode.desktop ? customAppBar : null,
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

    // Trường hợp 1: Màn hình chi tiết Mobile -> Scaffold với Header co giãn
    if (mode == PanelMode.mobileDetail) {
      final header = _buildHeader(context, mode, scope?.onMobileBack);

      return Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              Expanded(child: bodyContent),
            ],
          ),
        ),
      );
    }

    // Trường hợp 2: Mobile Tabs -> Ẩn Header của Panel (do SideBarPage + TabBar đã đảm nhiệm)
    if (mode == PanelMode.mobileTabs) {
      return AppContainer(color: bgColor, child: bodyContent);
    }

    // Trường hợp 3: Desktop -> Header co giãn linh hoạt bên trong cột phải
    final header = _buildHeader(context, mode, null);

    return AppContainer(
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(child: bodyContent),
        ],
      ),
    );
  }
}

