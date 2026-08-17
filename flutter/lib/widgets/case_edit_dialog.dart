import 'package:flutter/material.dart';
import 'package:flutter_web/widgets/text_input.dart';
import '../services/api_service.dart';

class CaseEditDialog extends StatefulWidget {
  final String? caseId;
  final String? initialTenTomTat;
  final String? initialTenDayDu;

  const CaseEditDialog({
    super.key,
    this.caseId,
    this.initialTenTomTat,
    this.initialTenDayDu,
  });

  @override
  State<CaseEditDialog> createState() => _CaseEditDialogState();
}

class _CaseEditDialogState extends State<CaseEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tenTomTatController;
  late final TextEditingController _tenDayDuController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tenTomTatController =
        TextEditingController(text: widget.initialTenTomTat ?? '');
    _tenDayDuController =
        TextEditingController(text: widget.initialTenDayDu ?? '');
  }

  @override
  void dispose() {
    _tenTomTatController.dispose();
    _tenDayDuController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final tenTomTat = _tenTomTatController.text.trim();
    final tenDayDu = _tenDayDuController.text.trim();

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.saveCase(
        id: widget.caseId,
        tenTomTat: tenTomTat,
        tenDayDu: tenDayDu,
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
      title: Text(isEdit ? 'Chỉnh sửa vụ việc/vụ án' : 'Tạo vụ việc/vụ án mới'),
      content: Form(
        key: _formKey,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 600, maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextInput(
                controller: _tenTomTatController,
                label: 'Tên tóm tắt (*)',
                hint: '...',
                minLines: 3,
                maxLines: 3,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên tóm tắt';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextInput(
                controller: _tenDayDuController,
                minLines: 6,
                maxLines: 6,
                isRequired: true,
                label: 'Tên đầy đủ vụ án/vụ việc',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên đầy đủ tên vụ án/vụ việc';
                  }
                  return null;
                },
                hint:
                    'Ví dụ: Vụ án ... xảy ra ngày ... tại ... hoặc Đơn của ông ... tố giác ... xảy ra ngày ... tại ....',
              ),
            ],
          ),
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
