import 'package:flutter/material.dart';
import '../../../common/app_button.dart';
import '../../../common/app_container.dart';

/// Widget hiển thị Banner tiêu đề hồ sơ và nút Chỉnh sửa hồ sơ vụ án
class CaseHeaderCard extends StatelessWidget {
  final String tenTomTat;
  final String tenDayDu;
  final VoidCallback? onEditCasePressed;
  final double? height;

  const CaseHeaderCard({
    super.key,
    required this.tenTomTat,
    required this.tenDayDu,
    this.onEditCasePressed,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final titleAndDescription = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppContainer.iconBox(
          borderRadius: 10,
          color: primaryColor.withValues(alpha: 0.12),
          child: Icon(Icons.gavel_rounded, color: primaryColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tenTomTat.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tenDayDu.isNotEmpty
                    ? tenDayDu
                    : 'Chưa cập nhật tên đầy đủ của hồ sơ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  height: 1.35,
                ),
                softWrap: true,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    final editCaseButton = onEditCasePressed != null
        ? AppIconButton(
            onPressed: onEditCasePressed,
            icon: Icons.edit_outlined,
            tooltip: 'Chỉnh sửa hồ sơ',
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
          )
        : const SizedBox.shrink();

    return AppContainer.banner(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18.0,
              vertical: 18.0,
            ),
            child: titleAndDescription,
          ),
          if (onEditCasePressed != null) ...[
            if (height != null) const Spacer() else const SizedBox(height: 12),
            Divider(
              height: 1,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: editCaseButton,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
