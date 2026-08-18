# Kế Hoạch Triển Khai: Tính Năng Xuất Văn Bản Theo Vụ Việc / Vụ Án (Case Level)

## 1. Mục tiêu & Tổng quan
Hiện tại hệ thống Quick Docs Helper chỉ hỗ trợ xuất các biểu mẫu văn bản theo từng cá nhân/đối tượng (`Person`). Tính năng mới này cho phép:
- Xuất các biểu mẫu văn bản ở cấp độ toàn bộ Vụ việc / Vụ án (`Case`).
- Liệt kê, tổng hợp danh sách tất cả các cá nhân/đối tượng trong vụ án vào văn bản (dạng danh sách liệt kê hoặc dạng bảng).
- Tích hợp xem trước trực tiếp trên giao diện bằng PDF.js và tải về file `.docx` kết quả chuẩn xác.

---

## 2. Cấu trúc Mẫu Văn Bản Word (`templates/case/`)

### 2.1. Thư mục & Metadata
- **Đường dẫn**: `templates/case/`
- **File cấu hình danh mục**: `templates/case/metadata.json`
  - Định dạng:
    ```json
    [
      {
        "file_name": "danh_sach_doi_tuong.docx",
        "display_name": "Danh sách các đối tượng trong vụ việc"
      },
      {
        "file_name": "bao_cao_tong_hop_vu_an.docx",
        "display_name": "Báo cáo tổng hợp vụ án"
      }
    ]
    ```

### 2.2. Cú pháp Jinja2 / `docxtpl` trong file Word (.docx)
1. **Thông tin vụ việc**:
   - `{{ case.ten_tom_tat }}`: Tên tóm tắt vụ việc.
   - `{{ case.ten_day_du }}`: Tên đầy đủ / mô tả vụ việc.
   - `{{ so_luong_nguoi }}`: Tổng số người trong vụ việc.
2. **Liệt kê danh sách đối tượng (dạng đoạn văn bản)**:
   ```jinja2
   {% for p in persons %}
   {{ loop.index }}. Họ và tên: {{ p.ho_ten }} - Ngày sinh: {{ p.ngay_sinh }} - Số CCCD: {{ p.so_cccd }} - Nơi ở: {{ p.noi_o_hien_tai }}
   {% endfor %}
   ```
3. **Liệt kê trong Bảng (Table - tự động nhân bản dòng)**:
   - Dòng dữ liệu mẫu trong bảng Word:
     - Ô 1 (STT): `{%tr for p in persons %}{{ loop.index }}`
     - Ô 2 (Họ tên): `{{ p.ho_ten }}`
     - Ô 3 (Ngày sinh): `{{ p.ngay_sinh }}`
     - Ô 4 (CCCD): `{{ p.so_cccd }}`
     - Ô 5 (Nơi thường trú/Hiện tại): `{{ p.noi_o_hien_tai }}{%tr endfor %}`

---

## 3. Kiến Trúc Backend (Python / FastAPI)

### 3.1. Dịch vụ xử lý Word (`src/services/docx_service.py`)
- **`get_case_templates()`**: Đọc danh sách mẫu từ `templates/case/metadata.json`.
- **`_resolve_case_template_path(template_filename)`**: Trỏ tới đường dẫn file mẫu trong thư mục `templates/case/`.
- **`_render_case_doc(template_filename, case_data, persons_data)`**:
  - Chuẩn bị context gồm: `case`, `persons` (danh sách dictionary thông tin cá nhân), `so_luong_nguoi`.
  - Thực hiện render bằng `DocxTemplate.render(context)`.
- **`generate_case_docx_bytes(...)`**: Render ra stream bộ nhớ `io.BytesIO` để tải về trực tiếp.
- **`generate_pdf_from_case(...)`**: Chuyển đổi file Word thành PDF, lưu cache tại `CACHE_DIR` để xem trước siêu tốc (0ms).

### 3.2. Router API (`src/api/generate_router.py`)
Bổ sung các endpoints sau:
- `GET /api/v1/generate/templates/case`: Lấy danh sách các mẫu văn bản dành cho vụ án.
- `GET /api/v1/generate/case/{case_id}/pdf-data`: Trả về dữ liệu nhị phân PDF để PDF.js render lên Canvas.
- `GET /api/v1/generate/case/{case_id}/preview-viewer`: Trả về trang HTML chứa trình xem PDF.js Canvas xem trước văn bản vụ án.
- `POST /api/v1/generate/case/{case_id}/download`: Kết xuất và tải file `.docx` kết quả về máy tính.

---

## 4. Kiến Trúc Frontend (Flutter Web / Desktop)

### 4.1. Cập nhật `ApiService` (`flutter/lib/services/api_service.dart`)
- **`getCaseTemplates()`**: Gọi `GET /api/v1/generate/templates/case`.
- **`getCasePreviewUrl(caseId, templateFile, {force = false})`**: Trả về URL xem trước tài liệu của vụ án.
- **`getCaseDownloadUrl(caseId, templateFile)`**: Trả về URL tải file Word của vụ án.

### 4.2. Cập nhật Trang Xuất Văn Bản (`flutter/lib/export_docs_page.dart`)
- Hỗ trợ 2 chế độ:
  - `isCaseLevel = false` (mặc định): Xuất tài liệu cho 1 cá nhân cụ thể.
  - `isCaseLevel = true`: Xuất tài liệu cho toàn bộ vụ án, nạp danh sách mẫu từ `getCaseTemplates()` và trỏ viewer tới URL tài liệu vụ án.

### 4.3. Thêm Nút Trên Giao Diện (`flutter/lib/widgets/case_detail_panel.dart`)
- Tại khu vực `headerActions` (nằm cạnh nút "Thêm Đối Tượng"):
  - Thêm nút `FilledButton.tonalIcon` hoặc `OutlinedButton.icon`:
    - **Icon**: `Icons.print_outlined` hoặc `Icons.description_outlined`
    - **Nhãn**: `Xuất Văn Bản Vụ Việc`
    - **Hành động**: Điều hướng tới `ExportDocsPage(caseId: caseId, caseData: caseData, isCaseLevel: true)`.

---

## 5. Kế Hoạch Các Bước Thực Hiện Chi Tiết

1. **Bước 1**: Tạo cấu trúc thư mục `templates/case/` và tạo sẵn file `metadata.json` mẫu.
2. **Bước 2**: Nâng cấp `DocxService` trong Python để bổ sung các hàm xử lý template vụ án và chuyển đổi PDF cache.
3. **Bước 3**: Bổ sung 4 API endpoints cho case trong `generate_router.py`.
4. **Bước 4**: Thêm các hàm tương ứng trong `ApiService` (Flutter).
5. **Bước 5**: Điều chỉnh `ExportDocsPage` hỗ trợ chế độ xem/tải tài liệu theo Case.
6. **Bước 6**: Bổ sung nút bấm "Xuất Văn Bản Vụ Việc" vào thanh tiêu đề của `CaseDetailPanel`.
7. **Bước 7**: Kiểm thử tạo mẫu `.docx` có lặp danh sách và kiểm tra chất lượng hiển thị PDF/tải về.
