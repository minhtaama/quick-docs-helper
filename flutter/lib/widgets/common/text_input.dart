import 'package:flutter/material.dart';
import 'floating_error_tooltip.dart';

class CustomTextInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool isRequired;
  final String? Function(String?)? validator;
  final int minLines;
  final int maxLines;
  final bool isInline;
  final double? inlineFontSize;

  const CustomTextInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.isRequired = false,
    this.validator,
    this.minLines = 1,
    this.maxLines = 1,
    this.isInline = false,
    this.inlineFontSize,
  });

  @override
  State<CustomTextInput> createState() => _CustomTextInputState();
}

class _CustomTextInputState extends State<CustomTextInput> {
  final FocusNode _focusNode = FocusNode();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
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
    return null;
  }

  void _validate() {
    final error = _runValidator(widget.controller.text);
    if (_errorMessage != error) {
      setState(() {
        _errorMessage = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (widget.isInline) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
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
              height: 1.3,
            ),
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            decoration: InputDecoration(
              hintText: widget.hint ?? widget.label,
              hintStyle: TextStyle(
                fontFamily: 'Times New Roman',
                fontFamilyFallback: const ['Times New Roman', 'Times', 'serif'],
                fontSize: widget.inlineFontSize != null
                    ? widget.inlineFontSize! - 1.0
                    : 13.0,
                color: Colors.grey.shade400,
              ),

              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 4,
              ),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryColor, width: 1.1),
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

    final bool isMultiLine = widget.minLines > 1 || widget.maxLines > 1;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
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
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            labelText: widget.isRequired ? '${widget.label} (*)' : widget.label,
            floatingLabelStyle: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 1),
            ),
            alignLabelWithHint: true,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            labelStyle: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.6),
            ),
            hintText: widget.hint,
            hintStyle: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.6),
            ),
            prefixIcon: (widget.icon != null && !isMultiLine)
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
