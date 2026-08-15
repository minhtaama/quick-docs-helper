import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'widgets/case_detail_panel.dart';
import 'widgets/case_edit_dialog.dart';
import 'person_page.dart';

class CaseDetailScreen extends StatefulWidget {
  final String caseId;

  const CaseDetailScreen({super.key, required this.caseId});

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
          SnackBar(
            content: Text('Lỗi tải chi tiết vụ việc: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _openAddPerson() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PersonPage(caseId: widget.caseId)),
    ).then((_) => _loadCase());
  }

  void _openEditPerson(Map<String, dynamic> person) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PersonPage(caseId: widget.caseId, initialPerson: person),
      ),
    ).then((_) => _loadCase());
  }

  Future<void> _showEditCaseDialog() async {
    if (_caseData == null) return;
    final updatedCase = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => CaseEditDialog(
        caseId: widget.caseId,
        initialTenVu: _caseData!['ten_vu'],
        initialMoTa: _caseData!['mo_ta'],
      ),
    );
    if (updatedCase != null) {
      _loadCase();
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

  Future<void> _downloadDocx(String personId, String hoTen) async {
    try {
      final ok = await ApiService.downloadPersonDocx(
        caseId: widget.caseId,
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

  Future<void> _deletePerson(String personId, String hoTen) async {
    final ok = await ApiService.deletePersonFromCase(widget.caseId, personId);
    if (ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa đối tượng: $hoTen'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadCase();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi xóa đối tượng'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _caseData?['ten_vu'] ?? 'Chi tiết vụ việc';
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
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
