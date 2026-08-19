import '../../../services/api_service.dart';
import '../export_docs_page.dart';
import '../../common/person_detail_dialog.dart';
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
    final caseId = caseData!['id'] ?? '';
    final updatedAt = caseData!['updated_at'] ?? '';

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
                      'Vụ án: $tenDayDu',
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
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  OutlinedButton.icon(
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
                ? _EmptyPersonView(
                    onAddPerson: onAddPersonPressed,
                    primaryColor: primaryColor,
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isTwoColumns = constraints.maxWidth >= 850;
                      final cardWidth = isTwoColumns
                          ? (constraints.maxWidth - 16) / 2
                          : constraints.maxWidth;

                      return SingleChildScrollView(
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: personList.map((item) {
                            if (item == null) return const SizedBox.shrink();
                            final person = Map<String, dynamic>.from(
                              item as Map,
                            );

                            return SizedBox(
                              width: cardWidth,
                              child: _PersonCard(
                                caseId: caseId,
                                person: person,
                                updatedAt: updatedAt,
                                primaryColor: primaryColor,
                                theme: theme,
                                onEditPerson: onEditPersonPressed,
                                onDeletePerson: (personId, hoTen) =>
                                    _confirmDeletePerson(
                                      context,
                                      personId,
                                      hoTen,
                                    ),
                              ),
                            );
                          }).toList(),
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

// ==============================================================================
// PRIVATE WIDGETS TÁCH RIÊNG ĐỂ CODE GỌN VÀ TÁI SỬ DỤNG
// ==============================================================================

/// Widget hiển thị trạng thái rỗng khi chưa có đối tượng nào
class _EmptyPersonView extends StatelessWidget {
  final VoidCallback? onAddPerson;
  final Color primaryColor;

  const _EmptyPersonView({
    required this.onAddPerson,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
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
            onPressed: onAddPerson,
            icon: const Icon(Icons.add),
            label: const Text('Thêm đối tượng/bị can đầu tiên'),
          ),
        ],
      ),
    );
  }
}

/// Widget Card hiển thị thông tin và hành động của 1 đối tượng
class _PersonCard extends StatelessWidget {
  final String caseId;
  final Map<String, dynamic> person;
  final String updatedAt;
  final Color primaryColor;
  final ThemeData theme;
  final Function(Map<String, dynamic> person)? onEditPerson;
  final Function(String personId, String hoTen)? onDeletePerson;

  const _PersonCard({
    required this.caseId,
    required this.person,
    required this.updatedAt,
    required this.primaryColor,
    required this.theme,
    this.onEditPerson,
    this.onDeletePerson,
  });

  @override
  Widget build(BuildContext context) {
    final personId = person['id'] ?? '';
    final hoTen = person['ho_ten'] ?? 'Chưa đặt tên';
    final imagePath = person['image_path'] ?? '';
    final bool hasImage =
        imagePath.toString().isNotEmpty &&
        caseId.isNotEmpty &&
        personId.toString().isNotEmpty;
    final String imageUrl = hasImage
        ? PersonApiService.getPersonImageUrl(
            caseId: caseId,
            personId: personId,
            updatedAt: updatedAt,
          )
        : '';

    final avatarWidget = _PersonAvatar(
      imageUrl: imageUrl,
      hasImage: hasImage,
      hoTen: hoTen,
      primaryColor: primaryColor,
      borderColor: theme.colorScheme.outline.withValues(alpha: 0.3),
    );

    final infoColumn = _PersonInfo(person: person, primaryColor: primaryColor);

    final actionButtons = _PersonActions(
      caseId: caseId,
      person: person,
      primaryColor: primaryColor,
      onEditPerson: onEditPerson != null ? () => onEditPerson!(person) : null,
    );

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10.0),
        onTap: () => PersonDetailDialog.show(
          context,
          caseId: caseId,
          person: person,
          updatedAt: updatedAt,
          onEdit: onEditPerson != null ? () => onEditPerson!(person) : null,
          onDelete: onDeletePerson != null
              ? () => onDeletePerson!(personId, hoTen)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  avatarWidget,
                  const SizedBox(width: 14),
                  Expanded(child: infoColumn),
                ],
              ),
              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 6),
              Align(alignment: Alignment.centerRight, child: actionButtons),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget hiển thị ảnh đại diện hoặc chữ cái đầu
class _PersonAvatar extends StatelessWidget {
  final String imageUrl;
  final bool hasImage;
  final String hoTen;
  final Color primaryColor;
  final Color borderColor;

  const _PersonAvatar({
    required this.imageUrl,
    required this.hasImage,
    required this.hoTen,
    required this.primaryColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.0),
      child: Container(
        width: 85,
        height: 125,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: hasImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person,
                  color: primaryColor.withValues(alpha: 0.6),
                ),
              )
            : Center(
                child: Text(
                  hoTen.isNotEmpty ? hoTen.substring(0, 1).toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Widget hiển thị cột thông tin đối tượng
class _PersonInfo extends StatelessWidget {
  final Map<String, dynamic> person;
  final Color primaryColor;

  const _PersonInfo({required this.person, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final hoTen = person['ho_ten'] ?? 'Chưa đặt tên';
    final gioiTinh = person['gioi_tinh'] ?? '';
    final ngaySinh = person['ngay_sinh']?.toString().trim() ?? '';
    final thangSinh = person['thang_sinh']?.toString().trim() ?? '';
    final namSinh = person['nam_sinh']?.toString().trim() ?? '';
    final cccd = person['cccd'] ?? '';
    final thuongTru =
        person['noi_thuong_tru'] ?? person['noi_o_hien_tai'] ?? '';

    String ngaySinhText = '';
    if (ngaySinh.isNotEmpty && thangSinh.isNotEmpty && namSinh.isNotEmpty) {
      ngaySinhText =
          'Ngày sinh: ${ngaySinh.padLeft(2, '0')}/${thangSinh.padLeft(2, '0')}/$namSinh';
    } else if (thangSinh.isNotEmpty && namSinh.isNotEmpty) {
      ngaySinhText = 'Ngày sinh: ${thangSinh.padLeft(2, '0')}/$namSinh';
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

    final tienAn = person['tien_an_tien_su'] is List
        ? (person['tien_an_tien_su'] as List)
        : [];
    final quanHe = person['quan_he_gia_dinh'] is List
        ? (person['quan_he_gia_dinh'] as List)
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              hoTen,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (gioiTinh.isNotEmpty)
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
                  color: primaryColor.withValues(alpha: 0.7),
                ),
              ),
            if (cccd.isNotEmpty)
              Text(
                'CCCD: $cccd',
                style: TextStyle(
                  fontSize: 12,
                  color: primaryColor.withValues(alpha: 0.7),
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
        if (tienAn.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Tiền án, tiền sự: ${tienAn.length} tiền án/tiền sự',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.red.shade700,
            ),
          ),
        ],
        if (quanHe.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Quan hệ gia đình: ${quanHe.length} người thân',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: primaryColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget chứa các nút thao tác đối tượng (Văn bản riêng, Sửa)
class _PersonActions extends StatelessWidget {
  final String caseId;
  final Map<String, dynamic> person;
  final Color primaryColor;
  final VoidCallback? onEditPerson;

  const _PersonActions({
    required this.caseId,
    required this.person,
    required this.primaryColor,
    this.onEditPerson,
  });

  @override
  Widget build(BuildContext context) {
    final exportButton = FilledButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExportDocsPage(caseId: caseId, person: person),
          ),
        );
      },
      icon: const Icon(Icons.description_outlined, size: 16),
      label: const Text('Văn bản cá nhân'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        visualDensity: VisualDensity.compact,
      ),
    );

    final editButton = onEditPerson != null
        ? IconButton(
            icon: Icon(Icons.edit_outlined, size: 18, color: primaryColor),
            tooltip: 'Sửa thông tin đối tượng',
            onPressed: onEditPerson,
          )
        : const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        exportButton,
        if (onEditPerson != null) editButton,
      ],
    );
  }
}
