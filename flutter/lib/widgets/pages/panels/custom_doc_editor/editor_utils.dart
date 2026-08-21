import 'package:flutter/material.dart';

/// Các tiện ích dùng chung trong module Soạn thảo văn bản tùy chỉnh
class DocEditorUtils {
  DocEditorUtils._();

  /// Danh sách font chữ dự phòng chuẩn văn bản hành chính Việt Nam
  static const List<String> fontFallback = [
    'Times New Roman',
    'Tinos',
    'Noto Serif',
    'Times',
    'serif',
  ];

  /// Sinh TextStyle chuẩn hóa từ thuộc tính đoạn văn bản DOCX
  static TextStyle docTextStyle({
    bool isBold = false,
    bool isItalic = false,
    bool isUnderline = false,
    double? fontSizePt,
    Color color = Colors.black,
  }) {
    // 1pt trong Word tương đương ~ 1.33px trên màn hình
    final sizePx = fontSizePt != null ? fontSizePt * 1.33 : 18.0;

    return TextStyle(
      fontFamily: 'Times New Roman',
      fontFamilyFallback: fontFallback,
      fontSize: sizePx,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: isUnderline
          ? TextDecoration.underline
          : TextDecoration.none,
      color: color,
      height: 1.5,
    );
  }

  /// Đo độ rộng thực tế (px) của chuỗi văn bản theo style định sẵn
  static double measureTextWidth(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size.width;
  }
}
