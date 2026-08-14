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

  void _confirmDeletePerson(BuildContext context, String personId, String hoTen) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa đối tượng'),
        content: Text('Bạn có chắc chắn muốn xóa hồ sơ của "$hoTen" khỏi vụ án này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              if (onDeletePerson != null) {
                onDeletePerson!(personId, hoTen);
              }
            },
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
      return const Center(child: Text('Không có dữ liệu vụ việc.'));
    }

    final tenVu = caseData!['ten_vu'] ?? 'Vụ việc';
    final moTa = caseData!['mo_ta'] ?? '';
    final List<dynamic> personList = caseData!['con_nguoi_list'] ?? [];

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner thông tin vụ án
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.folder_special, color: primaryColor, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tenVu,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (moTa.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          moTa,
                          style: TextStyle(
                            fontSize: 13,
                            color: primaryColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onEditCasePressed != null) ...[
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 20, color: primaryColor),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Tiêu đề danh sách đối tượng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DANH SÁCH ĐỐI TƯỢNG TRONG VỤ ÁN (${personList.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
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

          const SizedBox(height: 8),

          // Danh sách các cá nhân
          Expanded(
            child: personList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 48,
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có đối tượng nào trong vụ án này.',
                          style: TextStyle(
                            fontSize: 14,
                            color: primaryColor.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: onAddPersonPressed,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm đối tượng đầu tiên'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: personList.length,
                    itemBuilder: (context, index) {
                      final item = personList[index];
                      if (item == null) return const SizedBox.shrink();
                      final person = Map<String, dynamic>.from(item as Map);
                      final personId = person['id'] ?? '';
                      final hoTen = person['ho_ten'] ?? 'Chưa đặt tên';
                      final gioiTinh = person['gioi_tinh'] ?? '';
                      final namSinh = person['nam_sinh'] ?? '';
                      final cccd = person['cccd'] ?? '';
                      final thuongTru = person['noi_thuong_tru'] ?? person['noi_o_hien_tai'] ?? '';

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          side: BorderSide(
                            color: theme.colorScheme.outline.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: primaryColor.withValues(alpha: 0.1),
                                child: Text(
                                  hoTen.isNotEmpty ? hoTen.substring(0, 1).toUpperCase() : '?',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
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
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                        if (gioiTinh.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              gioiTinh,
                                              style: TextStyle(fontSize: 11, color: primaryColor),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 4,
                                      children: [
                                        if (namSinh.isNotEmpty)
                                          Text(
                                            'Năm sinh: $namSinh',
                                            style: TextStyle(fontSize: 12, color: primaryColor.withValues(alpha: 0.7)),
                                          ),
                                        if (cccd.isNotEmpty)
                                          Text(
                                            'CCCD: $cccd',
                                            style: TextStyle(fontSize: 12, color: primaryColor.withValues(alpha: 0.7)),
                                          ),
                                      ],
                                    ),
                                    if (thuongTru.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Thường trú: $thuongTru',
                                        style: TextStyle(fontSize: 12, color: primaryColor.withValues(alpha: 0.6)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Nút sửa thông tin
                              if (onEditPersonPressed != null)
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: primaryColor.withValues(alpha: 0.8),
                                    size: 20,
                                  ),
                                  tooltip: 'Chỉnh sửa thông tin đối tượng',
                                  onPressed: () => onEditPersonPressed!(person),
                                ),
                              const SizedBox(width: 4),
                              // Nút xuất Word
                              FilledButton.tonalIcon(
                                onPressed: () {
                                  if (onDownloadDocx != null) {
                                    onDownloadDocx!(personId, hoTen);
                                  }
                                },
                                icon: const Icon(Icons.description, size: 16),
                                label: const Text('Xuất Word'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Nút xóa
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent.withValues(alpha: 0.8),
                                  size: 20,
                                ),
                                tooltip: 'Xóa đối tượng',
                                onPressed: () => _confirmDeletePerson(context, personId, hoTen),
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
