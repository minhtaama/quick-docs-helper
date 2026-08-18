import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'widgets/welcome_view.dart';
import 'widgets/case_list_panel.dart';
import 'widgets/case_detail_panel.dart';
import 'widgets/case_edit_dialog.dart';
import 'person_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _cases = [];
  String? _selectedCaseId;
  Map<String, dynamic>? _selectedCaseDetails;
  double _sidebarWidth = 360.0;
  bool _isResizing = false;

  bool _isLoadingCases = false;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  /// Tải danh sách vụ việc từ Backend
  Future<void> _loadCases() async {
    setState(() => _isLoadingCases = true);
    try {
      final cases = await ApiService.getCases();
      if (mounted) {
        setState(() {
          _cases = cases;
          _isLoadingCases = false;

          // Nếu vụ án đang chọn bị xóa hoặc chưa có, xử lý lại
          if (_selectedCaseId != null) {
            final exists = _cases.any((c) => c['id'] == _selectedCaseId);
            if (!exists) {
              _selectedCaseId = null;
              _selectedCaseDetails = null;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cases = [];
          _isLoadingCases = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối máy chủ: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Tải chi tiết của vụ việc đang chọn
  Future<void> _loadCaseDetails(String caseId) async {
    setState(() => _isLoadingDetails = true);
    try {
      final details = await ApiService.getCaseDetails(caseId);
      if (mounted) {
        setState(() {
          _selectedCaseDetails = details;
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải chi tiết vụ việc: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Xử lý chọn vụ việc
  void _onSelectCase(String caseId) {
    setState(() => _selectedCaseId = caseId);
    _loadCaseDetails(caseId);
  }

  /// Hộp thoại tạo mới vụ việc
  Future<void> _showCreateCaseDialog() async {
    final newCase = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const CaseEditDialog(),
    );
    if (newCase != null) {
      await _loadCases();
      if (mounted) {
        final caseTitle = newCase['ten_tom_tat'] ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tạo vụ "$caseTitle" thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        // Tự động chọn vụ án vừa tạo trên màn hình rộng
        if (newCase['id'] != null) {
          setState(() => _selectedCaseId = newCase['id']);
          _loadCaseDetails(newCase['id']);
        }
      }
    }
  }

  /// Hộp thoại chỉnh sửa tên / mô tả vụ việc
  Future<void> _showEditCaseDialog(
    String caseId,
    String currentTenTomTat,
    String currentTenDayDu,
  ) async {
    final updatedCase = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => CaseEditDialog(
        caseId: caseId,
        initialTenTomTat: currentTenTomTat,
        initialTenDayDu: currentTenDayDu,
        onDelete: () => _deleteCase(caseId),
      ),
    );
    if (updatedCase != null) {
      await _loadCases();
      if (_selectedCaseId == caseId) {
        _loadCaseDetails(caseId);
      }
      if (mounted) {
        final caseTitle = updatedCase['ten_tom_tat'] ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật vụ "$caseTitle" thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Xóa vụ việc
  Future<void> _deleteCase(String caseId) async {
    final ok = await ApiService.deleteCase(caseId);
    if (ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa vụ việc'),
            backgroundColor: Colors.green,
          ),
        );
      }
      if (_selectedCaseId == caseId) {
        setState(() {
          _selectedCaseId = null;
          _selectedCaseDetails = null;
        });
      }
      _loadCases();
    }
  }

  /// Mở form thêm cá nhân vào vụ án
  void _openAddPerson() {
    if (_selectedCaseId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PersonPage(caseId: _selectedCaseId)),
    ).then((saved) {
      if (saved == true && _selectedCaseId != null) {
        _loadCaseDetails(_selectedCaseId!);
        _loadCases();
      }
    });
  }

  /// Mở form chỉnh sửa thông tin cá nhân
  void _openEditPerson(Map<String, dynamic> person) {
    if (_selectedCaseId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PersonPage(caseId: _selectedCaseId, initialPerson: person),
      ),
    ).then((saved) {
      if (saved == true && _selectedCaseId != null) {
        _loadCaseDetails(_selectedCaseId!);
        _loadCases();
      }
    });
  }

  /// Xóa cá nhân khỏi vụ án
  Future<void> _deletePerson(String personId, String hoTen) async {
    if (_selectedCaseId == null) return;
    final ok = await ApiService.deletePersonFromCase(
      _selectedCaseId!,
      personId,
    );
    if (ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa đối tượng: $hoTen'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadCaseDetails(_selectedCaseId!);
      _loadCases();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedCaseId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() {
            _selectedCaseId = null;
            _selectedCaseDetails = null;
          });
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 1200;

          // BỐ CỤC CHO MÀN HÌNH NHỎ (MOBILE)
          if (isMobile) {
            final hasSelectedCase = _selectedCaseId != null;

            return Scaffold(
              appBar: AppBar(
                leading: hasSelectedCase
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Quay lại danh sách',
                        onPressed: () {
                          setState(() {
                            _selectedCaseId = null;
                            _selectedCaseDetails = null;
                          });
                        },
                      )
                    : null,
                title: Text(
                  hasSelectedCase
                      ? (_selectedCaseDetails?['ten_tom_tat'] ??
                            'Chi tiết vụ việc')
                      : 'Quản lý vụ việc',
                ),
                centerTitle: !hasSelectedCase,
              ),
              body: hasSelectedCase
                  ? CaseDetailPanel(
                      caseData: _selectedCaseDetails,
                      isLoading: _isLoadingDetails,
                      onRefresh: () => _loadCaseDetails(_selectedCaseId!),
                      onAddPersonPressed: _openAddPerson,
                      onEditCasePressed: () => _showEditCaseDialog(
                        _selectedCaseId!,
                        _selectedCaseDetails?['ten_tom_tat'] ?? '',
                        _selectedCaseDetails?['ten_day_du'] ?? '',
                      ),
                      onEditPersonPressed: _openEditPerson,
                      onDeletePerson: _deletePerson,
                    )
                  : Column(
                      children: [
                        WelcomeView(
                          isCompact: true,
                          onNewCasePressed: _showCreateCaseDialog,
                        ),
                        Expanded(
                          child: _isLoadingCases
                              ? const Center(child: CircularProgressIndicator())
                              : CaseListPanel(
                                  cases: _cases,
                                  selectedCaseId: _selectedCaseId,
                                  onCaseSelected: _onSelectCase,
                                  onRefresh: _loadCases,
                                  onNewCasePressed: _showCreateCaseDialog,
                                  onCaseEdited: _showEditCaseDialog,
                                  onCaseDeleted: _deleteCase,
                                  isMobile: true,
                                ),
                        ),
                      ],
                    ),
            );
          }

          // BỐ CỤC CHO MÀN HÌNH RỘNG (WEB / DESKTOP SIDEBAR)
          return Scaffold(
            appBar: AppBar(
              title: const Text('Quick Docs Helper - Quản Lý Hồ Sơ Vụ Việc'),
              centerTitle: false,
            ),
            body: Row(
              children: [
                // Cột bên trái: Sidebar danh sách vụ việc
                SizedBox(
                  width: _sidebarWidth,
                  child: _isLoadingCases
                      ? const Center(child: CircularProgressIndicator())
                      : CaseListPanel(
                          cases: _cases,
                          selectedCaseId: _selectedCaseId,
                          onCaseSelected: _onSelectCase,
                          onRefresh: _loadCases,
                          onNewCasePressed: _showCreateCaseDialog,
                          onCaseEdited: _showEditCaseDialog,
                          onCaseDeleted: _deleteCase,
                          isMobile: false,
                        ),
                ),

                // Thanh kéo thay đổi kích thước Sidebar
                MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (_) {
                      setState(() => _isResizing = true);
                    },
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _sidebarWidth = (_sidebarWidth + details.delta.dx)
                            .clamp(360.0, 650.0);
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
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),

                // Cột bên phải: Chi tiết vụ án hoặc Placeholder Welcome
                Expanded(
                  child: _selectedCaseId != null
                      ? CaseDetailPanel(
                          caseData: _selectedCaseDetails,
                          isLoading: _isLoadingDetails,
                          onRefresh: () => _loadCaseDetails(_selectedCaseId!),
                          onAddPersonPressed: _openAddPerson,
                          onEditCasePressed: () => _showEditCaseDialog(
                            _selectedCaseId!,
                            _selectedCaseDetails?['ten_tom_tat'] ?? '',
                            _selectedCaseDetails?['ten_day_du'] ?? '',
                          ),
                          onEditPersonPressed: _openEditPerson,
                          onDeletePerson: _deletePerson,
                        )
                      : WelcomeView(
                          isCompact: false,
                          onNewCasePressed: _showCreateCaseDialog,
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
