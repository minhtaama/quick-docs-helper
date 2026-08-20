FROM python:3.10-slim

WORKDIR /app

# Cài đặt LibreOffice và font chữ Unicode tiếng Việt phục vụ xuất/xem trước PDF trên Linux
RUN apt-get update && apt-get install -y --no-install-recommends \
    libreoffice-writer \
    libreoffice-calc \
    fonts-liberation \
    fonts-dejavu-core \
    fonts-noto-core \
    fonts-noto-cjk \
    && rm -rf /var/lib/apt/lists/*

# Cài đặt các thư viện Python phụ thuộc
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Sao chép mã nguồn vào container
COPY . .

# Tạo các thư mục lưu trữ và cache
RUN mkdir -p data/cases data/cache templates static

EXPOSE 8000

ENV PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=utf-8

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
