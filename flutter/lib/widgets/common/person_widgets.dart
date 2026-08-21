import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../pages/custom_docs_page.dart';
import 'app_button.dart';
import 'app_container.dart';

/// Hàm tiện ích định dạng ngày sinh của đối tượng (DRY cho toàn project)
String formatPersonBirthDate(
  Map<String, dynamic> person, {
  bool includePrefix = false,
}) {
  final ngay = person['ngay_sinh']?.toString().trim() ?? '';
  final thang = person['thang_sinh']?.toString().trim() ?? '';
  final nam = person['nam_sinh']?.toString().trim() ?? '';

  if (ngay.isNotEmpty && thang.isNotEmpty && nam.isNotEmpty) {
    final str = '${ngay.padLeft(2, '0')}/${thang.padLeft(2, '0')}/$nam';
    return includePrefix ? 'Ngày sinh: $str' : str;
  } else if (thang.isNotEmpty && nam.isNotEmpty) {
    final str = '${thang.padLeft(2, '0')}/$nam';
    return includePrefix ? 'Ngày sinh: $str' : str;
  } else if (nam.isNotEmpty) {
    return includePrefix ? 'Năm sinh: $nam' : nam;
  } else if (ngay.isNotEmpty || thang.isNotEmpty) {
    final parts = [
      if (ngay.isNotEmpty) ngay.padLeft(2, '0'),
      if (thang.isNotEmpty) thang.padLeft(2, '0'),
      if (nam.isNotEmpty) nam,
    ];
    final str = parts.join('/');
    return includePrefix ? 'Ngày sinh: $str' : str;
  }
  return includePrefix ? '' : '---';
}

/// Widget hiển thị ảnh đại diện đối tượng với xử lý fallback chuẩn hoá (DRY)
class PersonAvatar extends StatelessWidget {
  final String caseId;
  final String personId;
  final String hoTen;
  final String imagePath;
  final String updatedAt;
  final double width;
  final double height;
  final double borderRadius;
  final Color? borderColor;
  final Color? primaryColor;
  final double fontSize;

  const PersonAvatar({
    super.key,
    required this.caseId,
    required this.personId,
    required this.hoTen,
    this.imagePath = '',
    this.updatedAt = '',
    this.width = 85,
    this.height = 125,
    this.borderRadius = 6.0,
    this.borderColor,
    this.primaryColor,
    this.fontSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effPrimary = primaryColor ?? theme.colorScheme.primary;
    final effBorderColor =
        borderColor ?? theme.colorScheme.outline.withValues(alpha: 0.3);

    final bool hasImage =
        imagePath.isNotEmpty && caseId.isNotEmpty && personId.isNotEmpty;
    final String imageUrl = hasImage
        ? PersonApiService.getPersonImageUrl(
            caseId: caseId,
            personId: personId,
            updatedAt: updatedAt,
          )
        : '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AppContainer(
        width: width,
        height: height,
        color: effPrimary.withValues(alpha: 0.08),
        borderRadius: borderRadius,
        borderColor: effBorderColor,
        child: hasImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person,
                  size: width * 0.45,
                  color: effPrimary.withValues(alpha: 0.5),
                ),
              )
            : Center(
                child: Text(
                  hoTen.trim().isNotEmpty
                      ? hoTen.trim().substring(0, 1).toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: effPrimary,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Widget cụm nút thao tác đối tượng đồng bộ chuẩn hoá trong toàn hệ thống (DRY)
class PersonActionButtons extends StatelessWidget {
  final String caseId;
  final Map<String, dynamic> person;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isCompact;
  final bool showEditLabel;
  final bool closeDialogOnNavigate;

  const PersonActionButtons({
    super.key,
    required this.caseId,
    required this.person,
    this.onEdit,
    this.onDelete,
    this.isCompact = true,
    this.showEditLabel = false,
    this.closeDialogOnNavigate = false,
  });

  void _navigateToCustomDocs(BuildContext context) {
    if (closeDialogOnNavigate) {
      Navigator.pop(context);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomDocsPage(
          caseId: caseId,
          person: person,
          isCaseLevel: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final customDocButton = AppButton.tonal(
      onPressed: () => _navigateToCustomDocs(context),
      icon: Icons.note_alt_outlined,
      iconSize: isCompact ? 15 : 17,
      label: 'Soạn thảo văn bản',
      isCompact: isCompact,
      backgroundColor: const Color(0xFFE65100).withValues(alpha: 0.25),
      foregroundColor: const Color(0xFFD84315),
      padding: isCompact
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );

    Widget? editButton;
    if (onEdit != null) {
      if (showEditLabel) {
        editButton = AppButton.outlined(
          onPressed: onEdit,
          icon: Icons.edit_outlined,
          iconSize: isCompact ? 15 : 17,
          label: 'Sửa thông tin',
          isCompact: isCompact,
          padding: isCompact
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        );
      } else {
        editButton = AppIconButton(
          icon: Icons.edit_outlined,
          size: isCompact ? 18 : 20,
          color: primaryColor,
          tooltip: 'Sửa thông tin đối tượng',
          onPressed: onEdit,
        );
      }
    }

    Widget? deleteButton;
    if (onDelete != null) {
      deleteButton = AppIconButton(
        icon: Icons.delete_outline,
        size: isCompact ? 18 : 20,
        color: Colors.redAccent,
        isOutlined: true,
        isDanger: true,
        tooltip: 'Xóa đối tượng',
        onPressed: onDelete,
      );
    }

    return Wrap(
      spacing: isCompact ? 6 : 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: [
        if (deleteButton != null) deleteButton,
        customDocButton,
        if (editButton != null) editButton,
      ],
    );
  }
}
