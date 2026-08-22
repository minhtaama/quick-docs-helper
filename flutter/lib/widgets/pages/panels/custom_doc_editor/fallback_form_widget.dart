import 'package:flutter/material.dart';
import '../../../common/text_input.dart';

/// Form dự phòng hiển thị danh sách các field cổ điển khi không nạp được bố cục DOCX
class FallbackFormWidget extends StatelessWidget {
  final List<Map<String, dynamic>> fields;
  final TextEditingController? Function(String varName) getController;

  const FallbackFormWidget({
    super.key,
    required this.fields,
    required this.getController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: fields.map((field) {
        final name = field['name'] as String? ?? '';
        final label = field['label'] as String? ?? name;
        final type = field['type'] as String? ?? 'input_text';
        final ctrl = getController(name);

        if (ctrl != null) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CustomTextInput(
              controller: ctrl,
              label: label,
              minLines: type == 'input_textarea' ? 3 : 1,
              maxLines: type == 'input_textarea' ? 5 : 1,
            ),
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }
}
