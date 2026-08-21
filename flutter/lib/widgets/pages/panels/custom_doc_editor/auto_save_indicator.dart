import 'package:flutter/material.dart';

/// Trạng thái của tính năng Tự động lưu (Auto-Save)
enum AutoSaveStatus { saved, saving, dirty, error }

/// Widget hiển thị trạng thái và tùy chọn Bật/Tắt Auto-Save trên thanh AppBar Toolbar
class AutoSaveIndicator extends StatelessWidget {
  final bool isAutoSaveEnabled;
  final ValueChanged<bool>? onToggleAutoSave;
  final AutoSaveStatus status;
  final DateTime? lastSavedTime;
  final VoidCallback? onManualSave;
  final bool isSaving;

  const AutoSaveIndicator({
    super.key,
    this.isAutoSaveEnabled = false,
    this.onToggleAutoSave,
    required this.status,
    this.lastSavedTime,
    this.onManualSave,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Thời gian lưu gần nhất
    final timeStr = lastSavedTime != null
        ? '${lastSavedTime!.hour.toString().padLeft(2, '0')}:${lastSavedTime!.minute.toString().padLeft(2, '0')}'
        : '';

    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Nút Toggle Bật/Tắt Auto-Save
          GestureDetector(
            onTap: () => onToggleAutoSave?.call(!isAutoSaveEnabled),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAutoSaveEnabled
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank_rounded,
                    size: 17,
                    color: isAutoSaveEnabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tự động lưu',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isAutoSaveEnabled
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isAutoSaveEnabled
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const VerticalDivider(),

          // Trạng thái lưu hoặc Nút Lưu nhanh khi tắt Auto-Save
          if (isSaving || status == AutoSaveStatus.saving) ...[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.8),
            ),
            const SizedBox(width: 5),
            Text(
              'Đang lưu...',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ] else if (status == AutoSaveStatus.dirty) ...[
            if (!isAutoSaveEnabled && onManualSave != null) ...[
              const SizedBox(width: 6),
              InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: isSaving ? null : onManualSave,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.orange.shade300,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.save_outlined,
                        size: 14,
                        color: Colors.orange.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Lưu',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Icon(
                Icons.cloud_queue_outlined,
                size: 16,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                'Chưa lưu',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
              ),
            ],
          ] else if (status == AutoSaveStatus.error) ...[
            Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
            const SizedBox(width: 4),
            Text(
              'Lỗi lưu',
              style: TextStyle(fontSize: 12, color: Colors.red.shade600),
            ),
          ] else ...[
            Icon(
              Icons.cloud_done_outlined,
              size: 16,
              color: Colors.green.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              timeStr.isNotEmpty ? 'Đã lưu lúc $timeStr' : 'Đã lưu',
              style: TextStyle(fontSize: 12, color: Colors.green.shade700),
            ),
          ],
        ],
      ),
    );
  }
}
