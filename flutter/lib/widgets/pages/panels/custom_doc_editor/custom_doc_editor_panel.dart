import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/widgets/common/app_container.dart';
import 'package:universal_html/html.dart' as html;
import '../../../common/app_button.dart';
import '../../../common/panel.dart';
import '../../../common/text_input.dart';
import '../../../../services/api_service.dart';
import 'a4_paper_sheet.dart';
import 'auto_save_indicator.dart';

/// Panel Soạn thảo văn bản tương tác trực tiếp trên giao diện tờ A4
class CustomDocEditorPanel extends StatefulWidget {
  final String templateDisplayName;
  final String templateFileName;
  final String level; // 'case' hoặc 'person'
  final String initialTitle;
  final List<Map<String, dynamic>> fields;
  final Map<String, dynamic> initialValues;
  final List<Map<String, dynamic>> availablePersons;
  final Map<String, dynamic>? caseData;
  final Map<String, dynamic>? person;
  final bool isCreatingNew;
  final Future<void> Function(Map<String, dynamic> data, {bool isAutoSave})
  onSave;
  final VoidCallback onCancel;
  final bool isSaving;

  const CustomDocEditorPanel({
    super.key,
    required this.templateDisplayName,
    required this.templateFileName,
    this.level = 'case',
    this.initialTitle = '',
    required this.fields,
    required this.initialValues,
    this.availablePersons = const [],
    this.caseData,
    this.person,
    this.isCreatingNew = false,
    required this.onSave,
    required this.onCancel,
    this.isSaving = false,
  });

  @override
  State<CustomDocEditorPanel> createState() => _CustomDocEditorPanelState();
}

class _CustomDocEditorPanelState extends State<CustomDocEditorPanel> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, dynamic> _complexValues = {};

  bool _isLoadingLayout = false;
  List<Map<String, dynamic>> _layoutElements = [];
  double _zoomScale = 1.0;

  // Quản lý Auto-Save (Mặc định tắt)
  bool _isAutoSaveEnabled = false;
  late AutoSaveStatus _autoSaveStatus;
  DateTime? _lastSavedTime;
  Timer? _autoSaveDebounceTimer;

  StreamSubscription? _domWheelSub;
  StreamSubscription? _domTouchStartSub;
  StreamSubscription? _domTouchMoveSub;
  StreamSubscription? _domTouchEndSub;

  @override
  void initState() {
    super.initState();
    _autoSaveStatus = widget.isCreatingNew
        ? AutoSaveStatus.dirty
        : AutoSaveStatus.saved;
    _attachDomZoomListeners();
    _titleController = TextEditingController(
      text: widget.initialTitle.isNotEmpty
          ? widget.initialTitle
          : widget.templateDisplayName,
    );
    _titleController.addListener(_onContentChanged);

    // Khởi tạo controllers cho các trường trong metadata
    for (final field in widget.fields) {
      final name = field['name'] as String? ?? '';
      final type = field['type'] as String? ?? 'text';
      final initVal = widget.initialValues[name];

      if (type == 'table' ||
          type == 'list' ||
          type == 'input_table' ||
          type == 'input_list' ||
          type == 'persons' ||
          type == 'input_persons' ||
          type == 'persons_section') {
        if (initVal is List) {
          _complexValues[name] = List.from(initVal);
        } else {
          _complexValues[name] = [];
        }
      } else {
        final ctrl = TextEditingController(text: initVal?.toString() ?? '');
        ctrl.addListener(_onContentChanged);
        _textControllers[name] = ctrl;
      }
    }

    _loadLayout();
  }

  @override
  void dispose() {
    _autoSaveDebounceTimer?.cancel();
    _detachDomZoomListeners();
    _titleController.removeListener(_onContentChanged);
    _titleController.dispose();
    for (final c in _textControllers.values) {
      c.removeListener(_onContentChanged);
      c.dispose();
    }
    super.dispose();
  }

  void _onContentChanged() {
    if (_autoSaveStatus != AutoSaveStatus.dirty) {
      setState(() {
        _autoSaveStatus = AutoSaveStatus.dirty;
      });
    }
    if (_isAutoSaveEnabled) {
      _autoSaveDebounceTimer?.cancel();
      _autoSaveDebounceTimer = Timer(
        const Duration(milliseconds: 1500),
        _performAutoSave,
      );
    }
  }

  void _toggleAutoSave(bool enabled) {
    setState(() {
      _isAutoSaveEnabled = enabled;
    });
    if (_isAutoSaveEnabled && _autoSaveStatus == AutoSaveStatus.dirty) {
      _performAutoSave();
    }
  }

  Future<void> _manualSave() async {
    _autoSaveDebounceTimer?.cancel();
    await _performAutoSave();
  }

  Future<void> _performAutoSave() async {
    if (!mounted) return;
    setState(() {
      _autoSaveStatus = AutoSaveStatus.saving;
    });

    final resultFields = <String, dynamic>{};
    for (final entry in _textControllers.entries) {
      resultFields[entry.key] = entry.value.text.trim();
    }
    for (final entry in _complexValues.entries) {
      resultFields[entry.key] = entry.value;
    }

    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : widget.templateDisplayName;

    try {
      await widget.onSave({
        'title': title,
        'custom_fields': resultFields,
      }, isAutoSave: true);

      if (mounted) {
        setState(() {
          _autoSaveStatus = AutoSaveStatus.saved;
          _lastSavedTime = DateTime.now();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _autoSaveStatus = AutoSaveStatus.error;
        });
      }
    }
  }

  void _attachDomZoomListeners() {
    if (kIsWeb) {
      try {
        _domWheelSub = html.window.onWheel.listen((e) {
          if (e.ctrlKey || e.metaKey) {
            e.preventDefault();
            final delta = (-e.deltaY * 0.01).clamp(-0.4, 0.4);
            if (mounted) {
              setState(() {
                _zoomScale = (_zoomScale + delta).clamp(0.6, 3.0);
              });
            }
          }
        });

        double touchStartDist = 0.0;
        double pinchBaseScale = 1.0;

        _domTouchStartSub = html.window.onTouchStart.listen((e) {
          if (e.touches != null && e.touches!.length == 2) {
            final t1 = e.touches![0];
            final t2 = e.touches![1];
            touchStartDist =
                (Offset(t1.page.x.toDouble(), t1.page.y.toDouble()) -
                        Offset(t2.page.x.toDouble(), t2.page.y.toDouble()))
                    .distance;
            pinchBaseScale = _zoomScale;
          }
        });

        _domTouchMoveSub = html.window.onTouchMove.listen((e) {
          if (e.touches != null &&
              e.touches!.length == 2 &&
              touchStartDist > 0) {
            e.preventDefault();
            final t1 = e.touches![0];
            final t2 = e.touches![1];
            final currentDist =
                (Offset(t1.page.x.toDouble(), t1.page.y.toDouble()) -
                        Offset(t2.page.x.toDouble(), t2.page.y.toDouble()))
                    .distance;
            final ratio = currentDist / touchStartDist;
            if (mounted) {
              setState(() {
                _zoomScale = (pinchBaseScale * ratio).clamp(0.6, 2.0);
              });
            }
          }
        });

        _domTouchEndSub = html.window.onTouchEnd.listen((e) {
          if (e.touches != null && e.touches!.length < 2) {
            touchStartDist = 0.0;
          }
        });
      } catch (_) {}
    }
  }

  void _detachDomZoomListeners() {
    _domWheelSub?.cancel();
    _domTouchStartSub?.cancel();
    _domTouchMoveSub?.cancel();
    _domTouchEndSub?.cancel();
  }

  Future<void> _loadLayout() async {
    setState(() => _isLoadingLayout = true);
    final layoutData = await CustomDocApiService.instance.getTemplateLayout(
      level: widget.level,
      templateFilename: widget.templateFileName,
    );

    if (mounted) {
      setState(() {
        _isLoadingLayout = false;
        if (layoutData != null && layoutData['elements'] is List) {
          _layoutElements = List<Map<String, dynamic>>.from(
            (layoutData['elements'] as List).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          );

          // Tự động khởi tạo controllers cho các trường có trong layout mà chưa có trong metadata
          for (final el in _layoutElements) {
            final type = el['type'] as String? ?? '';
            final name = el['name'] as String? ?? '';
            if (type == 'table' ||
                type == 'list' ||
                type == 'input_table' ||
                type == 'input_list' ||
                type == 'persons' ||
                type == 'input_persons' ||
                type == 'persons_section') {
              if (!_complexValues.containsKey(name)) {
                final initVal = widget.initialValues[name];
                _complexValues[name] = initVal is List
                    ? List.from(initVal)
                    : [];
              }
            } else if (type == 'paragraph') {
              final runs = el['runs'] as List? ?? [];
              for (final r in runs) {
                if (r is Map && r['type'] == 'field') {
                  final varName = r['name'] as String? ?? '';
                  if (varName.isNotEmpty &&
                      !varName.startsWith('person.') &&
                      !varName.startsWith('case.') &&
                      !_textControllers.containsKey(varName)) {
                    final rawName = varName.startsWith('ngay_')
                        ? varName.substring(5)
                        : varName;
                    final initVal =
                        widget.initialValues[varName] ??
                        widget.initialValues[rawName];
                    final ctrl = TextEditingController(
                      text: initVal?.toString() ?? '',
                    );
                    ctrl.addListener(_onContentChanged);
                    _textControllers[varName] = ctrl;
                  }
                }
              }
            }
          }
        }
      });
    }
  }

  TextEditingController? _getController(String varName) {
    if (_textControllers.containsKey(varName)) {
      return _textControllers[varName];
    }
    if (varName.startsWith('ngay_')) {
      final rawName = varName.substring(5);
      if (_textControllers.containsKey(rawName)) {
        return _textControllers[rawName];
      }
    }
    if (_textControllers.containsKey('ngay_$varName')) {
      return _textControllers['ngay_$varName'];
    }
    // Tự động tạo nếu chưa có
    final newCtrl = TextEditingController(
      text: widget.initialValues[varName]?.toString() ?? '',
    );
    newCtrl.addListener(_onContentChanged);
    _textControllers[varName] = newCtrl;
    return newCtrl;
  }

  Future<void> _submitToPreview() async {
    _autoSaveDebounceTimer?.cancel();

    final resultFields = <String, dynamic>{};
    for (final entry in _textControllers.entries) {
      resultFields[entry.key] = entry.value.text.trim();
    }
    for (final entry in _complexValues.entries) {
      resultFields[entry.key] = entry.value;
    }

    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : widget.templateDisplayName;

    await widget.onSave({
      'title': title,
      'custom_fields': resultFields,
    }, isAutoSave: false);
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      // backgroundColor: const Color(0xFFF1F3F4),
      appBarIcon: Icons.edit_document,
      appBarTitle: widget.templateDisplayName,
      appBarActions: [
        // Trạng thái và Toggle Auto-Save
        AutoSaveIndicator(
          isAutoSaveEnabled: _isAutoSaveEnabled,
          onToggleAutoSave: _toggleAutoSave,
          status: _autoSaveStatus,
          lastSavedTime: _lastSavedTime,
          onManualSave: _manualSave,
          isSaving: widget.isSaving || _autoSaveStatus == AutoSaveStatus.saving,
        ),
        const SizedBox(width: 8),
        // Nút Xem trước PDF
        AppButton.primary(
          onPressed: widget.isSaving ? null : _submitToPreview,
          isLoading: widget.isSaving,
          icon: Icons.visibility_rounded,
          label: 'Xem trước PDF',
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: _zoomScale,
                          end: _zoomScale,
                        ),
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOutCubic,
                        builder: (context, animScale, child) {
                          return SizedBox(width: 820 * animScale, child: child);
                        },
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: 820,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Box Tên lưu trữ biên bản nằm ở ngoài phía trên tờ A4
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.04,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: CustomTextInput(
                                      controller: _titleController,
                                      label: 'Tên lưu trữ',
                                      isRequired: true,
                                      icon: Icons.bookmark_border_rounded,
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                          ? 'Vui lòng nhập tên biên bản'
                                          : null,
                                    ),
                                  ),
                                  // Tờ giấy A4 chuẩn Microsoft Word
                                  A4PaperSheet(
                                    isLoadingLayout: _isLoadingLayout,
                                    layoutElements: _layoutElements,
                                    fields: widget.fields,
                                    getController: _getController,
                                    complexValues: _complexValues,
                                    availablePersons: widget.availablePersons,
                                    caseData: widget.caseData,
                                    person: widget.person,
                                    onComplexValueChanged: (name, val) {
                                      setState(() {
                                        _complexValues[name] = val;
                                      });
                                      _onContentChanged();
                                    },
                                    onContentChanged: _onContentChanged,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: AppContainer.iconBox(
                  padding: EdgeInsets.all(1),
                  width: 125,
                  color: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withValues(alpha: 0.75),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      AppIconButton(
                        icon: Icons.remove,
                        size: 18,
                        tooltip: 'Thu nhỏ tờ A4 (Ctrl + Cuộn chuột)',
                        onPressed: () {
                          setState(() {
                            _zoomScale = (_zoomScale - 0.1).clamp(0.6, 2.0);
                          });
                        },
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () {
                          setState(() {
                            _zoomScale = 1.0;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Text(
                            '${(_zoomScale * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      AppIconButton(
                        icon: Icons.add,
                        size: 18,
                        tooltip: 'Phóng to tờ A4 (Ctrl + Cuộn chuột)',
                        onPressed: () {
                          setState(() {
                            _zoomScale = (_zoomScale + 0.1).clamp(0.6, 2.0);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
