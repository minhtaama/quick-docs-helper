import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:ui_web' as ui_web;
import '../../services/api_service.dart';
import '../common/app_button.dart';
import '../common/panel.dart';
import '../common/sidebar_page.dart';
import 'panels/custom_doc_editor/custom_doc_editor_panel.dart';
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
  List<Map<String, dynamic>> _createdCustomDocs = [];
  Map<String, dynamic>? _selectedCreatedCustomDoc;
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
        _createdCustomDocs = docs;
        _isLoading = false;
        if (widget.initialDocId != null) {
          final matchedDoc = _createdCustomDocs.firstWhere(
            (d) => d['id']?.toString() == widget.initialDocId,
            orElse: () => <String, dynamic>{},
          );
          if (matchedDoc.isNotEmpty) {
            _selectedCreatedCustomDoc = matchedDoc;
            _registerCurrentIframe();
            _activeTemplate = _templates.firstWhere(
              (tpl) => tpl['file_name'] == matchedDoc['template_file'],
              orElse: () => <String, dynamic>{},
            );
            _activeEditingDoc = _selectedCreatedCustomDoc;
            _isEditingMode = true;
          }
        } else {
          _selectedCreatedCustomDoc = null;
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
            _selectedCreatedCustomDoc = null;
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
          _selectedCreatedCustomDoc = null;
        });
      }
    }
  }

  void _onSelectCreatedCustomDoc(Map<String, dynamic> doc) {
    if (_selectedCreatedCustomDoc?['id'] != doc['id'] || _isEditingMode) {
      setState(() {
        _selectedCreatedCustomDoc = doc;
        _activeTemplate = _templates.firstWhere(
          (tpl) => tpl['file_name'] == doc['template_file'],
        );
        _activeEditingDoc = _selectedCreatedCustomDoc;
        _isEditingMode = true;
        _previewReloadCounter++;
        _registerCurrentIframe();
      });
    }
  }

  String get _currentViewType {
    final docId = _selectedCreatedCustomDoc?['id'] ?? 'none';
    return 'custom-doc-preview-${widget.caseId}-$docId-$_previewReloadCounter';
  }

  void _registerCurrentIframe({bool force = false}) {
    if (kIsWeb && _selectedCreatedCustomDoc != null) {
      final previewUrl = CustomDocApiService.instance.getPreviewUrl(
        caseId: widget.caseId,
        targetId: _selectedCreatedCustomDoc!['id']?.toString(),
        templateFilename:
            _selectedCreatedCustomDoc!['template_file']?.toString() ?? '',
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
          content: Text('Không có mẫu văn bản nào trong hệ thống!'),
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
          title: const Text('Chọn mẫu văn bản'),
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
                      child: Text(
                        tpl['display_name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 3,
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
      _selectedCreatedCustomDoc = null;
    });
  }

  void _editCurrentDoc() {
    if (_selectedCreatedCustomDoc == null) return;

    final templateFile =
        _selectedCreatedCustomDoc!['template_file'] as String? ?? '';
    final matchedTemplate = _templates.firstWhere(
      (tpl) => tpl['file_name'] == templateFile,
      orElse: () => {
        'display_name': _selectedCreatedCustomDoc!['title'] ?? 'Văn bản',
        'file_name': templateFile,
        'fields': <Map<String, dynamic>>[],
      },
    );

    setState(() {
      _activeTemplate = matchedTemplate;
      _activeEditingDoc = _selectedCreatedCustomDoc;
      _isEditingMode = true;
    });
  }

  Future<void> _onSaveEditor(
    Map<String, dynamic> formData, {
    bool isAutoSave = false,
  }) async {
    if (_activeTemplate == null) return;

    if (!isAutoSave) {
      setState(() => _isSaving = true);
    }

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
          final idx = _createdCustomDocs.indexWhere(
            (d) => d['id'] == savedDoc['id'],
          );
          if (idx != -1) {
            _createdCustomDocs[idx] = savedDoc;
          }
        } else {
          _createdCustomDocs.insert(0, savedDoc);
        }
        _activeEditingDoc = savedDoc;
        _selectedCreatedCustomDoc = savedDoc;

        if (!isAutoSave) {
          _isEditingMode = false;
          _isSaving = false;
          _previewReloadCounter++;
          _registerCurrentIframe(force: true);
        }
      });
    } catch (e) {
      if (mounted) {
        if (!isAutoSave) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi lưu văn bản: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        rethrow;
      }
    }
  }

  Future<void> _deleteDoc(Map<String, dynamic> doc) async {
    final docId = doc['id']?.toString();
    if (docId == null) return;

    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa văn bản'),
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
          _createdCustomDocs.removeWhere((d) => d['id'] == docId);
          if (_selectedCreatedCustomDoc?['id'] == docId ||
              _activeEditingDoc?['id'] == docId) {
            _selectedCreatedCustomDoc = null;
            _activeEditingDoc = null;
            _activeTemplate = null;
            _isEditingMode = false;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa biên bản thành công!')),
        );
      }
    }
  }

  Future<void> _downloadCurrentDocx() async {
    if (_selectedCreatedCustomDoc == null) return;
    setState(() => _isDownloading = true);
    try {
      await CustomDocApiService.instance.downloadDocx(
        caseId: widget.caseId,
        targetId: _selectedCreatedCustomDoc!['id']?.toString(),
        templateFilename:
            _selectedCreatedCustomDoc!['template_file']?.toString() ?? '',
        personId: _personId,
        title: _selectedCreatedCustomDoc!['title']?.toString(),
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
        ? ('Thuộc hồ sơ: ${widget.caseData?['ten_tom_tat'] ?? 'Vụ án'}')
        : ('Đối với ${widget.person?['isdt'] ? 'đối tượng' : 'người liên quan'}: ${widget.person?['ho_ten'] ?? 'Đối tượng'}');

    final appBarWidget = AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Soạn thảo văn bản',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            targetName.toUpperCase(),
            style: TextStyle(
              fontSize: 17,
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
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
      shouldShowDetailPanelOnMobile:
          _selectedCreatedCustomDoc != null || _isEditingMode,
      onMobileBack: () {
        setState(() {
          if (_isEditingMode) {
            _isEditingMode = false;
            _activeTemplate = null;
            _activeEditingDoc = null;
          }
          _selectedCreatedCustomDoc = null;
        });
      },
      sideBar: CustomDocSidebar(
        customDocs: _createdCustomDocs,
        selectedDoc: _selectedCreatedCustomDoc,
        isCreatingNew: _isEditingMode && _activeEditingDoc == null,
        activeTemplateTitle: _activeTemplate?['display_name'],
        onSelectDoc: _onSelectCreatedCustomDoc,
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
        isCreatingNew: _activeEditingDoc == null,
        isSaving: _isSaving,
        onCancel: () {
          setState(() {
            _isEditingMode = false;
            _activeTemplate = null;
            _activeEditingDoc = null;
            if (_createdCustomDocs.isNotEmpty) {
              _selectedCreatedCustomDoc = _createdCustomDocs.first;
              _registerCurrentIframe();
            } else {
              _selectedCreatedCustomDoc = null;
            }
          });
        },
        onSave: _onSaveEditor,
      );
    }

    // 2. Chưa chọn biên bản nào
    if (_selectedCreatedCustomDoc == null) {
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
      appBarTitle:
          'Xem trước: ${_selectedCreatedCustomDoc!['title'] ?? "Biên bản"}',
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
                    'Xem trước: ${_selectedCreatedCustomDoc!['title'] ?? ""}',
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
