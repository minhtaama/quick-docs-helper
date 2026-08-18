import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:ui_web' as ui_web;
import 'services/api_service.dart';

class ExportDocsPage extends StatefulWidget {
  final String caseId;
  final Map<String, dynamic> person;

  const ExportDocsPage({super.key, required this.caseId, required this.person});

  @override
  State<ExportDocsPage> createState() => _ExportDocsPageState();
}

class _ExportDocsPageState extends State<ExportDocsPage> {
  List<Map<String, dynamic>> _templates = [];
  String? _selectedTemplateFile;
  String? _selectedDisplayName;
  bool _isLoadingTemplates = true;
  bool _isDownloading = false;
  int _previewReloadCounter = 0;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoadingTemplates = true);
    final templates = await ApiService.getPersonTemplates();
    if (mounted) {
      setState(() {
        _templates = templates;
        _isLoadingTemplates = false;
        if (_templates.isNotEmpty) {
          _selectedTemplateFile = _templates.first['file_name'];
          _selectedDisplayName = _templates.first['display_name'];
          _registerCurrentIframe();
        }
      });
    }
  }

  void _onSelectTemplate(Map<String, dynamic> template) {
    final fileName = template['file_name'];
    final displayName = template['display_name'];
    if (fileName != _selectedTemplateFile) {
      setState(() {
        _selectedTemplateFile = fileName;
        _selectedDisplayName = displayName;
        _previewReloadCounter++;
        _registerCurrentIframe();
      });
    }
  }

  String get _currentViewType =>
      'docx-preview-${widget.caseId}-${widget.person['id']}-$_selectedTemplateFile-$_previewReloadCounter';

  void _registerCurrentIframe({bool force = false}) {
    if (kIsWeb && _selectedTemplateFile != null) {
      final previewUrl = ApiService.getPersonDocxPreviewUrl(
        caseId: widget.caseId,
        personId: widget.person['id'] ?? '',
        templateFilename: _selectedTemplateFile!,
        force: force,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final viewType = _currentViewType;

      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final iframe = html.IFrameElement()
          ..src = previewUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = '#f1f3f4';
        return iframe;
      });
    }
  }

  void _forceReloadPreview() {
    if (_selectedTemplateFile == null) return;
    setState(() {
      _previewReloadCounter++;
      _registerCurrentIframe(force: true);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang kết xuất lại bản xem trước (đã xóa cache)...'),
        backgroundColor: Colors.blueGrey,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _downloadCurrentDocx() async {
    if (_selectedTemplateFile == null) return;
    setState(() => _isDownloading = true);
    try {
      final hoTen = widget.person['ho_ten'] ?? '???';
      final ok = await ApiService.downloadPersonTemplateDocx(
        caseId: widget.caseId,
        personId: widget.person['id'] ?? '',
        templateFilename: _selectedTemplateFile!,
        hoTen: hoTen,
      );

      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã xuất văn bản "${_selectedDisplayName ?? _selectedTemplateFile}" thành công!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải văn bản: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final hoTen = widget.person['ho_ten'] ?? 'Đối tượng';
    final cccd = widget.person['cccd'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'XUẤT VĂN BẢN HỒ SƠ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Đối tượng: $hoTen${cccd.isNotEmpty ? '  •  CCCD: $cccd' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          if (_selectedTemplateFile != null) ...[
            IconButton(
              onPressed: _forceReloadPreview,
              icon: const Icon(Icons.refresh),
              tooltip: 'Làm mới & Xóa cache xem trước (Force Reload)',
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: FilledButton.icon(
                onPressed: _isDownloading ? null : _downloadCurrentDocx,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download, size: 18),
                label: Text(
                  _isDownloading ? 'Đang xuất...' : 'Tải xuống file Word',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          if (_isLoadingTemplates) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải danh sách mẫu văn bản...'),
                ],
              ),
            );
          }

          if (_templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_off_outlined,
                    size: 48,
                    color: primaryColor.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chưa có mẫu văn bản nào trong thư mục templates/person/',
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
            );
          }

          // DANH SÁCH MẪU BÊN TRÁI
          final templateListWidget = Container(
            color: theme.colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'DANH SÁCH VĂN BẢN (${_templates.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: _templates.length,
                    itemBuilder: (context, index) {
                      final tpl = _templates[index];
                      final fileName = tpl['file_name'] ?? '';
                      final displayName =
                          tpl['display_name'] ??
                          fileName.replaceAll('.docx', '');
                      final isSelected = fileName == _selectedTemplateFile;

                      return Card(
                        elevation: isSelected ? 2 : 0,
                        margin: const EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(
                            color: isSelected
                                ? primaryColor
                                : theme.colorScheme.outline.withValues(
                                    alpha: 0.15,
                                  ),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        color: isSelected
                            ? theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5)
                            : theme.colorScheme.surface,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          onTap: () => _onSelectTemplate(tpl),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryColor
                                        : primaryColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Icon(
                                    Icons.description,
                                    size: 20,
                                    color: isSelected
                                        ? Colors.white
                                        : primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: primaryColor,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );

          // KHUNG XEM TRƯỚC BÊN PHẢI (GOOGLE DOCS PREVIEW)
          final previewWidget = Container(
            color: const Color(0xFFF1F3F4),
            child: Column(
              children: [
                // Toolbar đầu trang Preview
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outline.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 18,
                        color: primaryColor.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Xem trước: ${_selectedDisplayName ?? "Tài liệu"}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Nội dung tài liệu Docx hiển thị
                Expanded(
                  child: kIsWeb
                      ? HtmlElementView(
                          key: ValueKey(_currentViewType),
                          viewType: _currentViewType,
                        )
                      : Center(
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
                                'Xem trước văn bản: ${_selectedDisplayName ?? ""}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _downloadCurrentDocx,
                                icon: const Icon(Icons.download),
                                label: const Text('Tải xuống file Word'),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );

          // BỐ CỤC MOBILE (Dọc / Tabs)
          if (isMobile) {
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: const [
                      Tab(icon: Icon(Icons.list_alt), text: 'Chọn Mẫu Văn Bản'),
                      Tab(
                        icon: Icon(Icons.remove_red_eye),
                        text: 'Xem Trước & Tải Về',
                      ),
                    ],
                    labelColor: primaryColor,
                    indicatorColor: primaryColor,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [templateListWidget, previewWidget],
                    ),
                  ),
                ],
              ),
            );
          }

          // BỐ CỤC DESKTOP (2 Cột song song)
          return Row(
            children: [
              SizedBox(width: 380, child: templateListWidget),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
              ),
              Expanded(child: previewWidget),
            ],
          );
        },
      ),
    );
  }
}
