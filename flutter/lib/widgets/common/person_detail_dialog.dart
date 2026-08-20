import 'package:flutter/material.dart';
import 'app_button.dart';
import 'app_container.dart';
import 'app_dialog.dart';
import 'person_widgets.dart';

class PersonDetailDialog extends StatelessWidget {
  final String caseId;
  final Map<String, dynamic> person;
  final String updatedAt;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PersonDetailDialog({
    super.key,
    required this.caseId,
    required this.person,
    required this.updatedAt,
    this.onEdit,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required String caseId,
    required Map<String, dynamic> person,
    required String updatedAt,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return showAppDialog(
      context: context,
      builder: (ctx) => PersonDetailDialog(
        caseId: caseId,
        person: person,
        updatedAt: updatedAt,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final personId = person['id'] ?? '';
    final hoTen = person['ho_ten']?.toString().trim() ?? 'Chưa đặt tên';
    final gioiTinh = person['gioi_tinh']?.toString().trim() ?? '';
    final cccd = person['cccd']?.toString().trim() ?? '';
    final ngayCccd = person['ngay_cccd']?.toString().trim() ?? '';
    final thangCccd = person['thang_cccd']?.toString().trim() ?? '';
    final namCccd = person['nam_cccd']?.toString().trim() ?? '';
    final noiCapCccd = person['noi_cap_cccd']?.toString().trim() ?? '';

    final noiSinh = person['noi_sinh']?.toString().trim() ?? '';
    final queQuan = person['que_quan']?.toString().trim() ?? '';
    final quocTich = person['quoc_tich']?.toString().trim() ?? '';
    final danToc = person['dan_toc']?.toString().trim() ?? '';
    final tonGiao = person['ton_giao']?.toString().trim() ?? '';

    final noiThuongTru = person['noi_thuong_tru']?.toString().trim() ?? '';
    final noiTamTru = person['noi_tam_tru']?.toString().trim() ?? '';
    final noiOHienTai = person['noi_o_hien_tai']?.toString().trim() ?? '';

    final hocVan = person['hoc_van']?.toString().trim() ?? '';
    final ngheNghiep = person['nghe_nghiep']?.toString().trim() ?? '';
    final noiLamViec = person['noi_lam_viec']?.toString().trim() ?? '';
    final chucVu = person['chuc_vu']?.toString().trim() ?? '';
    final doanThe = person['doan_the']?.toString().trim() ?? '';

    final String ngaySinhText = formatPersonBirthDate(person);

    String ngayCapCccdText = '---';
    if (ngayCccd.isNotEmpty && thangCccd.isNotEmpty && namCccd.isNotEmpty) {
      ngayCapCccdText =
          '${ngayCccd.padLeft(2, '0')}/${thangCccd.padLeft(2, '0')}/$namCccd';
    } else if (namCccd.isNotEmpty) {
      ngayCapCccdText = namCccd;
    }

    final tienAnList = person['tien_an_tien_su'] is List
        ? (person['tien_an_tien_su'] as List)
        : [];
    final giaDinhList = person['quan_he_gia_dinh'] is List
        ? (person['quan_he_gia_dinh'] as List)
        : [];

    return SelectionArea(
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 4,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 850),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. DIALOG HEADER
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16.0),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.badge_outlined, color: primaryColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'THÔNG TIN CON NGƯỜI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    AppIconButton(
                      icon: Icons.close,
                      size: 20,
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // 2. SCROLLABLE BODY
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Overview Card (Avatar + Tên + CCCD + Ngày sinh)
                      AppContainer(
                        padding: const EdgeInsets.all(16.0),
                        color: primaryColor.withValues(alpha: 0.04),
                        borderRadius: 12.0,
                        borderColor: primaryColor.withValues(alpha: 0.15),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ảnh đại diện (DRY)
                            PersonAvatar(
                              caseId: caseId,
                              personId: personId,
                              hoTen: hoTen,
                              imagePath: person['image_path']?.toString() ?? '',
                              updatedAt: updatedAt,
                              width: 90,
                              height: 130,
                              borderRadius: 6.0,
                              fontSize: 28.0,
                            ),
                            const SizedBox(width: 18),

                            // Tóm tắt thông tin chính
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          hoTen,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                      if (gioiTinh.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            gioiTinh,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _buildKeyValueRow(
                                    'Số CCCD/CMND:',
                                    cccd.isNotEmpty ? cccd : '---',
                                    isBold: true,
                                  ),
                                  const SizedBox(height: 6),
                                  _buildKeyValueRow('Ngày sinh:', ngaySinhText),
                                  const SizedBox(height: 6),
                                  _buildKeyValueRow(
                                    'Nơi ở hiện nay:',
                                    noiOHienTai.isNotEmpty
                                        ? noiOHienTai
                                        : (noiThuongTru.isNotEmpty
                                              ? noiThuongTru
                                              : '---'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // I. THÔNG TIN CĂN CƯỚC & CƯ TRÚ
                      _buildSectionTitle(
                        context,
                        'I. THÔNG TIN CĂN CƯỚC & CƯ TRÚ',
                      ),
                      const SizedBox(height: 10),
                      _buildInfoGrid([
                        _buildGridItem('Nơi sinh:', noiSinh),
                        _buildGridItem('Quê quán:', queQuan),
                        _buildGridItem('Quốc tịch:', quocTich),
                        _buildGridItem('Dân tộc:', danToc),
                        _buildGridItem('Tôn giáo:', tonGiao, fullWidth: true),
                        _buildGridItem('Ngày cấp CCCD:', ngayCapCccdText),
                        _buildGridItem('Nơi cấp CCCD:', noiCapCccd),
                        _buildGridItem(
                          'Nơi thường trú:',
                          noiThuongTru,
                          fullWidth: true,
                        ),
                        _buildGridItem(
                          'Nơi tạm trú:',
                          noiTamTru,
                          fullWidth: true,
                        ),
                        _buildGridItem(
                          'Nơi ở hiện tại:',
                          noiOHienTai,
                          fullWidth: true,
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // II. HỌC VẤN, NGHỀ NGHIỆP & TỔ CHỨC
                      _buildSectionTitle(
                        context,
                        'II. HỌC VẤN, NGHỀ NGHIỆP & TỔ CHỨC',
                      ),
                      const SizedBox(height: 10),
                      _buildInfoGrid([
                        _buildGridItem('Trình độ học vấn:', hocVan),
                        _buildGridItem('Nghề nghiệp:', ngheNghiep),
                        _buildGridItem(
                          'Nơi làm việc:',
                          noiLamViec,
                          fullWidth: true,
                        ),
                        _buildGridItem('Chức vụ:', chucVu),
                        _buildGridItem('Đoàn thể / Đảng:', doanThe),
                      ]),
                      const SizedBox(height: 20),

                      // III. TIỀN ÁN, TIỀN SỰ
                      _buildSectionTitle(
                        context,
                        'III. TIỀN ÁN, TIỀN SỰ (${tienAnList.length})',
                      ),
                      const SizedBox(height: 10),
                      if (tienAnList.isEmpty)
                        AppContainer.banner(
                          padding: const EdgeInsets.all(12.0),
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.2),
                          borderColor: Colors.transparent,
                          child: const Text(
                            'Chưa có tiền án, tiền sự.',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        Column(
                          children: tienAnList.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = Map<String, dynamic>.from(
                              entry.value as Map,
                            );
                            final thoiGian =
                                item['thoi_gian']?.toString().trim() ?? '';
                            final noiDung =
                                item['noi_dung']?.toString().trim() ?? '';

                            return AppContainer(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              padding: const EdgeInsets.all(12.0),
                              color: Colors.red.withValues(alpha: 0.04),
                              borderRadius: 8.0,
                              borderColor: Colors.red.withValues(alpha: 0.2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  AppContainer.badge(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    color: Colors.red.shade700,
                                    borderRadius: 4,
                                    child: Text(
                                      '# ${idx + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (thoiGian.isNotEmpty)
                                          Text(
                                            thoiGian,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        if (noiDung.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            noiDung,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.85),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),

                      // IV. QUAN HỆ GIA ĐÌNH
                      _buildSectionTitle(
                        context,
                        'IV. QUAN HỆ GIA ĐÌNH (${giaDinhList.length})',
                      ),
                      const SizedBox(height: 10),
                      if (giaDinhList.isEmpty)
                        AppContainer.banner(
                          padding: const EdgeInsets.all(12.0),
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.2),
                          borderColor: Colors.transparent,
                          child: const Text(
                            'Chưa có thông tin quan hệ gia đình.',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        Column(
                          children: giaDinhList.asMap().entries.map((entry) {
                            final item = Map<String, dynamic>.from(
                              entry.value as Map,
                            );
                            final quanHe =
                                item['quan_he']?.toString().trim() ?? '';
                            final tenThanNhan =
                                item['ho_ten']?.toString().trim() ?? '';
                            final namSinhThanNhan =
                                item['nam_sinh']?.toString().trim() ?? '';
                            final ngheThanNhan =
                                item['nghe_nghiep']?.toString().trim() ?? '';
                            final noiOThanNhan =
                                item['noi_o']?.toString().trim() ?? '';

                            return AppContainer(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              padding: const EdgeInsets.all(12.0),
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.25),
                              borderRadius: 8.0,
                              borderColor: theme.colorScheme.outline.withValues(
                                alpha: 0.15,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (quanHe.isNotEmpty)
                                        AppContainer.badge(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          color: primaryColor.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: 4,
                                          child: Text(
                                            quanHe,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          tenThanNhan.isNotEmpty
                                              ? tenThanNhan
                                              : '---',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (namSinhThanNhan.isNotEmpty)
                                        Text(
                                          'Sinh năm: $namSinhThanNhan',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                    ],
                                  ),
                                  if (ngheThanNhan.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Nghề nghiệp: $ngheThanNhan',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                  if (noiOThanNhan.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Nơi ở: $noiOThanNhan',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),

              // 3. DIALOG FOOTER ACTIONS (DRY & Responsive Wrap để không bị tràn 107px)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.25,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16.0),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    if (onDelete != null)
                      AppIconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete!();
                        },
                        icon: Icons.delete_outline,
                        color: Colors.redAccent,
                        isOutlined: true,
                        isDanger: true,
                        tooltip: 'Xóa đối tượng',
                      )
                    else
                      const SizedBox.shrink(),
                    PersonActionButtons(
                      caseId: caseId,
                      person: person,
                      isCompact: false,
                      showEditLabel: true,
                      closeDialogOnNavigate: true,
                      onEdit: onEdit != null
                          ? () {
                              Navigator.pop(context);
                              onEdit!();
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: primaryColor.withValues(alpha: 0.85),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyValueRow(String key, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            key,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(List<Widget> items) {
    return Wrap(spacing: 16, runSpacing: 8, children: items);
  }

  Widget _buildGridItem(String label, String value, {bool fullWidth = false}) {
    final valText = value.isNotEmpty ? value : '---';
    return SizedBox(
      width: fullWidth ? 700 : 330,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              valText,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
