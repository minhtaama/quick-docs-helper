import 'package:flutter/material.dart';
import 'editor_utils.dart';
import 'fallback_form_widget.dart';
import 'layout_element_builder.dart';

/// Widget biểu diễn tờ giấy trắng A4 chuẩn Word và render toàn bộ nội dung tài liệu
class A4PaperSheet extends StatelessWidget {
  final bool isLoadingLayout;
  final List<Map<String, dynamic>> layoutElements;
  final List<Map<String, dynamic>> fields;
  final TextEditingController? Function(String varName) getController;
  final Map<String, dynamic> complexValues;
  final List<Map<String, dynamic>> availablePersons;
  final Map<String, dynamic>? caseData;
  final Map<String, dynamic>? person;
  final void Function(String name, dynamic value) onComplexValueChanged;
  final VoidCallback onContentChanged;

  const A4PaperSheet({
    super.key,
    required this.isLoadingLayout,
    required this.layoutElements,
    required this.fields,
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
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: 'Times New Roman',
        fontFamilyFallback: DocEditorUtils.fontFallback,
        fontSize: 18.0,
        color: Colors.black,
        height: 1.5,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isLoadingLayout)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Đang nạp cấu trúc tờ văn bản A4...'),
                    ],
                  ),
                ),
              )
            else if (layoutElements.isNotEmpty)
              ...layoutElements.map(
                (el) => LayoutElementBuilder(
                  element: el,
                  getController: getController,
                  complexValues: complexValues,
                  availablePersons: availablePersons,
                  caseData: caseData,
                  person: person,
                  onComplexValueChanged: onComplexValueChanged,
                  onContentChanged: onContentChanged,
                ),
              )
            else
              FallbackFormWidget(
                fields: fields,
                getController: getController,
              ),
          ],
        ),
      ),
    );
  }
}
