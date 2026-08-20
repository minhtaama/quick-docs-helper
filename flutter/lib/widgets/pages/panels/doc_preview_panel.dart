import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../common/app_button.dart';
import '../../common/panel.dart';

/// Panel xem trước văn bản Word (.docx) bên phải trong ExportDocsPage
class DocPreviewPanel extends StatelessWidget {
  final String? selectedDisplayName;
  final String currentViewType;
  final VoidCallback onDownload;
  final VoidCallback? onReload;
  final bool isDownloading;

  final bool isOverlayActive;

  const DocPreviewPanel({
    super.key,
    required this.selectedDisplayName,
    required this.currentViewType,
    required this.onDownload,
    this.onReload,
    this.isDownloading = false,
    this.isOverlayActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      backgroundColor: const Color(0xFFF1F3F4),
      appBarIcon: Icons.visibility_outlined,
      appBarTitle: 'Xem trước: ${selectedDisplayName ?? "Tài liệu"}',
      appBarActions: [
        if (onReload != null)
          AppIconButton(
            icon: Icons.refresh,
            tooltip: 'Làm mới & Xóa cache xem trước',
            onPressed: onReload,
          ),
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: AppButton.primary(
            onPressed: isDownloading ? null : onDownload,
            isLoading: isDownloading,
            icon: Icons.download,
            label: 'Tải file Word',
          ),
        ),
      ],
      child: _DocPreviewContent(
        selectedDisplayName: selectedDisplayName,
        currentViewType: currentViewType,
        onDownload: onDownload,
        isDownloading: isDownloading,
        isOverlayActive: isOverlayActive,
      ),
    );
  }
}

class _DocPreviewContent extends StatelessWidget {
  final String? selectedDisplayName;
  final String currentViewType;
  final VoidCallback onDownload;
  final bool isDownloading;
  final bool isOverlayActive;

  const _DocPreviewContent({
    required this.selectedDisplayName,
    required this.currentViewType,
    required this.onDownload,
    required this.isDownloading,
    this.isOverlayActive = false,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Stack(
        children: [
          IgnorePointer(
            ignoring: isOverlayActive,
            child: HtmlElementView(
              key: ValueKey(currentViewType),
              viewType: currentViewType,
            ),
          ),
          if (isOverlayActive)
            const Positioned.fill(
              child: ColoredBox(color: Colors.transparent),
            ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.desktop_windows, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Xem trước văn bản: ${selectedDisplayName ?? ""}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          AppButton.primary(
            onPressed: isDownloading ? null : onDownload,
            isLoading: isDownloading,
            icon: Icons.download,
            label: 'Tải xuống file Word',
          ),
        ],
      ),
    );
  }
}
