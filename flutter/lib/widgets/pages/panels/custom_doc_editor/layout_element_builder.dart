import 'package:flutter/material.dart';
import 'inline_list_section.dart';
import 'inline_persons_section.dart';
import 'inline_table_section.dart';
import 'paragraph_widget.dart';
import 'static_table_widget.dart';

/// Widget trung gian phân phối và hiển thị từng phần tử trên tờ A4 theo element type
class LayoutElementBuilder extends StatelessWidget {
  final Map<String, dynamic> element;
  final TextEditingController? Function(String varName) getController;
  final Map<String, dynamic> complexValues;
  final List<Map<String, dynamic>> availablePersons;
  final Map<String, dynamic>? caseData;
  final Map<String, dynamic>? person;
  final void Function(String name, dynamic value) onComplexValueChanged;
  final VoidCallback onContentChanged;

  const LayoutElementBuilder({
    super.key,
    required this.element,
    required this.getController,
    required this.complexValues,
    required this.availablePersons,
    this.caseData,
    this.person,
    required this.onComplexValueChanged,
    required this.onContentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final type = element['type'] as String? ?? 'spacer';

    switch (type) {
      case 'spacer':
        final h = (element['height'] as num?)?.toDouble() ?? 0.0;
        return SizedBox(height: h);

      case 'paragraph':
        return DocParagraphWidget(
          element: element,
          getController: getController,
          caseData: caseData,
          person: person,
          onContentChanged: onContentChanged,
        );

      case 'case_persons_loop':
        final rawParagraphs =
            (element['paragraphs'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];
        final persons = availablePersons.isNotEmpty
            ? availablePersons
            : ((caseData?['con_nguoi_list'] as List?)
                    ?.map((e) => Map<String, dynamic>.from(e as Map))
                    .toList() ??
                [<String, dynamic>{}]);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: persons.asMap().entries.map((entry) {
            final pIdx = entry.key;
            final pData = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: rawParagraphs.map((pEl) {
                return DocParagraphWidget(
                  element: pEl,
                  getController: getController,
                  caseData: caseData,
                  person: pData,
                  loopIndex: pIdx + 1,
                  onContentChanged: onContentChanged,
                );
              }).toList(),
            );
          }).toList(),
        );

      case 'static_table':
        return StaticTableWidget(
          element: element,
          getController: getController,
          caseData: caseData,
          person: person,
          onContentChanged: onContentChanged,
        );

      case 'input_persons':
      case 'persons':
      case 'persons_section':
        final name = element['name'] as String? ?? '';
        final fieldInfo = Map<String, dynamic>.from(
          element['field_info'] as Map? ?? {},
        );
        final label =
            fieldInfo['label'] as String? ??
            (name.isNotEmpty ? name : '<Không có dữ liệu label>');
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: InlinePersonsSection(
            label: label,
            availablePersons: availablePersons,
            selectedPersonIds: List<String>.from(complexValues[name] ?? []),
            onChanged: (ids) {
              onComplexValueChanged(name, ids);
            },
          ),
        );

      case 'input_list':
      case 'list':
        final name = element['name'] as String? ?? '';
        final fieldInfo = Map<String, dynamic>.from(
          element['field_info'] as Map? ?? {},
        );
        final label =
            fieldInfo['label'] as String? ??
            (name.isNotEmpty ? name : '<Không có dữ liệu label>');
        final itemSchema =
            (fieldInfo['item_schema'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: InlineListSection(
            label: label,
            itemSchema: itemSchema,
            initialRows: List<Map<String, dynamic>>.from(
              (complexValues[name] as List?)?.map(
                    (e) => Map<String, dynamic>.from(e as Map),
                  ) ??
                  [],
            ),
            onChanged: (rows) {
              onComplexValueChanged(name, rows);
            },
          ),
        );

      case 'input_table':
      case 'table':
        final name = element['name'] as String? ?? '';
        final fieldInfo = Map<String, dynamic>.from(
          element['field_info'] as Map? ?? {},
        );
        final label =
            fieldInfo['label'] as String? ??
            (name.isNotEmpty ? name : '<Không có dữ liệu label>');
        final itemSchema =
            (fieldInfo['item_schema'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: InlineTableSection(
            label: label,
            itemSchema: itemSchema,
            initialRows: List<Map<String, dynamic>>.from(
              (complexValues[name] as List?)?.map(
                    (e) => Map<String, dynamic>.from(e as Map),
                  ) ??
                  [],
            ),
            onChanged: (rows) {
              onComplexValueChanged(name, rows);
            },
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
