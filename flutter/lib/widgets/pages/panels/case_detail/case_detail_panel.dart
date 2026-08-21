import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';
import '../../../common/app_button.dart';
import '../../../common/app_dialog.dart';
import '../../../common/panel.dart';
import 'case_custom_docs_card.dart';
import 'case_header_card.dart';
import 'person_list_section.dart';

/// Panel hiển thị chi tiết vụ án và danh sách đối tượng / người liên quan
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
    return Panel(
      // customAppBar:
      appBarIcon: Icons.folder,
      appBarTitle: 'Hồ sơ',
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
    final tenTomTat = caseData['ten_tom_tat'] ?? '';
    final personList = caseData['con_nguoi_list'] as List? ?? [];
    final caseId = caseData['id'] ?? '';
    final updatedAt = caseData['updated_at'] ?? '';

    // Lọc danh sách: Đối tượng / Bị can (isdt == true) và Người liên quan (isdt == false)
    final doiTuongList = personList.where((item) {
      if (item is! Map) return false;
      final isdt = item['isdt'];
      return isdt == null ||
          isdt == true ||
          isdt == 'true' ||
          isdt == '1' ||
          isdt == 1;
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isTwoColumns = constraints.maxWidth >= 850;
              final cardWidth = isTwoColumns
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              final cardHeight = isTwoColumns ? 260.0 : null;

              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: CaseHeaderCard(
                      tenTomTat: tenTomTat,
                      tenDayDu: tenDayDu,
                      onEditCasePressed: onEditCasePressed,
                      height: cardHeight,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: CaseCustomDocsCard(
                      caseId: caseId,
                      caseData: caseData,
                      customTemplates: _customTemplates,
                      isLoadingTemplates: _isLoadingTemplates,
                      height: cardHeight,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 3. Section: Đối tượng / Bị can
          PersonListSection(
            title: 'ĐỐI TƯỢNG / BỊ CAN',
            icon: Icons.person_pin,
            primaryColor: primaryColor,
            buttonLabel: 'Thêm đối tượng / bị can',
            buttonIcon: Icons.person_add_alt_1_outlined,
            onAddPressed: () => onAddPersonPressed?.call(isdt: true),
            personList: doiTuongList,
            caseId: caseId,
            updatedAt: updatedAt,
            onEditPerson: onEditPersonPressed,
            onDeletePerson: (pId, name) =>
                _confirmDeletePerson(context, pId, name),
          ),
          const SizedBox(height: 32),

          // 4. Section: Người liên quan
          PersonListSection(
            title: 'NGƯỜI LIÊN QUAN',
            icon: Icons.group_outlined,
            primaryColor: primaryColor,
            buttonLabel: 'Thêm người liên quan',
            buttonIcon: Icons.group_add_outlined,
            onAddPressed: () => onAddPersonPressed?.call(isdt: false),
            personList: nguoiLienQuanList,
            caseId: caseId,
            updatedAt: updatedAt,
            onEditPerson: onEditPersonPressed,
            onDeletePerson: (pId, name) =>
                _confirmDeletePerson(context, pId, name),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
