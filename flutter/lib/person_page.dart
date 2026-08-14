import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'widgets/text_input.dart';
import 'widgets/radio_input.dart';
import 'services/api_service.dart';

class PersonPage extends StatefulWidget {
  final String? caseId;
  final Map<String, dynamic>? initialPerson;

  const PersonPage({
    super.key,
    this.caseId,
    this.initialPerson,
  });

  @override
  State<PersonPage> createState() => _PersonPageState();
}

class _PersonPageState extends State<PersonPage> {
  final _formKey = GlobalKey<FormState>();

  // 1. Thông tin cơ bản
  final _hoTenController = TextEditingController();
  final _gioiTinhController = TextEditingController(text: 'Nam');
  final _ngaySinhController = TextEditingController();
  final _thangSinhController = TextEditingController();
  final _namSinhController = TextEditingController();
  final _noiSinhController = TextEditingController();
  final _queQuanController = TextEditingController();
  final _quocTichController = TextEditingController(text: 'Việt Nam');
  final _danTocController = TextEditingController(text: 'Kinh');
  final _tonGiaoController = TextEditingController(text: 'Không');

  // 2. Thông tin CCCD
  final _cccdController = TextEditingController();
  final _ngayCccdController = TextEditingController();
  final _thangCccdController = TextEditingController();
  final _namCccdController = TextEditingController();
  final _noiCapCccdController = TextEditingController(text: 'Cục Cảnh sát QLHC về TTXH');

  // 3. Học vấn & Nghề nghiệp
  final _hocVanController = TextEditingController();
  final _ngheNghiepController = TextEditingController();
  final _noiLamViecController = TextEditingController();
  final _chucVuController = TextEditingController();
  final _doanTheController = TextEditingController();

  // 4. Địa chỉ cư trú
  final _noiThuongTruController = TextEditingController();
  final _noiTamTruController = TextEditingController();
  final _noiOHienTaiController = TextEditingController();

  // 5. Tiền án, tiền sự
  final _tienAnTienSuController = TextEditingController(text: 'Chưa có tiền án, tiền sự');

  String _selectedGioiTinh = 'Nam';
  bool _isSaving = false;

  // Ảnh đại diện
  Uint8List? _avatarBytes;
  String? _avatarFilename;

  @override
  void initState() {
    super.initState();
    if (widget.initialPerson != null) {
      final p = widget.initialPerson!;
      _hoTenController.text = p['ho_ten'] ?? '';
      _gioiTinhController.text = p['gioi_tinh'] ?? 'Nam';
      _selectedGioiTinh = _gioiTinhController.text;
      _ngaySinhController.text = p['ngay_sinh'] ?? '';
      _thangSinhController.text = p['thang_sinh'] ?? '';
      _namSinhController.text = p['nam_sinh'] ?? '';
      _noiSinhController.text = p['noi_sinh'] ?? '';
      _queQuanController.text = p['que_quan'] ?? '';
      _quocTichController.text = p['quoc_tich'] ?? 'Việt Nam';
      _danTocController.text = p['dan_toc'] ?? 'Kinh';
      _tonGiaoController.text = p['ton_giao'] ?? 'Không';
      _cccdController.text = p['cccd'] ?? '';
      _ngayCccdController.text = p['ngay_cccd'] ?? '';
      _thangCccdController.text = p['thang_cccd'] ?? '';
      _namCccdController.text = p['nam_cccd'] ?? '';
      _noiCapCccdController.text = p['noi_cap_cccd'] ?? 'Cục Cảnh sát QLHC về TTXH';
      _hocVanController.text = p['hoc_van'] ?? '';
      _ngheNghiepController.text = p['nghe_nghiep'] ?? '';
      _noiLamViecController.text = p['noi_lam_viec'] ?? '';
      _noiThuongTruController.text = p['noi_thuong_tru'] ?? '';
      _noiTamTruController.text = p['noi_tam_tru'] ?? '';
      _noiOHienTaiController.text = p['noi_o_hien_tai'] ?? '';
      _chucVuController.text = p['chuc_vu'] ?? '';
      _doanTheController.text = p['doan_the'] ?? '';
      _tienAnTienSuController.text = p['tien_an_tien_su'] ?? 'Chưa có tiền án, tiền sự';
    }
  }

  @override
  void dispose() {
    _hoTenController.dispose();
    _gioiTinhController.dispose();
    _ngaySinhController.dispose();
    _thangSinhController.dispose();
    _namSinhController.dispose();
    _noiSinhController.dispose();
    _queQuanController.dispose();
    _quocTichController.dispose();
    _danTocController.dispose();
    _tonGiaoController.dispose();
    _cccdController.dispose();
    _ngayCccdController.dispose();
    _thangCccdController.dispose();
    _namCccdController.dispose();
    _noiCapCccdController.dispose();
    _hocVanController.dispose();
    _ngheNghiepController.dispose();
    _noiLamViecController.dispose();
    _chucVuController.dispose();
    _doanTheController.dispose();
    _noiThuongTruController.dispose();
    _noiTamTruController.dispose();
    _noiOHienTaiController.dispose();
    _tienAnTienSuController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
        setState(() {
          _avatarBytes = result.files.first.bytes;
          _avatarFilename = result.files.first.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Map<String, String> _collectFields() {
    final fields = {
      'ho_ten': _hoTenController.text.trim(),
      'gioi_tinh': _gioiTinhController.text.trim(),
      'ngay_sinh': _ngaySinhController.text.trim(),
      'thang_sinh': _thangSinhController.text.trim(),
      'nam_sinh': _namSinhController.text.trim(),
      'noi_sinh': _noiSinhController.text.trim(),
      'que_quan': _queQuanController.text.trim(),
      'quoc_tich': _quocTichController.text.trim(),
      'dan_toc': _danTocController.text.trim(),
      'ton_giao': _tonGiaoController.text.trim(),
      'cccd': _cccdController.text.trim(),
      'ngay_cccd': _ngayCccdController.text.trim(),
      'thang_cccd': _thangCccdController.text.trim(),
      'nam_cccd': _namCccdController.text.trim(),
      'noi_cap_cccd': _noiCapCccdController.text.trim(),
      'hoc_van': _hocVanController.text.trim(),
      'nghe_nghiep': _ngheNghiepController.text.trim(),
      'noi_lam_viec': _noiLamViecController.text.trim(),
      'noi_thuong_tru': _noiThuongTruController.text.trim(),
      'noi_tam_tru': _noiTamTruController.text.trim(),
      'noi_o_hien_tai': _noiOHienTaiController.text.trim(),
      'chuc_vu': _chucVuController.text.trim(),
      'doan_the': _doanTheController.text.trim(),
      'tien_an_tien_su': _tienAnTienSuController.text.trim(),
    };

    if (widget.initialPerson != null && widget.initialPerson!['id'] != null) {
      fields['person_id'] = widget.initialPerson!['id'].toString();
    }

    return fields;
  }

  Future<void> _saveToCase() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.caseId == null) return;

    setState(() => _isSaving = true);
    try {
      final fields = _collectFields();
      await ApiService.savePersonToCase(
        caseId: widget.caseId!,
        fields: fields,
        imageBytes: _avatarBytes,
        imageFilename: _avatarFilename,
      );

      if (mounted) {
        final isEdit = widget.initialPerson != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit
                ? 'Đã cập nhật hồ sơ của "${fields['ho_ten']}" thành công!'
                : 'Đã thêm hồ sơ của "${fields['ho_ten']}" vào vụ án!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu hồ sơ: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isEdit = widget.initialPerson != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Chỉnh Sửa Hồ Sơ Cá Nhân' : 'Thêm Hồ Sơ Cá Nhân'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isEdit ? 'CHỈNH SỬA HỒ SƠ CÁ NHÂN' : 'HỒ SƠ CÁ NHÂN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEdit
                            ? 'Cập nhật các thông tin cá nhân dưới đây và nhấn Cập Nhật Hồ Sơ.'
                            : 'Điền đầy đủ các thông tin cá nhân dưới đây để lưu vào vụ việc hoặc xuất tài liệu Word.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: primaryColor.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Avatar picker
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: primaryColor.withValues(alpha: 0.1),
                              backgroundImage: _avatarBytes != null ? MemoryImage(_avatarBytes!) : null,
                              child: _avatarBytes == null
                                  ? Icon(Icons.person, size: 40, color: primaryColor)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _pickAvatar,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: primaryColor,
                                  child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: _pickAvatar,
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: Text(_avatarBytes != null ? 'Đổi ảnh đại diện' : 'Chọn ảnh đại diện'),
                        ),
                      ),

                      // 1. THÔNG TIN CƠ BẢN
                      _buildSectionHeader('I. THÔNG TIN CƠ BẢN', Icons.person_outline),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: CustomTextInput(
                              controller: _hoTenController,
                              label: 'Họ và tên',
                              hint: 'Nguyễn Văn A...',
                              icon: Icons.badge_outlined,
                              isRequired: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: CustomRadioInput(
                              label: 'Giới tính',
                              options: const ['Nam', 'Nữ'],
                              selectedValue: _selectedGioiTinh,
                              icon: Icons.wc,
                              onChanged: (val) {
                                setState(() {
                                  _selectedGioiTinh = val;
                                  _gioiTinhController.text = val;
                                });
                              },
                            ),
                          ),
                        ],
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextInput(
                              controller: _noiSinhController,
                              label: 'Nơi sinh',
                              hint: 'Xã/Phường, Huyện/Quận, Tỉnh/TP...',
                              icon: Icons.location_city,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextInput(
                              controller: _queQuanController,
                              label: 'Quê quán',
                              hint: 'Xã/Phường, Huyện/Quận, Tỉnh/TP...',
                              icon: Icons.home_work_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextInput(
                              controller: _quocTichController,
                              label: 'Quốc tịch',
                              hint: 'Việt Nam',
                              icon: Icons.flag_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextInput(
                              controller: _danTocController,
                              label: 'Dân tộc',
                              hint: 'Kinh',
                              icon: Icons.people_outline,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextInput(
                              controller: _tonGiaoController,
                              label: 'Tôn giáo',
                              hint: 'Không',
                              icon: Icons.church_outlined,
                            ),
                          ),
                        ],
                      ),

                      // 2. THÔNG TIN CCCD / ĐỊNH DANH
                      _buildSectionHeader('II. THÔNG TIN CCCD / ĐỊNH DANH', Icons.credit_card_outlined),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: CustomTextInput(
                              controller: _cccdController,
                              label: 'Số CCCD / CMND',
                              hint: '12 chữ số...',
                              icon: Icons.credit_card,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                Expanded(
                                  child: CustomTextInput(
                                    controller: _ngayCccdController,
                                    label: 'Ngày cấp',
                                    hint: '01',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: CustomTextInput(
                                    controller: _thangCccdController,
                                    label: 'Tháng cấp',
                                    hint: '01',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: CustomTextInput(
                                    controller: _namCccdController,
                                    label: 'Năm cấp',
                                    hint: '2022',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomTextInput(
                        controller: _noiCapCccdController,
                        label: 'Nơi cấp CCCD',
                        hint: 'Cục Cảnh sát QLHC về TTXH',
                        icon: Icons.account_balance_outlined,
                      ),

                      // 3. HỌC VẤN & CÔNG VIỆC
                      _buildSectionHeader('III. HỌC VẤN, NGHỀ NGHIỆP & ĐOÀN THỂ', Icons.work_outline),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextInput(
                              controller: _hocVanController,
                              label: 'Trình độ học vấn',
                              hint: '12/12, Đại học...',
                              icon: Icons.school_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextInput(
                              controller: _ngheNghiepController,
                              label: 'Nghề nghiệp',
                              hint: 'Kỹ sư, Tự do...',
                              icon: Icons.work_outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomTextInput(
                        controller: _noiLamViecController,
                        label: 'Nơi làm việc',
                        hint: 'Tên công ty / Cơ quan làm việc...',
                        icon: Icons.business_outlined,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextInput(
                              controller: _chucVuController,
                              label: 'Chức vụ',
                              hint: 'Nhân viên, Giám đốc...',
                              icon: Icons.manage_accounts_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextInput(
                              controller: _doanTheController,
                              label: 'Đoàn thể',
                              hint: 'Đoàn TNCS, Đảng viên...',
                              icon: Icons.groups_outlined,
                            ),
                          ),
                        ],
                      ),

                      // 4. ĐỊA CHỈ CƯ TRÚ
                      _buildSectionHeader('IV. ĐỊA CHỈ CƯ TRÚ', Icons.home_outlined),
                      CustomTextInput(
                        controller: _noiThuongTruController,
                        label: 'Nơi thường trú (Hộ khẩu)',
                        hint: 'Số nhà, đường, phường/xã, quận/huyện, tỉnh/TP...',
                        icon: Icons.home_outlined,
                      ),
                      const SizedBox(height: 12),
                      CustomTextInput(
                        controller: _noiTamTruController,
                        label: 'Nơi tạm trú',
                        hint: 'Địa chỉ tạm trú hiện tại...',
                        icon: Icons.holiday_village_outlined,
                      ),
                      const SizedBox(height: 12),
                      CustomTextInput(
                        controller: _noiOHienTaiController,
                        label: 'Nơi ở hiện nay',
                        hint: 'Nơi đang sinh sống thực tế...',
                        icon: Icons.pin_drop_outlined,
                      ),

                      // 5. TIỀN ÁN, TIỀN SỰ
                      _buildSectionHeader('V. TIỀN ÁN, TIỀN SỰ', Icons.gavel_outlined),
                      CustomTextInput(
                        controller: _tienAnTienSuController,
                        label: 'Tiền án, tiền sự',
                        hint: 'Chưa có tiền án, tiền sự...',
                        icon: Icons.gavel_outlined,
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      if (widget.caseId != null) ...[
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _saveToCase,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(isEdit ? Icons.check : Icons.save),
                          label: Text(
                            _isSaving
                                ? 'Đang lưu...'
                                : (isEdit ? 'CẬP NHẬT HỒ SƠ' : 'LƯU HỒ SƠ VÀO VỤ ÁN'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
