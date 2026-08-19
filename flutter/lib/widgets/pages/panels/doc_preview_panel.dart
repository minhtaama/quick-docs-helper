import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../common/panel.dart';

/// Panel xem trước văn bản Word (.docx) bên phải trong ExportDocsPage
class DocPreviewPanel extends StatelessWidget {
  final String? selectedDisplayName;
  final String currentViewType;
  final VoidCallback onDownload;
  final bool isDownloading;

  const DocPreviewPanel({
    super.key,
    required this.selectedDisplayName,
    required this.currentViewType,
    required this.onDownload,
    this.isDownloading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      backgroundColor: const Color(0xFFF1F3F4),
      header: _DocPreviewHeader(selectedDisplayName: selectedDisplayName),
      child: _DocPreviewContent(
        selectedDisplayName: selectedDisplayName,
        currentViewType: currentViewType,
        onDownload: onDownload,
        isDownloading: isDownloading,
      ),
    );
  }
}

class _DocPreviewHeader extends StatelessWidget {
  final String? selectedDisplayName;

  const _DocPreviewHeader({this.selectedDisplayName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 10.0,
      ),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Icon(
            Icons.visibility_outlined,
            size: 18,
            color: primaryColor.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Text(
            'Xem trước: ${selectedDisplayName ?? "Tài liệu"}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
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
          const Icon(
            Icons.desktop_windows,
            size: 48,
            color: Colors.grey,
          ),
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
