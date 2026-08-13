import sys
import os
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from src.config import load_config
from src.api.document_router import router as document_router

if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

config = load_config()
app = FastAPI(title=config.app_name)

static_dir = os.path.join(os.path.dirname(__file__), "..", "static")
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
<p>Vui lòng tạo file static/index.html để xem giao diện Web Form.</p>
</body>
</html>"""
