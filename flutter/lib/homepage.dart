import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'widgets/welcome_view.dart';
import 'widgets/case_list_panel.dart';
import 'widgets/case_detail_panel.dart';
import 'widgets/case_edit_dialog.dart';
import 'case_detail_screen.dart';
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
  void _onSelectCase(String caseId, bool isMobile) {
    if (isMobile) {
      // Trên Mobile: Chuyển màn hình riêng biệt
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: caseId)),
      ).then((_) => _loadCases());
    } else {
      // Trên Web/Desktop: Cập nhật vùng chi tiết bên phải
      setState(() => _selectedCaseId = caseId);
      _loadCaseDetails(caseId);
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tạo vụ việc "${newCase['ten_vu']}" thành công!'),
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
    String currentTenVu,
    String currentMoTa,
  ) async {
    final updatedCase = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => CaseEditDialog(
        caseId: caseId,
        initialTenVu: currentTenVu,
        initialMoTa: currentMoTa,
      ),
    );
    if (updatedCase != null) {
      await _loadCases();
      if (_selectedCaseId == caseId) {
        _loadCaseDetails(caseId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã cập nhật vụ việc "${updatedCase['ten_vu']}" thành công!',
            ),
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

  /// Tải file Word của cá nhân
  Future<void> _downloadDocx(String personId, String hoTen) async {
    if (_selectedCaseId == null) return;
    try {
      final ok = await ApiService.downloadPersonDocx(
        caseId: _selectedCaseId!,
        personId: personId,
        hoTen: hoTen,
      );
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xuất file Word lý lịch: $hoTen'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải file Word: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        // BỐ CỤC CHO MÀN HÌNH NHỎ (MOBILE)
        if (isMobile) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Quản Lý Vụ Việc'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Làm mới',
                  onPressed: _loadCases,
                ),
              ],
            ),
            body: Column(
              children: [
                // Welcome card xuất hiện bên trên danh sách vụ việc
                WelcomeView(
                  isCompact: true,
                  onNewCasePressed: _showCreateCaseDialog,
                ),
                // Danh sách vụ việc chiếm toàn bộ phần còn lại
                Expanded(
                  child: _isLoadingCases
                      ? const Center(child: CircularProgressIndicator())
                      : CaseListPanel(
                          cases: _cases,
                          selectedCaseId: _selectedCaseId,
                          onCaseSelected: (id) => _onSelectCase(id, true),
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
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Làm mới danh sách',
                onPressed: _loadCases,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              // Cột bên trái: Sidebar danh sách vụ việc
              SizedBox(
                width: 340,
                child: _isLoadingCases
                    ? const Center(child: CircularProgressIndicator())
                    : CaseListPanel(
                        cases: _cases,
                        selectedCaseId: _selectedCaseId,
                        onCaseSelected: (id) => _onSelectCase(id, false),
                        onRefresh: _loadCases,
                        onNewCasePressed: _showCreateCaseDialog,
                        onCaseEdited: _showEditCaseDialog,
                        onCaseDeleted: _deleteCase,
                        isMobile: false,
                      ),
              ),

              // Đường phân cách dọc
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.15),
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
                          _selectedCaseDetails?['ten_vu'] ?? '',
                          _selectedCaseDetails?['mo_ta'] ?? '',
                        ),
                        onEditPersonPressed: _openEditPerson,
                        onDownloadDocx: _downloadDocx,
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
    );
  }
}
