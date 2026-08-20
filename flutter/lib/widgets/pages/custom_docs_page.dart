import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:ui_web' as ui_web;
import '../../services/api_service.dart';
import '../common/app_button.dart';
import '../common/panel.dart';
import '../common/sidebar_page.dart';
import 'panels/custom_doc_editor_panel.dart';
import '../common/app_dialog.dart';
import 'sidebars/custom_doc_sidebar.dart';

class CustomDocsPage extends StatefulWidget {
  final String caseId;
  final Map<String, dynamic>? person;
  final Map<String, dynamic>? caseData;
  final bool isCaseLevel;

  final String? initialTemplateFile;
  final String? initialDocId;

  const CustomDocsPage({
    super.key,
    required this.caseId,
    this.person,
    this.caseData,  
    this.isCaseLevel = false,
    this.initialTemplateFile,
    this.initialDocId,
  });

  @override
  State<CustomDocsPage> createState() => _CustomDocsPageState();
}

class _CustomDocsPageState extends State<CustomDocsPage> {
  List<Map<String, dynamic>> _templates = [];
  List<Map<String, dynamic>> _customDocs = [];
  Map<String, dynamic>? _selectedDoc;
  bool _isLoading = true;
  bool _isDownloading = false;
  bool _isEditingMode = false;
  bool _isSaving = false;
  Map<String, dynamic>? _activeTemplate;
  Map<String, dynamic>? _activeEditingDoc;
  int _previewReloadCounter = 0;

  String? get _personId =>
      widget.isCaseLevel ? null : widget.person?['id']?.toString();

  List<Map<String, dynamic>> get _availablePersons {
    final conNguoiList = widget.caseData?['con_nguoi_list'];
    if (conNguoiList is List) {
      return conNguoiList
          .where((e) => e != null)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final level = widget.isCaseLevel ? 'case' : 'person';
    final futures = await Future.wait([
      CustomDocApiService.instance.getTemplates(level: level),
      CustomDocApiService.instance.getAll(
        caseId: widget.caseId,
        personId: _personId,
      ),
    ]);

    final templates = futures[0];
    final docs = futures[1];

    if (mounted) {
      setState(() {
        _templates = templates;
        _customDocs = docs;
        _isLoading = false;
        if (widget.initialDocId != null) {
          final matchedDoc = _customDocs.firstWhere(
            (d) => d['id']?.toString() == widget.initialDocId,
            orElse: () => <String, dynamic>{},
          );
          if (matchedDoc.isNotEmpty) {
            _selectedDoc = matchedDoc;
            _registerCurrentIframe();
          } else if (_customDocs.isNotEmpty) {
            _selectedDoc = _customDocs.first;
            _registerCurrentIframe();
          }
        } else if (_customDocs.isNotEmpty) {
          _selectedDoc = _customDocs.first;
          _registerCurrentIframe();
        } else {
          _selectedDoc = null;
        }

        // Tự động mở trình soạn thảo nếu có yêu cầu tạo nhanh từ template
        if (widget.initialTemplateFile != null && _templates.isNotEmpty) {
          final matchedTpl = _templates.firstWhere(
            (t) => t['file_name'] == widget.initialTemplateFile,
            orElse: () => <String, dynamic>{},
          );
          if (matchedTpl.isNotEmpty) {
            _activeTemplate = matchedTpl;
            _activeEditingDoc = null;
            _isEditingMode = true;
            _selectedDoc = null;
          }
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant CustomDocsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTemplateFile != oldWidget.initialTemplateFile &&
        widget.initialTemplateFile != null &&
        _templates.isNotEmpty) {
      final matchedTpl = _templates.firstWhere(
        (t) => t['file_name'] == widget.initialTemplateFile,
        orElse: () => <String, dynamic>{},
      );
      if (matchedTpl.isNotEmpty) {
        setState(() {
          _activeTemplate = matchedTpl;
          _activeEditingDoc = null;
          _isEditingMode = true;
          _selectedDoc = null;
        });
      }
    }
  }

  void _onSelectDoc(Map<String, dynamic> doc) {
    if (_selectedDoc?['id'] != doc['id'] || _isEditingMode) {
      setState(() {
        _selectedDoc = doc;
        _isEditingMode = false;
        _activeTemplate = null;
        _activeEditingDoc = null;
        _previewReloadCounter++;
        _registerCurrentIframe();
      });
    }
  }

  String get _currentViewType {
    final docId = _selectedDoc?['id'] ?? 'none';
    return 'custom-doc-preview-${widget.caseId}-$docId-$_previewReloadCounter';
  }

  void _registerCurrentIframe({bool force = false}) {
    if (kIsWeb && _selectedDoc != null) {
      final previewUrl = CustomDocApiService.instance.getPreviewUrl(
        caseId: widget.caseId,
        targetId: _selectedDoc!['id']?.toString(),
        templateFilename: _selectedDoc!['template_file']?.toString() ?? '',
        personId: _personId,
        force: force,
      );

      final viewType = _currentViewType;
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final iframe = html.IFrameElement()
          ..src = previewUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return iframe;
      });
    }
  }

  void _onReloadPreview() {
    setState(() {
      _previewReloadCounter++;
      _registerCurrentIframe(force: true);
    });
  }

  Future<void> _createNewDoc() async {
    if (_templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có mẫu văn bản tùy biến nào trong hệ thống!'),
        ),
      );
      return;
    }

    Map<String, dynamic>? selectedTemplate;
    if (_templates.length == 1) {
      selectedTemplate = _templates.first;
    } else {
      selectedTemplate = await showAppDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Chọn mẫu văn bản tùy biến'),
          children: _templates.map((tpl) {
            return SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(tpl),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tpl['display_name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            tpl['file_name'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    if (selectedTemplate == null || !mounted) return;

    setState(() {
      _activeTemplate = selectedTemplate;
      _activeEditingDoc = null;
      _isEditingMode = true;
      _selectedDoc = null;
    });
  }

  void _editCurrentDoc() {
    if (_selectedDoc == null) return;

    final templateFile = _selectedDoc!['template_file'] as String? ?? '';
    final matchedTemplate = _templates.firstWhere(
      (tpl) => tpl['file_name'] == templateFile,
      orElse: () => {
        'display_name': _selectedDoc!['title'] ?? 'Biên bản',
        'file_name': templateFile,
        'fields': <Map<String, dynamic>>[],
      },
    );

    setState(() {
      _activeTemplate = matchedTemplate;
      _activeEditingDoc = _selectedDoc;
      _isEditingMode = true;
    });
  }

  Future<void> _onSaveEditor(Map<String, dynamic> formData) async {
    if (_activeTemplate == null) return;

    setState(() => _isSaving = true);

    try {
      final isUpdating = _activeEditingDoc != null;
      final payload = isUpdating
          ? Map<String, dynamic>.from(_activeEditingDoc!)
          : <String, dynamic>{};

      payload['template_file'] = _activeTemplate!['file_name'];
      payload['title'] = formData['title'];
      payload['custom_fields'] = formData['custom_fields'];

      final savedDoc = await CustomDocApiService.instance.save(
        caseId: widget.caseId,
        docData: payload,
        personId: _personId,
      );

      setState(() {
        if (isUpdating) {
          final idx = _customDocs.indexWhere((d) => d['id'] == savedDoc['id']);
          if (idx != -1) {
            _customDocs[idx] = savedDoc;
          }
        } else {
          _customDocs.insert(0, savedDoc);
        }
        _selectedDoc = savedDoc;
        _isEditingMode = false;
        _isSaving = false;
        _previewReloadCounter++;
        _registerCurrentIframe(force: true);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUpdating
                  ? 'Đã cập nhật biên bản thành công!'
                  : 'Đã tạo và lưu biên bản thành công!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu biên bản: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDoc(Map<String, dynamic> doc) async {
    final docId = doc['id']?.toString();
    if (docId == null) return;

    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa biên bản'),
        content: Text('Bạn có chắc chắn muốn xóa "${doc['title']}" không?'),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.of(ctx).pop(false),
            label: 'Hủy',
          ),
          AppButton.primary(
            onPressed: () => Navigator.of(ctx).pop(true),
            isDanger: true,
            label: 'Xóa',
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await CustomDocApiService.instance.delete(
        docId,
        caseId: widget.caseId,
        personId: _personId,
      );

      if (success && mounted) {
        setState(() {
          _customDocs.removeWhere((d) => d['id'] == docId);
          if (_selectedDoc?['id'] == docId) {
            _selectedDoc = _customDocs.isNotEmpty ? _customDocs.first : null;
            _isEditingMode = false;
            _previewReloadCounter++;
            _registerCurrentIframe(force: true);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa biên bản thành công!')),
        );
      }
    }
  }

  Future<void> _downloadCurrentDocx() async {
    if (_selectedDoc == null) return;
    setState(() => _isDownloading = true);
    try {
      await CustomDocApiService.instance.downloadDocx(
        caseId: widget.caseId,
        targetId: _selectedDoc!['id']?.toString(),
        templateFilename: _selectedDoc!['template_file']?.toString() ?? '',
        personId: _personId,
        title: _selectedDoc!['title']?.toString(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải file Word: $e'),
            backgroundColor: Colors.red,
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
    final targetName = widget.isCaseLevel
        ? (widget.caseData?['ten_tom_tat'] ?? 'Vụ án')
        : (widget.person?['ho_ten'] ?? 'Đối tượng');

    final appBarWidget = AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VĂN BẢN TÙY BIẾN',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            targetName,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );

    if (_isLoading) {
      return Scaffold(
        appBar: appBarWidget,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải danh sách biên bản tùy biến...'),
            ],
          ),
        ),
      );
    }

    return SideBarPage(
      appBar: appBarWidget,
      tabs: const [
        Tab(icon: Icon(Icons.list_alt), text: 'Danh Sách Biên Bản'),
        Tab(icon: Icon(Icons.remove_red_eye), text: 'Xem Trước & Tải Về'),
      ],
      sideBar: CustomDocSidebar(
        customDocs: _customDocs,
        selectedDoc: _selectedDoc,
        isCreatingNew: _isEditingMode && _activeEditingDoc == null,
        activeTemplateTitle: _activeTemplate?['display_name'],
        onSelectDoc: _onSelectDoc,
        onCreateNewDoc: _createNewDoc,
        onDeleteDoc: _deleteDoc,
      ),
      child: _buildPanelWidget(context),
    );
  }

  Widget _buildPanelWidget(BuildContext context) {
    // 1. Chế độ Soạn thảo trên Tờ văn bản A4 tương tác
    if (_isEditingMode && _activeTemplate != null) {
      final templateFile = _activeTemplate!['file_name'] as String? ?? '';
      final templateDisplayName =
          _activeTemplate!['display_name'] as String? ?? 'Biên bản';
      final fields =
          (_activeTemplate!['fields'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      final initialTitle =
          _activeEditingDoc?['title'] as String? ?? templateDisplayName;
      final initialValues = Map<String, dynamic>.from(
        _activeEditingDoc?['custom_fields'] as Map? ?? {},
      );

      final level = widget.isCaseLevel ? 'case' : 'person';

      return CustomDocEditorPanel(
        key: ValueKey('editor-$templateFile-${_activeEditingDoc?['id']}'),
        templateDisplayName: templateDisplayName,
        templateFileName: templateFile,
        level: level,
        initialTitle: initialTitle,
        fields: fields,
        initialValues: initialValues,
        availablePersons: _availablePersons,
        caseData: widget.caseData,
        person: widget.person,
        isSaving: _isSaving,
        onCancel: () {
          setState(() {
            _isEditingMode = false;
            _activeTemplate = null;
            _activeEditingDoc = null;
            if (_customDocs.isNotEmpty) {
              _selectedDoc = _customDocs.first;
              _registerCurrentIframe();
            } else {
              _selectedDoc = null;
            }
          });
        },
        onSave: _onSaveEditor,
      );
    }

    // 2. Chưa chọn biên bản nào
    if (_selectedDoc == null) {
      return Panel(
        appBarIcon: Icons.article_outlined,
        appBarTitle: 'Văn bản tùy biến',
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.note_add_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Chưa chọn văn bản nào',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hãy tạo mới hoặc chọn một văn bản từ danh sách bên trái.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              AppButton.primary(
                onPressed: _createNewDoc,
                icon: Icons.add,
                label: 'Tạo biên bản ngay',
              ),
            ],
          ),
        ),
      );
    }

    // 3. Chế độ Xem trước PDF
    return Panel(
      backgroundColor: const Color(0xFFF1F3F4),
      appBarIcon: Icons.visibility_outlined,
      appBarTitle: 'Xem trước: ${_selectedDoc!['title'] ?? "Biên bản"}',
      appBarActions: [
        const SizedBox(width: 8),
        AppIconButton(
          icon: Icons.refresh,
          tooltip: 'Làm mới xem trước',
          onPressed: _onReloadPreview,
        ),
        const SizedBox(width: 8),
        AppButton.tonal(
          onPressed: _editCurrentDoc,
          icon: Icons.edit_note_rounded,
          label: 'Sửa nội dung',
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: AppButton.primary(
            onPressed: _isDownloading ? null : _downloadCurrentDocx,
            isLoading: _isDownloading,
            icon: Icons.download,
            label: 'Tải file Word',
          ),
        ),
      ],
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
                    'Xem trước: ${_selectedDoc!['title'] ?? ""}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  AppButton.primary(
                    onPressed: _isDownloading ? null : _downloadCurrentDocx,
                    icon: Icons.download,
                    label: 'Tải file Word',
                  ),
                ],
              ),
            ),
    );
  }
}
