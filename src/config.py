import os
from dataclasses import dataclass

@dataclass
class Config:
    """Cấu hình chung cho ứng dụng Quick Docs Helper"""
    app_name: str = os.getenv("APP_NAME", "QuickDocsHelper")
    app_env: str = os.getenv("APP_ENV", "development")
    log_level: str = os.getenv("LOG_LEVEL", "INFO")

def load_config() -> Config:
    """Hàm tải cấu hình ứng dụng"""
    return Config()
