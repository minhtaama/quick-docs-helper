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

## 3. Hướng Dẫn Soạn Thảo Mẫu Văn Bản Word (.docx) & Cú Pháp Jinja2

Hệ thống sử dụng engine **`docxtpl` (Jinja2)** để điền dữ liệu tự động. Bạn có thể sử dụng Microsoft Word hoặc LibreOffice Writer để thiết kế file mẫu `.docx` và đặt vào thư mục tương ứng:

* `templates/person/`: Mẫu văn bản cố định cấp đối tượng.
* `templates/case/`: Mẫu văn bản cố định cấp vụ án.
* `custom_templates/person/`: Mẫu văn bản tùy biến cấp đối tượng cá nhân (kèm `metadata.json`).
* `custom_templates/case/`: Mẫu văn bản tùy biến cấp vụ án (kèm `metadata.json`).

---

### 3.1. Bảng Tra Cứu Các Loại Thẻ Jinja2 Trong Word (`docxtpl`)

| Loại thẻ Jinja2 | Cú pháp mẫu | Mô tả & Ứng dụng |
| :--- | :--- | :--- |
| **Giá trị biến (Value)** | `{{ ten_bien }}` | Chèn trực tiếp giá trị chuỗi, số hoặc ngày tháng vào nội dung dòng chữ. |
| **Đoạn văn bản (Paragraph)** | `{%p if dieu_kien %} ... {%p endif %}`<br>`{%p for item in list %} ... {%p endfor %}` | Quản lý toàn bộ 1 đoạn văn (Paragraph). Nếu điều kiện `False`, **xóa bỏ hoàn toàn đoạn văn** (không để lại dòng trống thừa). |
| **Hàng trong bảng (Table Row)** | `{%tr for item in list %}`<br>`{{ item.ten }}`<br>`{%tr endfor %}` | Dùng trong bảng biểu Word. Thẻ mở `{%tr for %}` đặt ở dòng lặp đầu tiên, hệ thống sẽ tự động nhân bản các hàng trong bảng theo số lượng phần tử. |
| **Ô trong bảng (Table Cell)** | `{%tc if dieu_kien %} ... {%tc endif %}` | Dùng để ẩn/hiện hoặc xử lý logic bên trong một ô (Cell) duy nhất của bảng. |
| **Chuỗi định dạng (Run)** | `{%r if dieu_kien %} ... {%r endif %}` | Dùng khi muốn áp dụng điều kiện cho một cụm từ mà vẫn giữ nguyên định dạng font/màu sắc của run chữ đó. |

---

### 3.2. Chuẩn Quy Ước Trường Ngày Tháng (`type: "date"`) Trong Custom Document

Để đảm bảo tính đồng bộ tuyệt đối giữa `metadata.json`, mẫu Word `.docx` và giao diện soạn thảo A4, **tất cả các trường ngày tháng (`type: "date"`) bắt buộc phải đặt tên bắt đầu bằng tiền tố `ngay_`**.

#### A. Khai báo trong `metadata.json`
Tên trường (`name`) luôn có tiền tố `ngay_`:
```json
{
  "name": "ngay_lap_bb",
  "label": "Ngày lập biên bản",
  "type": "date",
  "placeholder": "19/08/2026"
}
```
*(Ví dụ các tên hợp lệ: `ngay_lap_bb`, `ngay_lap`, `ngay_sinh`, `ngay_ket_thuc`, `ngay_tam_giu`...)*

#### B. Cú pháp duy nhất trong file Word (.docx)
Trong file Word, sử dụng bộ biến tương ứng theo hậu tố:
```text
Hồi {{ gio_lap_bb }} giờ {{ phut_lap_bb }} phút ngày {{ ngay_lap_bb }} tháng {{ thang_lap_bb }} năm {{ nam_lap_bb }} tại {{ noi_lap_bien_ban }}
```
*hoặc dạng không có giờ phút:*
```text
ngày {{ ngay_lap_bb }} tháng {{ thang_lap_bb }} năm {{ nam_lap_bb }}
```

#### C. Cơ chế tự động bóc tách ở Backend
Khi người dùng nhập giá trị ngày (ví dụ `19/08/2026` hoặc `14:30 19/08/2026`) vào trường `ngay_lap_bb`, Backend tự động phân tích và sinh sẵn các biến:
* `{{ ngay_lap_bb }}` $\rightarrow$ Ngày (ví dụ: `19`)
* `{{ thang_lap_bb }}` $\rightarrow$ Tháng (ví dụ: `08`)
* `{{ nam_lap_bb }}` $\rightarrow$ Năm (ví dụ: `2026`)
* `{{ gio_lap_bb }}` $\rightarrow$ Giờ (ví dụ: `14`, nếu có)
* `{{ phut_lap_bb }}` $\rightarrow$ Phút (ví dụ: `30`, nếu có)
* `{{ ngay_lap_bb_full }}` $\rightarrow$ Chuỗi ngày đầy đủ (`19/08/2026`)

#### D. Hiển thị trên Giao diện Soạn thảo A4
Trên giao diện tương tác, hệ thống tự động gộp cụm `ngày {{ ngay_lap_bb }} tháng {{ thang_lap_bb }} năm {{ nam_lap_bb }}` thành **1 ô chọn ngày `DateTimeInput` duy nhất**, hỗ trợ gõ phím trực tiếp (`19082026`) hoặc chọn từ lịch.

---

### 3.3. Hướng Dẫn Cấu Hình Mẫu Văn Bản Tùy Biến (Custom Documents)

#### A. Cấu trúc file `metadata.json` mẫu (`custom_templates/person/metadata.json` hoặc `custom_templates/case/metadata.json`)

```json
[
  {
    "file_name": "bien_ban_ghi_loi_khai.docx",
    "display_name": "Biên bản ghi lời khai",
    "fields": [
      {
        "name": "ngay_lap_bb",
        "label": "Ngày lập biên bản",
        "type": "input_date",
        "placeholder": "19/08/2026"
      },
      {
        "name": "noi_lap_bien_ban",
        "label": "Địa điểm lập biên bản",
        "type": "input_text",
        "placeholder": "Trụ sở Công an..."
      },
      {
        "name": "tu_cach_tham_gia_to_tung",
        "label": "Tư cách tham gia tố tụng",
        "type": "input_dropdown",
        "options": [
          {
            "label": "Bị can",
            "value": "Bị can",
            "linked_fields": {
              "dieu_blhs": "60",
              "quyen_nghia_vu": "Quy định tại Điều 60 BLTTHS"
            }
          },
          {
            "label": "Bị hại",
            "value": "Bị hại",
            "linked_fields": {
              "dieu_blhs": "62",
              "quyen_nghia_vu": "Quy định tại Điều 62 BLTTHS"
            }
          },
          {
            "label": "Người làm chứng",
            "value": "Người làm chứng",
            "linked_fields": {
              "dieu_blhs": "66",
              "quyen_nghia_vu": "Quy định tại Điều 66 BLTTHS"
            }
          }
        ]
      },
      {
        "name": "hoi_va_dap",
        "label": "Hỏi và Đáp",
        "type": "input_list",
        "item_schema": [
          { "name": "cau_hoi", "label": "Hỏi", "type": "input_textarea" },
          { "name": "cau_tra_loi", "label": "Đáp", "type": "input_textarea" }
        ]
      }
    ]
  }
]
```

#### B. Hệ thống chuẩn hóa các kiểu dữ liệu (`input_*`) trong `metadata.json`:

| Kiểu `type` chuẩn | Quy ước đặt tên | Mô tả & Cách hiển thị |
| :--- | :--- | :--- |
| **`input_text`** | Tự do (`ten_dieu_tra_vien`) | Ô nhập văn bản một dòng. Tự động co giãn theo độ rộng thực tế hoặc mở rộng hết lề phải nếu ở cuối dòng. |
| **`input_textarea`** | Tự do (`noi_dung_khai_bao`) | Khung nhập văn bản nhiều dòng (mặc định tối thiểu 6 dòng, tự động mở rộng theo nội dung). |
| **`input_dropdown`** | Tự do (`tu_cach_tham_gia`) | Menu chọn nhanh giá trị inline (font Times New Roman). Hỗ trợ thuộc tính `linked_fields` để tự động điền các trường liên quan khi người dùng chọn. |
| **`input_date`** | **Bắt buộc tiền tố `ngay_`** (`ngay_lap_bb`) | Ô chọn ngày tháng inline kèm lịch, tự động bóc tách thành `ngay_...`, `thang_...`, `nam_...`. |
| **`input_persons`** | Tự do | Lặp danh sách đối tượng vụ án trên trang A4 theo từng đối tượng. |
| **`input_list` / `input_table`** | Tự do (`hoi_va_dap`) | Danh sách / Bảng động nhiều dòng. Cấu hình các cột con bên trong qua `item_schema`. |

---

### 3.4. Hướng Dẫn Cấu Hình Gói Tài Liệu Hồ Sơ (Document Bundles)

Tính năng **Document Bundle** cho phép kết hợp và sinh trọn gói nhiều văn bản A4 (cả cấp Vụ án lẫn cấp Đối tượng) trong một lần thao tác, tự động đồng bộ các trường dữ liệu chung và tải về trọn bộ file nén `.ZIP`.

#### A. Cấu trúc file cấu hình `custom_templates/bundles.json`

```json
[
  {
    "id": "bundle_tiep_nhan_ban_dau",
    "name": "Bộ hồ sơ tiếp nhận giải quyết ban đầu",
    "description": "Gồm Biên bản tiếp nhận, Biên bản làm việc, Công văn và Biên bản lấy lời khai",
    "items": [
      {
        "template": "case/bien_ban_lam_viec.docx",
        "scope": "case",
        "preset_values": {
          "noi_dung_lam_viec": "Làm việc về nội dung tiếp nhận tố giác tội phạm"
        }
      },
      {
        "template": "case/cv_mang_may_tinh.docx",
        "scope": "case"
      },
      {
        "template": "person/bien_ban_ghi_loi_khai.docx",
        "scope": "person",
        "for_each": "isdt"
      },
      {
        "template": "person/ly_lich_bi_can.docx",
        "scope": "person",
        "for_each": "isdt"
      }
    ]
  }
]
```

#### B. Quy tắc cấu hình các mục (`items`) trong Bundle:
* **`scope: "case"`**: Sinh đúng 1 văn bản A4 ở cấp vụ án.
* **`scope: "person"`**: Tự động mở rộng thành các trang A4 tương ứng với từng người trong vụ án dựa theo tham số `for_each`:
  * `"for_each": "all"`: Mở rộng cho tất cả đối tượng trong vụ án.
  * `"for_each": "isdt"`: Chỉ mở rộng cho các đối tượng là Đối tượng chính (`isdt == true`).
  * `"for_each": "not_isdt"`: Chỉ mở rộng cho các cá nhân không phải đối tượng chính (`isdt == false`, ví dụ: người làm chứng, bị hại).
* **`preset_values`**: Giá trị mặc định điền sẵn cho các trường cụ thể trong văn bản đó.

---

### 3.5. Danh Mục Biến Hệ Thống Có Sẵn Trong Custom Document

Trong bất kỳ file Word của Custom Document nào, bạn có thể sử dụng trực tiếp các biến có sẵn sau mà không cần khai báo lại trong `metadata.json`:

#### A. Thông tin Đối tượng cá nhân chính (`person.*`) *(Dành cho `custom_templates/person/`)*

* **Cơ bản**: `{{ person.ho_ten }}`, `{{ person.gioi_tinh }}`, `{{ person.isdt }}`
* **Ngày sinh**: `{{ person.ngay_sinh }}`, `{{ person.thang_sinh }}`, `{{ person.nam_sinh }}`
* **Nơi sinh & Quê quán**: `{{ person.noi_sinh }}`, `{{ person.que_quan }}`, `{{ person.quoc_tich }}`, `{{ person.dan_toc }}`, `{{ person.ton_giao }}`
* **CCCD / CMND**: `{{ person.cccd }}`, `{{ person.ngay_cccd }}`, `{{ person.noi_cap_cccd }}`
* **Cư trú**: `{{ person.noi_thuong_tru }}`, `{{ person.noi_tam_tru }}`, `{{ person.noi_o_hien_tai }}`
* **Học vấn & Công tác**: `{{ person.hoc_van }}`, `{{ person.nghe_nghiep }}`, `{{ person.noi_lam_viec }}`, `{{ person.chuc_vu }}`, `{{ person.doan_the }}`
* **Ảnh chân dung 3x4**: `{{ person.image }}` (Hệ thống tự động chèn ảnh nếu có)
* **Tiền án tiền sự & Gia đình**: `{{ person.tien_an_tien_su }}`, `{{ person.quan_he_gia_dinh }}`

#### B. Thông tin Vụ án (`case.*`) *(Dùng cho cả `case/` và `person/`)*

* `{{ case.id }}`: Mã ID vụ án
* `{{ case.ten_tom_tat }}`: Ký hiệu / Tên tóm tắt vụ việc
* `{{ case.ten_day_du }}`: Tên đầy đủ / Tóm tắt nội dung vụ việc
* `{{ case.created_at }}`: Ngày lập hồ sơ
* `{{ case.con_nguoi_list }}`: Danh sách toàn bộ đối tượng trong vụ án (Cú pháp chuẩn duy nhất).

#### C. Cú pháp vòng lặp Danh sách đối tượng vụ án & Lọc Đối tượng trong Word

> [!IMPORTANT]
> **Quy tắc chống khoảng cách / dòng trống thừa (`{%p for %}`)**:
> Khi viết vòng lặp cho các đoạn văn bản (như danh sách bị can trong vụ án, danh sách quan hệ gia đình, tiền án tiền sự, hỏi đáp...), **BẮT BUỘC** phải dùng cú pháp thẻ đoạn văn: `{%p for ... %}` và `{%p endfor %}`.
> Tiền tố `p` giúp `docxtpl` tự động xóa bỏ hoàn toàn dòng chứa thẻ mở và thẻ đóng sau khi render, giúp văn bản liền mạch tuyệt đối và không bị sinh ra dòng trống thừa.

* **1. Lặp toàn bộ đối tượng trong vụ án (`case.con_nguoi_list`)**:
```jinja2
{%p for p in case.con_nguoi_list %}
{{ loop.index }}. Họ và tên: {{ p.ho_ten }}	Giới tính: {{ p.gioi_tinh }}
Sinh ngày {{ p.ngay_sinh }} tháng {{ p.thang_sinh }} năm {{ p.nam_sinh }}  tại: {{ p.noi_sinh }}
Quốc tịch: {{ p.quoc_tich }};	Dân tộc: {{ p.dan_toc }};	Tôn giáo: {{ p.ton_giao}}
Thẻ CCCD: {{ p.cccd }}
Nơi thường trú: {{ p.noi_thuong_tru }}
Nơi ở hiện tại: {{ p.noi_o_hien_tai }}
{%p endfor %}
```

* **2. Lọc chỉ lấy Đối tượng chính (`isdt == true`) trong Word**:
```jinja2
{%p for p in case.con_nguoi_list if p.isdt %}
{{ loop.index }}. Bị can: {{ p.ho_ten }} - CCCD: {{ p.cccd }}
{%p endfor %}
```

* **3. Lọc chỉ lấy Người liên quan / Không phải đối tượng chính (`isdt == false`) trong Word**:
```jinja2
{%p for p in case.con_nguoi_list if not p.isdt %}
{{ loop.index }}. Người làm chứng / Bị hại: {{ p.ho_ten }} - CCCD: {{ p.cccd }}
{%p endfor %}
```

* **4. Lặp danh sách động / Bảng hỏi đáp (`hoi_va_dap`)**:
```jinja2
{%p for item in hoi_va_dap %}
Hỏi: {{ item.cau_hoi }}
Đáp: {{ item.cau_tra_loi }}
{%p endfor %}
```

* **5. Vòng lặp bảng danh sách đối tượng dạng Table trong Word (Cú pháp `{%tr for %}`)**:

| STT | Họ và tên | Ngày sinh | Số CCCD | Nơi ở hiện nay |
| :---: | :--- | :---: | :---: | :--- |
| `{%tr for p in case.con_nguoi_list if p.isdt %}` | | | | |
| `{{ loop.index }}` | `{{ p.ho_ten }}` | `{{ p.ngay_sinh }}/{{ p.thang_sinh }}/{{ p.nam_sinh }}` | `{{ p.cccd }}` | `{{ p.noi_o_hien_tai }}` |
| `{%tr endfor %}` | | | | |

#### D. Các biến hệ thống tự động:
* `{{ ngay_hien_tai }}`, `{{ thang_hien_tai }}`, `{{ nam_hien_tai }}`: Ngày, tháng, năm tại thời điểm kết xuất văn bản.
* `{{ doc_title }}`: Tiêu đề bản ghi văn bản do người dùng đặt khi lưu.

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
    - Kiểm tra log container: `docker compose logs -f`
    - Đảm bảo file Word template không bị khóa hoặc đặt sai đường dẫn trong `templates/person/` hoặc `templates/case/`.
* **Cập nhật giao diện Flutter không hiển thị trên Web:**
    - Xóa cache trình duyệt (nhấn `Ctrl + Shift + R` hoặc `Ctrl + F5`) để tải lại toàn bộ file tĩnh JavaScript/Wasm mới nhất.
* **Mẫu Word bảng không lặp hàng:**
    - Đảm bảo hàng mở vòng lặp có chứa `{%tr for ... %}` và hàng đóng vòng lặp chứa `{%tr endfor %}`. Không đặt thẻ lặp ngoài bảng.