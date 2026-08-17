# Quick Docs Helper

Ứng dụng hỗ trợ trích xuất, kết xuất và quản lý hồ sơ tài liệu tự động dành cho các vụ việc/vụ án. Hệ thống tích hợp trọn gói Backend **Python (FastAPI)**, giao diện **Flutter Web** và công cụ chuyển đổi **LibreOffice Headless**.

---

## 1. Tính Năng Nổi Bật

* **Quản lý Hồ sơ & Con người**: Tạo và quản lý thông tin các vụ việc, các cá nhân liên quan kèm ảnh đại diện, thân nhân và tiền án/tiền sự.
* **Kết xuất Văn bản Word (.docx)**: Điền tự động thông tin vào các mẫu biểu chuẩn (`.docx`) bằng công nghệ Jinja2 template (`docxtpl`).
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
│   └── person/              # Mẫu văn bản (.docx) + metadata.json
├── static/                  # Bản build Flutter Web được FastAPI phân phối trực tiếp
├── flutter/                 # Mã nguồn giao diện người dùng Flutter Web
├── src/                     # Mã nguồn Backend FastAPI
│   ├── api/                 # Các API Router (case_router, generate_router)
│   ├── schemas/             # Pydantic Schemas dữ liệu
│   ├── services/            # DocxService, StorageService
│   └── config.py            # Cấu hình đường dẫn hệ thống
├── main.py                  # Điểm khởi chạy FastAPI Server
├── Dockerfile               # Cấu hình đóng gói Docker image
├── docker-compose.yml       # Cấu hình Docker Compose service
└── requirements.txt         # Thư viện Python phụ thuộc
```

---

## 3. Hướng Dẫn Soạn Thảo Mẫu Văn Bản Word (.docx)

Hệ thống sử dụng engine **`docxtpl` (Jinja2)** để điền dữ liệu tự động. Bạn có thể sử dụng Microsoft Word hoặc LibreOffice Writer để thiết kế file mẫu `.docx` đặt trong thư mục `templates/person/`.

### a. Chèn Biến Đơn (Variables)
Đặt tên biến trong dấu ngoặc nhọn kép `{{ ten_bien }}`:
* `{{ ho_ten }}`: Họ và tên đối tượng
* `{{ ngay_sinh }}`, `{{ thang_sinh }}`, `{{ nam_sinh }}`: Ngày, tháng, năm sinh
* `{{ cccd }}`, `{{ ngay_cccd }}`, `{{ thang_cccd }}`, `{{ nam_cccd }}`, `{{ noi_cap_cccd }}`: Thông tin CCCD
* `{{ que_quan }}`, `{{ noi_thuong_tru }}`, `{{ noi_tam_tru }}`, `{{ noi_o_hien_tai }}`: Nơi ở, quê quán
* `{{ nghe_nghiep }}`, `{{ noi_lam_viec }}`, `{{ hoc_van }}`: Nghề nghiệp, học vấn
* `{{ image }}`: Vị trí chèn ảnh chân dung / ảnh thẻ

---

### b. Vòng Lặp Trong Đoạn Văn Bản (Paragraph Loop - `{%p for %}`)
Để lặp các dòng/đoạn văn bản mà không sinh ra các dòng trống thừa thãi, hãy thêm tiền tố `p` vào trước thẻ:

```jinja2
{%p for item in quan_he_gia_dinh %}
- {{ item.quan_he }}: {{ item.ho_ten }} (SN: {{ item.nam_sinh }}), Nghề nghiệp: {{ item.nghe_nghiep }}, Nơi ở: {{ item.noi_o }}
{%p endfor %}
```

---

### c. Cấu Trúc Điều Kiện If / Else (`{%p if %}`)
Hiển thị nội dung tùy theo việc danh sách có phần tử hay rỗng:

```jinja2
{%p if tien_an_tien_su %}
{%p for item in tien_an_tien_su %}
- {{ item.thoi_gian }}: {{ item.noi_dung }}
{%p endfor %}
{%p else %}
Chưa có tiền án, tiền sự
{%p endif %}
```

*Hoặc dùng cú pháp ngắn gọn `for ... else`:*
```jinja2
{%p for item in tien_an_tien_su %}
- {{ item.thoi_gian }}: {{ item.noi_dung }}
{%p else %}
Chưa có tiền án, tiền sự
{%p endfor %}
```

---

### d. Vòng Lặp Trong Bảng Word (Table Row Loop - `{%tr for %}`)
Để nhân bản từng hàng trong bảng Word tương ứng với mỗi phần tử trong danh sách, theo chuẩn của thư viện `docxtpl`, bạn tạo **3 hàng (rows)** trong bảng:
1. **Hàng 1 (Hàng mở vòng lặp):** Chỉ chứa thẻ `{%tr for item in quan_he_gia_dinh %}` (ở bất kỳ ô nào của hàng).
2. **Hàng 2 (Hàng dữ liệu mẫu):** Chứa các cột dữ liệu hiển thị (`{{ item.quan_he }}`, `{{ item.ho_ten }}`, `{{ item.nam_sinh }}`, `{{ item.noi_o }}`).
3. **Hàng 3 (Hàng đóng vòng lặp):** Chỉ chứa thẻ `{%tr endfor %}` (ở bất kỳ ô nào của hàng).

*(Khi xuất tài liệu, engine `docxtpl` sẽ tự động xóa 2 hàng chứa thẻ `{%tr ... %}` và nhân bản hàng dữ liệu ở giữa cho từng phần tử).*

**Minh họa thiết kế bảng quan hệ gia đình trong Word:**

| STT | Quan hệ | Họ và tên | Năm sinh | Nghề nghiệp | Nơi ở hiện tại |
|:---:|:---:|:---:|:---:|:---:|:---:|
| `{%tr for item in quan_he_gia_dinh %}` | | | | | |
| `{{ loop.index }}` | `{{ item.quan_he }}` | `{{ item.ho_ten }}` | `{{ item.nam_sinh }}` | `{{ item.nghe_nghiep }}` | `{{ item.noi_o }}` |
| `{%tr endfor %}` | | | | | |

* **`{{ loop.index }}`**: Tự động đánh số thứ tự từ 1 (1, 2, 3...).
* **`{{ loop.index0 }}`**: Tự động đánh số thứ tự từ 0.

---

## 4. Hướng Dẫn Triển Khai Trên VPS (aaPanel / Linux) Bằng Git & Docker

Đây là phương thức triển khai chuẩn và nhanh nhất trên máy chủ VPS Ubuntu/Debian có cài đặt aaPanel.

### Bước 1: Cài đặt Docker trên VPS aaPanel
1. Đăng nhập vào bảng điều khiển **aaPanel**.
2. Vào mục **App Store** -> Tìm kiếm **Docker** -> Nhấn **Install** (hoặc cài đặt trực tiếp qua Terminal).
3. Đảm bảo dịch vụ Docker đang hoạt động:
   ```bash
   docker --version
   docker compose version
   ```

### Bước 2: Kéo mã nguồn từ Git về VPS
Mở Terminal trên aaPanel hoặc SSH vào VPS và di chuyển tới thư mục muốn lưu trữ (ví dụ: `/www/wwwroot/`):

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
*(Nếu VPS dùng phiên bản Docker cũ hơn, sử dụng lệnh: `docker-compose up -d --build`)*

Container sẽ tự động:
* Cài đặt môi trường Python 3.10, LibreOffice Writer và đầy đủ font Unicode tiếng Việt.
* Mount thư mục `./data` và `./templates` từ VPS vào container (đảm bảo dữ liệu không bị mất khi cập nhật).
* Khởi chạy Web Server tại cổng `8000`.

### Bước 4: Mở Port hoặc Cấu hình Tên Miền (Domain / Reverse Proxy)

#### Cách 1: Truy cập trực tiếp qua IP và Cổng
* Trên aaPanel: Vào mục **Security** -> Nhấn **Add Port Rule** -> Mở cổng **`8000`**.
* Truy cập ứng dụng: `http://<IP_VPS>:8000`

#### Cách 2: Gắn tên miền và SSL (Khuyên dùng)
1. Trên aaPanel: Vào mục **Website** -> **Add Site** -> Nhập Domain của bạn.
2. Nhấn vào tên Domain vừa tạo -> Chọn tab **Reverse Proxy** -> **Add Reverse Proxy**:
   * **Proxy Name**: `quickdocs`
   * **Target URL**: `http://127.0.0.1:8000`
   * **Sent Domain**: `$host`
3. Cài đặt SSL miễn phí (Let's Encrypt) trong tab **SSL** của Website.
4. Truy cập ứng dụng an toàn qua: `https://your-domain.com`

### Bước 5: Cập nhật ứng dụng khi có code mới (Update)
Mỗi khi bạn đẩy code mới lên Git, chỉ cần chạy các lệnh sau trên VPS:

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
* Phần mềm LibreOffice (hoặc MS Word trên Windows)

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
# Hoặc: uvicorn main:app --reload --host 0.0.0.0 --port 8000
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
  * Kiểm tra xem container đã có LibreOffice chưa bằng cách xem log: `docker compose logs -f`
  * Đảm bảo file Word template không bị khóa hoặc đặt sai đường dẫn trong `templates/person/`.
* **Cập nhật giao diện Flutter không hiển thị trên Web:**
  * Xóa cache trình duyệt (nhấn `Ctrl + Shift + R`) để tải lại toàn bộ file tĩnh JavaScript/Wasm mới nhất.