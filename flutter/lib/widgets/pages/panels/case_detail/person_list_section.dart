import 'package:flutter/material.dart';
import '../../../common/app_button.dart';
import 'person_card.dart';

/// Widget hiển thị danh sách dạng lưới responsive cho từng nhóm người (Đối tượng hoặc Người liên quan)
class PersonListSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color primaryColor;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback? onAddPressed;
  final List<dynamic> personList;
  final String caseId;
  final String updatedAt;
  final Function(Map<String, dynamic> person)? onEditPerson;
  final Function(String personId, String hoTen)? onDeletePerson;

  const PersonListSection({
    super.key,
    required this.title,
    required this.icon,
    required this.primaryColor,
    required this.buttonLabel,
    required this.buttonIcon,
    this.onAddPressed,
    required this.personList,
    required this.caseId,
    required this.updatedAt,
    this.onEditPerson,
    this.onDeletePerson,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$title (${personList.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor.withValues(alpha: 0.9),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AppButton.outlined(
              icon: buttonIcon,
              label: buttonLabel,
              onPressed: onAddPressed,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (personList.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final isTwoColumns = constraints.maxWidth >= 850;
              final cardWidth = isTwoColumns
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: personList.map((item) {
                  if (item == null) return const SizedBox.shrink();
                  final person = Map<String, dynamic>.from(item as Map);

                  return SizedBox(
                    width: cardWidth,
                    child: PersonCard(
                      caseId: caseId,
                      person: person,
                      updatedAt: updatedAt,
                      primaryColor: primaryColor,
                      onEditPerson: onEditPerson,
                      onDeletePerson: onDeletePerson,
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }
}
