import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;

class ApiService {
  // Khi chạy Flutter Web trên cùng server FastAPI, đường dẫn rỗng "" sẽ tự động gọi theo host hiện tại.
  // Khi chạy riêng hoặc cần trỏ cứng, dùng http://127.0.0.1:8000.
  static String get baseUrl {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return 'http://127.0.0.1:8000';
  }

  /// Lấy danh sách tất cả các vụ án
  static Future<List<Map<String, dynamic>>> getCases() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/v1/cases'));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          return decoded
              .where((e) => e != null)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        return [];
      } else {
        debugPrint('Lỗi tải danh sách vụ việc (${response.statusCode})');
        return [];
      }
    } catch (e) {
      debugPrint('ApiService.getCases error: $e');
      return [];
    }
  }

  /// Thêm mới hoặc cập nhật một vụ án
  static Future<Map<String, dynamic>> saveCase({
    String? id,
    required String tenVu,
    required String moTa,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'ten_vu': tenVu,
        'mo_ta': moTa,
      };
      if (id != null && id.isNotEmpty) {
        body['id'] = id;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/cases'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return Map<String, dynamic>.from(decoded as Map);
      } else {
        throw Exception(
          'Lỗi lưu vụ việc (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('ApiService.saveCase error: $e');
      rethrow;
    }
  }

  /// Tạo mới một vụ án
  static Future<Map<String, dynamic>> createCase(
    String tenVu,
    String moTa,
  ) =>
      saveCase(tenVu: tenVu, moTa: moTa);

  /// Lấy thông tin chi tiết một vụ án kèm danh sách cá nhân
  static Future<Map<String, dynamic>?> getCaseDetails(String caseId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/cases/$caseId'),
      );
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          if (map['con_nguoi_list'] is List) {
            map['con_nguoi_list'] = (map['con_nguoi_list'] as List)
                .where((e) => e != null)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          } else {
            map['con_nguoi_list'] = <Map<String, dynamic>>[];
          }
          return map;
        }
      }
      return null;
    } catch (e) {
      debugPrint('ApiService.getCaseDetails error: $e');
      return null;
    }
  }

  /// Xóa một vụ án
  static Future<bool> deleteCase(String caseId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/cases/$caseId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.deleteCase error: $e');
      return false;
    }
  }

  /// Lưu hoặc cập nhật cá nhân vào vụ án (Form Data + Upload File Ảnh)
  static Future<Map<String, dynamic>> savePersonToCase({
    required String caseId,
    required Map<String, String> fields,
    Uint8List? imageBytes,
    String? imageFilename,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/cases/$caseId/persons');
      final request = http.MultipartRequest('POST', uri);

      // Gán các trường thông tin dạng text
      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      // Đính kèm file ảnh nếu có
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final filename = imageFilename ?? 'avatar.jpg';
        request.files.add(
          http.MultipartFile.fromBytes('image', imageBytes, filename: filename),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return Map<String, dynamic>.from(decoded as Map);
      } else {
        throw Exception(
          'Lỗi lưu thông tin cá nhân (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('ApiService.savePersonToCase error: $e');
      rethrow;
    }
  }

  /// Xóa một cá nhân khỏi vụ án
  static Future<bool> deletePersonFromCase(
    String caseId,
    String personId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/cases/$caseId/persons/$personId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.deletePersonFromCase error: $e');
      return false;
    }
  }

  /// Tải file Word Lý Lịch Cá Nhân (.docx) từ Backend
  static Future<bool> downloadPersonDocx({
    required String caseId,
    required String personId,
    required String hoTen,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/generate/ly-lich-ca-nhan/$caseId/$personId'),
      );

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final safeName = hoTen.trim().isEmpty ? 'CaNhan' : hoTen.trim();
        final filename = 'LyLich_$safeName.docx';

        if (kIsWeb) {
          final blob = html.Blob(
            [bytes],
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          );
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute("download", filename)
            ..click();
          html.Url.revokeObjectUrl(url);
        }
        return true;
      } else {
        throw Exception('Lỗi kết xuất file Word (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('ApiService.downloadPersonDocx error: $e');
      rethrow;
    }
  }
}
