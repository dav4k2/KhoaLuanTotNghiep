# models/notification.py

import uuid
from sqlalchemy import Column, String, Text, DateTime, Boolean, Integer, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from database import Base


def _uuid() -> str:
    return str(uuid.uuid4())


class DeviceToken(Base):
    """
    Lưu FCM token của từng thiết bị.
    Một user có thể đăng nhập nhiều thiết bị → nhiều token.
    """
    __tablename__ = "device_tokens"

    id         = Column(UUID(as_uuid=False), primary_key=True, default=_uuid)
    user_id    = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    fcm_token  = Column(String(512), nullable=False, unique=True)
    platform   = Column(String(20), nullable=True)   # "android" | "ios"
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="device_tokens")


class Notification(Base):
    """
    Lịch sử thông báo đã gửi — để hiển thị màn hình notification history.
    """
    __tablename__ = "notifications"

    id            = Column(UUID(as_uuid=False), primary_key=True, default=_uuid)
    user_id       = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    # Loại thông báo: "ai_result" | "community_comment" | "community_like"
    # | "disease_alert" | "expert_verified" | "system"
    notif_type    = Column(String(50), nullable=False)

    title         = Column(String(255), nullable=False)
    body          = Column(Text, nullable=False)

    # Dữ liệu phụ để điều hướng khi click (JSON string)
    # Ví dụ: '{"post_id": "abc123"}' hoặc '{"scan_id": "xyz"}'
    data          = Column(Text, nullable=True)

    is_read       = Column(Boolean, default=False, nullable=False)
    created_at    = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="notifications")