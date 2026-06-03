# config.py

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # ── Database ──────────────────────────────────────────────
    DATABASE_URL: str = "postgresql://postgres:181004@localhost:5432/khoa_luan_db"

    # ── JWT ───────────────────────────────────────────────────
    SECRET_KEY: str = "970faa09e32c07af0833a5c1a30a2c24e8bb6dc80dfc49aa285d7cdfce02fbf4"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 1 ngày

    # ── App ───────────────────────────────────────────────────
    APP_NAME: str = "Khoa Luan Tot Nghiep API"
    DEBUG: bool = True

    # ── Email / Gmail SMTP ────────────────────────────────────
    MAIL_USERNAME: str = "hoangthanhphongsn04@gmail.com"
    MAIL_PASSWORD: str = "hsrd wpue qkmy vcet"
    MAIL_FROM: str = "hoangthanhphongsn04@gmail.com"

    # ── Cloudinary ────────────────────────────────────────────
    cloudinary_cloud_name: str = ""
    cloudinary_api_key: str = ""
    cloudinary_api_secret: str = ""
    
    # ── Firebase Cloud Messaging v1 ───────────────────────────
    # Đường dẫn tới file JSON Service Account tải từ Firebase Console
    FIREBASE_SERVICE_ACCOUNT_PATH: str = "firebase_service_account.json"
    # Project ID lấy từ Firebase Console → Project Settings → General
    FIREBASE_PROJECT_ID: str = "kltn-bab0f"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()