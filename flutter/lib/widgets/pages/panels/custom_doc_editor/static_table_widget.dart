import 'package:flutter/material.dart';
import 'paragraph_widget.dart';

/// Widget hiển thị Bảng tĩnh (static_table) giữ nguyên bố cục hàng/cột từ Word
class StaticTableWidget extends StatelessWidget {
  final Map<String, dynamic> element;
  final TextEditingController? Function(String varName) getController;
  final Map<String, dynamic>? caseData;
  final Map<String, dynamic>? person;
  final VoidCallback? onContentChanged;

  const StaticTableWidget({
    super.key,
    required this.element,
    required this.getController,
    this.caseData,
    this.person,
    this.onContentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasBorder = element['has_border'] as bool? ?? false;
    final rows = (element['rows'] as List?)
            ?.map((r) => Map<String, dynamic>.from(r as Map))
            .toList() ??
        [];

    if (rows.isEmpty) return const SizedBox.shrink();

    // Đối với bảng ẩn outline thì hiển thị outline dạng mờ (alpha = 0.2)
    final borderColor = hasBorder
        ? Colors.black87
        : Colors.black.withValues(alpha: 0.2);

    final firstRowCells = (rows.first['cells'] as List?)
            ?.map((c) => Map<String, dynamic>.from(c as Map))
            .toList() ??
        [];

    final columnWidthMap = <int, TableColumnWidth>{};
    for (int i = 0; i < firstRowCells.length; i++) {
      final ratio = (firstRowCells[i]['width_ratio'] as num?)?.toDouble() ??
          (1.0 / (firstRowCells.isNotEmpty ? firstRowCells.length : 1));
      columnWidthMap[i] = FlexColumnWidth(ratio > 0 ? ratio : 1.0);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Table(
        border: TableBorder.all(
          color: borderColor,
          width: 0.5,
          style: BorderStyle.solid,
        ),
        columnWidths: columnWidthMap,
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: rows.map((r) {
          final cells = (r['cells'] as List?)
                  ?.map((c) => Map<String, dynamic>.from(c as Map))
                  .toList() ??
              [];

          return TableRow(
            children: cells.map((cell) {
              final paras = (cell['paragraphs'] as List?)
                      ?.map((p) => Map<String, dynamic>.from(p as Map))
                      .toList() ??
                  [];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 4.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: paras
                      .map((p) => DocParagraphWidget(
                            element: p,
                            getController: getController,
                            caseData: caseData,
                            person: person,
                            onContentChanged: onContentChanged,
                          ))
                      .toList(),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
