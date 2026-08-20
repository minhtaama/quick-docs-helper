import 'package:flutter/material.dart';
import '../../common/app_card.dart';
import '../../common/app_container.dart';

/// Sidebar danh sách mẫu văn bản bên trái trong ExportDocsPage
class DocTemplateSidebar extends StatelessWidget {
  final List<Map<String, dynamic>> templates;
  final String? selectedTemplateFile;
  final ValueChanged<Map<String, dynamic>> onSelectTemplate;

  const DocTemplateSidebar({
    super.key,
    required this.templates,
    required this.selectedTemplateFile,
    required this.onSelectTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return AppContainer(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'DANH SÁCH VĂN BẢN (${templates.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryColor.withValues(alpha: 0.8),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final tpl = templates[index];
                final fileName = tpl['file_name'] ?? '';
                final displayName =
                    tpl['display_name'] ?? fileName.replaceAll('.docx', '');
                final isSelected = fileName == selectedTemplateFile;

                return AppCard(
                  isSelected: isSelected,
                  onTap: () => onSelectTemplate(tpl),
                  child: Row(
                    children: [
                      AppContainer.iconBox(
                        color: isSelected
                            ? primaryColor
                            : primaryColor.withValues(alpha: 0.08),
                        child: Icon(
                          Icons.description,
                          size: 20,
                          color: isSelected ? Colors.white : primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: primaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: primaryColor,
                          size: 18,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
