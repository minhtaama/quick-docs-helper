import sys
import os
import shutil
import subprocess
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from src.config import Config
from src.api.case_router import router as case_router
from src.api.custom_doc_router import router as custom_doc_router
from src.api.generate_router import router as generate_router

if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

def sync_flutter_web():
    """Tự động kiểm tra và đồng bộ bản build của Flutter Web sang thư mục static nếu môi trường có Flutter SDK"""
    base_dir = os.path.dirname(__file__)
    flutter_dir = os.path.join(base_dir, "flutter")
    flutter_build_dir = os.path.join(flutter_dir, "build", "web")
    static_dir = os.path.join(base_dir, "static")

    if os.path.exists(flutter_dir) and shutil.which("flutter"):
        try:
            print("Đang tự động biên dịch Flutter Web...")
            subprocess.run(["flutter", "build", "web"], cwd=flutter_dir, shell=True)
            if os.path.exists(flutter_build_dir):
                os.makedirs(static_dir, exist_ok=True)
                shutil.copytree(flutter_build_dir, static_dir, dirs_exist_ok=True)
                print("Đã tự động đồng bộ Flutter Web vào thư mục static.")
        except Exception as e:
            print(f"Bỏ qua tự động build Flutter: {e}")

# Tự động đồng bộ Flutter Web khi khởi chạy main.py
sync_flutter_web()

app = FastAPI(title=Config.app_name)

# Bật CORS cho Flutter Web và các client
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["Content-Disposition"],
)

# 1. Đăng ký các API Routers
app.include_router(case_router)
app.include_router(custom_doc_router)
app.include_router(generate_router)

# 2. Đăng ký StaticFiles tại gốc "/" với html=True để phục vụ trọn bộ Flutter Web
static_dir = os.path.join(os.path.dirname(__file__), "static")
os.makedirs(static_dir, exist_ok=True)

app.mount("/", StaticFiles(directory=static_dir, html=True), name="static")
