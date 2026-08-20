import 'package:flutter/material.dart';
import '../../common/app_button.dart';
import '../../common/app_card.dart';
import '../../common/app_container.dart';

/// Sidebar danh sách các biên bản tùy biến bên trái trong CustomDocsPage
class CustomDocSidebar extends StatelessWidget {
  final List<Map<String, dynamic>> customDocs;
  final Map<String, dynamic>? selectedDoc;
  final ValueChanged<Map<String, dynamic>> onSelectDoc;
  final VoidCallback onCreateNewDoc;
  final ValueChanged<Map<String, dynamic>> onDeleteDoc;
  final bool isCreatingNew;
  final String? activeTemplateTitle;

  const CustomDocSidebar({
    super.key,
    required this.customDocs,
    required this.selectedDoc,
    required this.onSelectDoc,
    required this.onCreateNewDoc,
    required this.onDeleteDoc,
    this.isCreatingNew = false,
    this.activeTemplateTitle,
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
            child: AppButton.primary(
              onPressed: onCreateNewDoc,
              icon: Icons.add,
              label: 'Tạo biên bản mới',
              isFullWidth: true,
              height: 40,
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
            ),
          ),
          if (isCreatingNew) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: AppContainer(
                padding: const EdgeInsets.all(10),
                color: primaryColor.withValues(alpha: 0.1),
                borderColor: primaryColor,
                borderWidth: 1.5,
                borderRadius: 8,
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_document,
                      size: 20,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ĐANG SOẠN THẢO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeTemplateTitle ?? 'Biên bản mới',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'DANH SÁCH BIÊN BẢN ĐÃ TẠO (${customDocs.length})',
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
            child: customDocs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            size: 48,
                            color: theme.iconTheme.color?.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có biên bản tùy biến nào được tạo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bấm "Tạo biên bản mới" ở trên để bắt đầu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: customDocs.length,
                    itemBuilder: (context, index) {
                      final doc = customDocs[index];
                      final isSelected = !isCreatingNew && selectedDoc?['id'] == doc['id'];
                      final title =
                          doc['title'] as String? ?? 'Biên bản chưa đặt tên';
                      final createdAt = doc['created_at'] as String? ?? '';

                      return AppCard(
                        isSelected: isSelected,
                        onTap: () => onSelectDoc(doc),
                        child: Row(
                          children: [
                            AppContainer.iconBox(
                              color: isSelected
                                  ? primaryColor
                                  : primaryColor.withValues(alpha: 0.08),
                              child: Icon(
                                Icons.article,
                                color: isSelected ? Colors.white : primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 13.5,
                                      color: isSelected
                                          ? primaryColor
                                          : theme.textTheme.bodyMedium?.color,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    createdAt.isNotEmpty
                                        ? 'Cập nhật: $createdAt'
                                        : 'Văn bản tùy biến',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: theme.iconTheme.color?.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              hoverColor: Colors.red.withValues(alpha: 0.1),
                              splashRadius: 16,
                              tooltip: 'Xóa biên bản',
                              onPressed: () => onDeleteDoc(doc),
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
