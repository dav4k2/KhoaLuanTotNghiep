# schemas/notification_schema.py

from __future__ import annotations
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


# ── DeviceToken ───────────────────────────────────────────────


class DeviceTokenRegister(BaseModel):
    """Flutter gửi lên khi app khởi động / FCM token refresh."""
    fcm_token: str = Field(..., min_length=10)
    platform: Optional[str] = Field(None, pattern="^(android|ios)$")


class DeviceTokenResponse(BaseModel):
    id: str
    fcm_token: str
    platform: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


# ── Notification ──────────────────────────────────────────────


class NotificationResponse(BaseModel):
    id: str
    notif_type: str
    title: str
    body: str
    data: Optional[str]       # JSON string, Flutter tự parse
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True


class NotificationListResponse(BaseModel):
    total: int
    unread_count: int
    items: list[NotificationResponse]


class MarkReadRequest(BaseModel):
    """Đánh dấu một hoặc nhiều thông báo đã đọc."""
    notification_ids: list[str]