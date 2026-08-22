import 'package:flutter/material.dart';
import 'app_button.dart';
import 'dropdown_input.dart';
import 'text_input.dart';

class CustomFieldsDialog extends StatefulWidget {
  final String templateDisplayName;
  final String templateFileName;
  final String initialTitle;
  final List<Map<String, dynamic>> fields;
  final Map<String, dynamic> initialValues;
  final List<Map<String, dynamic>> availablePersons;

  const CustomFieldsDialog({
    super.key,
    required this.templateDisplayName,
    required this.templateFileName,
    this.initialTitle = '',
    required this.fields,
    required this.initialValues,
    this.availablePersons = const [],
  });

  @override
  State<CustomFieldsDialog> createState() => _CustomFieldsDialogState();
}

class _CustomFieldsDialogState extends State<CustomFieldsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, dynamic> _complexValues = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialTitle.isNotEmpty
          ? widget.initialTitle
          : widget.templateDisplayName,
    );

    for (final field in widget.fields) {
      final name = field['name'] as String? ?? '';
      final type = field['type'] as String? ?? 'input_text';
      final initVal = widget.initialValues[name];

      if (type == 'input_table' || type == 'input_list' || type == 'input_persons') {
        if (initVal is List) {
          _complexValues[name] = List.from(initVal);
        } else {
          _complexValues[name] = [];
        }
      } else {
        _textControllers[name] = TextEditingController(
          text: initVal?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final resultFields = <String, dynamic>{};
      for (final entry in _textControllers.entries) {
        resultFields[entry.key] = entry.value.text.trim();
      }
      for (final entry in _complexValues.entries) {
        resultFields[entry.key] = entry.value;
      }

      Navigator.of(context).pop({
        'title': _titleController.text.trim(),
        'custom_fields': resultFields,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.edit_document, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Điền thông tin: ${widget.templateDisplayName}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.templateFileName,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 620, maxWidth: 720),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                CustomTextInput(
                  controller: _titleController,
                  label: 'Tiêu đề bản ghi / tên biên bản',
                  isRequired: true,
                  icon: Icons.title_rounded,
                  hint: 'Ví dụ: Biên bản làm việc ngày 19/08...',
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Vui lòng nhập tiêu đề biên bản'
                      : null,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                ...widget.fields.map((field) => _buildFieldWidget(field)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        AppButton.text(
          onPressed: () => Navigator.of(context).pop(),
          label: 'Hủy',
        ),
        const SizedBox(width: 8),
        AppButton.primary(
          onPressed: _onSave,
          icon: Icons.save_outlined,
          label: 'Lưu thông tin',
        ),
      ],
    );
  }

  Widget _buildFieldWidget(Map<String, dynamic> field) {
    final name = field['name'] as String? ?? '';
    final label = field['label'] as String? ?? name;
    final type = field['type'] as String? ?? 'input_text';
    final placeholder = field['placeholder'] as String? ?? '';

    switch (type) {
      case 'input_textarea':
        final controller = _textControllers[name]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CustomTextInput(
            controller: controller,
            label: label,
            hint: placeholder.isNotEmpty ? placeholder : 'Nhập nội dung...',
            minLines: 3,
            maxLines: 5,
          ),
        );

      case 'input_date':
        final controller = _textControllers[name]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _CommonDateField(
            label: label,
            controller: controller,
            hint: placeholder.isNotEmpty ? placeholder : 'dd/mm/yyyy',
          ),
        );

      case 'input_dropdown':
        final controller = _textControllers[name]!;
        final options = (field['options'] as List?) ?? [];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CustomDropdownInput(
            controller: controller,
            label: label,
            hint: placeholder.isNotEmpty ? placeholder : null,
            options: options,
          ),
        );

      case 'input_persons':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _PersonsField(
            label: label,
            availablePersons: widget.availablePersons,
            selectedPersonIds: List<String>.from(_complexValues[name] ?? []),
            onChanged: (selectedIds) => _complexValues[name] = selectedIds,
          ),
        );

      case 'input_table':
      case 'input_list':
        final itemSchema = (field['item_schema'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _TableField(
            label: label,
            itemSchema: itemSchema,
            initialRows: List<Map<String, dynamic>>.from(
              (_complexValues[name] as List?)?.map(
                    (e) => Map<String, dynamic>.from(e as Map),
                  ) ??
                  [],
            ),
            onChanged: (rows) => _complexValues[name] = rows,
          ),
        );

      case 'input_text':
      default:
        final controller = _textControllers[name]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CustomTextInput(
            controller: controller,
            label: label,
            hint: placeholder.isNotEmpty ? placeholder : null,
            minLines: 1,
            maxLines: 1,
          ),
        );
    }
  }
}

/// Widget Date Picker sử dụng giao diện đồng bộ với CustomTextInput
class _CommonDateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _CommonDateField({
    required this.label,
    required this.controller,
    this.hint = 'dd/mm/yyyy',
  });

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    DateTime initial = now;
    if (controller.text.isNotEmpty) {
      final parts = controller.text.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          initial = DateTime(y, m, d);
        }
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('vi', 'VN'),
    );

    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      controller.text = formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        CustomTextInput(
          controller: controller,
          label: label,
          hint: hint,
          icon: Icons.calendar_today_outlined,
        ),
        Positioned(
          right: 6,
          top: 8,
          child: IconButton(
            icon: Icon(Icons.event_note, color: primaryColor, size: 20),
            tooltip: 'Chọn ngày từ lịch',
            onPressed: () => _pickDate(context),
          ),
        ),
      ],
    );
  }
}

/// Widget cho trường Persons (Chọn nhiều đối tượng)
class _PersonsField extends StatefulWidget {
  final String label;
  final List<Map<String, dynamic>> availablePersons;
  final List<String> selectedPersonIds;
  final ValueChanged<List<String>> onChanged;

  const _PersonsField({
    required this.label,
    required this.availablePersons,
    required this.selectedPersonIds,
    required this.onChanged,
  });

  @override
  State<_PersonsField> createState() => _PersonsFieldState();
}

class _PersonsFieldState extends State<_PersonsField> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List<String>.from(widget.selectedPersonIds);
  }

  void _showSelectDialog() {
    final tempSelected = Set<String>.from(_selectedIds);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          return AlertDialog(
            title: Text('Chọn đối tượng: ${widget.label}'),
            content: SizedBox(
              width: 480,
              height: 380,
              child: widget.availablePersons.isEmpty
                  ? const Center(
                      child: Text('Chưa có đối tượng nào trong hồ sơ vụ án'),
                    )
                  : ListView.builder(
                      itemCount: widget.availablePersons.length,
                      itemBuilder: (context, index) {
                        final person = widget.availablePersons[index];
                        final id = person['id']?.toString() ?? '';
                        final hoTen = person['ho_ten']?.toString() ?? 'Không rõ';
                        final cccd = person['cccd']?.toString() ?? '';
                        final isSelected = tempSelected.contains(id);

                        return CheckboxListTile(
                          value: isSelected,
                          activeColor: theme.colorScheme.primary,
                          title: Text(
                            hoTen,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            cccd.isNotEmpty ? 'CCCD: $cccd' : 'Chưa có CCCD',
                          ),
                          secondary: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                            foregroundColor: theme.colorScheme.primary,
                            child: Text(hoTen.isNotEmpty ? hoTen[0] : '?'),
                          ),
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                tempSelected.add(id);
                              } else {
                                tempSelected.remove(id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            actions: [
              AppButton.text(
                onPressed: () => Navigator.of(ctx).pop(),
                label: 'Hủy',
              ),
              const SizedBox(width: 8),
              AppButton.primary(
                onPressed: () {
                  setState(() {
                    _selectedIds = tempSelected.toList();
                  });
                  widget.onChanged(_selectedIds);
                  Navigator.of(ctx).pop();
                },
                label: 'Xác nhận',
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: primaryColor,
                ),
              ),
              AppButton.outlined(
                onPressed: _showSelectDialog,
                icon: Icons.person_add_alt_1,
                label: 'Chọn người',
                isCompact: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedIds.isEmpty)
            Text(
              'Chưa chọn người nào (bấm "Chọn người" ở trên)',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _selectedIds.map((id) {
                final matched = widget.availablePersons.firstWhere(
                  (p) => p['id']?.toString() == id,
                  orElse: () => {'ho_ten': id},
                );
                final name = matched['ho_ten']?.toString() ?? id;

                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: primaryColor.withValues(alpha: 0.15),
                    foregroundColor: primaryColor,
                    child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(fontSize: 11)),
                  ),
                  label: Text(name, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() {
                      _selectedIds.remove(id);
                    });
                    widget.onChanged(_selectedIds);
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

/// Widget cho trường Table / List động với CustomTextInput
class _TableField extends StatefulWidget {
  final String label;
  final List<Map<String, dynamic>> itemSchema;
  final List<Map<String, dynamic>> initialRows;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const _TableField({
    required this.label,
    required this.itemSchema,
    required this.initialRows,
    required this.onChanged,
  });

  @override
  State<_TableField> createState() => _TableFieldState();
}

class _TableFieldState extends State<_TableField> {
  final List<Map<String, TextEditingController>> _rowControllers = [];

  @override
  void initState() {
    super.initState();
    for (final row in widget.initialRows) {
      final ctrlMap = <String, TextEditingController>{};
      for (final col in widget.itemSchema) {
        final colName = col['name'] as String? ?? '';
        ctrlMap[colName] = TextEditingController(text: row[colName]?.toString() ?? '');
      }
      _rowControllers.add(ctrlMap);
    }
  }

  @override
  void dispose() {
    for (final rowMap in _rowControllers) {
      for (final ctrl in rowMap.values) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  void _notifyChange() {
    final rowsData = _rowControllers.map((rowMap) {
      final map = <String, dynamic>{};
      for (final entry in rowMap.entries) {
        map[entry.key] = entry.value.text.trim();
      }
      return map;
    }).toList();
    widget.onChanged(rowsData);
  }

  void _addRow() {
    final ctrlMap = <String, TextEditingController>{};
    for (final col in widget.itemSchema) {
      final colName = col['name'] as String? ?? '';
      ctrlMap[colName] = TextEditingController();
    }
    setState(() {
      _rowControllers.add(ctrlMap);
    });
    _notifyChange();
  }

  void _deleteRow(int index) {
    final removed = _rowControllers.removeAt(index);
    for (final ctrl in removed.values) {
      ctrl.dispose();
    }
    setState(() {});
    _notifyChange();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: primaryColor,
                ),
              ),
              AppButton.tonal(
                onPressed: _addRow,
                icon: Icons.add,
                label: 'Thêm dòng',
                isCompact: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_rowControllers.isEmpty)
            Text(
              'Chưa có dữ liệu nào trong bảng này. Bấm "Thêm dòng" để nhập.',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _rowControllers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final rowMap = _rowControllers[index];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Dòng #${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const Spacer(),
                          AppIconButton(
                            icon: Icons.delete_outline,
                            isDanger: true,
                            onPressed: () => _deleteRow(index),
                            tooltip: 'Xóa dòng này',
                            size: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...widget.itemSchema.map((col) {
                        final colName = col['name'] as String? ?? '';
                        final colLabel = col['label'] as String? ?? colName;
                        final colType = col['type'] as String? ?? 'text';
                        final ctrl = rowMap[colName]!;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CustomTextInput(
                            controller: ctrl,
                            label: colLabel,
                            minLines: colType == 'textarea' ? 2 : 1,
                            maxLines: colType == 'textarea' ? 3 : 1,
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

