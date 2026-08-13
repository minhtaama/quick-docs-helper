import sys
from src.config import load_config

def main() -> int:
    """Hàm chạy chính của dự án Quick Docs Helper"""
    if hasattr(sys.stdout, "reconfigure"):
        try:
            sys.stdout.reconfigure(encoding="utf-8")
        except Exception:
            pass

    config = load_config()
    print(f"Chào mừng bạn đến với {config.app_name}! (Môi trường: {config.app_env})")
    print("Hệ thống đã sẵn sàng hỗ trợ bạn xử lý tài liệu.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
