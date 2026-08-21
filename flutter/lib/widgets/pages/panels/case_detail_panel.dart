import '../../../services/api_service.dart';
import '../custom_docs_page.dart';
import '../../common/app_button.dart';
import '../../common/app_card.dart';
import '../../common/app_container.dart';
import '../../common/app_dialog.dart';
import '../../common/person_detail_dialog.dart';
import '../../common/person_widgets.dart';
import '../../common/quick_action_card.dart';
import '../../common/panel.dart';
import 'package:flutter/material.dart';

/// Panel hiển thị chi tiết vụ án và danh sách đối tượng
class CaseDetailPanel extends StatelessWidget {
  final Map<String, dynamic>? caseData;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final Function({bool isdt})? onAddPersonPressed;
  final VoidCallback? onEditCasePressed;
  final Function(Map<String, dynamic> person)? onEditPersonPressed;
  final Future<void> Function(String personId, String hoTen)? onDeletePerson;

  const CaseDetailPanel({
    super.key,
    required this.caseData,
    this.isLoading = false,
    this.onRefresh,
    this.onAddPersonPressed,
    this.onEditCasePressed,
    this.onEditPersonPressed,
    this.onDeletePerson,
  });

  @override
  Widget build(BuildContext context) {
    final tenTomTat = caseData?['ten_tom_tat'] ?? '';

    return Panel(
      customAppBar: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          tenTomTat.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ),
        ),
      ),
      appBarIcon: Icons.file_open,
      appBarTitle: tenTomTat,
      isLoading: isLoading,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0),
      child: _CaseDetailContent(
        caseData: caseData,
        onRefresh: onRefresh,
        onAddPersonPressed: onAddPersonPressed,
        onEditCasePressed: onEditCasePressed,
        onEditPersonPressed: onEditPersonPressed,
        onDeletePerson: onDeletePerson,
      ),
    );
  }
}

class _CaseDetailContent extends StatefulWidget {
  final Map<String, dynamic>? caseData;
  final VoidCallback? onRefresh;
  final Function({bool isdt})? onAddPersonPressed;
  final VoidCallback? onEditCasePressed;
  final Function(Map<String, dynamic> person)? onEditPersonPressed;
  final Future<void> Function(String personId, String hoTen)? onDeletePerson;

  const _CaseDetailContent({
    required this.caseData,
    this.onRefresh,
    this.onAddPersonPressed,
    this.onEditCasePressed,
    this.onEditPersonPressed,
    this.onDeletePerson,
  });

  @override
  State<_CaseDetailContent> createState() => _CaseDetailContentState();
}

class _CaseDetailContentState extends State<_CaseDetailContent> {
  List<Map<String, dynamic>> _customTemplates = [];
  bool _isLoadingTemplates = true;

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  @override
  void didUpdateWidget(covariant _CaseDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.caseData?['id'] != oldWidget.caseData?['id']) {
      _fetchTemplates();
    }
  }

  Future<void> _fetchTemplates() async {
    try {
      final templates = await CustomDocApiService.instance.getTemplates(
        level: 'case',
      );
      if (mounted) {
        setState(() {
          _customTemplates = templates;
          _isLoadingTemplates = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingTemplates = false);
      }
    }
  }

  void _confirmDeletePerson(
    BuildContext context,
    String personId,
    String hoTen,
  ) {
    showAppDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'ĐTV có chắc chắn muốn xóa đối tượng "$hoTen" khỏi vụ án này?',
        ),
        actions: [
          AppButton.text(onPressed: () => Navigator.pop(ctx), label: 'Hủy'),
          AppButton.primary(
            onPressed: () async {
              Navigator.pop(ctx);
              if (widget.onDeletePerson != null) {
                await widget.onDeletePerson!(personId, hoTen);
              }
            },
            isDanger: true,
            label: 'Xóa',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final caseData = widget.caseData;
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

    final onAddPersonPressed = widget.onAddPersonPressed;
    final onEditCasePressed = widget.onEditCasePressed;
    final onEditPersonPressed = widget.onEditPersonPressed;

    final tenDayDu = caseData['ten_day_du'] ?? '';
    final personList = caseData['con_nguoi_list'] as List? ?? [];
    final caseId = caseData['id'] ?? '';
    final updatedAt = caseData['updated_at'] ?? '';

    // Lọc danh sách: Đối tượng / Bị can (isdt == true) và Người liên quan (isdt == false)
    final doiTuongList = personList.where((item) {
      if (item is! Map) return false;
      final isdt = item['isdt'];
      return isdt == null || isdt == true || isdt == 'true' || isdt == '1' || isdt == 1;
    }).toList();

    final nguoiLienQuanList = personList.where((item) {
      if (item is! Map) return false;
      final isdt = item['isdt'];
      return isdt == false || isdt == 'false' || isdt == '0' || isdt == 0;
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Vụ Án
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final isHeaderCompact = headerConstraints.maxWidth < 750;

              final titleAndDescription = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppContainer.iconBox(
                    borderRadius: 10,
                    color: primaryColor.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.gavel_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TÊN HỒ SƠ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryColor.withValues(alpha: 0.65),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tenDayDu.isNotEmpty
                              ? tenDayDu
                              : 'Chưa cập nhật tên đầy đủ vụ án',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.85,
                            ),
                            height: 1.35,
                          ),
                          softWrap: true,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final editCaseButton = onEditCasePressed != null
                  ? AppButton.outlined(
                      onPressed: onEditCasePressed,
                      icon: Icons.edit_outlined,
                      iconSize: 16,
                      label: 'Chỉnh sửa hồ sơ',
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    )
                  : const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppContainer.banner(
                    padding: const EdgeInsets.all(18.0),
                    child: isHeaderCompact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              titleAndDescription,
                              if (onEditCasePressed != null) ...[
                                const SizedBox(height: 14),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: editCaseButton,
                                ),
                              ],
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: titleAndDescription),
                              if (onEditCasePressed != null) ...[
                                const SizedBox(width: 16),
                                editCaseButton,
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),

                  // KHUNG CHỌN NHANH HÀNH ĐỘNG (QUICK SELECT BOX)
                  LayoutBuilder(
                    builder: (context, cardConstraints) {
                      final customDocs =
                          caseData['custom_documents'] as List? ?? [];

                      return QuickActionCard(
                        height: 270,
                        icon: Icons.note_alt_outlined,
                        title: 'Soạn thảo văn bản',
                        subtitle:
                            'Soạn thảo các văn bản theo mẫu, điền thông tin và tải về',
                        badge: '${customDocs.length} bản ghi',
                        color: const Color(0xFFE65100),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomDocsPage(
                                caseId: caseId,
                                caseData: caseData,
                                isCaseLevel: true,
                              ),
                            ),
                          );
                        },
                        bottomWidget: _customTemplates.isEmpty
                            ? (_isLoadingTemplates
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Text(
                                          'Đang tải danh sách mẫu...',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const Center(
                                      child: Text(
                                        'Không có mẫu văn bản',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ))
                            : SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Column(
                                  children: _customTemplates.map((tpl) {
                                    final displayName =
                                        tpl['display_name'] ??
                                        tpl['file_name'] ??
                                        'Mẫu';
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 6.0,
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          6.0,
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CustomDocsPage(
                                                caseId: caseId,
                                                caseData: caseData,
                                                isCaseLevel: true,
                                                initialTemplateFile:
                                                    tpl['file_name'],
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0,
                                            vertical: 7.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFE65100,
                                            ).withValues(alpha: 0.06),
                                            borderRadius:
                                                BorderRadius.circular(6.0),
                                            border: Border.all(
                                              color: const Color(
                                                0xFFE65100,
                                              ).withValues(alpha: 0.15),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.add_circle_outline,
                                                size: 15,
                                                color: Color(0xFFE65100),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  displayName,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: Color(0xFFE65100),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Icon(
                                                Icons.edit,
                                                size: 12,
                                                color: const Color(
                                                  0xFFE65100,
                                                ).withValues(alpha: 0.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // ===================================================================
          // SECTION 1: DANH SÁCH ĐỐI TƯỢNG / BỊ CAN
          // ===================================================================
          Row(
            children: [
              Icon(Icons.person_pin, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ĐỐI TƯỢNG / BỊ CAN TRONG VỤ ÁN (${doiTuongList.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryColor.withValues(alpha: 0.9),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppButton.tonal(
                icon: Icons.person_add_alt_1_outlined,
                label: 'Thêm đối tượng / bị can',
                onPressed: () => onAddPersonPressed?.call(isdt: true),
                backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                foregroundColor: Colors.black87,
              ),
            ],
          ),
          const SizedBox(height: 12),
          doiTuongList.isEmpty
              ? _EmptyPersonView(
                  onAddPerson: () => onAddPersonPressed?.call(isdt: true),
                  primaryColor: primaryColor,
                  title: 'Chưa có đối tượng/bị can nào trong vụ án này.',
                  buttonLabel: 'Thêm đối tượng / bị can đầu tiên',
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isTwoColumns = constraints.maxWidth >= 850;
                    final cardWidth = isTwoColumns
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: doiTuongList.map((item) {
                        if (item == null) return const SizedBox.shrink();
                        final person = Map<String, dynamic>.from(item as Map);

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
                                _confirmDeletePerson(context, personId, hoTen),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

          const SizedBox(height: 32),

          // ===================================================================
          // SECTION 2: DANH SÁCH NGƯỜI LIÊN QUAN
          // ===================================================================
          Row(
            children: [
              Icon(Icons.group_outlined, color: const Color(0xFF00695C), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'NGƯỜI LIÊN QUAN (${nguoiLienQuanList.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00695C),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppButton.tonal(
                icon: Icons.group_add_outlined,
                label: 'Thêm người liên quan',
                onPressed: () => onAddPersonPressed?.call(isdt: false),
                backgroundColor: const Color(0xFF00695C).withValues(alpha: 0.1),
                foregroundColor: Colors.black87,
              ),
            ],
          ),
          const SizedBox(height: 12),
          nguoiLienQuanList.isEmpty
              ? _EmptyPersonView(
                  onAddPerson: () => onAddPersonPressed?.call(isdt: false),
                  primaryColor: const Color(0xFF00695C),
                  title: 'Chưa có người liên quan nào trong vụ án này.',
                  buttonLabel: 'Thêm người liên quan',
                  icon: Icons.group_outlined,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isTwoColumns = constraints.maxWidth >= 850;
                    final cardWidth = isTwoColumns
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: nguoiLienQuanList.map((item) {
                        if (item == null) return const SizedBox.shrink();
                        final person = Map<String, dynamic>.from(item as Map);

                        return SizedBox(
                          width: cardWidth,
                          child: _PersonCard(
                            caseId: caseId,
                            person: person,
                            updatedAt: updatedAt,
                            primaryColor: const Color(0xFF00695C),
                            theme: theme,
                            onEditPerson: onEditPersonPressed,
                            onDeletePerson: (personId, hoTen) =>
                                _confirmDeletePerson(context, personId, hoTen),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ==============================================================================
// PRIVATE WIDGETS TÁCH RIÊNG ĐỂ CODE GỌN VÀ TÁI SỬ DỤNG
// ==============================================================================

/// Widget hiển thị trạng thái rỗng khi chưa có đối tượng / người liên quan nào
class _EmptyPersonView extends StatelessWidget {
  final VoidCallback? onAddPerson;
  final Color primaryColor;
  final String title;
  final String buttonLabel;
  final IconData icon;

  const _EmptyPersonView({
    required this.onAddPerson,
    required this.primaryColor,
    this.title = 'Chưa có đối tượng/bị can nào trong vụ án này.',
    this.buttonLabel = 'Thêm đối tượng/bị can đầu tiên',
    this.icon = Icons.people_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 44,
            color: primaryColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: primaryColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          AppButton.outlined(
            onPressed: onAddPerson,
            icon: Icons.add,
            label: buttonLabel,
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

    final infoColumn = _PersonInfo(person: person, primaryColor: primaryColor);

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

/// Widget hiển thị cột thông tin đối tượng
class _PersonInfo extends StatelessWidget {
  final Map<String, dynamic> person;
  final Color primaryColor;

  const _PersonInfo({required this.person, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final hoTen = person['ho_ten']?.toString().trim() ?? 'Chưa đặt tên';
    final gioiTinh = person['gioi_tinh']?.toString().trim() ?? '';
    final cccd = person['cccd']?.toString().trim() ?? '';
    final thuongTru =
        person['noi_thuong_tru']?.toString().trim() ??
        person['noi_o_hien_tai']?.toString().trim() ??
        '';

    final String ngaySinhText = formatPersonBirthDate(person, includePrefix: true);

    final rawIsdt = person['isdt'];
    final isdt = rawIsdt == null ? true : (rawIsdt == true || rawIsdt == 'true' || rawIsdt == '1' || rawIsdt == 1);

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
