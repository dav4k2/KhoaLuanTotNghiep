# Dockerfile
# Đặt file này ở thư mục gốc của backend (cùng cấp với main.py)

# ── Stage 1: Base image ───────────────────────────────────────
# Dùng Python 3.11 slim để image nhỏ gọn hơn
FROM python:3.11-slim

# ── Thiết lập môi trường ──────────────────────────────────────
# Không tạo file .pyc (bytecode) → giảm dung lượng
ENV PYTHONDONTWRITEBYTECODE=1
# Không buffer stdout/stderr → log hiển thị ngay lập tức
ENV PYTHONUNBUFFERED=1

# ── Thư mục làm việc trong container ─────────────────────────
WORKDIR /app

# ── Cài dependencies ──────────────────────────────────────────
# Copy requirements trước (tận dụng Docker layer cache)
# Nếu requirements.txt không thay đổi → Docker dùng cache, build nhanh hơn
COPY my_app/requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# ── Copy toàn bộ source code vào container ────────────────────
COPY my_app/. .

# ── Mở port 8000 ─────────────────────────────────────────────
EXPOSE 8000

# ── Lệnh khởi động server ─────────────────────────────────────
# --host 0.0.0.0 : lắng nghe từ mọi IP (không chỉ localhost)
# --port 8000    : chạy trên port 8000
# --reload       : CHỈ dùng khi development, xoá khi production
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]