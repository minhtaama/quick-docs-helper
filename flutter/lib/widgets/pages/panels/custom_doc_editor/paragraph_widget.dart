import 'package:flutter/material.dart';
import '../../../common/date_time_input.dart';
import '../../../common/dropdown_input.dart';
import '../../../common/text_input.dart';
import 'editor_utils.dart';

/// Widget hiển thị đoạn văn bản (paragraph) kèm các trường nhập liệu inline
class DocParagraphWidget extends StatelessWidget {
  final Map<String, dynamic> element;
  final TextEditingController? Function(String varName) getController;
  final Map<String, dynamic>? caseData;
  final Map<String, dynamic>? person;
  final int? loopIndex;
  final VoidCallback? onContentChanged;

  const DocParagraphWidget({
    super.key,
    required this.element,
    required this.getController,
    this.caseData,
    this.person,
    this.loopIndex,
    this.onContentChanged,
  });

  void _handleLinkedFields(dynamic item) {
    if (item is Map && item['linked_fields'] is Map) {
      final linkedMap = Map<String, dynamic>.from(item['linked_fields'] as Map);
      linkedMap.forEach((targetVar, targetVal) {
        final targetController = getController(targetVar);
        if (targetController != null) {
          targetController.text = targetVal?.toString() ?? '';
        }
      });
      onContentChanged?.call();
    }
  }

  String _resolveFieldValue(String rawVarName) {
    final varName = rawVarName.replaceAll(' ', '');
    if (varName == 'loop.index') {
      return '${loopIndex ?? 1}';
    }
    if (varName.startsWith('p.')) {
      final prop = varName.substring(2);
      return person?[prop]?.toString() ?? '';
    }
    if (varName.startsWith('person.')) {
      final prop = varName.substring(7);
      return person?[prop]?.toString() ?? '';
    }
    if (varName.startsWith('case.')) {
      final prop = varName.substring(5);
      return caseData?[prop]?.toString() ?? '';
    }
    return '';
  }

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
      fontFamilyFallback: DocEditorUtils.fontFallback,
      fontSize: fontSize,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: color,
      wordSpacing: wordSpacing,
      height: height,
    );
  }

  bool _isStaticRun(Map<String, dynamic> run) {
    final runType = run['type'] as String? ?? 'text';
    if (runType == 'text') return true;
    if (runType == 'field') {
      final varName = (run['name'] as String? ?? '').replaceAll(' ', '');
      if (varName == 'loop.index' ||
          varName.startsWith('person.') ||
          varName.startsWith('p.') ||
          varName.startsWith('case.')) {
        return true;
      }
      if (getController(varName) == null &&
          getController(run['name'] as String? ?? '') == null) {
        return true;
      }
    }
    return false;
  }

  InlineSpan _buildSpanFromRun(Map<String, dynamic> run) {
    final runType = run['type'] as String? ?? 'text';
    final isRunBold = run['bold'] == true;
    final isRunItalic = run['italic'] == true;
    final fSize = ((run['size'] as num?)?.toDouble() ?? 14.0) + 4.0;
    final fFamily = run['font'] as String? ?? 'Times New Roman';
    final isRunSubscript = run['subscript'] == true;
    final isRunSuperscript = run['superscript'] == true;

    final style = _docTextStyle(
      font: fFamily,
      fontSize: (isRunSubscript || isRunSuperscript) ? fSize * 0.75 : fSize,
      bold: isRunBold,
      italic: isRunItalic,
      wordSpacing: -0.5,
    );

    if (runType == 'text') {
      final text = run['text'] as String? ?? '';
      return TextSpan(text: text, style: style);
    } else if (runType == 'field') {
      final rawName = run['name'] as String? ?? '';
      final varName = rawName.replaceAll(' ', '');
      if (varName == 'loop.index' ||
          varName.startsWith('person.') ||
          varName.startsWith('p.') ||
          varName.startsWith('case.')) {
        final val = _resolveFieldValue(varName);
        final isPerson =
            varName.startsWith('person.') || varName.startsWith('p.');
        final display = val.isNotEmpty
            ? val
            : (isPerson ? '.....' : '....................');
        return TextSpan(text: display, style: style);
      }
      return TextSpan(
        text: ' {{ $rawName }} ',
        style: style.copyWith(color: Colors.grey),
      );
    }
    return const TextSpan(text: '');
  }

  bool _checkIsTrailing(int idx, List<Map<String, dynamic>> runs) {
    for (int k = idx + 1; k < runs.length; k++) {
      final r = runs[k];
      final rType = r['type'] as String? ?? 'text';
      if (rType == 'field') return false;
      final txt = (r['text'] as String? ?? '').trim();
      if (txt.isNotEmpty) return false;
    }
    return true;
  }

  (double, int) _calculatePrefixWidth(
    int idx,
    List<Map<String, dynamic>> runs,
    double fli,
  ) {
    double width = fli > 0 ? fli : 0.0;
    int fieldCount = 1;
    for (int pIdx = 0; pIdx < idx; pIdx++) {
      final pRun = runs[pIdx];
      final pType = pRun['type'] as String? ?? 'text';
      final pBold = pRun['bold'] == true;
      final pItalic = pRun['italic'] == true;
      final pSz = ((pRun['size'] as num?)?.toDouble() ?? 14.0) + 4.0;
      final pFam = pRun['font'] as String? ?? 'Times New Roman';
      final pSub = pRun['subscript'] == true;
      final pSup = pRun['superscript'] == true;
      final realSz = (pSub || pSup) ? pSz * 0.75 : pSz;

      if (pType == 'text') {
        final pText = pRun['text'] as String? ?? '';
        width += DocEditorUtils.measureTextWidth(
          pText,
          _docTextStyle(
            font: pFam,
            fontSize: realSz,
            bold: pBold,
            italic: pItalic,
            wordSpacing: -1.0,
          ),
        );
      } else if (pType == 'field') {
        final pName = (pRun['name'] as String? ?? '').replaceAll(' ', '');
        if (_isStaticRun(pRun)) {
          final val = _resolveFieldValue(pName);
          final display = val.isNotEmpty ? val : '     ';
          width += DocEditorUtils.measureTextWidth(
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
          fieldCount++;
          final fInfo = Map<String, dynamic>.from(pRun['field_info'] as Map? ?? {});
          final fType = fInfo['type'] as String? ?? '';
          final isDate =
              fType == 'input_date' ||
              pRun['is_collapsed_date'] == true ||
              pName.startsWith('ngay_');
          final isDropdown = fType == 'input_dropdown';
          if (isDate) {
            width += (130.0 + 8.0);
          } else if (isDropdown) {
            width += (160.0 + 8.0);
          } else {
            width += (140.0 + 8.0);
          }
        }
      }
    }
    return (width, fieldCount);
  }

  InlineSpan _buildInteractiveSpan({
    required Map<String, dynamic> run,
    required int idx,
    required List<Map<String, dynamic>> runs,
    required double availableWidth,
    required double fli,
  }) {
    final varName = run['name'] as String? ?? '';
    final controller = getController(varName);
    if (controller == null) return const TextSpan(text: '');

    final fieldInfo = Map<String, dynamic>.from(
      run['field_info'] as Map? ?? {},
    );
    final fType = fieldInfo['type'] as String? ?? 'input_text';
    final fPlaceholder = fieldInfo['placeholder'] as String? ?? '...';
    final fSize = ((run['size'] as num?)?.toDouble() ?? 14.0) + 4.0;
    final isCollapsedDate = run['is_collapsed_date'] == true;
    final fFamily = run['font'] as String? ?? 'Times New Roman';

    if (fType == 'input_date' || isCollapsedDate || varName.startsWith('ngay_')) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: DateTimeInput(
            isInline: true,
            inlineFontSize: fSize - 1.5,
            controller: controller,
            label: fieldInfo['label'] as String? ?? varName,
            hint: fPlaceholder.isNotEmpty ? fPlaceholder : 'dd/mm/yyyy',
          ),
        ),
      );
    }

    if (fType == 'input_dropdown') {
      final options = (fieldInfo['options'] as List?) ?? [];
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: CustomDropdownInput(
            isInline: true,
            inlineFontSize: fSize - 0.5,
            controller: controller,
            label: fieldInfo['label'] as String? ?? varName,
            hint: fPlaceholder,
            options: options,
            onItemSelected: _handleLinkedFields,
          ),
        ),
      );
    }

    // Trường hợp ô input nằm ở cuối đoạn văn bản -> tự động kéo giãn đến hết lề phải trang giấy A4
    final isTrailing = _checkIsTrailing(idx, runs);
    if (isTrailing) {
      final (prefixWidth, fieldCount) = _calculatePrefixWidth(idx, runs, fli);
      final remainingWidth =
          availableWidth - prefixWidth - (fieldCount * 8.0) - 20.0;
      if (remainingWidth >= 80.0) {
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: SizedBox(
              width: remainingWidth,
              child: CustomTextInput(
                isInline: true,
                inlineFontSize: fSize - 0.5,
                controller: controller,
                label: fieldInfo['label'] as String? ?? varName,
                hint: fPlaceholder,
              ),
            ),
          ),
        );
      }
    }

    // Trường hợp ô input nằm ở giữa câu văn -> tự co giãn theo độ dài chữ thực tế để không bị ngắt dòng
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: _InlineDynamicTextInput(
          controller: controller,
          label: fieldInfo['label'] as String? ?? varName,
          hint: fPlaceholder,
          fontSize: fSize,
          font: fFamily,
          maxWidth: availableWidth,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alignStr = element['align'] as String? ?? 'left';
    final rawRuns =
        (element['runs'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    TextAlign textAlign = TextAlign.left;
    if (alignStr == 'center') {
      textAlign = TextAlign.center;
    } else if (alignStr == 'right') {
      textAlign = TextAlign.right;
    } else if (alignStr == 'justify') {
      textAlign = TextAlign.justify;
    }

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
          processedRuns.add({
            'type': 'field',
            'name': currentName,
            'is_collapsed_date': true,
            'field_info':
                currentRun['field_info'] ??
                {'type': 'input_date', 'name': currentName},
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

    final topSpace = (element['space_before'] as num?)?.toDouble() ?? 0.0;
    final bottomSpace = (element['space_after'] as num?)?.toDouble() ?? 0.0;
    final fli = (element['first_line_indent'] as num?)?.toDouble() ?? 0.0;
    final li = (element['left_indent'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: EdgeInsets.only(
        top: topSpace > 0 ? topSpace : 1.0,
        bottom: bottomSpace > 0 ? bottomSpace : 1.0,
        left: li > 0 ? li : 0.0,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth = constraints.maxWidth;

          // Kiểm tra xem đoạn văn có chứa trường input_textarea (nhiều dòng) hay không
          final bool hasTextarea = processedRuns.any((r) {
            if (_isStaticRun(r)) return false;
            final fieldInfo = Map<String, dynamic>.from(
              r['field_info'] as Map? ?? {},
            );
            final t = fieldInfo['type'] as String? ?? '';
            return t == 'input_textarea';
          });

          if (hasTextarea) {
            final List<Widget> colWidgets = [];
            final inlineSpans = <InlineSpan>[];

            if (fli > 0 && alignStr != 'center' && alignStr != 'right') {
              inlineSpans.add(WidgetSpan(child: SizedBox(width: fli)));
            }

            for (int idx = 0; idx < processedRuns.length; idx++) {
              final run = processedRuns[idx];
              if (_isStaticRun(run)) {
                inlineSpans.add(_buildSpanFromRun(run));
              } else {
                final fieldInfo = Map<String, dynamic>.from(
                  run['field_info'] as Map? ?? {},
                );
                final fType = fieldInfo['type'] as String? ?? 'input_text';
                final varName = run['name'] as String? ?? '';
                final controller = getController(varName);
                if (controller == null) continue;

                if (fType == 'input_textarea') {
                  if (inlineSpans.isNotEmpty) {
                    colWidgets.add(
                      SizedBox(
                        width: double.infinity,
                        child: Text.rich(
                          TextSpan(children: List.from(inlineSpans)),
                          textAlign: textAlign,
                        ),
                      ),
                    );
                    inlineSpans.clear();
                  }
                  final fSize =
                      ((run['size'] as num?)?.toDouble() ?? 14.0) + 4.0;
                  final fPlaceholder =
                      fieldInfo['placeholder'] as String? ?? '...';
                  colWidgets.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: SizedBox(
                        width: double.infinity,
                        child: CustomTextInput(
                          isInline: true,
                          inlineFontSize: fSize - 2,
                          controller: controller,
                          label: fieldInfo['label'] as String? ?? varName,
                          hint: fPlaceholder,
                          minLines: 6,
                          maxLines: 9999,
                        ),
                      ),
                    ),
                  );
                } else {
                  inlineSpans.add(
                    _buildInteractiveSpan(
                      run: run,
                      idx: idx,
                      runs: processedRuns,
                      availableWidth: availableWidth,
                      fli: fli,
                    ),
                  );
                }
              }
            }

            if (inlineSpans.isNotEmpty) {
              colWidgets.add(
                SizedBox(
                  width: double.infinity,
                  child: Text.rich(
                    TextSpan(children: inlineSpans),
                    textAlign: textAlign,
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: colWidgets,
            );
          }

          // Kiểm tra xem đoạn văn có trường input nằm ở cuối dòng (như "Ông/bà: ...", "Tôi: ...", "Về việc: ...") hay không
          int? trailingIdx;
          for (int k = processedRuns.length - 1; k >= 0; k--) {
            if (!_isStaticRun(processedRuns[k])) {
              if (_checkIsTrailing(k, processedRuns)) {
                final fInfo = Map<String, dynamic>.from(
                  processedRuns[k]['field_info'] as Map? ?? {},
                );
                final fType = fInfo['type'] as String? ?? 'input_text';
                final isDate =
                    fType == 'input_date' ||
                    processedRuns[k]['is_collapsed_date'] == true ||
                    (processedRuns[k]['name'] as String? ?? '').startsWith(
                      'ngay_',
                    );
                if (!isDate && fType != 'input_textarea') {
                  trailingIdx = k;
                }
              }
              break;
            }
          }

          if (trailingIdx != null) {
            final (prefixWidth, _) = _calculatePrefixWidth(
              trailingIdx,
              processedRuns,
              fli,
            );
            if (prefixWidth < availableWidth - 60.0) {
              final List<Widget> rowChildren = [];
              if (fli > 0 && alignStr != 'center' && alignStr != 'right') {
                rowChildren.add(SizedBox(width: fli));
              }

              final List<InlineSpan> prefixSpans = [];

              void flushPrefixSpans() {
                if (prefixSpans.isNotEmpty) {
                  rowChildren.add(
                    Text.rich(
                      TextSpan(children: List.from(prefixSpans)),
                      textAlign: textAlign,
                    ),
                  );
                  prefixSpans.clear();
                }
              }

              for (int k = 0; k < trailingIdx; k++) {
                final r = processedRuns[k];
                if (_isStaticRun(r)) {
                  prefixSpans.add(_buildSpanFromRun(r));
                } else {
                  flushPrefixSpans();
                  final varName = r['name'] as String? ?? '';
                  final controller = getController(varName);
                  if (controller != null) {
                    final fieldInfo = Map<String, dynamic>.from(
                      r['field_info'] as Map? ?? {},
                    );
                    final fType = fieldInfo['type'] as String? ?? 'input_text';
                    final fPlaceholder =
                        fieldInfo['placeholder'] as String? ?? '...';
                    final fSize =
                        ((r['size'] as num?)?.toDouble() ?? 14.0) + 4.0;
                    final isCollapsedDate = r['is_collapsed_date'] == true;
                    final fFamily = r['font'] as String? ?? 'Times New Roman';

                    if (fType == 'input_date' ||
                        isCollapsedDate ||
                        varName.startsWith('ngay_')) {
                      rowChildren.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: DateTimeInput(
                            isInline: true,
                            inlineFontSize: fSize - 1.5,
                            controller: controller,
                            label: fieldInfo['label'] as String? ?? varName,
                            hint: fPlaceholder.isNotEmpty
                                ? fPlaceholder
                                : 'dd/mm/yyyy',
                          ),
                        ),
                      );
                    } else if (fType == 'input_dropdown') {
                      rowChildren.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: CustomDropdownInput(
                            isInline: true,
                            inlineFontSize: fSize - 0.5,
                            controller: controller,
                            label: fieldInfo['label'] as String? ?? varName,
                            hint: fPlaceholder,
                            options: (fieldInfo['options'] as List?) ?? [],
                            onItemSelected: _handleLinkedFields,
                          ),
                        ),
                      );
                    } else {
                      rowChildren.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _InlineDynamicTextInput(
                            controller: controller,
                            label: fieldInfo['label'] as String? ?? varName,
                            hint: fPlaceholder,
                            fontSize: fSize,
                            font: fFamily,
                            maxWidth: availableWidth,
                          ),
                        ),
                      );
                    }
                  }
                }
              }

              flushPrefixSpans();

              final trailingRun = processedRuns[trailingIdx];
              final tVarName = trailingRun['name'] as String? ?? '';
              final tController = getController(tVarName);
              final tFieldInfo = Map<String, dynamic>.from(
                trailingRun['field_info'] as Map? ?? {},
              );
              final tType = tFieldInfo['type'] as String? ?? 'input_text';
              final tPlaceholder =
                  tFieldInfo['placeholder'] as String? ?? '...';
              final tSize =
                  ((trailingRun['size'] as num?)?.toDouble() ?? 14.0) + 4.0;

              if (tController != null) {
                if (tType == 'input_dropdown') {
                  rowChildren.add(
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: CustomDropdownInput(
                          isInline: true,
                          inlineFontSize: tSize - 0.5,
                          controller: tController,
                          label: tFieldInfo['label'] as String? ?? tVarName,
                          hint: tPlaceholder,
                          options: (tFieldInfo['options'] as List?) ?? [],
                          onItemSelected: _handleLinkedFields,
                        ),
                      ),
                    ),
                  );
                } else {
                  rowChildren.add(
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: CustomTextInput(
                          isInline: true,
                          inlineFontSize: tSize - 0.5,
                          controller: tController,
                          label: tFieldInfo['label'] as String? ?? tVarName,
                          hint: tPlaceholder,
                        ),
                      ),
                    ),
                  );
                }
              }

              return SizedBox(
                width: double.infinity,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: rowChildren,
                ),
              );
            }
          }

          // Toàn bộ các runs còn lại (đoạn văn dài nhiều dòng có trường nhập inline ở giữa)
          final spans = <InlineSpan>[];

          if (fli > 0 && alignStr != 'center' && alignStr != 'right') {
            spans.add(WidgetSpan(child: SizedBox(width: fli)));
          }

          for (int idx = 0; idx < processedRuns.length; idx++) {
            final run = processedRuns[idx];
            if (_isStaticRun(run)) {
              spans.add(_buildSpanFromRun(run));
            } else {
              spans.add(
                _buildInteractiveSpan(
                  run: run,
                  idx: idx,
                  runs: processedRuns,
                  availableWidth: availableWidth,
                  fli: fli,
                ),
              );
            }
          }

          return SizedBox(
            width: double.infinity,
            child: Text.rich(TextSpan(children: spans), textAlign: textAlign),
          );
        },
      ),
    );
  }
}

/// Widget ô nhập text inline tự động co giãn theo độ dài văn bản thực tế
class _InlineDynamicTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final double fontSize;
  final String font;
  final double maxWidth;

  const _InlineDynamicTextInput({
    required this.controller,
    required this.label,
    this.hint,
    required this.fontSize,
    required this.font,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final currentText = controller.text;
        final measureSample = currentText.isNotEmpty
            ? currentText
            : ((hint != null && hint!.isNotEmpty) ? hint! : label);

        final textWidth = DocEditorUtils.measureTextWidth(
          measureSample,
          TextStyle(
            fontFamily: font,
            fontFamilyFallback: DocEditorUtils.fontFallback,
            fontSize: fontSize,
          ),
        );

        final maxAllowed = (maxWidth - 20.0).clamp(120.0, 550.0);
        final calculatedWidth = (textWidth + 24.0).clamp(120.0, maxAllowed);

        return SizedBox(
          width: calculatedWidth,
          child: CustomTextInput(
            isInline: true,
            inlineFontSize: fontSize - 0.5,
            controller: controller,
            label: label,
            hint: hint,
          ),
        );
      },
    );
  }
}
