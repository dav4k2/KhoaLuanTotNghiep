# services/cloudinary_service.py
# Đặt file này vào:  services/cloudinary_service.py  (cùng cấp với auth_service.py)

import cloudinary
import cloudinary.uploader
from config import settings        # ← import flat, không có my_app.

# Cấu hình 1 lần khi module được import
cloudinary.config(
    cloud_name = settings.cloudinary_cloud_name,
    api_key    = settings.cloudinary_api_key,
    api_secret = settings.cloudinary_api_secret,
    secure     = True,
)

_ALLOWED = {"jpg", "jpeg", "png", "webp", "heic"}
_MAX_MB  = 10


async def upload_image(file_bytes: bytes, filename: str,
                       folder: str = "community/posts") -> dict:
    """
    Upload ảnh lên Cloudinary.
    Trả về: { url, public_id, width, height }
    Raise:   ValueError nếu file không hợp lệ.
    """
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else ""
    if ext not in _ALLOWED:
        raise ValueError(f"Định dạng không hỗ trợ: .{ext}")
    if len(file_bytes) > _MAX_MB * 1024 * 1024:
        raise ValueError(f"Ảnh quá lớn, tối đa {_MAX_MB} MB")

    result = cloudinary.uploader.upload(
        file_bytes,
        folder        = folder,
        resource_type = "image",
        transformation = [
            {"quality": "auto", "fetch_format": "auto"},
            {"width": 1200, "crop": "limit"},
        ],
    )
    return {
        "url":       result["secure_url"],
        "public_id": result["public_id"],
        "width":     result.get("width"),
        "height":    result.get("height"),
    }


async def delete_image(public_id: str) -> bool:
    result = cloudinary.uploader.destroy(public_id)
    return result.get("result") == "ok"