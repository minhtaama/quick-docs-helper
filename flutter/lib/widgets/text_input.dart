import 'package:flutter/material.dart';

class CustomTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool isRequired;
  final String? Function(String?)? validator;

  const CustomTextInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.isRequired = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator:
          validator ??
          (isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập $label';
                  }
                  return null;
                }
              : null),
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: isRequired ? '$label (*)' : label,
        labelStyle: const TextStyle(fontSize: 14),
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
        prefixIcon: icon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 10, right: 8),
                child: Icon(icon, size: 16),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
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
    );
  }
}
