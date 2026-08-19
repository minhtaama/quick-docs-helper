import 'package:flutter/material.dart';

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

    return Container(
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

                return Card(
                  elevation: isSelected ? 2 : 0,
                  margin: const EdgeInsets.only(bottom: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: BorderSide(
                      color: isSelected
                          ? primaryColor
                          : theme.colorScheme.outline.withValues(
                              alpha: 0.15,
                            ),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  color: isSelected
                      ? theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5)
                      : theme.colorScheme.surface,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8.0),
                    onTap: () => onSelectTemplate(tpl),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor
                                  : primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
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
                    ),
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
