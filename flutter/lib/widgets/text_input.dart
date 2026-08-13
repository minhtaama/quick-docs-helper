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
      validator: validator ??
          (isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập $label';
                  }
                  return null;
                }
              : null),
      decoration: InputDecoration(
        labelText: isRequired ? '$label (*)' : label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
