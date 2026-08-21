import 'package:flutter/material.dart';
import '../../../common/quick_action_card.dart';
import '../../custom_docs_page.dart';

/// Widget Thao tác nhanh (Quick Action Card) cho mục Soạn thảo văn bản tùy chỉnh cấp vụ án
class CaseCustomDocsCard extends StatelessWidget {
  final String caseId;
  final Map<String, dynamic> caseData;
  final List<Map<String, dynamic>> customTemplates;
  final bool isLoadingTemplates;
  final double? height;

  const CaseCustomDocsCard({
    super.key,
    required this.caseId,
    required this.caseData,
    required this.customTemplates,
    required this.isLoadingTemplates,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final customDocs = caseData['custom_documents'] as List? ?? [];
    const customDocColor = Color.fromARGB(255, 34, 114, 206);

    return QuickActionCard(
      height: height,
      icon: Icons.note_alt_outlined,
      title: 'Soạn thảo văn bản',
      subtitle: 'Soạn thảo các văn bản theo mẫu, điền thông tin và tải về',
      badge: '${customDocs.length} bản ghi',
      color: customDocColor,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomDocsPage(
              caseId: caseId,
              caseData: caseData,
              isCaseLevel: true,
            ),
          ),
        );
      },
      bottomWidget: customTemplates.isEmpty
          ? (isLoadingTemplates
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Đang tải danh sách mẫu...',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : const Center(
                    child: Text(
                      'Không có mẫu văn bản',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: customTemplates.map((tpl) {
                  final displayName =
                      tpl['display_name'] ?? tpl['file_name'] ?? 'Mẫu';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6.0),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomDocsPage(
                              caseId: caseId,
                              caseData: caseData,
                              isCaseLevel: true,
                              initialTemplateFile: tpl['file_name'],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 7.0,
                        ),
                        decoration: BoxDecoration(
                          color: customDocColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(
                            color: customDocColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_circle_outline,
                              size: 15,
                              color: customDocColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: customDocColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.edit,
                              size: 12,
                              color: customDocColor.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}
