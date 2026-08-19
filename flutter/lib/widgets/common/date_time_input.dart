import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'floating_error_tooltip.dart';

class DateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll('/', '');
    if (text.length > 8) text = text.substring(0, 8);

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }

    final String formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class DateTimeInput extends StatefulWidget {
  final String label;
  final String? hint;
  final IconData? icon;
  final bool isRequired;
  final TextEditingController? dayController;
  final TextEditingController? monthController;
  final TextEditingController? yearController;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool isInline;
  final double? inlineFontSize;

  const DateTimeInput({
    super.key,
    required this.label,
    this.hint = 'dd/mm/yyyy (vd: 15081995)',
    this.icon = Icons.calendar_today,
    this.isRequired = false,
    this.dayController,
    this.monthController,
    this.yearController,
    this.controller,
    this.validator,
    this.isInline = false,
    this.inlineFontSize,
  });

  @override
  State<DateTimeInput> createState() => _DateTimeInputState();
}

class _DateTimeInputState extends State<DateTimeInput> {
  late TextEditingController _displayController;
  final FocusNode _focusNode = FocusNode();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    String initialText = '';
    if (widget.controller != null && widget.controller!.text.isNotEmpty) {
      initialText = widget.controller!.text;
    } else {
      final d = widget.dayController?.text.trim() ?? '';
      final m = widget.monthController?.text.trim() ?? '';
      final y = widget.yearController?.text.trim() ?? '';

      if (d.isNotEmpty || m.isNotEmpty || y.isNotEmpty) {
        final formattedD = d.isNotEmpty ? d.padLeft(2, '0') : '';
        final formattedM = m.isNotEmpty ? m.padLeft(2, '0') : '';
        if (formattedD.isNotEmpty && formattedM.isNotEmpty && y.isNotEmpty) {
          initialText = '$formattedD/$formattedM/$y';
        } else if (formattedD.isNotEmpty && formattedM.isNotEmpty) {
          initialText = '$formattedD/$formattedM/';
        } else if (formattedD.isNotEmpty) {
          initialText = '$formattedD/';
        }
      }
    }

    _displayController = TextEditingController(text: initialText);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _displayController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _validate();
    } else {
      if (_errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
      }
    }
  }

  String? _runValidator(String? value) {
    if (widget.validator != null) {
      return widget.validator!(value);
    }
    if (widget.isRequired) {
      if (value == null || value.trim().isEmpty) {
        return 'Vui lòng nhập ${widget.label}';
      }
    }
    if (value != null && value.trim().isNotEmpty) {
      final digits = value.replaceAll('/', '');
      if (digits.length < 8) {
        return 'Vui lòng nhập đủ 8 chữ số (dd/mm/yyyy)';
      }
      final day = int.tryParse(digits.substring(0, 2)) ?? 0;
      final month = int.tryParse(digits.substring(2, 4)) ?? 0;
      final year = int.tryParse(digits.substring(4, 8)) ?? 0;
      if (day < 1 ||
          day > 31 ||
          month < 1 ||
          month > 12 ||
          year < 1900 ||
          year > 2100) {
        return 'Ngày tháng năm không hợp lệ';
      }
    }
    return null;
  }

  void _validate() {
    final error = _runValidator(_displayController.text);
    if (_errorMessage != error) {
      setState(() {
        _errorMessage = error;
      });
    }
  }

  void _onChanged(String value) {
    if (widget.controller != null) {
      widget.controller!.text = value;
    }

    final digits = value.replaceAll('/', '');
    String day = '';
    String month = '';
    String year = '';

    if (digits.length >= 2) {
      day = digits.substring(0, 2);
    } else {
      day = digits;
    }

    if (digits.length >= 4) {
      month = digits.substring(2, 4);
    } else if (digits.length > 2) {
      month = digits.substring(2);
    }

    if (digits.length > 4) {
      year = digits.substring(4);
    }

    if (widget.dayController != null) widget.dayController!.text = day;
    if (widget.monthController != null) widget.monthController!.text = month;
    if (widget.yearController != null) widget.yearController!.text = year;

    if (_errorMessage != null) {
      _validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (widget.isInline) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: 130,
            child: TextFormField(
              controller: _displayController,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              onChanged: _onChanged,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
                DateTextInputFormatter(),
              ],
              validator: (value) {
                final error = _runValidator(value);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _errorMessage != error) {
                    setState(() {
                      _errorMessage = error;
                    });
                  }
                });
                return null;
              },
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontFamilyFallback: const ['Times New Roman', 'Times', 'serif'],
                fontSize: widget.inlineFontSize ?? 14.0,
                fontWeight: FontWeight.normal,
                color: Colors.black87,
                height: 1.1,
              ),
              decoration: InputDecoration(
                hintText: widget.hint ?? widget.label,
                hintStyle: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontFamilyFallback: const [
                    'Times New Roman',
                    'Times',
                    'serif',
                  ],
                  fontSize: widget.inlineFontSize != null
                      ? widget.inlineFontSize! - 1.0
                      : 13.0,
                  color: Colors.grey,
                ),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),

                border: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.grey.shade400,
                    width: 1.0,
                  ),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.grey.shade400,
                    width: 1.0,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
            ),
          ),
          if (_errorMessage != null)
            Positioned(
              top: -34,
              left: 0,
              child: FloatingErrorTooltip(message: _errorMessage!),
            ),
        ],
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        TextFormField(
          controller: _displayController,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          onChanged: _onChanged,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
            DateTextInputFormatter(),
          ],
          validator: (value) {
            final error = _runValidator(value);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _errorMessage != error) {
                setState(() {
                  _errorMessage = error;
                });
              }
            });
            return null;
          },
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            labelText: widget.isRequired ? '${widget.label} (*)' : widget.label,
            alignLabelWithHint: true,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            labelStyle: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.6),
            ),
            floatingLabelStyle: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 1),
            ),
            hintText: widget.hint,
            hintStyle: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.6),
            ),
            prefixIcon: widget.icon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 10, right: 8),
                    child: Icon(widget.icon, size: 16),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4.0),
              borderSide: const BorderSide(width: 1.5),
            ),
            isDense: true,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
        if (_errorMessage != null)
          Positioned(
            top: -38,
            left: 8,
            child: FloatingErrorTooltip(message: _errorMessage!),
          ),
      ],
    );
  }
}
