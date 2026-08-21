import 'package:flutter/material.dart';
import '../../../common/app_button.dart';
import 'editor_utils.dart';

/// Widget Danh sách người tham gia inline trên tờ giấy A4 (type: "input_persons")
class InlinePersonsSection extends StatelessWidget {
  final String label;
  final List<Map<String, dynamic>> availablePersons;
  final List<String> selectedPersonIds;
  final ValueChanged<List<String>> onChanged;

  const InlinePersonsSection({
    super.key,
    required this.label,
    required this.availablePersons,
    required this.selectedPersonIds,
    required this.onChanged,
  });

  void _showSelectDialog(BuildContext context) {
    final tempSelected = Set<String>.from(selectedPersonIds);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          return AlertDialog(
            title: Text('Chọn đối tượng: $label'),
            content: SizedBox(
              width: 480,
              height: 380,
              child: availablePersons.isEmpty
                  ? const Center(
                      child: Text('Chưa có đối tượng nào trong hồ sơ'),
                    )
                  : ListView.builder(
                      itemCount: availablePersons.length,
                      itemBuilder: (context, index) {
                        final person = availablePersons[index];
                        final id = person['id']?.toString() ?? '';
                        final hoTen =
                            person['ho_ten']?.toString() ?? 'Không rõ';
                        final cccd = person['cccd']?.toString() ?? '';
                        final rawIsdt = person['isdt'];
                        final isdt = rawIsdt == null
                            ? true
                            : (rawIsdt == true ||
                                rawIsdt == 'true' ||
                                rawIsdt == '1' ||
                                rawIsdt == 1);
                        final isSelected = tempSelected.contains(id);

                        return CheckboxListTile(
                          value: isSelected,
                          activeColor: theme.colorScheme.primary,
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  hoTen,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isdt
                                      ? theme.colorScheme.primary.withValues(
                                          alpha: 0.1,
                                        )
                                      : const Color(0xFF00695C).withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isdt ? 'Đối tượng' : 'Người liên quan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isdt
                                        ? theme.colorScheme.primary
                                        : const Color(0xFF00695C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            cccd.isNotEmpty ? 'CCCD: $cccd' : 'Chưa có CCCD',
                          ),
                          secondary: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            foregroundColor: theme.colorScheme.primary,
                            child: Text(hoTen.isNotEmpty ? hoTen[0] : '?'),
                          ),
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                tempSelected.add(id);
                              } else {
                                tempSelected.remove(id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            actions: [
              AppButton.text(
                onPressed: () => Navigator.of(ctx).pop(),
                label: 'Hủy',
              ),
              const SizedBox(width: 8),
              AppButton.primary(
                onPressed: () {
                  onChanged(tempSelected.toList());
                  Navigator.of(ctx).pop();
                },
                label: 'Xác nhận',
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Times New Roman',
                  fontFamilyFallback: DocEditorUtils.fontFallback,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showSelectDialog(context),
                icon: const Icon(Icons.person_add_alt_1, size: 15),
                label: const Text(
                  'Chọn đối tượng',
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontFamilyFallback: DocEditorUtils.fontFallback,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (selectedPersonIds.isEmpty)
            Text(
              'Chưa chọn đối tượng nào (Bấm "Chọn đối tượng" ở trên)',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontFamilyFallback: DocEditorUtils.fontFallback,
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: selectedPersonIds.map((id) {
                final matched = availablePersons.firstWhere(
                  (p) => p['id']?.toString() == id,
                  orElse: () => {'ho_ten': id},
                );
                final name = matched['ho_ten']?.toString() ?? id;
                final cccd = matched['cccd']?.toString() ?? '';

                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: primaryColor.withValues(alpha: 0.15),
                    foregroundColor: primaryColor,
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: const TextStyle(
                        fontFamily: 'Times New Roman',
                        fontFamilyFallback: DocEditorUtils.fontFallback,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  label: Text(
                    cccd.isNotEmpty ? '$name ($cccd)' : name,
                    style: const TextStyle(
                      fontFamily: 'Times New Roman',
                      fontFamilyFallback: DocEditorUtils.fontFallback,
                      fontSize: 14,
                    ),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    final updated = List<String>.from(selectedPersonIds)
                      ..remove(id);
                    onChanged(updated);
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
