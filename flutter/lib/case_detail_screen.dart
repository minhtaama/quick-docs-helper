import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'widgets/case_detail_panel.dart';
import 'person_page.dart';

class CaseDetailScreen extends StatefulWidget {
  final String caseId;

  const CaseDetailScreen({
    super.key,
    required this.caseId,
  });

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  Map<String, dynamic>? _caseData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCase();
  }

  Future<void> _loadCase() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getCaseDetails(widget.caseId);
      if (mounted) {
        setState(() {
          _caseData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải chi tiết vụ việc: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _openAddPerson() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonPage(caseId: widget.caseId),
      ),
    ).then((_) => _loadCase());
  }

  void _openEditPerson(Map<String, dynamic> person) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonPage(
          caseId: widget.caseId,
          initialPerson: person,
        ),
      ),
    ).then((_) => _loadCase());
  }

  void _showEditCaseDialog() {
    if (_caseData == null) return;
    final tenVuController = TextEditingController(text: _caseData!['ten_vu'] ?? '');
    final moTaController = TextEditingController(text: _caseData!['mo_ta'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉnh Sửa Vụ Việc'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: tenVuController,
                decoration: const InputDecoration(
                  labelText: 'Tên vụ việc / Vụ án (*)',
                  isDense: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên vụ việc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: moTaController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả / Ghi chú',
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final tenVu = tenVuController.text.trim();
              final moTa = moTaController.text.trim();
              Navigator.pop(ctx);

              try {
                await ApiService.saveCase(
                  id: widget.caseId,
                  tenVu: tenVu,
                  moTa: moTa,
                );
                _loadCase();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã cập nhật vụ việc "$tenVu" thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi cập nhật: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadDocx(String personId, String hoTen) async {
    try {
      final ok = await ApiService.downloadPersonDocx(
        caseId: widget.caseId,
        personId: personId,
        hoTen: hoTen,
      );
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xuất file Word lý lịch: $hoTen'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải file Word: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _deletePerson(String personId, String hoTen) async {
    final ok = await ApiService.deletePersonFromCase(widget.caseId, personId);
    if (ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa đối tượng: $hoTen'), backgroundColor: Colors.green),
        );
      }
      _loadCase();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi xóa đối tượng'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _caseData?['ten_vu'] ?? 'Chi tiết vụ việc';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: CaseDetailPanel(
        caseData: _caseData,
        isLoading: _isLoading,
        onRefresh: _loadCase,
        onAddPersonPressed: _openAddPerson,
        onEditCasePressed: _showEditCaseDialog,
        onEditPersonPressed: _openEditPerson,
        onDownloadDocx: _downloadDocx,
        onDeletePerson: _deletePerson,
      ),
    );
  }
}
