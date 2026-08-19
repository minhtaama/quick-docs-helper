import 'package:flutter/material.dart';
import '../../common/panel.dart';
import '../../common/text_input.dart';
import '../../common/date_time_input.dart';
import '../../../services/api_service.dart';

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
  final ValueChanged<Map<String, dynamic>> onSave;
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialTitle.isNotEmpty
          ? widget.initialTitle
          : widget.templateDisplayName,
    );

    // Khởi tạo controllers cho các trường trong metadata
    for (final field in widget.fields) {
      final name = field['name'] as String? ?? '';
      final type = field['type'] as String? ?? 'text';
      final initVal = widget.initialValues[name];

      if (type == 'table' || type == 'list' || type == 'persons') {
        if (initVal is List) {
          _complexValues[name] = List.from(initVal);
        } else {
          _complexValues[name] = [];
        }
      } else {
        _textControllers[name] = TextEditingController(
          text: initVal?.toString() ?? '',
        );
      }
    }

    _loadLayout();
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
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
                    _textControllers[varName] = TextEditingController(
                      text: initVal?.toString() ?? '',
                    );
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
    _textControllers[varName] = newCtrl;
    return newCtrl;
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final resultFields = <String, dynamic>{};
      for (final entry in _textControllers.entries) {
        resultFields[entry.key] = entry.value.text.trim();
      }
      for (final entry in _complexValues.entries) {
        resultFields[entry.key] = entry.value;
      }

      widget.onSave({
        'title': _titleController.text.trim(),
        'custom_fields': resultFields,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      backgroundColor: const Color(0xFFF1F3F4),
      appBarIcon: Icons.edit_document,
      appBarTitle: 'Soạn thảo: ${widget.templateDisplayName}',
      appBarActions: [
        TextButton.icon(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Quay lại'),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: FilledButton.icon(
            onPressed: widget.isSaving ? null : _submit,
            icon: widget.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: const Text('Lưu & Xem trước PDF'),
          ),
        ),
      ],
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
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
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CustomTextInput(
                      controller: _titleController,
                      label: 'Tên lưu trữ biên bản / Tiêu đề hồ sơ (*)',
                      isRequired: true,
                      icon: Icons.bookmark_border_rounded,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Vui lòng nhập tên biên bản'
                          : null,
                    ),
                  ),

                  // Tờ giấy A4 chuẩn Microsoft Word
                  _buildA4PaperSheet(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildA4PaperSheet(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: 'Times New Roman',
        fontFamilyFallback: [
          'Times New Roman',
          'Tinos',
          'Noto Serif',
          'Times',
          'serif',
        ],
        fontSize: 18.0,
        color: Colors.black,
        height: 1.5,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoadingLayout)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Đang nạp cấu trúc tờ văn bản A4...'),
                    ],
                  ),
                ),
              )
            else if (_layoutElements.isNotEmpty)
              ..._layoutElements.map((el) => _buildLayoutElement(el, context))
            else
              ..._buildFallbackForm(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutElement(Map<String, dynamic> el, BuildContext context) {
    final type = el['type'] as String? ?? 'spacer';

    switch (type) {
      case 'spacer':
        final h = (el['height'] as num?)?.toDouble() ?? 0.0;
        return SizedBox(height: h);

      case 'paragraph':
        return _buildParagraphElement(el, context);

      case 'persons_section':
        final name = el['name'] as String? ?? '';
        final fieldInfo = Map<String, dynamic>.from(
          el['field_info'] as Map? ?? {},
        );
        final label =
            fieldInfo['label'] as String? ??
            (name.isNotEmpty ? name : '<Không có dữ liệu label>');
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: _InlinePersonsSection(
            label: label,
            availablePersons: widget.availablePersons,
            selectedPersonIds: List<String>.from(_complexValues[name] ?? []),
            onChanged: (ids) {
              setState(() {
                _complexValues[name] = ids;
              });
            },
          ),
        );

      case 'list':
        final name = el['name'] as String? ?? '';
        final fieldInfo = Map<String, dynamic>.from(
          el['field_info'] as Map? ?? {},
        );
        final label =
            fieldInfo['label'] as String? ??
            (name.isNotEmpty ? name : '<Không có dữ liệu label>');
        final itemSchema =
            (fieldInfo['item_schema'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: _InlineListSection(
            label: label,
            itemSchema: itemSchema,
            initialRows: List<Map<String, dynamic>>.from(
              (_complexValues[name] as List?)?.map(
                    (e) => Map<String, dynamic>.from(e as Map),
                  ) ??
                  [],
            ),
            onChanged: (rows) {
              _complexValues[name] = rows;
            },
          ),
        );

      case 'table':
        final name = el['name'] as String? ?? '';
        final fieldInfo = Map<String, dynamic>.from(
          el['field_info'] as Map? ?? {},
        );
        final label =
            fieldInfo['label'] as String? ??
            (name.isNotEmpty ? name : '<Không có dữ liệu label>');
        final itemSchema =
            (fieldInfo['item_schema'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: _InlineTableSection(
            label: label,
            itemSchema: itemSchema,
            initialRows: List<Map<String, dynamic>>.from(
              (_complexValues[name] as List?)?.map(
                    (e) => Map<String, dynamic>.from(e as Map),
                  ) ??
                  [],
            ),
            onChanged: (rows) {
              _complexValues[name] = rows;
            },
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // --- Helper Methods khử trùng lặp (DRY) ---

  static const List<String> _fontFallback = [
    'Times New Roman',
    'Tinos',
    'Noto Serif',
    'Times',
    'serif',
  ];

  TextStyle _docTextStyle({
    String font = 'Times New Roman',
    double fontSize = 18.0,
    bool bold = false,
    bool italic = false,
    Color color = Colors.black,
    double wordSpacing = 0.0,
    double? height,
  }) {
    return TextStyle(
      fontFamily: font,
      fontFamilyFallback: _fontFallback,
      fontSize: fontSize,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: color,
      wordSpacing: wordSpacing,
      height: height,
    );
  }

  String _resolveFieldValue(String varName) {
    if (varName.startsWith('person.')) {
      final prop = varName.substring(7);
      return widget.person?[prop]?.toString() ?? '';
    }
    if (varName.startsWith('case.')) {
      final prop = varName.substring(5);
      return widget.caseData?[prop]?.toString() ?? '';
    }
    return '';
  }

  double _measureTextWidth(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width;
  }

  Widget _buildParagraphElement(Map<String, dynamic> el, BuildContext context) {
    final alignStr = el['align'] as String? ?? 'left';
    final rawRuns =
        (el['runs'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    var wrapAlign = WrapAlignment.start;
    if (alignStr == 'center') wrapAlign = WrapAlignment.center;
    if (alignStr == 'right') wrapAlign = WrapAlignment.end;

    // Tiền xử lý runs để gộp cụm ngày tháng năm (từ {{ ngay_X }} đến {{ nam_X }}) thành 1 ô duy nhất
    final processedRuns = <Map<String, dynamic>>[];
    int i = 0;
    while (i < rawRuns.length) {
      final currentRun = rawRuns[i];
      final currentType = currentRun['type'] as String? ?? 'text';
      final currentName = currentRun['name'] as String? ?? '';

      // Kiểm tra nếu currentRun là biến ngày bắt đầu bằng ngay_
      if (currentType == 'field' && currentName.startsWith('ngay_')) {
        final dateSuffix = currentName.substring(5); // ví dụ: lap_bb
        final thangVar = 'thang_$dateSuffix';
        final namVar = 'nam_$dateSuffix';

        // Kiểm tra xem phía sau có chuỗi chứa 'tháng', thangVar, 'năm', namVar không
        int j = i + 1;
        bool foundThang = false;
        bool foundNam = false;
        int endIdx = i;

        while (j < rawRuns.length && j <= i + 6) {
          final r = rawRuns[j];
          final rName = r['name'] as String? ?? '';
          if (rName == thangVar) foundThang = true;
          if (rName == namVar) {
            foundNam = true;
            endIdx = j;
            break;
          }
          j++;
        }

        if (foundThang && foundNam) {
          // Gộp cụm: chỉ thêm 1 run field ngày đại diện, bỏ qua các thẻ trung gian đến endIdx
          processedRuns.add({
            'type': 'field',
            'name': currentName,
            'is_collapsed_date': true,
            'field_info':
                currentRun['field_info'] ??
                {'type': 'date', 'name': currentName},
          });
          i = endIdx + 1;
          continue;
        }
      }

      processedRuns.add(currentRun);
      i++;
    }

    // Nếu đoạn văn bản hoàn toàn rỗng, không hiển thị khoảng trống
    if (processedRuns.isEmpty) return const SizedBox.shrink();

    final topSpace = (el['space_before'] as num?)?.toDouble() ?? 0.0;
    final bottomSpace = (el['space_after'] as num?)?.toDouble() ?? 0.0;
    final fli = (el['first_line_indent'] as num?)?.toDouble() ?? 0.0;
    final li = (el['left_indent'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: EdgeInsets.only(
        top: topSpace > 0 ? topSpace : 1.0,
        bottom: bottomSpace > 0 ? bottomSpace : 1.0,
        left: li > 0 ? li : 0.0,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth = constraints.maxWidth;

          final List<Widget> children = [];
          if (fli > 0) {
            children.add(SizedBox(width: fli));
          }

          children.addAll(
            processedRuns.asMap().entries.map<Widget>((entry) {
              final idx = entry.key;
              final run = entry.value;
              final runType = run['type'] as String? ?? 'text';
              final isRunBold = run['bold'] == true;
              final isRunItalic = run['italic'] == true;
              final fSize = ((run['size'] as num?)?.toDouble() ?? 14.0) + 4.0;
              final fFamily = run['font'] as String? ?? 'Times New Roman';

              if (runType == 'text') {
                final text = run['text'] as String? ?? '';
                final isRunSubscript = run['subscript'] == true;
                final isRunSuperscript = run['superscript'] == true;
                final textWidget = Text(
                  text,
                  style: _docTextStyle(
                    font: fFamily,
                    fontSize: (isRunSubscript || isRunSuperscript)
                        ? fSize * 0.75
                        : fSize,
                    bold: isRunBold,
                    italic: isRunItalic,
                    wordSpacing: -1,
                  ),
                );
                if (isRunSuperscript) {
                  return Transform.translate(
                    offset: const Offset(0, -6),
                    child: textWidget,
                  );
                } else if (isRunSubscript) {
                  return Transform.translate(
                    offset: const Offset(0, 4),
                    child: textWidget,
                  );
                }
                return textWidget;
              } else if (runType == 'field') {
                final varName = run['name'] as String? ?? '';

                // 1 & 2: Biến của person.* hoặc case.*
                if (varName.startsWith('person.') ||
                    varName.startsWith('case.')) {
                  final val = _resolveFieldValue(varName);
                  final isPerson = varName.startsWith('person.');
                  final display = val.isNotEmpty
                      ? ' $val '
                      : (isPerson ? '     ' : ' .................... ');
                  return Text(
                    display,
                    style: _docTextStyle(
                      font: fFamily,
                      fontSize: fSize,
                      bold: isRunBold,
                      italic: isRunItalic,
                      wordSpacing: -0.5,
                    ),
                  );
                }

                // 3. Nếu là trường custom_fields
                final controller = _getController(varName);
                if (controller == null) {
                  return Text(
                    ' {{ $varName }} ',
                    style: _docTextStyle(
                      font: fFamily,
                      fontSize: fSize,
                      color: Colors.grey,
                      wordSpacing: -0.5,
                    ),
                  );
                }

                final fieldInfo = Map<String, dynamic>.from(
                  run['field_info'] as Map? ?? {},
                );
                final fType = fieldInfo['type'] as String? ?? 'text';
                final fPlaceholder =
                    fieldInfo['placeholder'] as String? ?? '...';
                final isCollapsedDate = run['is_collapsed_date'] == true;

                if (fType == 'date' ||
                    isCollapsedDate ||
                    varName.startsWith('ngay_')) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: DateTimeInput(
                      isInline: true,
                      inlineFontSize: fSize - 1.5,
                      controller: controller,
                      label: fieldInfo['label'] as String? ?? varName,
                      hint: fPlaceholder.isNotEmpty
                          ? fPlaceholder
                          : 'dd/mm/yyyy',
                    ),
                  );
                } else if (fType == 'textarea') {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: CustomTextInput(
                        isInline: true,
                        inlineFontSize: fSize,
                        controller: controller,
                        label: fieldInfo['label'] as String? ?? varName,
                        hint: fPlaceholder,
                        minLines: 2,
                        maxLines: 4,
                      ),
                    ),
                  );
                } else {
                  // Ô text 1 dòng - Khởi tạo widget 1 lần duy nhất (DRY)
                  final inputWidget = CustomTextInput(
                    isInline: true,
                    inlineFontSize: fSize - 0.5,
                    controller: controller,
                    label: fieldInfo['label'] as String? ?? varName,
                    hint: fPlaceholder,
                  );

                  // Kiểm tra xem đây có phải là ô input ở cuối đoạn văn không
                  final bool isTrailingField =
                      (idx == processedRuns.length - 1) ||
                      processedRuns
                          .sublist(idx + 1)
                          .every(
                            (r) =>
                                r['type'] == 'text' &&
                                (r['text'] as String? ?? '').trim().isEmpty,
                          );

                  if (isTrailingField) {
                    double prefixWidth = fli > 0 ? fli : 0.0;
                    int fieldCount =
                        1; // Tính cả ô input cuối này (có padding ngang 8px)
                    for (int pIdx = 0; pIdx < idx; pIdx++) {
                      final pRun = processedRuns[pIdx];
                      final pType = pRun['type'] as String? ?? 'text';
                      final pBold = pRun['bold'] == true;
                      final pItalic = pRun['italic'] == true;
                      final pSz =
                          ((pRun['size'] as num?)?.toDouble() ?? 14.0) + 4.0;
                      final pFam = pRun['font'] as String? ?? 'Times New Roman';

                      if (pType == 'text') {
                        final pText = pRun['text'] as String? ?? '';
                        final pSub = pRun['subscript'] == true;
                        final pSup = pRun['superscript'] == true;
                        final realSz = (pSub || pSup) ? pSz * 0.75 : pSz;
                        prefixWidth += _measureTextWidth(
                          pText,
                          _docTextStyle(
                            font: pFam,
                            fontSize: realSz,
                            bold: pBold,
                            italic: pItalic,
                            wordSpacing: -1,
                          ),
                        );
                      } else if (pType == 'field') {
                        final pName = pRun['name'] as String? ?? '';
                        if (pName.startsWith('person.') ||
                            pName.startsWith('case.')) {
                          final val = _resolveFieldValue(pName);
                          final display = val.isNotEmpty ? ' $val ' : '     ';
                          prefixWidth += _measureTextWidth(
                            display,
                            _docTextStyle(
                              font: pFam,
                              fontSize: pSz,
                              bold: pBold,
                              italic: pItalic,
                              wordSpacing: -0.5,
                            ),
                          );
                        } else {
                          // Ô input trước đó (ví dụ ô ngày)
                          fieldCount++;
                          final fInfo = Map<String, dynamic>.from(
                            pRun['field_info'] as Map? ?? {},
                          );
                          final fType = fInfo['type'] as String? ?? 'text';
                          if (fType == 'date' ||
                              pRun['is_collapsed_date'] == true ||
                              pName.startsWith('ngay_')) {
                            prefixWidth += (130.0 + 12.0);
                          } else {
                            prefixWidth += 140.0 + 12.0;
                          }
                        }
                      }
                    }

                    // Tính remainingWidth trừ đi 2px theo yêu cầu để Wrap không bao giờ bị tràn sang dòng mới
                    final double remainingWidth =
                        availableWidth -
                        prefixWidth -
                        (fieldCount * 8.0) -
                        12.0;
                    if (remainingWidth >= 100.0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SizedBox(
                          width: remainingWidth,
                          child: inputWidget,
                        ),
                      );
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: IntrinsicWidth(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 140,
                          maxWidth: 450,
                        ),
                        child: inputWidget,
                      ),
                    ),
                  );
                }
              }

              return const SizedBox.shrink();
            }),
          );

          return Wrap(
            alignment: wrapAlign,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          );
        },
      ),
    );
  }

  List<Widget> _buildFallbackForm(BuildContext context) {
    return widget.fields.map((field) {
      final name = field['name'] as String? ?? '';
      final label = field['label'] as String? ?? name;
      final type = field['type'] as String? ?? 'text';
      final ctrl = _textControllers[name];

      if (ctrl != null) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CustomTextInput(
            controller: ctrl,
            label: label,
            minLines: type == 'textarea' ? 3 : 1,
            maxLines: type == 'textarea' ? 5 : 1,
          ),
        );
      }
      return const SizedBox.shrink();
    }).toList();
  }
}

/// Widget Danh sách người tham gia inline trên tờ giấy
class _InlinePersonsSection extends StatelessWidget {
  final String label;
  final List<Map<String, dynamic>> availablePersons;
  final List<String> selectedPersonIds;
  final ValueChanged<List<String>> onChanged;

  const _InlinePersonsSection({
    required this.label,
    required this.availablePersons,
    required this.selectedPersonIds,
    required this.onChanged,
  });

  void _showSelectDialog(BuildContext context) {
    final tempSelected = Set<String>.from(selectedPersonIds);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          return AlertDialog(
            title: Text('Chọn đối tượng: $label'),
            content: SizedBox(
              width: 480,
              height: 380,
              child: availablePersons.isEmpty
                  ? const Center(
                      child: Text('Chưa có đối tượng nào trong hồ sơ'),
                    )
                  : ListView.builder(
                      itemCount: availablePersons.length,
                      itemBuilder: (context, index) {
                        final person = availablePersons[index];
                        final id = person['id']?.toString() ?? '';
                        final hoTen =
                            person['ho_ten']?.toString() ?? 'Không rõ';
                        final cccd = person['cccd']?.toString() ?? '';
                        final isSelected = tempSelected.contains(id);

                        return CheckboxListTile(
                          value: isSelected,
                          activeColor: theme.colorScheme.primary,
                          title: Text(
                            hoTen,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            cccd.isNotEmpty ? 'CCCD: $cccd' : 'Chưa có CCCD',
                          ),
                          secondary: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            foregroundColor: theme.colorScheme.primary,
                            child: Text(hoTen.isNotEmpty ? hoTen[0] : '?'),
                          ),
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                tempSelected.add(id);
                              } else {
                                tempSelected.remove(id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  onChanged(tempSelected.toList());
                  Navigator.of(ctx).pop();
                },
                child: const Text('Xác nhận'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Times New Roman',
                  fontFamilyFallback: [
                    'Times New Roman',
                    'Tinos',
                    'Noto Serif',
                    'Times',
                    'serif',
                  ],
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showSelectDialog(context),
                icon: const Icon(Icons.person_add_alt_1, size: 15),
                label: const Text(
                  'Chọn đối tượng',
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontFamilyFallback: [
                      'Times New Roman',
                      'Tinos',
                      'Noto Serif',
                      'Times',
                      'serif',
                    ],
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (selectedPersonIds.isEmpty)
            Text(
              'Chưa chọn đối tượng nào (Bấm "Chọn đối tượng" ở trên)',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontFamilyFallback: const [
                  'Times New Roman',
                  'Tinos',
                  'Noto Serif',
                  'Times',
                  'serif',
                ],
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: selectedPersonIds.map((id) {
                final matched = availablePersons.firstWhere(
                  (p) => p['id']?.toString() == id,
                  orElse: () => {'ho_ten': id},
                );
                final name = matched['ho_ten']?.toString() ?? id;
                final cccd = matched['cccd']?.toString() ?? '';

                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: primaryColor.withValues(alpha: 0.15),
                    foregroundColor: primaryColor,
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: const TextStyle(
                        fontFamily: 'Times New Roman',
                        fontFamilyFallback: [
                          'Times New Roman',
                          'Tinos',
                          'Noto Serif',
                          'Times',
                          'serif',
                        ],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  label: Text(
                    cccd.isNotEmpty ? '$name ($cccd)' : name,
                    style: const TextStyle(
                      fontFamily: 'Times New Roman',
                      fontFamilyFallback: [
                        'Times New Roman',
                        'Tinos',
                        'Noto Serif',
                        'Times',
                        'serif',
                      ],
                      fontSize: 14,
                    ),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    final updated = List<String>.from(selectedPersonIds)
                      ..remove(id);
                    onChanged(updated);
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

/// Widget Danh sách khối (type: "list") - Mỗi lượt là 1 Card, các field con xếp dọc từng dòng riêng biệt
class _InlineListSection extends StatefulWidget {
  final String label;
  final List<Map<String, dynamic>> itemSchema;
  final List<Map<String, dynamic>> initialRows;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const _InlineListSection({
    required this.label,
    required this.itemSchema,
    required this.initialRows,
    required this.onChanged,
  });

  @override
  State<_InlineListSection> createState() => _InlineListSectionState();
}

class _InlineListSectionState extends State<_InlineListSection> {
  final List<Map<String, TextEditingController>> _controllers = [];

  @override
  void initState() {
    super.initState();
    for (final row in widget.initialRows) {
      final map = <String, TextEditingController>{};
      for (final col in widget.itemSchema) {
        final cName = col['name'] as String? ?? '';
        final ctrl = TextEditingController(text: row[cName]?.toString() ?? '');
        ctrl.addListener(_notify);
        map[cName] = ctrl;
      }
      _controllers.add(map);
    }
  }

  @override
  void dispose() {
    for (final m in _controllers) {
      for (final c in m.values) {
        c.removeListener(_notify);
        c.dispose();
      }
    }
    super.dispose();
  }

  void _notify() {
    final res = _controllers.map((m) {
      final r = <String, dynamic>{};
      for (final e in m.entries) {
        r[e.key] = e.value.text.trim();
      }
      return r;
    }).toList();
    widget.onChanged(res);
  }

  void _addRow() {
    final map = <String, TextEditingController>{};
    for (final col in widget.itemSchema) {
      final cName = col['name'] as String? ?? '';
      final ctrl = TextEditingController();
      ctrl.addListener(_notify);
      map[cName] = ctrl;
    }
    setState(() {
      _controllers.add(map);
    });
    _notify();
  }

  void _removeRow(int idx) {
    final removed = _controllers.removeAt(idx);
    for (final c in removed.values) {
      c.removeListener(_notify);
      c.dispose();
    }
    setState(() {});
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_controllers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Danh sách "${widget.label}" chưa có dữ liệu',
                    style: TextStyle(
                      fontFamily: 'Times New Roman',
                      fontFamilyFallback: const [
                        'Times New Roman',
                        'Tinos',
                        'Noto Serif',
                        'Times',
                        'serif',
                      ],
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Thêm',
                    style: TextStyle(
                      fontFamily: 'Times New Roman',
                      fontFamilyFallback: [
                        'Times New Roman',
                        'Tinos',
                        'Noto Serif',
                        'Times',
                        'serif',
                      ],
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: _controllers.asMap().entries.map((entry) {
              final idx = entry.key;
              final ctrlMap = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header của từng lượt
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '# ${idx + 1}',
                                style: TextStyle(
                                  fontFamily: 'Times New Roman',
                                  fontFamilyFallback: const [
                                    'Times New Roman',
                                    'Tinos',
                                    'Noto Serif',
                                    'Times',
                                    'serif',
                                  ],
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Colors.red.shade400,
                          ),
                          tooltip: 'Xóa',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _removeRow(idx),
                        ),
                      ],
                    ),
                    const Divider(height: 16),

                    // Từng field con hiển thị trên 1 dòng riêng biệt
                    ...widget.itemSchema.map((col) {
                      final cName = col['name'] as String? ?? '';
                      final cLabel = col['label']?.toString() ?? cName;
                      final cType = col['type'] as String? ?? 'text';
                      final cPlaceholder =
                          col['placeholder']?.toString() ??
                          'Nhập ${cLabel.toLowerCase()}...';
                      final ctrl = ctrlMap[cName]!;

                      final bool isMultiLine = cType == 'textarea';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$cLabel:',
                              style: const TextStyle(
                                fontFamily: 'Times New Roman',
                                fontFamilyFallback: [
                                  'Times New Roman',
                                  'Tinos',
                                  'Noto Serif',
                                  'Times',
                                  'serif',
                                ],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            CustomTextInput(
                              isInline: true,
                              controller: ctrl,
                              label: cLabel,
                              hint: cPlaceholder,
                              minLines: isMultiLine ? 3 : 1,
                              maxLines: isMultiLine ? 9999 : 1,
                              inlineFontSize: 16,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }).toList(),
          ),
        if (_controllers.isNotEmpty)
          FilledButton.tonalIcon(
            onPressed: _addRow,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text(
              'Thêm',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontFamilyFallback: [
                  'Times New Roman',
                  'Tinos',
                  'Noto Serif',
                  'Times',
                  'serif',
                ],
              ),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
              visualDensity: VisualDensity.compact,
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}

/// Widget Bảng kẻ ô tương tác trực tiếp trên tờ giấy A4 (type: "table" - chia cột theo các field con)
class _InlineTableSection extends StatefulWidget {
  final String label;
  final List<Map<String, dynamic>> itemSchema;
  final List<Map<String, dynamic>> initialRows;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const _InlineTableSection({
    required this.label,
    required this.itemSchema,
    required this.initialRows,
    required this.onChanged,
  });

  @override
  State<_InlineTableSection> createState() => _InlineTableSectionState();
}

class _InlineTableSectionState extends State<_InlineTableSection> {
  final List<Map<String, TextEditingController>> _controllers = [];

  @override
  void initState() {
    super.initState();
    for (final row in widget.initialRows) {
      final map = <String, TextEditingController>{};
      for (final col in widget.itemSchema) {
        final cName = col['name'] as String? ?? '';
        final ctrl = TextEditingController(text: row[cName]?.toString() ?? '');
        ctrl.addListener(_notify);
        map[cName] = ctrl;
      }
      _controllers.add(map);
    }
  }

  @override
  void dispose() {
    for (final m in _controllers) {
      for (final c in m.values) {
        c.removeListener(_notify);
        c.dispose();
      }
    }
    super.dispose();
  }

  void _notify() {
    final res = _controllers.map((m) {
      final r = <String, dynamic>{};
      for (final e in m.entries) {
        r[e.key] = e.value.text.trim();
      }
      return r;
    }).toList();
    widget.onChanged(res);
  }

  void _addRow() {
    final map = <String, TextEditingController>{};
    for (final col in widget.itemSchema) {
      final cName = col['name'] as String? ?? '';
      final ctrl = TextEditingController();
      ctrl.addListener(_notify);
      map[cName] = ctrl;
    }
    setState(() {
      _controllers.add(map);
    });
    _notify();
  }

  void _removeRow(int idx) {
    final removed = _controllers.removeAt(idx);
    for (final c in removed.values) {
      c.removeListener(_notify);
      c.dispose();
    }
    setState(() {});
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'Times New Roman',
                fontFamilyFallback: [
                  'Times New Roman',
                  'Tinos',
                  'Noto Serif',
                  'Times',
                  'serif',
                ],
                fontWeight: FontWeight.bold,
                fontSize: 15.0,
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _addRow,
              icon: const Icon(Icons.add, size: 15),
              label: const Text(
                'Thêm dòng',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontFamilyFallback: [
                    'Times New Roman',
                    'Tinos',
                    'Noto Serif',
                    'Times',
                    'serif',
                  ],
                ),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_controllers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text(
                'Bảng chưa có dữ liệu. Bấm "Thêm dòng" ở trên để nhập dữ liệu.',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontFamilyFallback: [
                    'Times New Roman',
                    'Tinos',
                    'Noto Serif',
                    'Times',
                    'serif',
                  ],
                  fontSize: 13.5,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 1),
            ),
            child: Column(
              children: [
                // Header Bảng
                Container(
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        child: const Text(
                          'STT',
                          style: TextStyle(
                            fontFamily: 'Times New Roman',
                            fontFamilyFallback: [
                              'Times New Roman',
                              'Tinos',
                              'Noto Serif',
                              'Times',
                              'serif',
                            ],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      ...widget.itemSchema.map((col) {
                        final colLabel = col['label']?.toString();
                        final colName = col['name']?.toString();
                        final displayLabel =
                            (colLabel != null && colLabel.trim().isNotEmpty)
                            ? colLabel
                            : ((colName != null && colName.trim().isNotEmpty)
                                  ? colName
                                  : '<Không có nhãn cột>');

                        return Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 6,
                            ),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: Colors.black87,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Text(
                              displayLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Times New Roman',
                                fontFamilyFallback: [
                                  'Times New Roman',
                                  'Tinos',
                                  'Noto Serif',
                                  'Times',
                                  'serif',
                                ],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.black87, thickness: 1),
                // Các hàng dữ liệu
                ..._controllers.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final ctrlMap = entry.value;

                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          alignment: Alignment.center,
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(
                              fontFamily: 'Times New Roman',
                              fontFamilyFallback: [
                                'Times New Roman',
                                'Tinos',
                                'Noto Serif',
                                'Times',
                                'serif',
                              ],
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...widget.itemSchema.map((col) {
                          final cName = col['name'] as String? ?? '';
                          final cType = col['type'] as String? ?? 'text';
                          final ctrl = ctrlMap[cName]!;

                          return Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: CustomTextInput(
                                isInline: true,
                                controller: ctrl,
                                label: '',
                                hint: 'Nhập...',
                                minLines: cType == 'textarea' ? 2 : 1,
                                maxLines: cType == 'textarea' ? 3 : 1,
                              ),
                            ),
                          );
                        }),
                        SizedBox(
                          width: 40,
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Xóa dòng này',
                            onPressed: () => _removeRow(idx),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}
