import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CaseEditDialog extends StatefulWidget {
  final String? caseId;
  final String? initialTenVu;
  final String? initialMoTa;

  const CaseEditDialog({
    super.key,
    this.caseId,
    this.initialTenVu,
    this.initialMoTa,
  });

  @override
  State<CaseEditDialog> createState() => _CaseEditDialogState();
}

class _CaseEditDialogState extends State<CaseEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tenVuController;
  late final TextEditingController _moTaController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tenVuController = TextEditingController(text: widget.initialTenVu ?? '');
    _moTaController = TextEditingController(text: widget.initialMoTa ?? '');
  }

  @override
  void dispose() {
    _tenVuController.dispose();
    _moTaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final tenVu = _tenVuController.text.trim();
    final moTa = _moTaController.text.trim();

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.saveCase(
        id: widget.caseId,
        tenVu: tenVu,
        moTa: moTa,
      );
      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu vụ việc: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.caseId != null && widget.caseId!.isNotEmpty;

    return AlertDialog(
      title: Text(isEdit ? 'Chỉnh Sửa Vụ Việc' : 'Tạo Vụ Việc Mới'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _tenVuController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tên vụ việc / Vụ án (*)',
                hintText: 'Ví dụ: Vụ án buôn lậu A...',
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
              controller: _moTaController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả / Ghi chú',
                hintText: 'Nhập thông tin tóm tắt về vụ việc...',
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEdit ? 'Cập nhật' : 'Tạo'),
        ),
      ],
    );
  }
}
