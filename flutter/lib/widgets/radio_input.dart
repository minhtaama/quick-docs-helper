import 'package:flutter/material.dart';

class CustomRadioInput extends StatelessWidget {
  final String label;
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onChanged;
  final IconData? icon;
  final bool isRequired;

  const CustomRadioInput({
    super.key,
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.icon,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(icon, size: 16, color: primaryColor.withValues(alpha: 0.7)),
            ),
          ],
          Text(
            isRequired ? '$label (*):' : '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: primaryColor.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 16,
              children: options.map((option) {
                final isSelected = selectedValue.trim().toLowerCase() == option.trim().toLowerCase();
                return InkWell(
                  onTap: () => onChanged(option),
                  borderRadius: BorderRadius.circular(4.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String>(
                          value: option,
                          groupValue: isSelected ? option : null,
                          onChanged: (val) {
                            if (val != null) onChanged(val);
                          },
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          option,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
