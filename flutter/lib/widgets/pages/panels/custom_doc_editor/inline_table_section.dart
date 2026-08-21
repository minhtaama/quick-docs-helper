import 'package:flutter/material.dart';
import '../../../common/text_input.dart';
import 'editor_utils.dart';

/// Widget Bảng kẻ ô tương tác trực tiếp trên tờ giấy A4 (type: "input_table" - chia cột theo các field con)
class InlineTableSection extends StatefulWidget {
  final String label;
  final List<Map<String, dynamic>> itemSchema;
  final List<Map<String, dynamic>> initialRows;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const InlineTableSection({
    super.key,
    required this.label,
    required this.itemSchema,
    required this.initialRows,
    required this.onChanged,
  });

  @override
  State<InlineTableSection> createState() => _InlineTableSectionState();
}

class _InlineTableSectionState extends State<InlineTableSection> {
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
                    'Bảng "${widget.label}" chưa có dữ liệu',
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
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 1),
            ),
            child: Column(
              children: [
                // Header Bảng
                Container(
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        child: const Text(
                          'STT',
                          style: TextStyle(
                            fontFamily: 'Times New Roman',
                            fontFamilyFallback: DocEditorUtils.fontFallback,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      ...widget.itemSchema.map((col) {
                        final colLabel = col['label']?.toString();
                        final colName = col['name']?.toString();
                        final displayLabel =
                            (colLabel != null && colLabel.trim().isNotEmpty)
                            ? colLabel
                            : ((colName != null && colName.trim().isNotEmpty)
                                  ? colName
                                  : '<Không có nhãn cột>');

                        return Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 6,
                            ),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: Colors.black87,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Text(
                              displayLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Times New Roman',
                                fontFamilyFallback: DocEditorUtils.fontFallback,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.black87, thickness: 1),
                // Các hàng dữ liệu
                ..._controllers.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final ctrlMap = entry.value;

                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          alignment: Alignment.center,
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(
                              fontFamily: 'Times New Roman',
                              fontFamilyFallback: DocEditorUtils.fontFallback,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...widget.itemSchema.map((col) {
                          final cName = col['name'] as String? ?? '';
                          final cType = col['type'] as String? ?? 'text';
                          final ctrl = ctrlMap[cName]!;

                          return Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: CustomTextInput(
                                isInline: true,
                                controller: ctrl,
                                label: '',
                                hint: 'Nhập...',
                                minLines: cType == 'textarea' ? 2 : 1,
                                maxLines: cType == 'textarea' ? 3 : 1,
                              ),
                            ),
                          );
                        }),
                        SizedBox(
                          width: 40,
                          child: IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Colors.red.shade400,
                            ),
                            tooltip: 'Xóa dòng',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _removeRow(idx),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        if (_controllers.isNotEmpty) ...[
          const SizedBox(height: 8),
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
      ],
    );
  }
}
