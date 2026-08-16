import 'package:file_picker/file_picker.dart';
import 'widgets/date_time_input.dart';
import 'widgets/avatar_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'widgets/text_input.dart';
import 'widgets/radio_input.dart';
import 'services/api_service.dart';

class PersonPage extends StatefulWidget {
  final Map<String, dynamic>? initialPerson;
  final String? caseId;

  const PersonPage({super.key, this.initialPerson, this.caseId});

  @override
  State<PersonPage> createState() => _PersonPageState();
}

class _PersonPageState extends State<PersonPage> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  late TextEditingController _hoTenController;
  late TextEditingController _gioiTinhController;
  late TextEditingController _ngaySinhController;
  late TextEditingController _thangSinhController;
  late TextEditingController _namSinhController;
  late TextEditingController _noiSinhController;
  late TextEditingController _queQuanController;
  late TextEditingController _quocTichController;
  late TextEditingController _danTocController;
  late TextEditingController _tonGiaoController;
  late TextEditingController _cccdController;
  late TextEditingController _ngayCccdController;
  late TextEditingController _thangCccdController;
  late TextEditingController _namCccdController;
  late TextEditingController _noiCapCccdController;
  late TextEditingController _hocVanController;
  late TextEditingController _ngheNghiepController;
  late TextEditingController _noiLamViecController;
  late TextEditingController _noiThuongTruController;
  late TextEditingController _noiTamTruController;
  late TextEditingController _noiOHienTaiController;
  late TextEditingController _chucVuController;
  late TextEditingController _doanTheController;
  late TextEditingController _tienAnTienSuController;

  String _selectedGioiTinh = 'Nam';
  bool _isSaving = false;

  // Ảnh đại diện
  Uint8List? _avatarBytes;
  String? _avatarFilename;
  String? _initialImageUrl;

  @override
  void initState() {
    super.initState();
    final p = widget.initialPerson;

    _hoTenController = TextEditingController(text: p?['ho_ten'] ?? '');
    _gioiTinhController = TextEditingController(text: p?['gioi_tinh'] ?? 'Nam');
    _ngaySinhController = TextEditingController(text: p?['ngay_sinh'] ?? '');
    _thangSinhController = TextEditingController(text: p?['thang_sinh'] ?? '');
    _namSinhController = TextEditingController(text: p?['nam_sinh'] ?? '');
    _noiSinhController = TextEditingController(text: p?['noi_sinh'] ?? '');
    _queQuanController = TextEditingController(text: p?['que_quan'] ?? '');
    _quocTichController = TextEditingController(
      text: p?['quoc_tich'] ?? 'Việt Nam',
    );
    _danTocController = TextEditingController(text: p?['dan_toc'] ?? 'Kinh');
    _tonGiaoController = TextEditingController(text: p?['ton_giao'] ?? 'Không');
    _cccdController = TextEditingController(text: p?['cccd'] ?? '');
    _ngayCccdController = TextEditingController(text: p?['ngay_cccd'] ?? '');
    _thangCccdController = TextEditingController(text: p?['thang_cccd'] ?? '');
    _namCccdController = TextEditingController(text: p?['nam_cccd'] ?? '');
    _noiCapCccdController = TextEditingController(
      text: p?['noi_cap_cccd'] ?? 'Cục Cảnh sát QLHC về TTXH',
    );
    _hocVanController = TextEditingController(text: p?['hoc_van'] ?? '');
    _ngheNghiepController = TextEditingController(
      text: p?['nghe_nghiep'] ?? '',
    );
    _noiLamViecController = TextEditingController(
      text: p?['noi_lam_viec'] ?? '',
    );
    _noiThuongTruController = TextEditingController(
      text: p?['noi_thuong_tru'] ?? '',
    );
    _noiTamTruController = TextEditingController(text: p?['noi_tam_tru'] ?? '');
    _noiOHienTaiController = TextEditingController(
      text: p?['noi_o_hien_tai'] ?? '',
    );
    _chucVuController = TextEditingController(text: p?['chuc_vu'] ?? '');
    _doanTheController = TextEditingController(text: p?['doan_the'] ?? '');
    _tienAnTienSuController = TextEditingController(
      text: p?['tien_an_tien_su'] ?? 'Chưa có tiền án, tiền sự',
    );

    if (p != null) {
      _selectedGioiTinh = p['gioi_tinh'] ?? 'Nam';
      final imagePath = p['image_path'] ?? '';
      final personId = p['id'] ?? '';
      if (imagePath.toString().isNotEmpty &&
          widget.caseId != null &&
          personId.toString().isNotEmpty) {
        _initialImageUrl =
            '${ApiService.baseUrl}/api/v1/cases/${widget.caseId}/persons/$personId/image?t=${DateTime.now().millisecondsSinceEpoch}';
      }
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
    _noiThuongTruController.dispose();
    _noiTamTruController.dispose();
    _noiOHienTaiController.dispose();
    _chucVuController.dispose();
    _doanTheController.dispose();
    _tienAnTienSuController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _avatarBytes = result.files.single.bytes;
        _avatarFilename = result.files.single.name;
      });
    }
  }

  Future<void> _saveToCase() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng kiểm tra lại thông tin còn thiếu/chưa hợp lệ',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final isEdit = widget.initialPerson != null;
      final personId = isEdit
          ? widget.initialPerson!['id']
          : DateTime.now().millisecondsSinceEpoch.toString();

      final personData = {
        'person_id': personId,
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
        'image_path': widget.initialPerson?['image_path'] ?? '',
      };

      final Map<String, String> fields = {};
      personData.forEach((key, value) {
        fields[key] = value.toString();
      });

      await ApiService.savePersonToCase(
        caseId: widget.caseId!,
        fields: fields,
        imageBytes: _avatarBytes,
        imageFilename: _avatarFilename,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Cập nhật đối tượng thành công!'
                  : 'Đã lưu đối tượng vào vụ án!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isEdit = widget.initialPerson != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'THÔNG TIN ĐỐI TƯỢNG/BỊ CAN' : 'THÊM ĐỐI TƯỢNG/BỊ CAN',
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
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
                        isEdit
                            ? 'Cập nhật các thông tin cá nhân dưới đây và nhấn Cập Nhật Hồ Sơ.'
                            : 'Điền đầy đủ các thông tin cá nhân dưới đây để lưu vào vụ việc/vụ án và xuất Word.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: primaryColor.withValues(alpha: 0.6),
                        ),
                      ),

                      // 1. THÔNG TIN CƠ BẢN
                      _Section1BasicInfo(
                        avatarBytes: _avatarBytes,
                        initialImageUrl: _initialImageUrl,
                        onPickAvatar: _pickAvatar,
                        hoTenController: _hoTenController,
                        selectedGioiTinh: _selectedGioiTinh,
                        onGioiTinhChanged: (val) {
                          setState(() {
                            _selectedGioiTinh = val;
                            _gioiTinhController.text = val;
                          });
                        },
                        ngaySinhController: _ngaySinhController,
                        thangSinhController: _thangSinhController,
                        namSinhController: _namSinhController,
                        noiSinhController: _noiSinhController,
                        queQuanController: _queQuanController,
                        quocTichController: _quocTichController,
                        danTocController: _danTocController,
                        tonGiaoController: _tonGiaoController,
                      ),

                      // 2. THÔNG TIN CCCD / ĐỊNH DANH
                      _Section2CccdInfo(
                        cccdController: _cccdController,
                        ngayCccdController: _ngayCccdController,
                        thangCccdController: _thangCccdController,
                        namCccdController: _namCccdController,
                        noiCapCccdController: _noiCapCccdController,
                      ),

                      // 3. HỌC VẤN & CÔNG VIỆC
                      _Section3EducationWork(
                        hocVanController: _hocVanController,
                        ngheNghiepController: _ngheNghiepController,
                        noiLamViecController: _noiLamViecController,
                        chucVuController: _chucVuController,
                        doanTheController: _doanTheController,
                      ),

                      // 4. ĐỊA CHỈ CƯ TRÚ
                      _Section4Residences(
                        noiThuongTruController: _noiThuongTruController,
                        noiTamTruController: _noiTamTruController,
                        noiOHienTaiController: _noiOHienTaiController,
                      ),

                      // 5. TIỀN ÁN, TIỀN SỰ
                      _Section5CriminalRecord(
                        tienAnTienSuController: _tienAnTienSuController,
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(isEdit ? Icons.check : Icons.save),
                          label: Text(
                            _isSaving
                                ? 'Đang lưu...'
                                : (isEdit
                                      ? 'CẬP NHẬT HỒ SƠ'
                                      : 'LƯU HỒ SƠ VÀO VỤ ÁN'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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

// Widget tiêu đề section
Widget _buildSectionHeader(BuildContext context, String title) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.only(top: 20.0, bottom: 12.0),
    child: Row(
      children: [
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

// SECTION 1: THÔNG TIN CƠ BẢN
class _Section1BasicInfo extends StatelessWidget {
  final Uint8List? avatarBytes;
  final String? initialImageUrl;
  final VoidCallback onPickAvatar;
  final TextEditingController hoTenController;
  final String selectedGioiTinh;
  final ValueChanged<String> onGioiTinhChanged;
  final TextEditingController ngaySinhController;
  final TextEditingController thangSinhController;
  final TextEditingController namSinhController;
  final TextEditingController noiSinhController;
  final TextEditingController queQuanController;
  final TextEditingController quocTichController;
  final TextEditingController danTocController;
  final TextEditingController tonGiaoController;

  const _Section1BasicInfo({
    required this.avatarBytes,
    required this.initialImageUrl,
    required this.onPickAvatar,
    required this.hoTenController,
    required this.selectedGioiTinh,
    required this.onGioiTinhChanged,
    required this.ngaySinhController,
    required this.thangSinhController,
    required this.namSinhController,
    required this.noiSinhController,
    required this.queQuanController,
    required this.quocTichController,
    required this.danTocController,
    required this.tonGiaoController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(context, 'I. THÔNG TIN CƠ BẢN'),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: AvatarPicker(
                  avatarBytes: avatarBytes,
                  initialImageUrl: initialImageUrl,
                  onPickAvatar: onPickAvatar,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomTextInput(
                          controller: hoTenController,
                          label: 'Họ và tên',
                          hint: 'Nguyễn Văn A...',
                          icon: Icons.badge_outlined,
                          isRequired: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 180,
                        child: CustomRadioInput(
                          options: const ['Nam', 'Nữ'],
                          selectedValue: selectedGioiTinh,
                          icon: Icons.wc,
                          onChanged: onGioiTinhChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: DateTimeInput(
                          label: 'Ngày tháng năm sinh',
                          hint: 'dd/mm/yyyy (vd: 15081995)',
                          icon: Icons.calendar_today,
                          dayController: ngaySinhController,
                          monthController: thangSinhController,
                          yearController: namSinhController,
                          isRequired: true,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Vui lòng nhập ngày sinh';
                            }
                            if (val.length != 10) {
                              return 'Vui lòng nhập ngày sinh hợp lệ';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: CustomTextInput(
                          controller: noiSinhController,
                          label: 'Nơi sinh',
                          hint: 'Xã/Phường, Tỉnh/TP...',
                          icon: Icons.location_city,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextInput(
                    controller: queQuanController,
                    label: 'Quê quán',
                    hint: 'Xã/Phường, Tỉnh/TP...',
                    icon: Icons.home_work_outlined,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextInput(
                          controller: quocTichController,
                          label: 'Quốc tịch',
                          hint: 'Việt Nam',
                          icon: Icons.flag_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomTextInput(
                          controller: danTocController,
                          label: 'Dân tộc',
                          hint: 'Kinh',
                          icon: Icons.people_outline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomTextInput(
                          controller: tonGiaoController,
                          label: 'Tôn giáo',
                          hint: 'Không',
                          icon: Icons.church_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// SECTION 2: THÔNG TIN CCCD
class _Section2CccdInfo extends StatelessWidget {
  final TextEditingController cccdController;
  final TextEditingController ngayCccdController;
  final TextEditingController thangCccdController;
  final TextEditingController namCccdController;
  final TextEditingController noiCapCccdController;

  const _Section2CccdInfo({
    required this.cccdController,
    required this.ngayCccdController,
    required this.thangCccdController,
    required this.namCccdController,
    required this.noiCapCccdController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(context, 'II. THÔNG TIN CCCD'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: CustomTextInput(
                controller: cccdController,
                label: 'Số CCCD / CMND',
                hint: '12 chữ số...',
                icon: Icons.credit_card,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: DateTimeInput(
                label: 'Ngày cấp CCCD',
                hint: 'dd/mm/yyyy (vd: 01012022)',
                icon: Icons.calendar_today,
                dayController: ngayCccdController,
                monthController: thangCccdController,
                yearController: namCccdController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CustomTextInput(
          controller: noiCapCccdController,
          label: 'Nơi cấp CCCD',
          hint: 'Cục Cảnh sát QLHC về TTXH',
          icon: Icons.account_balance_outlined,
        ),
      ],
    );
  }
}

// SECTION 3: HỌC VẤN & CÔNG VIỆC
class _Section3EducationWork extends StatelessWidget {
  final TextEditingController hocVanController;
  final TextEditingController ngheNghiepController;
  final TextEditingController noiLamViecController;
  final TextEditingController chucVuController;
  final TextEditingController doanTheController;

  const _Section3EducationWork({
    required this.hocVanController,
    required this.ngheNghiepController,
    required this.noiLamViecController,
    required this.chucVuController,
    required this.doanTheController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(context, 'III. HỌC VẤN, NGHỀ NGHIỆP & ĐOÀN THỂ'),
        Row(
          children: [
            Expanded(
              child: CustomTextInput(
                controller: hocVanController,
                label: 'Trình độ học vấn',
                hint: '12/12, Đại học...',
                icon: Icons.school_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextInput(
                controller: ngheNghiepController,
                label: 'Nghề nghiệp',
                hint: 'Kỹ sư, Tự do...',
                icon: Icons.work_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CustomTextInput(
          controller: noiLamViecController,
          label: 'Nơi làm việc',
          hint: 'Tên công ty / Cơ quan làm việc...',
          icon: Icons.business_outlined,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomTextInput(
                controller: chucVuController,
                label: 'Chức vụ',
                hint: 'Nhân viên, Giám đốc...',
                icon: Icons.manage_accounts_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextInput(
                controller: doanTheController,
                label: 'Đoàn thể',
                hint: 'Đoàn TNCS, Đảng viên...',
                icon: Icons.groups_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// SECTION 4: ĐỊA CHỈ CƯ TRÚ
class _Section4Residences extends StatelessWidget {
  final TextEditingController noiThuongTruController;
  final TextEditingController noiTamTruController;
  final TextEditingController noiOHienTaiController;

  const _Section4Residences({
    required this.noiThuongTruController,
    required this.noiTamTruController,
    required this.noiOHienTaiController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(context, 'IV. ĐỊA CHỈ CƯ TRÚ'),
        CustomTextInput(
          controller: noiThuongTruController,
          label: 'Nơi thường trú (Hộ khẩu)',
          hint: 'Số nhà, đường, phường/xã, tỉnh/TP...',
          icon: Icons.home_outlined,
        ),
        const SizedBox(height: 12),
        CustomTextInput(
          controller: noiTamTruController,
          label: 'Nơi tạm trú',
          hint: 'Địa chỉ tạm trú hiện tại...',
          icon: Icons.holiday_village_outlined,
        ),
        const SizedBox(height: 12),
        CustomTextInput(
          controller: noiOHienTaiController,
          label: 'Nơi ở hiện nay',
          hint: 'Nơi đang sinh sống thực tế...',
          icon: Icons.pin_drop_outlined,
        ),
      ],
    );
  }
}

// SECTION 5: TIỀN ÁN, TIỀN SỰ
class _Section5CriminalRecord extends StatelessWidget {
  final TextEditingController tienAnTienSuController;

  const _Section5CriminalRecord({required this.tienAnTienSuController});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(context, 'V. TIỀN ÁN, TIỀN SỰ'),
        CustomTextInput(
          controller: tienAnTienSuController,
          label: 'Tiền án, tiền sự',
          hint: 'Chưa có tiền án, tiền sự...',
          minLines: 4,
          maxLines: 8,
        ),
      ],
    );
  }
}
