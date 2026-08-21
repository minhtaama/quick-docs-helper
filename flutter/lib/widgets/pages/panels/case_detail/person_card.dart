import 'package:flutter/material.dart';
import '../../../common/app_card.dart';
import '../../../common/app_container.dart';
import '../../../common/person_detail_dialog.dart';
import '../../../common/person_widgets.dart';

/// Widget Card hiển thị thông tin tóm tắt và các nút thao tác của một đối tượng / người liên quan
class PersonCard extends StatelessWidget {
  final String caseId;
  final Map<String, dynamic> person;
  final String updatedAt;
  final Color primaryColor;
  final Function(Map<String, dynamic> person)? onEditPerson;
  final Function(String personId, String hoTen)? onDeletePerson;

  const PersonCard({
    super.key,
    required this.caseId,
    required this.person,
    required this.updatedAt,
    required this.primaryColor,
    this.onEditPerson,
    this.onDeletePerson,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final personId = person['id']?.toString() ?? '';
    final hoTen = person['ho_ten']?.toString().trim() ?? 'Chưa đặt tên';

    final avatarWidget = PersonAvatar(
      caseId: caseId,
      personId: personId,
      hoTen: hoTen,
      imagePath: person['image_path']?.toString() ?? '',
      updatedAt: updatedAt,
      width: 85,
      height: 125,
      borderRadius: 4.0,
      fontSize: 16.0,
    );

    final infoColumn = PersonInfo(person: person, primaryColor: primaryColor);

    final actionButtons = PersonActionButtons(
      caseId: caseId,
      person: person,
      isCompact: true,
      onEdit: onEditPerson != null ? () => onEditPerson!(person) : null,
    );

    return AppCard(
      elevation: 1,
      margin: EdgeInsets.zero,
      borderRadius: 10.0,
      padding: const EdgeInsets.all(16.0),
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
    );
  }
}

/// Widget hiển thị chi tiết thông tin nhân thân của đối tượng / người liên quan
class PersonInfo extends StatelessWidget {
  final Map<String, dynamic> person;
  final Color primaryColor;

  const PersonInfo({
    super.key,
    required this.person,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final hoTen = person['ho_ten']?.toString().trim() ?? 'Chưa đặt tên';
    final gioiTinh = person['gioi_tinh']?.toString().trim() ?? '';
    final cccd = person['cccd']?.toString().trim() ?? '';
    final thuongTru =
        person['noi_thuong_tru']?.toString().trim() ??
        person['noi_o_hien_tai']?.toString().trim() ??
        '';

    final String ngaySinhText = formatPersonBirthDate(
      person,
      includePrefix: true,
    );

    final rawIsdt = person['isdt'];
    final isdt = rawIsdt == null
        ? true
        : (rawIsdt == true ||
              rawIsdt == 'true' ||
              rawIsdt == '1' ||
              rawIsdt == 1);

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
              AppContainer.badge(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: primaryColor.withValues(alpha: 0.08),
                child: Text(
                  gioiTinh,
                  style: TextStyle(fontSize: 11, color: primaryColor),
                ),
              ),
            AppContainer.badge(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: isdt
                  ? primaryColor.withValues(alpha: 0.1)
                  : const Color(0xFF00695C).withValues(alpha: 0.1),
              child: Text(
                isdt ? 'Đối tượng' : 'Người liên quan',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isdt ? primaryColor : const Color(0xFF00695C),
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
        if (isdt && tienAn.isNotEmpty) ...[
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
        if (isdt && quanHe.isNotEmpty) ...[
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
