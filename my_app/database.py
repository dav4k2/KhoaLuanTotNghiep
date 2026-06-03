# backend/database.py

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

from config import settings

# Tạo engine kết nối tới PostgreSQL
engine = create_engine(
    settings.DATABASE_URL,
    # Pool connection - tái sử dụng kết nối thay vì tạo mới mỗi lần
    pool_pre_ping=True,   # Kiểm tra kết nối còn sống trước khi dùng
    pool_size=10,         # Số kết nối tối đa trong pool
    max_overflow=20,      # Số kết nối tạm thêm khi pool đầy
)

# SessionLocal: Factory tạo ra các database session
SessionLocal = sessionmaker(
    autocommit=False,  # Không tự động commit, phải gọi db.commit() thủ công
    autoflush=False,   # Không tự flush trước mỗi query
    bind=engine,
)

# Base: Class cha cho tất cả SQLAlchemy models
Base = declarative_base()


# Dependency injection cho FastAPI
# Dùng yield để đảm bảo session luôn được đóng dù có lỗi hay không
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
