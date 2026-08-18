import '../services/api_service.dart';
import '../export_docs_page.dart';
import 'package:flutter/material.dart';

class CaseDetailPanel extends StatelessWidget {
  final Map<String, dynamic>? caseData;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final VoidCallback onAddPersonPressed;
  final VoidCallback? onEditCasePressed;
  final Function(Map<String, dynamic> person)? onEditPersonPressed;
  final Future<void> Function(String personId, String hoTen)? onDeletePerson;

  const CaseDetailPanel({
    super.key,
    required this.caseData,
    this.isLoading = false,
    this.onRefresh,
    required this.onAddPersonPressed,
    this.onEditCasePressed,
    this.onEditPersonPressed,
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

    final tenDayDu = caseData!['ten_day_du'] ?? '';
    final personList = caseData!['con_nguoi_list'] as List? ?? [];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Vụ Án
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final isHeaderCompact = headerConstraints.maxWidth < 650;

              final titleAndDescription = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tenDayDu.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tên đầy đủ: $tenDayDu',
                      style: TextStyle(
                        fontSize: 16,
                        color: primaryColor.withValues(alpha: 0.75),
                        fontWeight: FontWeight.bold,
                      ),
                      softWrap: true,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              );

              final headerActions = Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () {
                      final caseId = caseData!['id'] ?? '';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExportDocsPage(
                            caseId: caseId,
                            caseData: caseData,
                            isCaseLevel: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('Văn bản chung'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: onAddPersonPressed,
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('Thêm người'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              );

              return Container(
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
                child: isHeaderCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleAndDescription,
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: Container()),
                              headerActions,
                            ],
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: titleAndDescription),
                          const SizedBox(width: 16),
                          headerActions,
                        ],
                      ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Header Danh sách con người
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'DANH SÁCH ĐỐI TƯỢNG/BỊ CAN TRONG VỤ ÁN (${personList.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor.withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            ),
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
                      final ngaySinh =
                          person['ngay_sinh']?.toString().trim() ?? '';
                      final thangSinh =
                          person['thang_sinh']?.toString().trim() ?? '';
                      final namSinh =
                          person['nam_sinh']?.toString().trim() ?? '';
                      final cccd = person['cccd'] ?? '';
                      final thuongTru =
                          person['noi_thuong_tru'] ??
                          person['noi_o_hien_tai'] ??
                          '';

                      String ngaySinhText = '';
                      if (ngaySinh.isNotEmpty &&
                          thangSinh.isNotEmpty &&
                          namSinh.isNotEmpty) {
                        ngaySinhText =
                            'Ngày sinh: ${ngaySinh.padLeft(2, '0')}/${thangSinh.padLeft(2, '0')}/$namSinh';
                      } else if (thangSinh.isNotEmpty && namSinh.isNotEmpty) {
                        ngaySinhText =
                            'Ngày sinh: ${thangSinh.padLeft(2, '0')}/$namSinh';
                      } else if (namSinh.isNotEmpty) {
                        ngaySinhText = 'Năm sinh: $namSinh';
                      } else if (ngaySinh.isNotEmpty || thangSinh.isNotEmpty) {
                        final parts = [
                          if (ngaySinh.isNotEmpty) ngaySinh.padLeft(2, '0'),
                          if (thangSinh.isNotEmpty) thangSinh.padLeft(2, '0'),
                          if (namSinh.isNotEmpty) namSinh,
                        ];
                        ngaySinhText = 'Ngày sinh: ${parts.join('/')}';
                      }

                      final imagePath = person['image_path'] ?? '';
                      final bool hasImage =
                          imagePath.toString().isNotEmpty &&
                          caseId.toString().isNotEmpty &&
                          personId.toString().isNotEmpty;
                      final updatedAt = caseData?['updated_at'] ?? '';
                      final String imageUrl = hasImage
                          ? '${ApiService.baseUrl}/api/v1/cases/$caseId/persons/$personId/image?v=$updatedAt'
                          : '';

                      return LayoutBuilder(
                        builder: (context, cardConstraints) {
                          final isCompact = cardConstraints.maxWidth < 600;

                          final avatarWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(4.0),
                            child: Container(
                              width: isCompact ? 40 * 2.0 : 40 * 2.5,
                              height: isCompact ? 60 * 2.0 : 60 * 2.5,
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: hasImage
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.person,
                                            color: primaryColor.withValues(
                                              alpha: 0.6,
                                            ),
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
                                          fontSize: isCompact ? 14 : 16,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                            ),
                          );

                          final infoColumn = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    hoTen,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (gioiTinh.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
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
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (ngaySinhText.isNotEmpty)
                                    Text(
                                      ngaySinhText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: primaryColor.withValues(
                                          alpha: 0.7,
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
                                    color: primaryColor.withValues(alpha: 0.6),
                                  ),
                                  softWrap: true,
                                ),
                              ],
                              if (person['tien_an_tien_su'] is List &&
                                  (person['tien_an_tien_su'] as List)
                                      .isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Tiền án, tiền sự: ${(person['tien_an_tien_su'] as List).length} tiền án/tiền sự',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                              if (person['quan_he_gia_dinh'] is List &&
                                  (person['quan_he_gia_dinh'] as List)
                                      .isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Quan hệ gia đình: ${(person['quan_he_gia_dinh'] as List).length} người thân',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: primaryColor.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ],
                          );

                          final actionButtons = Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (onEditPersonPressed != null)
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: primaryColor,
                                  ),
                                  tooltip: 'Sửa thông tin đối tượng',
                                  onPressed: () => onEditPersonPressed!(person),
                                ),
                              FilledButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ExportDocsPage(
                                        caseId: caseId,
                                        person: person,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.print_outlined,
                                  size: 16,
                                ),
                                label: const Text('Xuất văn bản'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
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
                          );

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
                              child: isCompact
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            avatarWidget,
                                            const SizedBox(width: 12),
                                            Expanded(child: infoColumn),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Divider(
                                          height: 1,
                                          color: theme.colorScheme.outline
                                              .withValues(alpha: 0.15),
                                        ),
                                        const SizedBox(height: 4),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: actionButtons,
                                        ),
                                      ],
                                    )
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        avatarWidget,
                                        const SizedBox(width: 16),
                                        Expanded(child: infoColumn),
                                        const SizedBox(width: 12),
                                        actionButtons,
                                      ],
                                    ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
