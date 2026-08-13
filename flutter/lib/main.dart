import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart' as fp;
import 'package:universal_html/html.dart' as html;

void main() {
  runApp(const QuickDocsApp());
}

class QuickDocsApp extends StatelessWidget {
  const QuickDocsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lý Lịch Cá Nhân - Quick Docs Helper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const FormPage(),
    );
  }
}

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _hoTenController = TextEditingController();
  final _gioiTinhController = TextEditingController();
  final _ngaySinhController = TextEditingController();
  final _thangSinhController = TextEditingController();
  final _namSinhController = TextEditingController();
  final _noiSinhController = TextEditingController();
  final _queQuanController = TextEditingController();
  final _quocTichController = TextEditingController(text: 'Việt Nam');
  final _danTocController = TextEditingController(text: 'Kinh');
  final _tonGiaoController = TextEditingController(text: 'Không');

  final _cccdController = TextEditingController();
  final _noiCapCccdController = TextEditingController();
  final _ngayCccdController = TextEditingController();
  final _thangCccdController = TextEditingController();
  final _namCccdController = TextEditingController();

  final _hocVanController = TextEditingController();
  final _ngheNghiepController = TextEditingController();
  final _noiLamViecController = TextEditingController();
  final _chucVuController = TextEditingController();
  final _doanTheController = TextEditingController();

  final _noiThuongTruController = TextEditingController();
  final _noiTamTruController = TextEditingController();
  final _noiOHienTaiController = TextEditingController();

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.image,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedImageBytes = result.files.first.bytes;
        _selectedImageName = result.files.first.name;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse('/api/documents/generate-ly-lich');
      final request = http.MultipartRequest('POST', uri);

      // Thêm các trường form
      request.fields['ho_ten'] = _hoTenController.text;
      request.fields['gioi_tinh'] = _gioiTinhController.text;
      request.fields['ngay_sinh'] = _ngaySinhController.text;
      request.fields['thang_sinh'] = _thangSinhController.text;
      request.fields['nam_sinh'] = _namSinhController.text;
      request.fields['noi_sinh'] = _noiSinhController.text;
      request.fields['que_quan'] = _queQuanController.text;
      request.fields['quoc_tich'] = _quocTichController.text;
      request.fields['dan_toc'] = _danTocController.text;
      request.fields['ton_giao'] = _tonGiaoController.text;

      request.fields['cccd'] = _cccdController.text;
      request.fields['noi_cap_cccd'] = _noiCapCccdController.text;
      request.fields['ngay_cccd'] = _ngayCccdController.text;
      request.fields['thang_cccd'] = _thangCccdController.text;
      request.fields['nam_cccd'] = _namCccdController.text;

      request.fields['hoc_van'] = _hocVanController.text;
      request.fields['nghe_nghiep'] = _ngheNghiepController.text;
      request.fields['noi_lam_viec'] = _noiLamViecController.text;
      request.fields['chuc_vu'] = _chucVuController.text;
      request.fields['doan_the'] = _doanTheController.text;

      request.fields['noi_thuong_tru'] = _noiThuongTruController.text;
      request.fields['noi_tam_tru'] = _noiTamTruController.text;
      request.fields['noi_o_hien_tai'] = _noiOHienTaiController.text;

      // Thêm ảnh chân dung nếu có
      if (_selectedImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          _selectedImageBytes!,
          filename: _selectedImageName ?? 'avatar.png',
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final filename = 'LyLich_${_hoTenController.text.isEmpty ? 'CaNhan' : _hoTenController.text}.docx';

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
              content: Text('Xuất file thành công: $filename'),
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
            content: Text('Lỗi: $e'),
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
        title: const Text('QUICK DOCS HELPER (FLUTTER)'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1E1B4B),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: const Color(0xFF0F172A),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TỜ KHAI LÝ LỊCH CÁ NHÂN',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF818CF8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Điền đầy đủ thông tin bên dưới để ứng dụng tự động xuất file Word (.docx)',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    // SECTION I
                    _buildSectionHeader('I. THÔNG TIN CÁ NHÂN & ĂNH'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 110,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: _selectedImageBytes != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                                    )
                                  : const Icon(Icons.person, size: 60, color: Colors.white38),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.upload_file, size: 16),
                              label: const Text('Chọn ảnh 3x4', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            children: [
                              _buildTextField(_hoTenController, 'Họ và tên (*)', required: true),
                              const SizedBox(height: 12),
                              _buildTextField(_gioiTinhController, 'Giới tính (Nam/Nữ)'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // SECTION II
                    _buildSectionHeader('II. NGÀY SINH & QUÊ QUÁN'),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_ngaySinhController, 'Ngày sinh')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_thangSinhController, 'Tháng sinh')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_namSinhController, 'Năm sinh')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_noiSinhController, 'Nơi sinh')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_queQuanController, 'Quê quán')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_quocTichController, 'Quốc tịch')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_danTocController, 'Dân tộc')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_tonGiaoController, 'Tôn giáo')),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // SECTION III
                    _buildSectionHeader('III. GIẤY TỜ CĂN CƯỚC / CMND'),
                    Row(
                      children: [
                        Expanded(flex: 2, child: _buildTextField(_cccdController, 'Số CCCD / CMND')),
                        const SizedBox(width: 12),
                        Expanded(flex: 3, child: _buildTextField(_noiCapCccdController, 'Nơi cấp CCCD')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_ngayCccdController, 'Ngày cấp')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_thangCccdController, 'Tháng cấp')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_namCccdController, 'Năm cấp')),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // SECTION IV
                    _buildSectionHeader('IV. HỌC VẤN & CÔNG VIỆC'),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_hocVanController, 'Trình độ học vấn')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_ngheNghiepController, 'Nghề nghiệp')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_noiLamViecController, 'Nơi làm việc')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_chucVuController, 'Chức vụ')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_doanTheController, 'Đoàn thể')),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // SECTION V
                    _buildSectionHeader('V. ĐƠN VỊ CƯ TRÚ'),
                    _buildTextField(_noiThuongTruController, 'Nơi thường trú'),
                    const SizedBox(height: 12),
                    _buildTextField(_noiTamTruController, 'Nơi tạm trú'),
                    const SizedBox(height: 12),
                    _buildTextField(_noiOHienTaiController, 'Nơi ở hiện tại'),
                    const SizedBox(height: 32),

                    // SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                        ),
                        onPressed: _isLoading ? null : _submitForm,
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text('ĐANG TẠO FILE WORD...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              )
                            : const Text(
                                'XUẤT & TẢI FILE WORD (.DOCX)',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFFA78BFA),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool required = false}) {
    return TextFormField(
      controller: controller,
      validator: required ? (value) => (value == null || value.isEmpty) ? 'Trường này là bắt buộc' : null : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
