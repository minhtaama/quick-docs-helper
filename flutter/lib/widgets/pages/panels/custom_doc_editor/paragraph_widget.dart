import 'package:flutter/material.dart';
import '../../../common/date_time_input.dart';
import '../../../common/text_input.dart';
import 'editor_utils.dart';

/// Widget hiển thị đoạn văn bản (paragraph) kèm các trường nhập liệu inline
class DocParagraphWidget extends StatelessWidget {
  final Map<String, dynamic> element;
  final TextEditingController? Function(String varName) getController;
  final Map<String, dynamic>? caseData;
  final Map<String, dynamic>? person;
  final VoidCallback? onContentChanged;

  const DocParagraphWidget({
    super.key,
    required this.element,
    required this.getController,
    this.caseData,
    this.person,
    this.onContentChanged,
  });

  String _resolveFieldValue(String varName) {
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

  @override
  Widget build(BuildContext context) {
    final alignStr = element['align'] as String? ?? 'left';
    final rawRuns =
        (element['runs'] as List?)
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
                final controller = getController(varName);
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
                        prefixWidth += DocEditorUtils.measureTextWidth(
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
                          prefixWidth += DocEditorUtils.measureTextWidth(
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
}
