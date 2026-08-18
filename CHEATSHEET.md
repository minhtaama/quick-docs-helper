# 📚 SỔ TAY TỔNG HỢP KIẾN THỨC: FASTAPI & JINJA2

Tài liệu này tổng hợp toàn bộ các khái niệm cốt lõi về **Jinja2**, cách phân biệt **Path Parameter** vs **Query Parameter** trong **FastAPI**, và **Các loại Response trả về**.

---

## 1. JINJA2 LÀ GÌ?

### 1.1. Khái niệm
* **Jinja2** là một **Template Engine** (bộ máy xử lý khuôn mẫu) chuẩn cho Python.
* Nhiệm vụ chính: Tách biệt mã nguồn logic Backend (Python) và giao diện Frontend (HTML, CSS, JS, hoặc file Word Docx). Cho phép điền dữ liệu động từ code Python vào các file tĩnh.

### 1.2. Cú pháp cơ bản của Jinja2
* `{{ bien }}`: **In giá trị biến** ra giao diện (Ví dụ: `{{ pdf_data_url }}`).
* `{% if dieu_kien %} ... {% else %} ... {% endif %}`: **Cấu trúc rẽ nhánh điều kiện**.
* `{% for item in danh_sach %} ... {% endfor %}`: **Vòng lặp danh sách**.
* `{# ghi chu #}`: **Comment / Ghi chú** (sẽ không bị hiển thị ra ngoài kết quả).

### 1.3. Cách cấu hình Jinja2 trong FastAPI
```python
import os
from fastapi import FastAPI, Request
from fastapi.templating import Jinja2Templates

app = FastAPI()

# 1. Chỉ định thư mục chứa các file HTML template
TEMPLATES_DIR = os.path.join(os.path.dirname(__file__), "templates")
templates = Jinja2Templates(directory=TEMPLATES_DIR)

# 2. Render template trong API endpoint
@app.get("/viewer")
async def show_viewer(request: Request, file_name: str):
    return templates.TemplateResponse(
        request=request,                    # Bắt buộc (FastAPI/Starlette mới)
        name="preview_viewer.html",         # Tên file template trong thư mục templates
        context={                           # Dữ liệu truyền sang HTML
            "pdf_data_url": f"/data/{file_name}",
            "force": False
        }
    )
```

---

## 2. PHÂN BIỆT PATH PARAMETERS VÀ QUERY PARAMETERS TRONG FASTAPI

FastAPI phân loại các tham số dựa trên **Decorator `@router.get(...)`** và **kiểu khai báo trong hàm**.

```
URL Mẫu:
http://127.0.0.1:8000/api/v1/generate/person/CASE_01/PER_02/pdf-data?template_file=mau.docx&force=true
                      |___________________________________________| |_________________________________|
                                 PATH PARAMETERS                                QUERY PARAMETERS
```

---

### 2.1. Path Parameters (Tham số trên đường dẫn)
* **Khái niệm**: Là các giá trị nằm trực tiếp trong cấu trúc đường dẫn URL, dùng để định danh tài nguyên cụ thể (ID vụ việc, ID người dùng...).
* **Cách nhận diện**: Được đặt trong cặp dấu ngoặc nhọn `{...}` ở decorator.
* **Ví dụ Code**:
```python
from fastapi import APIRouter

router = APIRouter()

# {case_id} và {person_id} nằm trong đường dẫn
@router.get("/person/{case_id}/{person_id}/info")
async def get_person_info(case_id: str, person_id: str):
    # case_id sẽ nhận "CASE_01"
    # person_id sẽ nhận "PER_02"
    return {"case": case_id, "person": person_id}
```

---

### 2.2. Query Parameters (Tham số truy vấn sau dấu `?` và `&`)
* **Khái niệm**: Là các tham số nằm sau dấu hỏi chấm `?` trên URL, dùng để lọc, phân trang, cấu hình tùy chọn (tên mẫu, cờ `force`, từ khóa tìm kiếm...). Các tham số nối với nhau bằng dấu `&`.
* **Cách nhận diện**: Các tham số khai báo trong hàm **KHÔNG** xuất hiện trong `{...}` của decorator, hoặc được khai báo với `Query(...)`.
* **Ví dụ Code**:
```python
from typing import Optional
from fastapi import APIRouter, Query

router = APIRouter()

@router.get("/person/search")
async def search_person(
    keyword: str = Query(..., description="Từ khóa bắt buộc"),
    page: int = Query(1, description="Trang hiện tại (mặc định 1)"),
    force: bool = Query(False, description="Cờ boolean (mặc định False)"),
    timestamp: Optional[str] = Query(None, description="Tùy chọn không bắt buộc")
):
    # Khi gọi: /person/search?keyword=Nguyen&page=2&force=true
    # FastAPI tự động ép kiểu: page thành int(2), force thành bool(True)
    return {"keyword": keyword, "page": page, "force": force}
```

---

### 2.3. Bảng so sánh tổng hợp

| Đặc điểm | Path Parameters | Query Parameters |
| :--- | :--- | :--- |
| **Vị trí trên URL** | Nằm trong thân đường dẫn: `/users/123` | Nằm sau dấu `?`: `/users?page=1&limit=10` |
| **Mục đích chính** | Định danh tài nguyên bắt buộc | Lọc, tùy chọn, cờ bật/tắt, phân trang |
| **Khai báo ở Decorator** | Bắt buộc nằm trong `{ten_bien}` | **Không** nằm trong `{...}` của decorator |
| **Khai báo ở Hàm** | `ten_bien: str` | `ten_bien: str = Query(gia_tri_mac_dinh)` |
| **Bắt buộc / Tùy chọn** | Thường là bắt buộc | Có thể tùy chọn và có giá trị mặc định |

---

## 3. CÁC LOẠI RESPONSE PHỔ BIẾN TRONG FASTAPI

FastAPI cung cấp nhiều kiểu phản hồi (Response Class) tùy theo loại dữ liệu bạn muốn trả về cho Client/Trình duyệt:

### 3.1. Trả về JSON (Mặc định)
Dùng khi viết API cho ứng dụng Mobile, Flutter hoặc Frontend Javascript gọi lấy dữ liệu.
```python
@router.get("/data")
async def get_data():
    # FastAPI tự động chuyển Dict/List/Pydantic Model thành JSONResponse
    return {"status": "success", "data": [1, 2, 3]}
```

---

### 3.2. `TemplateResponse` (Trả về giao diện HTML qua Jinja2)
Dùng khi muốn trả về trọn vẹn một trang web HTML được render từ template.
```python
from fastapi.templating import Jinja2Templates

templates = Jinja2Templates(directory="src/templates")

@router.get("/preview")
async def preview_page(request: Request, pdf_url: str):
    return templates.TemplateResponse(
        request=request,
        name="preview_viewer.html",
        context={"pdf_data_url": pdf_url}
    )
```

---

### 3.3. `FileResponse` (Trả về file từ ổ cứng)
Dùng khi bạn đã có sẵn file trên đĩa cứng (PDF, DOCX, Hình ảnh...) và muốn người dùng tải hoặc xem trực tiếp.
```python
from fastapi.responses import FileResponse

@router.get("/download-pdf")
async def get_file_from_disk():
    file_path = "data/cache/document.pdf"
    return FileResponse(
        path=file_path,
        media_type="application/pdf",          # Hoặc application/octet-stream
        filename="tailieu.pdf",                # Tên file khi tải về
        headers={"Content-Disposition": "inline; filename=tailieu.pdf"} # inline: xem trên web, attachment: tự tải về
    )
```

---

### 3.4. `StreamingResponse` (Trả về luồng dữ liệu Bytes từ bộ nhớ RAM)
Dùng khi dữ liệu được tạo ra trong RAM (dạng `io.BytesIO`) và không cần lưu xuống ổ cứng trước khi gửi.
```python
import io
from fastapi.responses import StreamingResponse

@router.get("/download-docx")
async def stream_docx():
    # Giả sử buffer là một luồng BytesIO chứa nội dung file Word
    buffer = io.BytesIO(b"Noi dung file...")
    buffer.seek(0)
    
    return StreamingResponse(
        buffer,
        media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        headers={"Content-Disposition": "attachment; filename=output.docx"}
    )
```

---

### 3.5. `HTMLResponse` (Trả về chuỗi HTML thô)
Dùng khi muốn trả về chuỗi HTML ngắn mà không cần tạo file template.
```python
from fastapi.responses import HTMLResponse

@router.get("/hello-html")
async def hello_html():
    return HTMLResponse(content="<h1>Xin chào các bạn</h1>")
```

---

### 3.6. `Response` (Dữ liệu thô / Raw Bytes)
Dùng khi muốn kiểm soát hoàn toàn mã trạng thái, Header và dữ liệu byte nhị phân.
```python
from fastapi.responses import Response

@router.get("/raw-image")
async def get_raw_image():
    image_bytes = b"..."
    return Response(
        content=image_bytes,
        media_type="image/png",
        status_code=200
    )
```
