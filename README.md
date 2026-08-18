# Quick Docs Helper

Ứng dụng hỗ trợ trích xuất, kết xuất và quản lý hồ sơ tài liệu tự động dành cho các vụ việc/vụ án. Hệ thống tích hợp trọn gói Backend **Python (FastAPI)**, giao diện **Flutter Web** và công cụ chuyển đổi **LibreOffice Headless** / **Microsoft Word**.

---

## 1. Tính Năng Nổi Bật

* **Quản lý Vụ việc & Đối tượng**: Tạo và quản lý thông tin các vụ án, các đối tượng liên quan kèm ảnh đại diện 3x4, thân nhân và tiền án/tiền sự.
* **Kết xuất Văn bản Đối tượng Riêng (.docx)**: Điền tự động thông tin cá nhân vào các mẫu biểu chuẩn (`.docx`) bằng công nghệ Jinja2 template (`docxtpl`).
* **Kết xuất Văn bản Chung Vụ Án (.docx)**: Tổng hợp toàn bộ danh sách đối tượng, thông tin vụ án vào các mẫu báo cáo và bảng danh sách tự động.
* **Xem trước PDF tức thì (0ms)**: Sử dụng Mozilla PDF.js Canvas chống bị IDM bắt link, kết hợp bộ nhớ đệm Cache PDF thông minh.
* **Tải xuống trực tiếp từ RAM**: Tải file `.docx` trực tiếp qua bộ nhớ RAM (Streaming Response), không lưu tệp tạm thừa thãi trên máy chủ.
* **Đóng gói Docker trọn bộ**: Tích hợp sẵn font tiếng Việt Unicode và LibreOffice Writer phục vụ render PDF trên môi trường Linux/Docker.

---

## 2. Cấu Trúc Dự Án

```
quick-docs-helper/
├── data/                    # Thư mục lưu trữ dữ liệu (được mount qua Docker)
│   ├── cases/               # Dữ liệu các vụ việc và hồ sơ cá nhân (.json + ảnh)
│   └── cache/               # Bộ nhớ đệm cache file PDF xem trước
├── templates/               # Thư mục chứa các mẫu văn bản Word
│   ├── person/              # Mẫu văn bản cá nhân (.docx) + metadata.json
│   └── case/                # Mẫu văn bản chung của vụ án (.docx) + metadata.json
├── static/                  # Bản build Flutter Web được FastAPI phân phối trực tiếp
├── flutter/                 # Mã nguồn giao diện người dùng Flutter Web
├── src/                     # Mã nguồn Backend FastAPI
│   ├── api/                 # Các API Router (case_router, generate_router)
│   ├── schemas/             # Pydantic Schemas dữ liệu (PersonData, CaseData)
│   ├── services/            # BaseDocxService, PersonDocxService, CaseDocxService, StorageService
│   └── config.py            # Cấu hình đường dẫn hệ thống
├── main.py                  # Điểm khởi chạy FastAPI Server
├── Dockerfile               # Cấu hình đóng gói Docker image
├── docker-compose.yml       # Cấu hình Docker Compose service
└── requirements.txt         # Thư viện Python phụ thuộc
```

---

## 3. Hướng Dẫn Soạn Thảo Mẫu Văn Bản Word (.docx)

Hệ thống sử dụng engine **`docxtpl` (Jinja2)** để điền dữ liệu tự động. Bạn có thể sử dụng Microsoft Word hoặc LibreOffice Writer để thiết kế file mẫu `.docx` và đặt vào thư mục tương ứng:
* `templates/person/`: Mẫu văn bản riêng cho từng đối tượng.
* `templates/case/`: Mẫu văn bản chung cho toàn bộ vụ án.

---

### 3.1. Danh Sách Biến Trong Mẫu Đối Tượng Riêng (`templates/person/`)

Khi soạn thảo mẫu cho từng cá nhân, bạn sử dụng trực tiếp các tên biến sau bên trong dấu ngoặc kép `{{ ten_bien }}`:

#### A. Thông tin cá nhân cơ bản
| Tên biến | Kiểu dữ liệu | Ý nghĩa / Ví dụ |
|:---|:---|:---|
| `{{ id }}` | Chuỗi | Mã định danh duy nhất (UUID) của đối tượng |
| `{{ ho_ten }}` | Chuỗi | Họ và tên đối tượng (ví dụ: `Nguyễn Văn Trỗi`) |
| `{{ gioi_tinh }}` | Chuỗi | Giới tính (`Nam`, `Nữ`...) |
| `{{ ngay_sinh }}` | Chuỗi | Ngày sinh (ví dụ: `15`) |
| `{{ thang_sinh }}` | Chuỗi | Tháng sinh (ví dụ: `08`) |
| `{{ nam_sinh }}` | Chuỗi | Năm sinh (ví dụ: `1990`) |
| `{{ noi_sinh }}` | Chuỗi | Nơi sinh (Xã/Phường, Quận/Huyện, Tỉnh/TP) |
| `{{ que_quan }}` | Chuỗi | Quê quán / Nguyên quán |
| `{{ quoc_tich }}` | Chuỗi | Quốc tịch (ví dụ: `Việt Nam`) |
| `{{ dan_toc }}` | Chuỗi | Dân tộc (ví dụ: `Kinh`, `Tày`...) |
| `{{ ton_giao }}` | Chuỗi | Tôn giáo (ví dụ: `Không`, `Phật giáo`...) |

#### B. Thông tin Giấy tờ & Cư trú
| Tên biến | Kiểu dữ liệu | Ý nghĩa / Ví dụ |
|:---|:---|:---|
| `{{ cccd }}` | Chuỗi | Số thẻ CCCD / CMND (12 chữ số) |
| `{{ ngay_cccd }}` | Chuỗi | Ngày cấp thẻ CCCD |
| `{{ thang_cccd }}` | Chuỗi | Tháng cấp thẻ CCCD |
| `{{ nam_cccd }}` | Chuỗi | Năm cấp thẻ CCCD |
| `{{ noi_cap_cccd }}` | Chuỗi | Nơi cấp CCCD (ví dụ: `Cục Cảnh sát QLHC về TTXH`) |
| `{{ noi_thuong_tru }}` | Chuỗi | Nơi đăng ký thường trú (Hộ khẩu) |
| `{{ noi_tam_tru }}` | Chuỗi | Nơi đăng ký tạm trú |
| `{{ noi_o_hien_tai }}` | Chuỗi | Nơi ở hiện nay / Nơi cư trú thực tế |

#### C. Học vấn, Nghề nghiệp & Tổ chức
| Tên biến | Kiểu dữ liệu | Ý nghĩa / Ví dụ |
|:---|:---|:---|
| `{{ hoc_van }}` | Chuỗi | Trình độ học vấn phổ thông (ví dụ: `12/12`) |
| `{{ nghe_nghiep }}` | Chuỗi | Nghề nghiệp hiện tại (ví dụ: `Tự do`, `Lái xe`...) |
| `{{ noi_lam_viec }}` | Chuỗi | Nơi làm việc / Cơ quan |
| `{{ chuc_vu }}` | Chuỗi | Chức vụ |
| `{{ doan_the }}` | Chuỗi | Đoàn thể / Đảng phái |
| `{{ image }}` | Hình ảnh | Ảnh thẻ chân dung 3x4cm (Hệ thống tự chèn `InlineImage`) |

#### D. Danh sách Tiền án, Tiền sự (`tien_an_tien_su`)
Là một danh sách gồm các bản ghi tiền án/tiền sự. Sử dụng vòng lặp:
```jinja2
{%p if tien_an_tien_su %}
{%p for item in tien_an_tien_su %}
- Lần {{ loop.index }}: Thời gian: {{ item.thoi_gian }} - Nội dung: {{ item.noi_dung }}
{%p endfor %}
{%p else %}
Không có tiền án, tiền sự.
{%p endif %}
```
* `{{ loop.index }}`: Số thứ tự tăng dần từ 1.
* `{{ item.thoi_gian }}`: Thời gian / Năm bị xử lý.
* `{{ item.noi_dung }}`: Nội dung hành vi vi phạm / Bản án / Quyết định xử phạt.

#### E. Danh sách Quan hệ gia đình (`quan_he_gia_dinh`)
Có thể hiển thị dạng danh sách đoạn văn hoặc dạng bảng biểu:

* **Cách 1: Lặp dạng đoạn văn bản (`{%p for %}`)**:
```jinja2
{%p for item in quan_he_gia_dinh %}
- {{ item.quan_he }}: {{ item.ho_ten }} (Sinh năm: {{ item.nam_sinh }}), Nghề nghiệp: {{ item.nghe_nghiep }}, Nơi ở: {{ item.noi_o }}
{%p endfor %}
```

* **Cách 2: Lặp từng hàng trong bảng Word (`{%tr for %}`)**:
Tạo bảng 3 hàng như sau:

| STT | Quan hệ | Họ và tên | Năm sinh | Nghề nghiệp | Nơi ở hiện nay |
|:---:|:---:|:---:|:---:|:---:|:---:|
| `{%tr for item in quan_he_gia_dinh %}` | | | | | |
| `{{ loop.index }}` | `{{ item.quan_he }}` | `{{ item.ho_ten }}` | `{{ item.nam_sinh }}` | `{{ item.nghe_nghiep }}` | `{{ item.noi_o }}` |
| `{%tr endfor %}` | | | | | |

---

### 3.2. Danh Sách Biến Trong Mẫu Chung Của Vụ Án (`templates/case/`)

Khi soạn thảo mẫu báo cáo tổng hợp hoặc danh sách vụ án, dữ liệu context cung cấp 2 đối tượng chính:

#### A. Thông tin vụ án (`case`)
| Tên biến | Kiểu dữ liệu | Ý nghĩa / Ví dụ |
|:---|:---|:---|
| `{{ case.id }}` | Chuỗi | Mã ID của vụ án |
| `{{ case.ten_tom_tat }}` | Chuỗi | Tên tóm tắt / Ký hiệu vụ việc (ví dụ: `Vụ án ma túy X`) |
| `{{ case.ten_day_du }}` | Chuỗi | Tên đầy đủ / Nội dung tóm tắt chi tiết vụ án |
| `{{ case.created_at }}` | Chuỗi | Thời điểm tạo hồ sơ vụ án |
| `{{ case.updated_at }}` | Chuỗi | Thời điểm cập nhật dữ liệu gần nhất |
| `{{ con_nguoi_list \| length }}` | Số nguyên | Tổng số lượng đối tượng trong vụ án |

#### B. Danh sách toàn bộ đối tượng trong vụ án (`con_nguoi_list`)
Mỗi phần tử `p` trong `con_nguoi_list` chứa đầy đủ tất cả các trường thông tin của đối tượng như ở mục 3.1:
* `p.ho_ten`: Họ và tên
* `p.gioi_tinh`: Giới tính
* `p.ngay_sinh`, `p.thang_sinh`, `p.nam_sinh`: Ngày, tháng, năm sinh
* `p.noi_sinh`, `p.que_quan`, `p.quoc_tich`, `p.dan_toc`, `p.ton_giao`
* `p.cccd`, `p.ngay_cccd`, `p.thang_cccd`, `p.nam_cccd`, `p.noi_cap_cccd`
* `p.noi_thuong_tru`, `p.noi_tam_tru`, `p.noi_o_hien_tai`
* `p.hoc_van`, `p.nghe_nghiep`, `p.noi_lam_viec`, `p.chuc_vu`, `p.doan_the`
* `p.tien_an_tien_su`: Danh sách tiền án, tiền sự của đối tượng
* `p.quan_he_gia_dinh`: Danh sách thân nhân của đối tượng

#### C. Các cách lặp danh sách đối tượng trong Word:

* **Cách 1: Lặp danh sách chi tiết (Dạng đoạn văn bản)**:
```jinja2
{% for p in con_nguoi_list %}
{{ loop.index }}. Họ và tên: {{ p.ho_ten }} (Sinh ngày: {{ p.ngay_sinh }}/{{ p.thang_sinh }}/{{ p.nam_sinh }} - Số CCCD: {{ p.cccd }})
- Quê quán: {{ p.que_quan }}
- Nơi thường trú: {{ p.noi_thuong_tru }}
- Nơi ở hiện nay: {{ p.noi_o_hien_tai }}
- Nghề nghiệp: {{ p.nghe_nghiep }}
{% endfor %}
```

* **Cách 2: Bảng danh sách đối tượng trong Word (Cú pháp `{%tr for %}`)**:
Tạo bảng trong Microsoft Word gồm 3 hàng:

| STT | Họ và tên | Ngày sinh | Số CCCD | Nơi thường trú | Nơi ở hiện nay |
|:---:|:---|:---:|:---:|:---|:---|
| `{%tr for p in con_nguoi_list %}` | | | | | |
| `{{ loop.index }}` | `{{ p.ho_ten }}` | `{{ p.ngay_sinh }}/{{ p.thang_sinh }}/{{ p.nam_sinh }}` | `{{ p.cccd }}` | `{{ p.noi_thuong_tru }}` | `{{ p.noi_o_hien_tai }}` |
| `{%tr endfor %}` | | | | | |

---

## 4. Hướng Dẫn Triển Khai Trên VPS (aaPanel / Linux) Bằng Git & Docker

Đây là phương thức triển khai chuẩn và nhanh nhất trên máy chủ VPS Ubuntu/Debian có cài đặt aaPanel.

### Bước 1: Cài đặt Docker trên VPS aaPanel
1. Đăng nhập vào bảng điều khiển **aaPanel**.
2. Vào mục **App Store** -> Tìm kiếm **Docker** -> Nhấn **Install**.
3. Kiểm tra dịch vụ Docker trong Terminal:
   ```bash
   docker --version
   docker compose version
   ```

### Bước 2: Kéo mã nguồn từ Git về VPS
Mở Terminal trên aaPanel hoặc SSH vào VPS và di chuyển tới thư mục muốn lưu trữ:
```bash
cd /www/wwwroot/
git clone <URL_KHO_LUU_TRU_GIT_CUA_BAN> quick-docs-helper
cd quick-docs-helper
```

### Bước 3: Khởi chạy ứng dụng bằng Docker Compose
Chạy lệnh sau để build và khởi chạy container dưới nền:
```bash
docker compose up -d --build
```

Container sẽ tự động:
* Cài đặt môi trường Python 3.10, LibreOffice Writer và đầy đủ font Unicode tiếng Việt.
* Mount thư mục `./data` và `./templates` từ VPS vào container (dữ liệu và mẫu biểu được bảo toàn vĩnh viễn khi cập nhật code).
* Khởi chạy Web Server tại cổng `8000`.

### Bước 4: Cấu hình Tên Miền (Domain / Reverse Proxy)
1. Trên aaPanel: Vào mục **Website** -> **Add Site** -> Nhập Domain của bạn.
2. Nhấn vào tên Domain vừa tạo -> Chọn tab **Reverse Proxy** -> **Add Reverse Proxy**:
   * **Proxy Name**: `quickdocs`
   * **Target URL**: `http://127.0.0.1:8000`
   * **Sent Domain**: `$host`
3. Cài đặt chứng chỉ SSL miễn phí (Let's Encrypt) trong tab **SSL** của Website.
4. Truy cập ứng dụng an toàn qua giao thức: `https://your-domain.com`

### Bước 5: Cập nhật ứng dụng khi có code mới
Mỗi khi có cập nhật mới trên kho Git:
```bash
cd /www/wwwroot/quick-docs-helper
git pull
docker compose up -d --build
```

---

## 5. Hướng Dẫn Chạy Ở Môi Trường Phát Triển Cục Bộ (Local Development)

### a. Yêu cầu môi trường
* Python 3.10+
* Flutter SDK 3.x
* Phần mềm Microsoft Word (Windows) hoặc LibreOffice (Linux/macOS)

### b. Chạy Backend FastAPI
```bash
# 1. Tạo môi trường ảo
python -m venv .venv
.\.venv\Scripts\activate   # Trên Windows
# source .venv/bin/activate # Trên Linux / macOS

# 2. Cài đặt thư viện
pip install -r requirements.txt

# 3. Khởi chạy Server (Tự động biên dịch Flutter Web nếu có Flutter SDK)
python main.py
# Hoặc chạy phát triển: uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

### c. Chạy Frontend Flutter Web độc lập (khi debug UI)
```bash
cd flutter
flutter pub get
flutter run -d chrome
```

---

## 6. Xử Lý Sự Cố Thường Gặp (Troubleshooting)

* **Lỗi không kết xuất được PDF trên VPS Linux:**
  * Kiểm tra log container: `docker compose logs -f`
  * Đảm bảo file Word template không bị khóa hoặc đặt sai đường dẫn trong `templates/person/` hoặc `templates/case/`.
* **Cập nhật giao diện Flutter không hiển thị trên Web:**
  * Xóa cache trình duyệt (nhấn `Ctrl + Shift + R` hoặc `Ctrl + F5`) để tải lại toàn bộ file tĩnh JavaScript/Wasm mới nhất.
* **Mẫu Word bảng không lặp hàng:**
  * Đảm bảo hàng mở vòng lặp có chứa `{%tr for ... %}` và hàng đóng vòng lặp chứa `{%tr endfor %}`. Không đặt thẻ lặp ngoài bảng.