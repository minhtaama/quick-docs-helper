import 'package:flutter/material.dart';
import '../../common/app_button.dart';
import '../../common/app_card.dart';
import '../../common/app_container.dart';

/// Sidebar danh sách các văn bản và gói tài liệu (Bundle) bên trái trong CustomDocsPage
class CustomDocSidebar extends StatelessWidget {
  final List<Map<String, dynamic>> customDocs;
  final Map<String, dynamic>? selectedDoc;
  final ValueChanged<Map<String, dynamic>> onSelectDoc;
  final VoidCallback onCreateNewDoc;
  final ValueChanged<Map<String, dynamic>> onDeleteDoc;
  final bool isCreatingNew;
  final String? activeTemplateTitle;
  final List<Map<String, dynamic>> bundles;
  final Map<String, dynamic>? selectedBundle;
  final ValueChanged<Map<String, dynamic>>? onSelectBundle;

  const CustomDocSidebar({
    super.key,
    required this.customDocs,
    required this.selectedDoc,
    required this.onSelectDoc,
    required this.onCreateNewDoc,
    required this.onDeleteDoc,
    this.isCreatingNew = false,
    this.activeTemplateTitle,
    this.bundles = const [],
    this.selectedBundle,
    this.onSelectBundle,
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
              label: 'Tạo văn bản mới',
              isFullWidth: true,
              height: 40,
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
            ),
          ),
          if (bundles.isNotEmpty && onSelectBundle != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: PopupMenuButton<Map<String, dynamic>>(
                tooltip: 'Chọn gói tài liệu cần xuất trọn bộ',
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onSelected: (b) => onSelectBundle!(b),
                itemBuilder: (context) {
                  return bundles.map((b) {
                    final bName = b['name'] as String? ?? 'Bộ tài liệu';
                    final bDesc = b['description'] as String? ?? '';
                    return PopupMenuItem<Map<String, dynamic>>(
                      value: b,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.folder_zip_outlined, size: 18, color: primaryColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  bName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          if (bDesc.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              bDesc,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade400, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.folder_zip, size: 18, color: Colors.amber.shade900),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedBundle != null
                              ? 'Bộ: ${selectedBundle!['name']}'
                              : 'Xuất theo Bộ tài liệu (Bundle)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.amber.shade900),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
                    Icon(Icons.edit_document, size: 20, color: primaryColor),
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
                            activeTemplateTitle ?? 'Văn bản mới',
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
                'DANH SÁCH VĂN BẢN ĐÃ TẠO (${customDocs.length})',
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
                            'Chưa có văn bản nào được tạo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bấm "Tạo văn bản mới" ở trên để bắt đầu.',
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
                      final isSelected =
                          !isCreatingNew && selectedBundle == null && selectedDoc?['id'] == doc['id'];
                      final title =
                          doc['title'] as String? ?? 'Văn bản chưa đặt tên';
                      final createdAt = doc['created_at'] as String? ?? '';
                      final bundleName = doc['bundle_name'] as String?;

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
                                  if (bundleName != null && bundleName.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.blue.shade200, width: 0.5),
                                      ),
                                      child: Text(
                                        'Bộ: $bundleName',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    createdAt.isNotEmpty
                                        ? createdAt
                                        : 'Soạn thảo văn bản',
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
                              tooltip: 'Xóa văn bản',
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
