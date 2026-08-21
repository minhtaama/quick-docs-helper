import 'package:flutter/material.dart';
import '../../../common/text_input.dart';
import 'editor_utils.dart';

/// Widget Danh sách khối (type: "input_list") - Mỗi lượt là 1 Card, các field con xếp dọc từng dòng riêng biệt
class InlineListSection extends StatefulWidget {
  final String label;
  final List<Map<String, dynamic>> itemSchema;
  final List<Map<String, dynamic>> initialRows;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const InlineListSection({
    super.key,
    required this.label,
    required this.itemSchema,
    required this.initialRows,
    required this.onChanged,
  });

  @override
  State<InlineListSection> createState() => _InlineListSectionState();
}

class _InlineListSectionState extends State<InlineListSection> {
  final List<Map<String, TextEditingController>> _controllers = [];

  @override
  void initState() {
    super.initState();
    for (final row in widget.initialRows) {
      final map = <String, TextEditingController>{};
      for (final col in widget.itemSchema) {
        final cName = col['name'] as String? ?? '';
        final ctrl = TextEditingController(text: row[cName]?.toString() ?? '');
        ctrl.addListener(_notify);
        map[cName] = ctrl;
      }
      _controllers.add(map);
    }
  }

  @override
  void dispose() {
    for (final m in _controllers) {
      for (final c in m.values) {
        c.removeListener(_notify);
        c.dispose();
      }
    }
    super.dispose();
  }

  void _notify() {
    final res = _controllers.map((m) {
      final r = <String, dynamic>{};
      for (final e in m.entries) {
        r[e.key] = e.value.text.trim();
      }
      return r;
    }).toList();
    widget.onChanged(res);
  }

  void _addRow() {
    final map = <String, TextEditingController>{};
    for (final col in widget.itemSchema) {
      final cName = col['name'] as String? ?? '';
      final ctrl = TextEditingController();
      ctrl.addListener(_notify);
      map[cName] = ctrl;
    }
    setState(() {
      _controllers.add(map);
    });
    _notify();
  }

  void _removeRow(int idx) {
    final removed = _controllers.removeAt(idx);
    for (final c in removed.values) {
      c.removeListener(_notify);
      c.dispose();
    }
    setState(() {});
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_controllers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Danh sách "${widget.label}" chưa có dữ liệu',
                    style: TextStyle(
                      fontFamily: 'Times New Roman',
                      fontFamilyFallback: DocEditorUtils.fontFallback,
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Thêm',
                    style: TextStyle(
                      fontFamily: 'Times New Roman',
                      fontFamilyFallback: DocEditorUtils.fontFallback,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: _controllers.asMap().entries.map((entry) {
              final idx = entry.key;
              final ctrlMap = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header của từng lượt
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '# ${idx + 1}',
                                style: TextStyle(
                                  fontFamily: 'Times New Roman',
                                  fontFamilyFallback: DocEditorUtils.fontFallback,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Colors.red.shade400,
                          ),
                          tooltip: 'Xóa',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _removeRow(idx),
                        ),
                      ],
                    ),
                    const Divider(height: 16),

                    // Từng field con hiển thị trên 1 dòng riêng biệt
                    ...widget.itemSchema.map((col) {
                      final cName = col['name'] as String? ?? '';
                      final cLabel = col['label']?.toString() ?? cName;
                      final cType = col['type'] as String? ?? 'text';
                      final cPlaceholder =
                          col['placeholder']?.toString() ??
                          'Nhập ${cLabel.toLowerCase()}...';
                      final ctrl = ctrlMap[cName]!;

                      final bool isMultiLine = cType == 'textarea';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$cLabel:',
                              style: const TextStyle(
                                fontFamily: 'Times New Roman',
                                fontFamilyFallback: DocEditorUtils.fontFallback,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            CustomTextInput(
                              isInline: true,
                              controller: ctrl,
                              label: cLabel,
                              hint: cPlaceholder,
                              minLines: isMultiLine ? 3 : 1,
                              maxLines: isMultiLine ? 9999 : 1,
                              inlineFontSize: 16,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }).toList(),
          ),
        if (_controllers.isNotEmpty)
          FilledButton.tonalIcon(
            onPressed: _addRow,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text(
              'Thêm',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontFamilyFallback: DocEditorUtils.fontFallback,
              ),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
              visualDensity: VisualDensity.compact,
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}
