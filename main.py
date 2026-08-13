import sys
import os
import shutil
import subprocess
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from src.config import load_config
from src.api.document_router import router as document_router

if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

def sync_flutter_web():
    """Tự động kiểm tra và đồng bộ bản build của Flutter Web sang thư mục static"""
    base_dir = os.path.dirname(__file__)
    flutter_dir = os.path.join(base_dir, "flutter")
    if not os.path.exists(flutter_dir):
        flutter_dir = os.path.join(base_dir, "flutter_app")

    flutter_build_dir = os.path.join(flutter_dir, "build", "web")
    static_dir = os.path.join(base_dir, "static")

    if os.path.exists(flutter_dir):
        if not os.path.exists(flutter_build_dir):
            print("Đang tự động biên dịch Flutter Web...")
            subprocess.run(["flutter", "build", "web"], cwd=flutter_dir, shell=True)

        if os.path.exists(flutter_build_dir):
            os.makedirs(static_dir, exist_ok=True)
            shutil.copytree(flutter_build_dir, static_dir, dirs_exist_ok=True)
            print("Đã tự động đồng bộ Flutter Web vào thư mục static.")

# Tự động đồng bộ Flutter Web khi khởi chạy main.py
sync_flutter_web()

config = load_config()
app = FastAPI(title=config.app_name)

# Bật CORS cho Flutter Web và các client
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

static_dir = os.path.join(os.path.dirname(__file__), "static")
os.makedirs(static_dir, exist_ok=True)

app.mount("/static", StaticFiles(directory=static_dir), name="static")

app.include_router(document_router)

@app.get("/", response_class=HTMLResponse)
async def read_index():
    index_path = os.path.join(static_dir, "index.html")
    if os.path.exists(index_path):
        with open(index_path, "r", encoding="utf-8") as f:
            return f.read()
    return """<!DOCTYPE html>
<html>
<head><meta charset='utf-8'><title>Quick Docs Helper</title></head>
<body>
<h1>Quick Docs Helper API đang hoạt động!</h1>
<p>Vui lòng mở ứng dụng Flutter Web để điền thông tin và xuất file Word.</p>
</body>
</html>"""
