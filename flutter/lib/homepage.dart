import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart' as fp;
import 'package:universal_html/html.dart' as html;
import 'widgets/text_input.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();

  // 5 trường thông tin đầu tiên khớp chính xác với template ly-lich-ca-nhan.docx
  final _hoTenController = TextEditingController();
  final _gioiTinhController = TextEditingController();
  final _ngaySinhController = TextEditingController();
  final _thangSinhController = TextEditingController();
  final _namSinhController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _hoTenController.dispose();
    _gioiTinhController.dispose();
    _ngaySinhController.dispose();
    _thangSinhController.dispose();
    _namSinhController.dispose();
    super.dispose();
  }

  // 1. XUẤT 5 TRƯỜNG THÔNG TIN THÀNH FILE .JSON
  void _exportJson() {
    if (!_formKey.currentState!.validate()) return;

    final dataMap = {
      'ho_ten': _hoTenController.text.trim(),
      'gioi_tinh': _gioiTinhController.text.trim(),
      'ngay_sinh': _ngaySinhController.text.trim(),
      'thang_sinh': _thangSinhController.text.trim(),
      'nam_sinh': _namSinhController.text.trim(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(dataMap);
    final bytes = utf8.encode(jsonString);

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final filename = 'HoSo_${_hoTenController.text.trim().isEmpty ? 'CaNhan' : _hoTenController.text.trim()}.json';

      html.AnchorElement(href: url)
        ..setAttribute("download", filename)
        ..click();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xuất file hồ sơ JSON thành công: $filename'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // 2. NẠP DỮ LIỆU TỪ FILE .JSON VÀO 5 TRƯỜNG INPUT
  Future<void> _importJson() async {
    try {
      final fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
        final jsonContent = utf8.decode(result.files.first.bytes!);
        final Map<String, dynamic> dataMap = jsonDecode(jsonContent);

        setState(() {
          _hoTenController.text = dataMap['ho_ten'] ?? '';
          _gioiTinhController.text = dataMap['gioi_tinh'] ?? '';
          _ngaySinhController.text = dataMap['ngay_sinh'] ?? '';
          _thangSinhController.text = dataMap['thang_sinh'] ?? '';
          _namSinhController.text = dataMap['nam_sinh'] ?? '';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã nạp hồ sơ từ file: ${result.files.first.name}'),
              backgroundColor: Colors.blueAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đọc file JSON: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // 3. GỬI 5 TRƯỜNG DỮ LIỆU SANG PYTHON BACKEND ĐỂ XUẤT FILE WORD (.DOCX)
  Future<void> _generateDocx() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse('/api/documents/generate-ly-lich');
      final request = http.MultipartRequest('POST', uri);

      request.fields['ho_ten'] = _hoTenController.text;
      request.fields['gioi_tinh'] = _gioiTinhController.text;
      request.fields['ngay_sinh'] = _ngaySinhController.text;
      request.fields['thang_sinh'] = _thangSinhController.text;
      request.fields['nam_sinh'] = _namSinhController.text;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final filename = 'LyLich_${_hoTenController.text.trim().isEmpty ? 'CaNhan' : _hoTenController.text.trim()}.docx';

        if (kIsWeb) {
          final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute("download", filename)
            ..click();
          html.Url.revokeObjectUrl(url);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tạo file Word thành công: $filename'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Lỗi server (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi dữ liệu: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Hồ Sơ 5 Trường Thông Tin'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'HỒ SƠ CÁ NHÂN (5 TRƯỜNG)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _importJson,
                          icon: const Icon(Icons.file_upload, size: 18),
                          label: const Text('Nạp file .JSON'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      controller: _hoTenController,
                      label: 'Họ và tên',
                      hint: 'Nhập đầy đủ họ và tên...',
                      icon: Icons.person,
                      isRequired: true,
                    ),
                    const SizedBox(height: 12),
                    CustomTextInput(
                      controller: _gioiTinhController,
                      label: 'Giới tính',
                      hint: 'Nam / Nữ',
                      icon: Icons.wc,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextInput(
                            controller: _ngaySinhController,
                            label: 'Ngày sinh',
                            hint: '15',
                            icon: Icons.calendar_today,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomTextInput(
                            controller: _thangSinhController,
                            label: 'Tháng sinh',
                            hint: '08',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomTextInput(
                            controller: _namSinhController,
                            label: 'Năm sinh',
                            hint: '1995',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _exportJson,
                            icon: const Icon(Icons.save_alt),
                            label: const Text('LƯU VỀ FILE .JSON'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _generateDocx,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.description),
                            label: Text(_isLoading ? 'ĐANG TẠO...' : 'TẠO FILE WORD (.DOCX)'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
