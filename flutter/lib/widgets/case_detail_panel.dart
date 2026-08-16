import 'dart:convert';
import '../services/api_service.dart';
import 'package:flutter/material.dart';

class CaseDetailPanel extends StatelessWidget {
  final Map<String, dynamic>? caseData;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onAddPersonPressed;
  final VoidCallback? onEditCasePressed;
  final Function(Map<String, dynamic> person)? onEditPersonPressed;
  final Future<void> Function(String personId, String hoTen)? onDownloadDocx;
  final Future<void> Function(String personId, String hoTen)? onDeletePerson;

  const CaseDetailPanel({
    super.key,
    required this.caseData,
    this.isLoading = false,
    required this.onRefresh,
    required this.onAddPersonPressed,
    this.onEditCasePressed,
    this.onEditPersonPressed,
    this.onDownloadDocx,
    this.onDeletePerson,
  });

  void _confirmDeletePerson(
    BuildContext context,
    String personId,
    String hoTen,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'ĐTV có chắc chắn muốn xóa đối tượng "$hoTen" khỏi vụ án này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (onDeletePerson != null) {
                await onDeletePerson!(personId, hoTen);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (caseData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: primaryColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Chọn hoặc tạo một vụ án để xem thông tin chi tiết',
              style: TextStyle(
                fontSize: 16,
                color: primaryColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    final tenVu = caseData!['ten_vu'] ?? 'Chưa đặt tên';
    final moTa = caseData!['mo_ta'] ?? '';
    final personList = caseData!['con_nguoi_list'] as List? ?? [];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Vụ Án
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.folder_special,
                            color: primaryColor,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tenVu,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (moTa.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          moTa,
                          style: TextStyle(
                            fontSize: 14,
                            color: primaryColor.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onEditCasePressed != null) ...[
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: primaryColor,
                    ),
                    tooltip: 'Sửa tên / mô tả vụ việc',
                    onPressed: onEditCasePressed,
                  ),
                  const SizedBox(width: 8),
                ],
                FilledButton.icon(
                  onPressed: onAddPersonPressed,
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Thêm Đối Tượng'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Header Danh sách con người
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DANH SÁCH ĐỐI TƯỢNG/BỊ CAN TRONG VỤ ÁN (${personList.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor.withValues(alpha: 0.8),
                  letterSpacing: 0.5,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Làm mới danh sách',
                onPressed: onRefresh,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Danh sách đối tượng
          Expanded(
            child: personList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có đối tượng/bị can nào trong vụ án này.',
                          style: TextStyle(
                            fontSize: 14,
                            color: primaryColor.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: onAddPersonPressed,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm đối tượng/bị can đầu tiên'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: personList.length,
                    itemBuilder: (context, index) {
                      final item = personList[index];
                      if (item == null) return const SizedBox.shrink();
                      final caseId = caseData?['id'] ?? '';
                      final person = Map<String, dynamic>.from(item as Map);
                      final personId = person['id'] ?? '';
                      final hoTen = person['ho_ten'] ?? 'Chưa đặt tên';
                      final gioiTinh = person['gioi_tinh'] ?? '';
                      final namSinh = person['nam_sinh'] ?? '';
                      final cccd = person['cccd'] ?? '';
                      final thuongTru =
                          person['noi_thuong_tru'] ??
                          person['noi_o_hien_tai'] ??
                          '';

                      final imagePath = person['image_path'] ?? '';
                      final bool hasImage =
                          imagePath.toString().isNotEmpty &&
                          caseId.toString().isNotEmpty &&
                          personId.toString().isNotEmpty;
                      final String imageUrl = hasImage
                          ? '${ApiService.baseUrl}/api/v1/cases/$caseId/persons/$personId/image?t=${DateTime.now().millisecondsSinceEpoch}'
                          : '';

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          side: BorderSide(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4.0),
                                child: Container(
                                  width: 40 * 2.5,
                                  height: 60 * 2.5,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4.0),
                                    border: Border.all(
                                      color: theme.colorScheme.outline
                                          .withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: hasImage
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                                    Icons.person,
                                                    color: primaryColor
                                                        .withValues(alpha: 0.6),
                                                  ),
                                        )
                                      : Center(
                                          child: Text(
                                            hoTen.isNotEmpty
                                                ? hoTen
                                                      .substring(0, 1)
                                                      .toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          hoTen,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (gioiTinh.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withValues(
                                                alpha: 0.08,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              gioiTinh,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (namSinh.isNotEmpty)
                                          Text(
                                            'Năm sinh: $namSinh',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: primaryColor.withValues(
                                                alpha: 0.7,
                                              ),
                                            ),
                                          ),
                                        if (namSinh.isNotEmpty &&
                                            cccd.isNotEmpty)
                                          Text(
                                            '  •  ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: primaryColor.withValues(
                                                alpha: 0.4,
                                              ),
                                            ),
                                          ),
                                        if (cccd.isNotEmpty)
                                          Text(
                                            'CCCD: $cccd',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: primaryColor.withValues(
                                                alpha: 0.7,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (thuongTru.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Thường trú: $thuongTru',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: primaryColor.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (onEditPersonPressed != null) ...[
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: primaryColor,
                                      ),
                                      tooltip: 'Sửa thông tin đối tượng',
                                      onPressed: () =>
                                          onEditPersonPressed!(person),
                                    ),
                                  ],
                                  if (onDownloadDocx != null) ...[
                                    FilledButton.icon(
                                      onPressed: () =>
                                          onDownloadDocx!(personId, hoTen),
                                      icon: const Icon(
                                        Icons.description,
                                        size: 16,
                                      ),
                                      label: const Text('Xuất Word'),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ],
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent.withValues(
                                        alpha: 0.8,
                                      ),
                                      size: 20,
                                    ),
                                    tooltip: 'Xóa đối tượng',
                                    onPressed: () => _confirmDeletePerson(
                                      context,
                                      personId,
                                      hoTen,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
