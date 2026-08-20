import 'package:flutter/material.dart';
import '../../common/app_button.dart';
import '../../common/app_container.dart';
import '../../common/panel.dart';

/// Panel hiển thị màn hình chào mừng khi chưa chọn vụ việc
class WelcomePanel extends StatelessWidget {
  final VoidCallback? onNewCasePressed;

  const WelcomePanel({super.key, this.onNewCasePressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Panel(
      child: Center(
        child: AppContainer(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_shared_outlined,
                  size: 56,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Chào mừng đến với Quick Docs Helper',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hệ thống quản lý dữ liệu vụ án và tự động hóa kết xuất các biểu mẫu Word (.docx) chuyên nghiệp.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: primaryColor.withValues(alpha: 0.65),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              AppContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: 8,
                borderColor: theme.colorScheme.outline.withValues(alpha: 0.15),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      size: 16,
                      color: primaryColor.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Chọn một vụ án từ danh sách bên trái để xem chi tiết',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: primaryColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (onNewCasePressed != null) ...[
                const SizedBox(height: 16),
                AppButton.outlined(
                  onPressed: onNewCasePressed,
                  icon: Icons.add,
                  label: 'Tạo Vụ Việc Mới',
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}