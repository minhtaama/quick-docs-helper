import 'package:flutter/material.dart';
import 'app_button.dart';
import 'panel.dart';

/// Widget bố cục 2 cột (Sidebar bên trái & Nội dung chính bên phải)
/// Hỗ trợ kéo dãn chiều rộng Sidebar trên Desktop và tự động thích ứng với Mobile:
/// - Nếu [tabs] != null: Hiển thị giao diện chuyển đổi qua lại giữa Sidebar và Child bằng TabBar trên Mobile.
/// - Nếu [tabs] == null: Hoạt động theo mô hình Master-Detail (danh sách / chi tiết) dựa trên cờ [shouldShowDetailPanelOnMobile].
class SideBarPage extends StatefulWidget {
  /// Thanh AppBar toàn cục của trang
  final PreferredSizeWidget? appBar;

  /// Widget hiển thị ở cột Sidebar (bên trái)
  final Widget sideBar;

  /// Widget hiển thị ở cột Nội dung chính (bên phải)
  final Widget child;

  /// Danh sách các Tab trên Mobile (nếu có)
  final List<Tab>? tabs;

  /// Cờ quyết định hiển thị màn hình chi tiết trên Mobile khi không dùng Tabs (mặc định false)
  final bool shouldShowDetailPanelOnMobile;

  /// Callback khi người dùng bấm quay lại từ màn hình chi tiết trên Mobile
  final VoidCallback? onMobileBack;

  /// Độ rộng khởi tạo của Sidebar trên Desktop (mặc định 380.0)
  final double defaultSidebarWidth;

  /// Độ rộng tối thiểu khi kéo Sidebar (mặc định 320.0)
  final double minSidebarWidth;

  /// Độ rộng tối đa khi kéo Sidebar (mặc định 650.0)
  final double maxSidebarWidth;

  /// Điểm ngắt chuyển sang giao diện Mobile (mặc định 1200.0)
  final double breakpoint;

  /// Cho phép kéo thay đổi kích thước Sidebar hay không (mặc định true)
  final bool isResizable;

  const SideBarPage({
    super.key,
    this.appBar,
    required this.sideBar,
    required this.child,
    this.tabs,
    this.shouldShowDetailPanelOnMobile = false,
    this.onMobileBack,
    this.defaultSidebarWidth = 380.0,
    this.minSidebarWidth = 320.0,
    this.maxSidebarWidth = 650.0,
    this.breakpoint = 1200.0,
    this.isResizable = true,
  });

  @override
  State<SideBarPage> createState() => _SideBarPageState();
}

class _SideBarPageState extends State<SideBarPage> {
  late double _sidebarWidth;
  bool _isResizing = false;

  @override
  void initState() {
    super.initState();
    _sidebarWidth = widget.defaultSidebarWidth;
  }

  /// Xây dựng AppBar cho SideBarPage (tự động gắn nút Back nếu trang được push từ Route trước)
  PreferredSizeWidget? _buildPageAppBar(BuildContext context) {
    if (widget.appBar == null) return null;

    if (widget.appBar is! AppBar) {
      return widget.appBar;
    }

    final originalAppBar = widget.appBar as AppBar;
    final bool canPopRoute = ModalRoute.of(context)?.canPop ?? false;

    Widget? effectiveLeading = originalAppBar.leading;
    bool effectiveAutomaticallyImplyLeading =
        originalAppBar.automaticallyImplyLeading;

    if (effectiveLeading == null) {
      if (canPopRoute) {
        effectiveLeading = AppIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Quay lại',
          onPressed: () => Navigator.maybePop(context),
        );
        effectiveAutomaticallyImplyLeading = false;
      } else {
        effectiveAutomaticallyImplyLeading = false;
      }
    }

    return AppBar(
      key: originalAppBar.key,
      leading: effectiveLeading,
      automaticallyImplyLeading: effectiveAutomaticallyImplyLeading,
      title: originalAppBar.title,
      actions: originalAppBar.actions,
      flexibleSpace: originalAppBar.flexibleSpace,
      bottom: originalAppBar.bottom,
      elevation: originalAppBar.elevation,
      scrolledUnderElevation: originalAppBar.scrolledUnderElevation,
      shadowColor: originalAppBar.shadowColor,
      surfaceTintColor: originalAppBar.surfaceTintColor,
      shape: originalAppBar.shape,
      backgroundColor: originalAppBar.backgroundColor,
      foregroundColor: originalAppBar.foregroundColor,
      iconTheme: originalAppBar.iconTheme,
      actionsIconTheme: originalAppBar.actionsIconTheme,
      primary: originalAppBar.primary,
      centerTitle: originalAppBar.centerTitle,
      excludeHeaderSemantics: originalAppBar.excludeHeaderSemantics,
      titleSpacing: originalAppBar.titleSpacing,
      toolbarOpacity: originalAppBar.toolbarOpacity,
      bottomOpacity: originalAppBar.bottomOpacity,
      toolbarHeight: originalAppBar.toolbarHeight,
      leadingWidth: originalAppBar.leadingWidth,
      toolbarTextStyle: originalAppBar.toolbarTextStyle,
      titleTextStyle: originalAppBar.titleTextStyle,
      systemOverlayStyle: originalAppBar.systemOverlayStyle,
      forceMaterialTransparency: originalAppBar.forceMaterialTransparency,
      clipBehavior: originalAppBar.clipBehavior,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < widget.breakpoint;
        final theme = Theme.of(context);
        final primaryColor = theme.colorScheme.primary;
        final pageAppBar = _buildPageAppBar(context);

        // BỐ CỤC CHO MÀN HÌNH NHỎ (MOBILE / TABLET)
        if (isMobile) {
          // Trường hợp 1: Có cấu hình Tabs (như trang ExportDocsPage)
          if (widget.tabs != null && widget.tabs!.isNotEmpty) {
            return PanelScope(
              mode: PanelMode.mobileTabs,
              child: DefaultTabController(
                length: widget.tabs!.length,
                child: Scaffold(
                  appBar: pageAppBar,
                  body: Column(
                    children: [
                      TabBar(
                        tabs: widget.tabs!,
                        labelColor: primaryColor,
                        indicatorColor: primaryColor,
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [widget.sideBar, widget.child],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Trường hợp 2: Không dùng Tabs, hoạt động theo mô hình Master-Detail (như HomePage)
          // 2.1. Đang ở màn hình chi tiết (Detail) -> Panel tự hiển thị Scaffold với AppBar riêng
          if (widget.shouldShowDetailPanelOnMobile) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop && widget.onMobileBack != null) {
                  widget.onMobileBack!();
                }
              },
              child: PanelScope(
                mode: PanelMode.mobileDetail,
                onMobileBack: widget.onMobileBack,
                child: widget.child,
              ),
            );
          }

          // 2.2. Đang ở màn hình danh sách (Master) -> Hiển thị AppBar chung của SideBarPage
          return PanelScope(
            mode: PanelMode.desktop,
            child: Scaffold(
              appBar: pageAppBar,
              body: widget.sideBar,
            ),
          );
        }

        // BỐ CỤC CHO MÀN HÌNH RỘNG (DESKTOP / WEB)
        return PanelScope(
          mode: PanelMode.desktop,
          child: Scaffold(
            appBar: pageAppBar,
            body: Row(
              children: [
                // Cột bên trái: Sidebar
                SizedBox(
                  width: _sidebarWidth,
                  child: widget.sideBar,
                ),

                // Thanh kéo co giãn kích thước Sidebar
                if (widget.isResizable)
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (_) {
                        setState(() => _isResizing = true);
                      },
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _sidebarWidth = (_sidebarWidth + details.delta.dx).clamp(
                            widget.minSidebarWidth,
                            widget.maxSidebarWidth,
                          );
                        });
                      },
                      onHorizontalDragEnd: (_) {
                        setState(() => _isResizing = false);
                      },
                      child: Container(
                        width: 8,
                        color: Colors.transparent,
                        alignment: Alignment.center,
                        child: Container(
                          width: 1.5,
                          color: _isResizing
                              ? primaryColor
                              : theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  )
                else
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.15),
                  ),

                // Cột bên phải: Nội dung chính
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
