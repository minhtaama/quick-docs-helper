import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:ui_web' as ui_web;
import '../../services/api_service.dart';
import '../common/custom_fields_dialog.dart';
import '../common/panel.dart';
import '../common/sidebar_page.dart';

class CustomDocsPage extends StatefulWidget {
  final String caseId;
  final Map<String, dynamic>? person;
  final Map<String, dynamic>? caseData;
  final bool isCaseLevel;

  const CustomDocsPage({
    super.key,
    required this.caseId,
    this.person,
    this.caseData,
    this.isCaseLevel = false,
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
  bool _isDialogOpen = false;
  int _previewReloadCounter = 0;

  String? get _personId => widget.isCaseLevel ? null : widget.person?['id']?.toString();

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
        if (_customDocs.isNotEmpty) {
          _selectedDoc = _customDocs.first;
          _registerCurrentIframe();
        } else {
          _selectedDoc = null;
        }
      });
    }
  }

  void _onSelectDoc(Map<String, dynamic> doc) {
    if (_selectedDoc?['id'] != doc['id']) {
      setState(() {
        _selectedDoc = doc;
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
      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) {
          final iframe = html.IFrameElement()
            ..src = previewUrl
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%';
          return iframe;
        },
      );
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

    setState(() => _isDialogOpen = true);

    try {
      // Bước 1: Chọn mẫu Word
      Map<String, dynamic>? selectedTemplate;
      if (_templates.length == 1) {
        selectedTemplate = _templates.first;
      } else {
        selectedTemplate = await showDialog<Map<String, dynamic>>(
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
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
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

      // Bước 2: Mở CustomFieldsDialog để điền thông tin
      final fields = (selectedTemplate['fields'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => CustomFieldsDialog(
          templateDisplayName: selectedTemplate!['display_name'] ?? '',
          templateFileName: selectedTemplate['file_name'] ?? '',
          fields: fields,
          initialValues: const {},
          availablePersons: _availablePersons,
        ),
      );

      if (result == null || !mounted) return;

      final newDocPayload = {
        'template_file': selectedTemplate['file_name'],
        'title': result['title'],
        'custom_fields': result['custom_fields'],
      };

      final savedDoc = await CustomDocApiService.instance.save(
        caseId: widget.caseId,
        docData: newDocPayload,
        personId: _personId,
      );

      setState(() {
        _customDocs.insert(0, savedDoc);
        _selectedDoc = savedDoc;
        _previewReloadCounter++;
        _registerCurrentIframe(force: true);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo và lưu biên bản thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo biên bản: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDialogOpen = false);
      }
    }
  }

  Future<void> _editCurrentDoc() async {
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

    final fields = (matchedTemplate['fields'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    final initialValues = Map<String, dynamic>.from(
      _selectedDoc!['custom_fields'] as Map? ?? {},
    );

    setState(() => _isDialogOpen = true);

    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => CustomFieldsDialog(
          templateDisplayName: matchedTemplate['display_name'] ?? '',
          templateFileName: templateFile,
          initialTitle: _selectedDoc!['title'] ?? '',
          fields: fields,
          initialValues: initialValues,
          availablePersons: _availablePersons,
        ),
      );

      if (result == null || !mounted) return;

      final updatedPayload = Map<String, dynamic>.from(_selectedDoc!);
      updatedPayload['title'] = result['title'];
      updatedPayload['custom_fields'] = result['custom_fields'];

      final savedDoc = await CustomDocApiService.instance.save(
        caseId: widget.caseId,
        docData: updatedPayload,
        personId: _personId,
      );

      setState(() {
        final idx = _customDocs.indexWhere((d) => d['id'] == savedDoc['id']);
        if (idx != -1) {
          _customDocs[idx] = savedDoc;
        }
        _selectedDoc = savedDoc;
        _previewReloadCounter++;
        _registerCurrentIframe(force: true);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật biên bản thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật biên bản: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDialogOpen = false);
      }
    }
  }

  Future<void> _deleteDoc(Map<String, dynamic> doc) async {
    final docId = doc['id']?.toString();
    if (docId == null) return;

    setState(() => _isDialogOpen = true);

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xác nhận xóa biên bản'),
          content: Text('Bạn có chắc chắn muốn xóa "${doc['title']}" không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Xóa'),
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
              _previewReloadCounter++;
              _registerCurrentIframe(force: true);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa biên bản thành công!')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isDialogOpen = false);
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
      sideBar: _buildSidebarWidget(context),
      child: _buildPanelWidget(context),
    );
  }

  Widget _buildSidebarWidget(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: FilledButton.icon(
                onPressed: _createNewDoc,
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Tạo biên bản mới',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'DANH SÁCH BIÊN BẢN (${_customDocs.length})',
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
            child: _customDocs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            size: 48,
                            color: theme.iconTheme.color?.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có biên bản tùy biến nào được tạo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bấm "Tạo biên bản mới" ở trên để bắt đầu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: _customDocs.length,
                    itemBuilder: (context, index) {
                      final doc = _customDocs[index];
                      final isSelected = _selectedDoc?['id'] == doc['id'];
                      final title = doc['title'] as String? ?? 'Biên bản chưa đặt tên';
                      final templateFile = doc['template_file'] as String? ?? '';
                      final createdAt = doc['created_at'] as String? ?? '';

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
                          onTap: () => _onSelectDoc(doc),
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
                                    Icons.article_outlined,
                                    size: 20,
                                    color: isSelected ? Colors.white : primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? primaryColor
                                              : theme.colorScheme.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        templateFile,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSelected
                                              ? primaryColor.withValues(alpha: 0.7)
                                              : theme.colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (createdAt.isNotEmpty)
                                        Text(
                                          createdAt,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                  color: Colors.redAccent,
                                  tooltip: 'Xóa biên bản',
                                  onPressed: () => _deleteDoc(doc),
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
  }

  Widget _buildPanelWidget(BuildContext context) {
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
                'Chưa chọn biên bản nào để xem',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hãy tạo mới hoặc chọn một biên bản từ danh sách bên trái.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _createNewDoc,
                icon: const Icon(Icons.add),
                label: const Text('Tạo biên bản ngay'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isDialogOpen) {
      return Panel(
        backgroundColor: const Color(0xFFF1F3F4),
        appBarIcon: Icons.edit_note_rounded,
        appBarTitle: 'Đang mở hộp thoại: ${_selectedDoc!['title'] ?? ""}',
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_document, size: 54, color: Colors.grey),
              SizedBox(height: 14),
              Text(
                'Đang điền thông tin trong hộp thoại...',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Vui lòng hoàn thành hoặc đóng hộp thoại để xem trước tài liệu.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Panel(
      backgroundColor: const Color(0xFFF1F3F4),
      appBarIcon: Icons.visibility_outlined,
      appBarTitle: 'Xem trước: ${_selectedDoc!['title'] ?? "Biên bản"}',
      appBarActions: [
        FilledButton.tonalIcon(
          onPressed: _editCurrentDoc,
          icon: const Icon(Icons.edit_note_rounded, size: 18),
          label: const Text('Sửa nội dung'),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Làm mới xem trước',
          onPressed: _onReloadPreview,
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
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
            label: const Text('Tải file Word'),
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
                  const Icon(Icons.desktop_windows, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'Xem trước: ${_selectedDoc!['title'] ?? ""}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isDownloading ? null : _downloadCurrentDocx,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Tải file Word'),
                  ),
                ],
              ),
            ),
    );
  }
}
