import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../common/panel.dart';

/// Panel xem trước văn bản Word (.docx) bên phải trong ExportDocsPage
class DocPreviewPanel extends StatelessWidget {
  final String? selectedDisplayName;
  final String currentViewType;
  final VoidCallback onDownload;
  final VoidCallback? onReload;
  final bool isDownloading;

  const DocPreviewPanel({
    super.key,
    required this.selectedDisplayName,
    required this.currentViewType,
    required this.onDownload,
    this.onReload,
    this.isDownloading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      backgroundColor: const Color(0xFFF1F3F4),
      appBarIcon: Icons.visibility_outlined,
      appBarTitle: 'Xem trước: ${selectedDisplayName ?? "Tài liệu"}',
      appBarActions: [
        if (onReload != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới & Xóa cache xem trước',
            onPressed: onReload,
          ),
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: FilledButton.icon(
            onPressed: isDownloading ? null : onDownload,
            icon: isDownloading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download, size: 18),
            label: const Text('Tải file Word'),
          ),
        ),
      ],
      child: _DocPreviewContent(
        selectedDisplayName: selectedDisplayName,
        currentViewType: currentViewType,
        onDownload: onDownload,
        isDownloading: isDownloading,
      ),
    );
  }
}

class _DocPreviewContent extends StatelessWidget {
  final String? selectedDisplayName;
  final String currentViewType;
  final VoidCallback onDownload;
  final bool isDownloading;

  const _DocPreviewContent({
    required this.selectedDisplayName,
    required this.currentViewType,
    required this.onDownload,
    required this.isDownloading,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return HtmlElementView(
        key: ValueKey(currentViewType),
        viewType: currentViewType,
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
          FilledButton.icon(
            onPressed: isDownloading ? null : onDownload,
            icon: isDownloading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download),
            label: const Text('Tải xuống file Word'),
          ),
        ],
      ),
    );
  }
}
