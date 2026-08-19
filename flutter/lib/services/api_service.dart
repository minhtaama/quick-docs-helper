import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;

/// Lớp trừu tượng cơ sở định nghĩa chuẩn giao tiếp API cho toàn bộ hệ thống
abstract class BaseApiService {
  // Khi chạy Flutter Web trên cùng server FastAPI, đường dẫn rỗng "" sẽ tự động gọi theo host hiện tại.
  // Khi chạy riêng hoặc cần trỏ cứng, dùng http://127.0.0.1:8000.
  static String get baseUrl {
    if (kDebugMode) {
      return 'http://127.0.0.1:8000';
    }
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return 'http://127.0.0.1:8000';
  }

  /// Lấy danh sách tất cả các thực thể (vụ án, đối tượng hoặc văn bản tùy biến)
  Future<List<Map<String, dynamic>>> getAll({String? caseId});

  /// Lấy chi tiết một thực thể theo ID
  Future<Map<String, dynamic>?> getById(String id, {String? caseId});

  /// Xóa một thực thể theo ID
  Future<bool> delete(String id, {String? caseId});

  /// Lấy danh sách mẫu văn bản từ Backend
  Future<List<Map<String, dynamic>>> getTemplates();

  /// Lấy đường dẫn URL trang xem trước tài liệu qua Canvas/PDF.js
  String getPreviewUrl({
    required String caseId,
    String? targetId,
    required String templateFilename,
    bool force = false,
    int? timestamp,
  });

  /// Tải file Word theo mẫu chỉ định
  Future<bool> downloadDocx({
    required String caseId,
    String? targetId,
    required String templateFilename,
    String? title,
  });

  /// Hàm tiện ích kích hoạt tải file nhị phân trên trình duyệt Web
  @protected
  void triggerBrowserDownload(Uint8List bytes, String filename) {
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
  }

  /// Hàm tiện ích trích xuất tên file từ header Content-Disposition
  @protected
  String extractFilenameFromHeader(
    Map<String, String> headers,
    String defaultFilename,
  ) {
    final disposition = headers['content-disposition'];
    if (disposition != null) {
      final matchUtf8 = RegExp(
        r"filename\*=UTF-8''([^;\r\n]+)",
        caseSensitive: false,
      ).firstMatch(disposition);
      if (matchUtf8 != null && matchUtf8.group(1) != null) {
        return Uri.decodeFull(matchUtf8.group(1)!);
      } else {
        final matchStandard = RegExp(
          r'filename="?([^";\r\n]+)"?',
          caseSensitive: false,
        ).firstMatch(disposition);
        if (matchStandard != null && matchStandard.group(1) != null) {
          return matchStandard.group(1)!.trim();
        }
      }
    }
    return defaultFilename;
  }
}

/// Service quản lý giao tiếp API cấp Vụ Án (Case Level) theo mô hình Singleton
class CaseApiService extends BaseApiService {
  CaseApiService._internal();
  static final CaseApiService _instance = CaseApiService._internal();
  factory CaseApiService() => _instance;
  static CaseApiService get instance => _instance;

  @override
  Future<List<Map<String, dynamic>>> getAll({String? caseId}) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseApiService.baseUrl}/api/v1/cases'),
      );
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
      debugPrint('CaseApiService.getAll error: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getById(String id, {String? caseId}) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseApiService.baseUrl}/api/v1/cases/$id'),
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
          if (map['custom_documents'] is List) {
            map['custom_documents'] = (map['custom_documents'] as List)
                .where((e) => e != null)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          } else {
            map['custom_documents'] = <Map<String, dynamic>>[];
          }
          return map;
        }
      }
      return null;
    } catch (e) {
      debugPrint('CaseApiService.getById error: $e');
      return null;
    }
  }

  /// Thêm mới hoặc cập nhật một vụ án
  Future<Map<String, dynamic>> save({
    String? id,
    required String tenTomTat,
    required String tenDayDu,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'ten_tom_tat': tenTomTat,
        'ten_day_du': tenDayDu,
      };
      if (id != null && id.isNotEmpty) {
        body['id'] = id;
      }

      final response = await http.post(
        Uri.parse('${BaseApiService.baseUrl}/api/v1/cases'),
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
      debugPrint('CaseApiService.save error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> delete(String id, {String? caseId}) async {
    try {
      final response = await http.delete(
        Uri.parse('${BaseApiService.baseUrl}/api/v1/cases/$id'),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('CaseApiService.delete error: $e');
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTemplates() async {
    try {
      final response = await http.get(
        Uri.parse('${BaseApiService.baseUrl}/api/v1/generate/templates/case'),
      );
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          return decoded
              .where((e) => e != null)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('CaseApiService.getTemplates error: $e');
      return [];
    }
  }

  @override
  String getPreviewUrl({
    required String caseId,
    String? targetId,
    required String templateFilename,
    bool force = false,
    int? timestamp,
  }) {
    final encoded = Uri.encodeComponent(templateFilename);
    final t = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final forceParam = force ? '&force=true&t=$t' : '&t=$t';
    return '${BaseApiService.baseUrl}/api/v1/generate/case/$caseId/preview-viewer?template_file=$encoded$forceParam';
  }

  @override
  Future<bool> downloadDocx({
    required String caseId,
    String? targetId,
    required String templateFilename,
    String? title,
  }) async {
    try {
      final encoded = Uri.encodeComponent(templateFilename);
      final response = await http.post(
        Uri.parse(
          '${BaseApiService.baseUrl}/api/v1/generate/case/$caseId/download?template_file=$encoded',
        ),
      );

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final defaultName =
            '${templateFilename.replaceAll('.docx', '')}_${title?.trim().isNotEmpty == true ? title!.trim() : "VuViec"}.docx';
        final filename = extractFilenameFromHeader(
          response.headers,
          defaultName,
        );
        triggerBrowserDownload(bytes, filename);
        return true;
      } else {
        throw Exception('Lỗi tải văn bản vụ việc (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('CaseApiService.downloadDocx error: $e');
      rethrow;
    }
  }
}

/// Service quản lý giao tiếp API cấp Đối Tượng / Cá Nhân (Person Level) theo mô hình Singleton
class PersonApiService extends BaseApiService {
  PersonApiService._internal();
  static final PersonApiService _instance = PersonApiService._internal();
  factory PersonApiService() => _instance;
  static PersonApiService get instance => _instance;

  static String getPersonImageUrl({
    required String caseId,
    required String personId,
    String? updatedAt,
  }) {
    final v = updatedAt ?? DateTime.now().millisecondsSinceEpoch.toString();
    return '${BaseApiService.baseUrl}/api/v1/cases/$caseId/persons/$personId/image?v=$v';
  }

  @override
  Future<List<Map<String, dynamic>>> getAll({String? caseId}) async {
    if (caseId == null || caseId.isEmpty) return [];
    try {
      final caseData = await CaseApiService().getById(caseId);
      if (caseData != null && caseData['con_nguoi_list'] is List) {
        return List<Map<String, dynamic>>.from(caseData['con_nguoi_list']);
      }
      return [];
    } catch (e) {
      debugPrint('PersonApiService.getAll error: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getById(String id, {String? caseId}) async {
    if (caseId == null || caseId.isEmpty) return null;
    final list = await getAll(caseId: caseId);
    try {
      return list.firstWhere((p) => p['id'] == id);
    } catch (_) {
      return null;
    }
  }

  /// Lưu hoặc cập nhật cá nhân vào vụ án (Form Data + Upload File Ảnh)
  Future<Map<String, dynamic>> save({
    required String caseId,
    required Map<String, String> fields,
    Uint8List? imageBytes,
    String? imageFilename,
  }) async {
    try {
      final uri = Uri.parse(
        '${BaseApiService.baseUrl}/api/v1/cases/$caseId/persons',
      );
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
      debugPrint('PersonApiService.save error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> delete(String id, {String? caseId}) async {
    if (caseId == null || caseId.isEmpty) return false;
    try {
      final response = await http.delete(
        Uri.parse('${BaseApiService.baseUrl}/api/v1/cases/$caseId/persons/$id'),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('PersonApiService.delete error: $e');
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTemplates() async {
    try {
      final response = await http.get(
        Uri.parse('${BaseApiService.baseUrl}/api/v1/generate/templates/person'),
      );
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          return decoded
              .where((e) => e != null)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('PersonApiService.getTemplates error: $e');
      return [];
    }
  }

  @override
  String getPreviewUrl({
    required String caseId,
    String? targetId,
    required String templateFilename,
    bool force = false,
    int? timestamp,
  }) {
    final personId = targetId ?? '';
    final encoded = Uri.encodeComponent(templateFilename);
    final t = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final forceParam = force ? '&force=true&t=$t' : '&t=$t';
    return '${BaseApiService.baseUrl}/api/v1/generate/person/$caseId/$personId/preview-viewer?template_file=$encoded$forceParam';
  }

  @override
  Future<bool> downloadDocx({
    required String caseId,
    String? targetId,
    required String templateFilename,
    String? title,
  }) async {
    try {
      final personId = targetId ?? '';
      final encoded = Uri.encodeComponent(templateFilename);
      final response = await http.post(
        Uri.parse(
          '${BaseApiService.baseUrl}/api/v1/generate/person/$caseId/$personId/download?template_file=$encoded',
        ),
      );

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final defaultName =
            '${templateFilename.replaceAll('.docx', '')}_${title?.trim().isNotEmpty == true ? title!.trim() : "CaNhan"}.docx';
        final filename = extractFilenameFromHeader(
          response.headers,
          defaultName,
        );
        triggerBrowserDownload(bytes, filename);
        return true;
      } else {
        throw Exception('Lỗi tải văn bản (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('PersonApiService.downloadDocx error: $e');
      rethrow;
    }
  }
}

/// Service quản lý giao tiếp API cấp Văn Bản Tùy Biến (Custom Document Level) theo mô hình Singleton
class CustomDocApiService extends BaseApiService {
  CustomDocApiService._internal();
  static final CustomDocApiService _instance = CustomDocApiService._internal();

  /// Factory constructor trả về Singleton instance
  factory CustomDocApiService() => _instance;

  /// Getter instance truy cập tĩnh
  static CustomDocApiService get instance => _instance;

  @override
  Future<List<Map<String, dynamic>>> getAll({String? caseId}) async {
    if (caseId == null || caseId.isEmpty) return [];
    try {
      final response = await http.get(
        Uri.parse('${BaseApiService.baseUrl}/api/v1/cases/$caseId/custom-docs'),
      );
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          return decoded
              .where((e) => e != null)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('CustomDocApiService.getAll error: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getById(String id, {String? caseId}) async {
    if (caseId == null || caseId.isEmpty) return null;
    try {
      final response = await http.get(
        Uri.parse(
          '${BaseApiService.baseUrl}/api/v1/cases/$caseId/custom-docs/$id',
        ),
      );
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
      return null;
    } catch (e) {
      debugPrint('CustomDocApiService.getById error: $e');
      return null;
    }
  }

  /// Thêm mới hoặc cập nhật một văn bản tùy biến
  Future<Map<String, dynamic>> save({
    required String caseId,
    required Map<String, dynamic> docData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${BaseApiService.baseUrl}/api/v1/cases/$caseId/custom-docs'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(docData),
      );
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return Map<String, dynamic>.from(decoded as Map);
      } else {
        throw Exception(
          'Lỗi lưu văn bản tùy biến (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('CustomDocApiService.save error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> delete(String id, {String? caseId}) async {
    if (caseId == null || caseId.isEmpty) return false;
    try {
      final response = await http.delete(
        Uri.parse(
          '${BaseApiService.baseUrl}/api/v1/cases/$caseId/custom-docs/$id',
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('CustomDocApiService.delete error: $e');
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTemplates() async {
    try {
      final response = await http.get(
        Uri.parse('${BaseApiService.baseUrl}/api/v1/generate/templates/custom'),
      );
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          return decoded
              .where((e) => e != null)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('CustomDocApiService.getTemplates error: $e');
      return [];
    }
  }

  @override
  String getPreviewUrl({
    required String caseId,
    String? targetId,
    required String templateFilename,
    bool force = false,
    int? timestamp,
  }) {
    final docId = targetId ?? '';
    final t = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final forceParam = force ? '&force=true&t=$t' : '&t=$t';
    return '${BaseApiService.baseUrl}/api/v1/generate/custom/$caseId/$docId/preview-viewer?$forceParam';
  }

  @override
  Future<bool> downloadDocx({
    required String caseId,
    String? targetId,
    required String templateFilename,
    String? title,
  }) async {
    try {
      final docId = targetId ?? '';
      final response = await http.post(
        Uri.parse(
          '${BaseApiService.baseUrl}/api/v1/generate/custom/$caseId/$docId/download',
        ),
      );

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final defaultName = '${title ?? "VanBanCustom"}.docx';
        final filename = extractFilenameFromHeader(
          response.headers,
          defaultName,
        );
        triggerBrowserDownload(bytes, filename);
        return true;
      } else {
        throw Exception('Lỗi tải văn bản tùy biến (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('CustomDocApiService.downloadDocx error: $e');
      rethrow;
    }
  }
}
