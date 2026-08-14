# Quick Docs Helper

Ứng dụng hỗ trợ xử lý và quản lý tài liệu nhanh chóng với Backend Python (FastAPI) và Frontend Flutter Web.

---

## 1. Yêu cầu tiên quyết (Prerequisites)

Trước khi bắt đầu, hãy đảm bảo máy tính của bạn đã cài đặt các công cụ sau:

- **Git**: Dùng để tải mã nguồn dự án.
- **Python** (phiên bản 3.10 trở lên): Dùng để chạy Backend FastAPI.
- **Flutter SDK** (phiên bản 3.x, khuyên dùng Dart SDK >= 3.9.0): Dùng cho Frontend.
- Trình duyệt web (Google Chrome, Edge,...) hoặc thiết bị giả lập.

---

## 2. Hướng dẫn Tải dự án (Git Clone)

Mở Terminal / PowerShell và chạy lệnh sau để tải dự án về máy:

```bash
git clone <URL_KHO_LUU_TRU_CUA_BAN>
cd quick-docs-helper
```

---

## 3. Cài đặt Phụ thuộc & Thư viện (Dependencies)

Dự án gồm 2 phần chính: Backend (Python) và Frontend (Flutter).

### a. Cài đặt Backend (Python FastAPI)

1. Tạo và kích hoạt môi trường ảo (Virtual Environment):
   - Trên Windows:
     ```bash
     python -m venv venv
     .\venv\Scripts\activate
     ```
   - Trên macOS / Linux:
     ```bash
     python3 -m venv venv
     source venv/bin/activate
     ```

2. Cài đặt các gói thư viện Python từ `requirements.txt`:
   ```bash
   pip install -r requirements.txt
   ```

### b. Cài đặt Frontend (Flutter)

1. Di chuyển vào thư mục ứng dụng Flutter:
   ```bash
   cd flutter
   ```

2. Tải các package phụ thuộc của Flutter:
   ```bash
   flutter pub get
   ```
   *(Lưu ý: Nếu gặp lỗi xung đột phiên bản Dart SDK trong file `pubspec.yaml`, bạn có thể điều chỉnh giá trị `sdk: ^3.9.0` cho phù hợp với bản Dart SDK trên máy).*

3. Trở lại thư mục gốc dự án:
   ```bash
   cd ..
   ```

---

## 4. Hướng dẫn Khởi chạy Dự án (Running the Project)

### Cách 1: Khởi chạy Backend FastAPI (Khuyên dùng khi phát triển)

Chạy trực tiếp Backend Python với Uvicorn:

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Sau khi khởi chạy thành công:
- Trang chủ ứng dụng / API: `http://localhost:8000`
- Tài liệu API tương tác (Swagger UI): `http://localhost:8000/docs`

### Cách 2: Khởi chạy Frontend Flutter Web độc lập

Nếu bạn muốn chạy riêng giao diện Flutter Web trong quá trình phát triển UI:

```bash
cd flutter
flutter run -d chrome
```

### Cách 3: Sử dụng Docker & Docker Compose

Nếu bạn đã cài đặt Docker trên máy:

```bash
docker-compose up --build
```

---

## 5. Cấu trúc Dự án (Project Structure)

```
quick-docs-helper/
├── main.py              # File khởi chạy chính của ứng dụng FastAPI
├── requirements.txt     # Danh sách thư viện Python phụ thuộc
├── Dockerfile           # Đóng gói ứng dụng với Docker
├── docker-compose.yml   # Cấu hình khởi chạy Docker service
├── flutter/             # Mã nguồn giao diện Flutter
│   ├── lib/             # Mã nguồn Dart/Flutter
│   └── pubspec.yaml     # File cấu hình phụ thuộc Flutter
├── src/                 # Mã nguồn backend Python (routing, config, api)
└── templates/           # Thư mục chứa giao diện / file mẫu
```

---

## 6. Xử lý Lỗi Thường Gặp (Troubleshooting)

- **Lỗi SDK version solving failed trong Flutter:**
  Mở file `flutter/pubspec.yaml`, tìm dòng `environment:` -> `sdk:` và đổi phiên bản thành `^3.9.0` để khớp với Dart SDK local.

- **Lỗi thiếu thư viện Python:**
  Đảm bảo bạn đã kích hoạt môi trường ảo `venv` trước khi chạy `pip install -r requirements.txt`.
