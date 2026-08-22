import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import '../../../../services/api_service.dart';
import '../../../common/app_button.dart';
import '../../../common/panel.dart';
import 'a4_paper_sheet.dart';

/// Panel Soạn thảo trọn bộ hồ sơ (Bundle) tương tác trực tiếp trên từng tờ A4
class BundleDocEditorPanel extends StatefulWidget {
  final String caseId;
  final String bundleId;
  final String bundleName;
  final Map<String, dynamic>? caseData;
  final List<Map<String, dynamic>> availablePersons;
  final VoidCallback onCancel;
  final VoidCallback onSavedSuccess;

  const BundleDocEditorPanel({
    super.key,
    required this.caseId,
    required this.bundleId,
    required this.bundleName,
    this.caseData,
    this.availablePersons = const [],
    required this.onCancel,
    required this.onSavedSuccess,
  });

  @override
  State<BundleDocEditorPanel> createState() => _BundleDocEditorPanelState();
}

class _BundleDocEditorPanelState extends State<BundleDocEditorPanel> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _documents = [];
  int _activeDocIndex = 0;
  double _zoomScale = 1.0;

  // Quản lý Controllers và ComplexValues theo từng doc_key
  final Map<String, Map<String, TextEditingController>> _docControllers = {};
  final Map<String, Map<String, dynamic>> _docComplexValues = {};
  final Map<String, dynamic> _sharedFieldValues = {};

  StreamSubscription? _domWheelSub;

  @override
  void initState() {
    super.initState();
    _attachDomZoomListeners();
    _loadBundleLayout();
  }

  @override
  void dispose() {
    _domWheelSub?.cancel();
    for (final controllers in _docControllers.values) {
      for (final c in controllers.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _attachDomZoomListeners() {
    if (kIsWeb) {
      _domWheelSub = html.window.onWheel.listen((event) {
        if (event.ctrlKey) {
          event.preventDefault();
          setState(() {
            if (event.deltaY < 0) {
              _zoomScale = (_zoomScale + 0.05).clamp(0.5, 1.6);
            } else {
              _zoomScale = (_zoomScale - 0.05).clamp(0.5, 1.6);
            }
          });
        }
      });
    }
  }

  Future<void> _loadBundleLayout() async {
    setState(() => _isLoading = true);
    try {
      final layoutData = await BundleApiService.instance.getBundleLayout(
        caseId: widget.caseId,
        bundleId: widget.bundleId,
      );

      if (layoutData != null && mounted) {
        final docs = (layoutData['documents'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];

        for (final doc in docs) {
          final docKey = doc['doc_key'] as String? ?? '';
          final presetValues = Map<String, dynamic>.from(doc['preset_values'] as Map? ?? {});
          final layout = Map<String, dynamic>.from(doc['layout'] as Map? ?? {});
          final fields = (layout['fields'] as List?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              [];

          _docControllers[docKey] = {};
          _docComplexValues[docKey] = {};

          for (final f in fields) {
            final fName = f['name'] as String? ?? '';
            final fType = f['type'] as String? ?? 'input_text';
            final initialVal = presetValues[fName] ?? '';

            if (fType == 'input_table' || fType == 'input_list') {
              _docComplexValues[docKey]![fName] = initialVal is List ? List.from(initialVal) : [];
            } else {
              final ctrl = TextEditingController(text: initialVal.toString());
              ctrl.addListener(() {
                _onFieldValueChanged(fName, ctrl.text);
              });
              _docControllers[docKey]![fName] = ctrl;
            }
          }
        }

        setState(() {
          _documents = docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải bố cục Bundle: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onFieldValueChanged(String fieldName, String value) {
    _sharedFieldValues[fieldName] = value;
    // Đồng bộ sang các văn bản khác có cùng tên trường nếu người dùng chưa sửa riêng
    for (final entry in _docControllers.entries) {
      final controllers = entry.value;
      if (controllers.containsKey(fieldName)) {
        final targetCtrl = controllers[fieldName]!;
        if (targetCtrl.text != value) {
          targetCtrl.value = targetCtrl.value.copyWith(
            text: value,
            selection: TextSelection.collapsed(offset: value.length),
          );
        }
      }
    }
  }

  TextEditingController? _getControllerForActiveDoc(String varName) {
    if (_documents.isEmpty || _activeDocIndex >= _documents.length) return null;
    final activeDocKey = _documents[_activeDocIndex]['doc_key'] as String? ?? '';
    final controllers = _docControllers[activeDocKey];
    if (controllers == null) return null;

    if (controllers.containsKey(varName)) {
      return controllers[varName];
    }
    // Nếu biến chưa có trong controllers, tự động tạo controller để bind
    final initialText = _sharedFieldValues[varName]?.toString() ?? '';
    final newCtrl = TextEditingController(text: initialText);
    newCtrl.addListener(() {
      _onFieldValueChanged(varName, newCtrl.text);
    });
    controllers[varName] = newCtrl;
    return newCtrl;
  }

  Future<void> _saveAndDownloadBundle() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> documentsData = {};

      for (final doc in _documents) {
        final docKey = doc['doc_key'] as String? ?? '';
        final controllers = _docControllers[docKey] ?? {};
        final complexVals = _docComplexValues[docKey] ?? {};

        final Map<String, dynamic> customFields = {};
        for (final entry in controllers.entries) {
          customFields[entry.key] = entry.value.text;
        }
        for (final entry in complexVals.entries) {
          customFields[entry.key] = entry.value;
        }
        documentsData[docKey] = customFields;
      }

      final success = await BundleApiService.instance.renderAndDownloadBundle(
        caseId: widget.caseId,
        bundleId: widget.bundleId,
        documentsData: documentsData,
        defaultZipName: '${widget.bundleName}.zip',
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã lưu và tải trọn bộ hồ sơ "${widget.bundleName}" thành công!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        widget.onSavedSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xuất bộ hồ sơ: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Map<String, dynamic>? _getActivePerson() {
    if (_documents.isEmpty || _activeDocIndex >= _documents.length) return null;
    final activeDoc = _documents[_activeDocIndex];
    final personId = activeDoc['person_id'] as String?;
    if (personId == null) return null;

    final conNguoiList = widget.caseData?['con_nguoi_list'];
    if (conNguoiList is List) {
      for (final p in conNguoiList) {
        if (p is Map && p['id']?.toString() == personId) {
          return Map<String, dynamic>.from(p);
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    if (_isLoading) {
      return Panel(
        appBarTitle: widget.bundleName,
        appBarIcon: Icons.folder_zip_outlined,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang nạp bố cục các văn bản trong bộ hồ sơ...'),
            ],
          ),
        ),
      );
    }

    final activeDoc = _documents.isNotEmpty && _activeDocIndex < _documents.length
        ? _documents[_activeDocIndex]
        : null;
    final activeDocKey = activeDoc?['doc_key'] as String? ?? '';
    final activeLayout = Map<String, dynamic>.from(activeDoc?['layout'] as Map? ?? {});
    final activeElements = (activeLayout['elements'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final activeFields = (activeLayout['fields'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final activeComplex = _docComplexValues[activeDocKey] ?? {};
    final activePerson = _getActivePerson();

    return Panel(
      appBarTitle: widget.bundleName,
      appBarIcon: Icons.folder_zip_outlined,
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.zoom_out, size: 20),
          tooltip: 'Thu nhỏ',
          onPressed: () {
            setState(() => _zoomScale = (_zoomScale - 0.1).clamp(0.5, 1.6));
          },
        ),
        Center(
          child: Text(
            '${(_zoomScale * 100).toInt()}%',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.zoom_in, size: 20),
          tooltip: 'Phóng to',
          onPressed: () {
            setState(() => _zoomScale = (_zoomScale + 0.1).clamp(0.5, 1.6));
          },
        ),
        const SizedBox(width: 8),
        AppButton.outlined(
          label: 'Đóng',
          icon: Icons.close,
          onPressed: widget.onCancel,
        ),
        const SizedBox(width: 8),
        AppButton.primary(
          label: _isSaving ? 'Đang xuất ZIP...' : 'Lưu & Tải trọn bộ (.ZIP)',
          icon: Icons.archive_outlined,
          isLoading: _isSaving,
          onPressed: _saveAndDownloadBundle,
        ),
      ],
      child: Column(
        children: [
          // Thanh chuyển đổi các tờ A4 trong Bundle
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _documents.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final doc = entry.value;
                  final isSelected = idx == _activeDocIndex;
                  final docTitle = doc['display_name'] as String? ?? 'Văn bản ${idx + 1}';
                  final scope = doc['scope'] as String? ?? 'case';

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() => _activeDocIndex = idx);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? primaryColor : Colors.grey.shade300,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              scope == 'case' ? Icons.description_outlined : Icons.person_outline,
                              size: 16,
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${idx + 1}. $docTitle',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Tờ A4 hiển thị và chỉnh sửa nội dung
          Expanded(
            child: Container(
              color: const Color(0xFFE2E8F0),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Transform.scale(
                    scale: _zoomScale,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: 794,
                      child: A4PaperSheet(
                        isLoadingLayout: false,
                        layoutElements: activeElements,
                        fields: activeFields,
                        getController: _getControllerForActiveDoc,
                        complexValues: activeComplex,
                        availablePersons: widget.availablePersons,
                        caseData: widget.caseData,
                        person: activePerson,
                        onComplexValueChanged: (name, val) {
                          setState(() {
                            activeComplex[name] = val;
                          });
                        },
                        onContentChanged: () {
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
