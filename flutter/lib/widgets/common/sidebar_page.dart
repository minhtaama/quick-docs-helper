import 'package:flutter/material.dart';

/// Widget bố cục 2 cột (Sidebar bên trái & Nội dung chính bên phải)
/// Hỗ trợ kéo dãn chiều rộng Sidebar trên Desktop và tự động thích ứng với Mobile:
/// - Nếu [tabs] != null: Hiển thị giao diện chuyển đổi qua lại giữa Sidebar và Child bằng TabBar trên Mobile.
/// - Nếu [tabs] == null: Hoạt động theo mô hình Master-Detail (danh sách / chi tiết) dựa trên cờ [shouldShowDetailPanelOnMobile].
class SideBarPage extends StatefulWidget {
  /// Thanh AppBar của trang
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < widget.breakpoint;
        final theme = Theme.of(context);
        final primaryColor = theme.colorScheme.primary;

        // BỐ CỤC CHO MÀN HÌNH NHỎ (MOBILE / TABLET)
        if (isMobile) {
          // Trường hợp 1: Có cấu hình Tabs (như trang ExportDocsPage)
          if (widget.tabs != null && widget.tabs!.isNotEmpty) {
            return DefaultTabController(
              length: widget.tabs!.length,
              child: Scaffold(
                appBar: widget.appBar,
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
            );
          }

          // Trường hợp 2: Không dùng Tabs, hoạt động theo mô hình Master-Detail (như HomePage)
          return PopScope(
            canPop: !widget.shouldShowDetailPanelOnMobile,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && widget.onMobileBack != null) {
                widget.onMobileBack!();
              }
            },
            child: Scaffold(
              appBar: widget.appBar,
              body: widget.shouldShowDetailPanelOnMobile
                  ? widget.child
                  : widget.sideBar,
            ),
          );
        }

        // BỐ CỤC CHO MÀN HÌNH RỘNG (DESKTOP / WEB)
        return Scaffold(
          appBar: widget.appBar,
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
        );
      },
    );
  }
}
