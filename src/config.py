import os

# Đường dẫn tuyệt đối tới thư mục gốc dự án (quick-docs-helper)
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEMPLATES_DIR = os.path.join(BASE_DIR, "templates")
TEMP_OUTPUTS_DIR = os.path.join(BASE_DIR, "temp_outputs")

DATA_DIR = os.path.join(BASE_DIR, "data")
CASES_DIR = os.path.join(DATA_DIR, "cases")

class Config:
    """
    Cấu hình chung cho ứng dụng Quick Docs Helper
    """

    app_name: str = os.getenv("APP_NAME", "QuickDocsHelper")
    app_env: str = os.getenv("APP_ENV", "development")
    log_level: str = os.getenv("LOG_LEVEL", "INFO")
