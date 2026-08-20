import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:ui_web' as ui_web;
import '../../services/api_service.dart';
import '../common/sidebar_page.dart';
import 'sidebars/doc_template_sidebar.dart';
import 'panels/doc_preview_panel.dart';

class ExportDocsPage extends StatefulWidget {
  final String caseId;
  final Map<String, dynamic>? person;
  final Map<String, dynamic>? caseData;
  final bool isCaseLevel;
  final String? initialTemplateFile;

  const ExportDocsPage({
    super.key,
    required this.caseId,
    this.person,
    this.caseData,
    this.isCaseLevel = false,
    this.initialTemplateFile,
  });

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

  BaseApiService get _apiService =>
      widget.isCaseLevel ? CaseApiService() : PersonApiService();

  String? get _targetId {
    if (widget.isCaseLevel) return null;
    return widget.person?['id']?.toString();
  }

  String? get _targetTitle {
    if (widget.isCaseLevel) {
      return widget.caseData?['ten_tom_tat']?.toString();
    }
    return widget.person?['ho_ten']?.toString();
  }

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoadingTemplates = true);
    final templates = await _apiService.getTemplates();

    if (mounted) {
      setState(() {
        _templates = templates;
        _isLoadingTemplates = false;
        if (_templates.isNotEmpty) {
          if (widget.initialTemplateFile != null) {
            final matched = _templates.firstWhere(
              (t) => t['file_name'] == widget.initialTemplateFile,
              orElse: () => _templates.first,
            );
            _selectedTemplateFile = matched['file_name'];
            _selectedDisplayName = matched['display_name'];
          } else {
            _selectedTemplateFile = _templates.first['file_name'];
            _selectedDisplayName = _templates.first['display_name'];
          }
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

  String get _currentViewType {
    if (widget.isCaseLevel) {
      return 'docx-preview-case-${widget.caseId}-$_selectedTemplateFile-$_previewReloadCounter';
    }
    final personId = widget.person?['id'] ?? '';
    return 'docx-preview-${widget.caseId}-$personId-$_selectedTemplateFile-$_previewReloadCounter';
  }

  void _registerCurrentIframe({bool force = false}) {
    if (kIsWeb && _selectedTemplateFile != null) {
      final previewUrl = _apiService.getPreviewUrl(
        caseId: widget.caseId,
        targetId: _targetId,
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
      final bool ok = await _apiService.downloadDocx(
        caseId: widget.caseId,
        targetId: _targetId,
        templateFilename: _selectedTemplateFile!,
        title: _targetTitle,
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
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String titleText = widget.isCaseLevel
        ? 'Xuất Tài Liệu Vụ Việc'
        : 'Xuất Tài Liệu Cá Nhân';
    final String subtitleText;
    if (widget.isCaseLevel) {
      final tenTomTat = widget.caseData?['ten_tom_tat'] ?? '';
      subtitleText = 'Vụ việc: ${tenTomTat.isNotEmpty ? tenTomTat : "---"}';
    } else {
      final hoTen = widget.person?['ho_ten'] ?? 'Chưa đặt tên';
      final cccd = widget.person?['cccd'] ?? '';
      subtitleText =
          'Đối tượng: $hoTen${cccd.isNotEmpty ? '  •  CCCD: $cccd' : ''}';
    }

    final appBarWidget = AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titleText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitleText,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );

    if (_isLoadingTemplates) {
      return Scaffold(
        appBar: appBarWidget,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải danh sách mẫu văn bản...'),
            ],
          ),
        ),
      );
    }

    if (_templates.isEmpty) {
      final folderDesc = widget.isCaseLevel
          ? 'templates/case/'
          : 'templates/person/';
      return Scaffold(
        appBar: appBarWidget,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_off_outlined,
                size: 48,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'Chưa có mẫu văn bản nào trong thư mục $folderDesc',
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return SideBarPage(
      appBar: appBarWidget,
      tabs: const [
        Tab(icon: Icon(Icons.list_alt), text: 'Chọn Mẫu Văn Bản'),
        Tab(icon: Icon(Icons.remove_red_eye), text: 'Xem Trước & Tải Về'),
      ],
      sideBar: DocTemplateSidebar(
        templates: _templates,
        selectedTemplateFile: _selectedTemplateFile,
        onSelectTemplate: _onSelectTemplate,
      ),
      child: DocPreviewPanel(
        selectedDisplayName: _selectedDisplayName,
        currentViewType: _currentViewType,
        onDownload: _downloadCurrentDocx,
        onReload: _forceReloadPreview,
        isDownloading: _isDownloading,
      ),
    );
  }
}
