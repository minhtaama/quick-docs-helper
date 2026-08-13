FROM python:3.10-slim

WORKDIR /app

# Cài đặt các thư viện phụ thuộc
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Sao chép mã nguồn vào container
COPY . .

# Tạo thư mục đầu ra và thư mục mẫu nếu chưa có
RUN mkdir -p temp_outputs templates static

EXPOSE 8000

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
