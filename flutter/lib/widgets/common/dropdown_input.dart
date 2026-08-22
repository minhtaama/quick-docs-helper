import 'package:flutter/material.dart';

/// Component Dropdown dùng chung cho toàn hệ thống, hỗ trợ cả chế độ Form lẫn Inline trong văn bản
class CustomDropdownInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final List<dynamic> options; // Danh sách String hoặc Map {"label": "...", "value": "...", "linked_fields": {...}}
  final bool isInline;
  final double? inlineFontSize;
  final void Function(dynamic selectedItem)? onItemSelected;

  const CustomDropdownInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    required this.options,
    this.isInline = false,
    this.inlineFontSize,
    this.onItemSelected,
  });

  @override
  State<CustomDropdownInput> createState() => _CustomDropdownInputState();
}

class _CustomDropdownInputState extends State<CustomDropdownInput> {
  String _getItemLabel(dynamic item) {
    if (item is Map) {
      return item['label']?.toString() ?? item['value']?.toString() ?? '';
    }
    return item?.toString() ?? '';
  }

  String _getItemValue(dynamic item) {
    if (item is Map) {
      return item['value']?.toString() ?? item['label']?.toString() ?? '';
    }
    return item?.toString() ?? '';
  }

  dynamic _findItemByValue(String val) {
    for (final opt in widget.options) {
      if (_getItemValue(opt) == val) {
        return opt;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final currentValue = widget.controller.text;
        final selectedOpt = _findItemByValue(currentValue);

        if (widget.isInline) {
          final fontSize = widget.inlineFontSize ?? 14.0;
          final displayLabel = selectedOpt != null
              ? _getItemLabel(selectedOpt)
              : (currentValue.isNotEmpty ? currentValue : (widget.hint ?? widget.label));
          final hasValue = currentValue.isNotEmpty;

          return PopupMenuButton<dynamic>(
            tooltip: widget.label,
            padding: EdgeInsets.zero,
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            elevation: 4,
            onSelected: (item) {
              final val = _getItemValue(item);
              widget.controller.text = val;
              widget.onItemSelected?.call(item);
            },
            itemBuilder: (context) {
              return widget.options.map((opt) {
                final optVal = _getItemValue(opt);
                final optLabel = _getItemLabel(opt);
                final isSelected = optVal == currentValue;

                return PopupMenuItem<dynamic>(
                  value: opt,
                  height: 38,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(Icons.check, size: 16, color: primaryColor),
                          )
                        else
                          const SizedBox(width: 24),
                        Flexible(
                          child: Text(
                            optLabel,
                            style: TextStyle(
                              fontFamily: 'Times New Roman',
                              fontFamilyFallback: const ['Times New Roman', 'Times', 'serif'],
                              fontSize: fontSize,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? primaryColor : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade400,
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      displayLabel,
                      style: TextStyle(
                        fontFamily: 'Times New Roman',
                        fontFamilyFallback: const ['Times New Roman', 'Times', 'serif'],
                        fontSize: fontSize,
                        fontWeight: FontWeight.normal,
                        color: hasValue ? Colors.black87 : Colors.grey.shade400,
                        height: 1.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          );
        }

        // Chế độ Form thông thường
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<dynamic>(
                  isExpanded: true,
                  value: selectedOpt,
                  hint: Text(
                    widget.hint ?? 'Chọn ${widget.label}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                  items: widget.options.map((opt) {
                    return DropdownMenuItem<dynamic>(
                      value: opt,
                      child: Text(
                        _getItemLabel(opt),
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (item) {
                    if (item != null) {
                      final val = _getItemValue(item);
                      widget.controller.text = val;
                      widget.onItemSelected?.call(item);
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
