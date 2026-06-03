# routers/notification_router.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from database import get_db
from dependencies.auth_dependency import get_current_user
from models.user import User
import repositories.notification_repository as notif_repo
from schemas.notification_schema import (
    DeviceTokenRegister,
    DeviceTokenResponse,
    NotificationListResponse,
    NotificationResponse,
    MarkReadRequest,
)

router = APIRouter(prefix="/notifications", tags=["Notifications"])


# ── Device token ──────────────────────────────────────────────

@router.post(
    "/device-token",
    response_model=DeviceTokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Đăng ký / cập nhật FCM token",
)
async def register_device_token(
    body: DeviceTokenRegister,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Flutter gọi endpoint này ngay khi app khởi động
    hoặc khi FCM cấp token mới (onTokenRefresh).
    """
    token = notif_repo.upsert_device_token(
        db,
        user_id=current_user.id,
        fcm_token=body.fcm_token,
        platform=body.platform,
    )
    return token


@router.delete(
    "/device-token",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Xoá FCM token khi logout",
)
async def remove_device_token(
    body: DeviceTokenRegister,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    deleted = notif_repo.delete_token(db, body.fcm_token, current_user.id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Token không tồn tại")


# ── Notification history ──────────────────────────────────────

@router.get(
    "/",
    response_model=NotificationListResponse,
    summary="Lấy danh sách thông báo của user",
)
async def get_notifications(
    skip: int = 0,
    limit: int = 30,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    items, total, unread_count = notif_repo.get_notifications_by_user(
        db, current_user.id, skip=skip, limit=limit
    )
    return NotificationListResponse(
        total=total,
        unread_count=unread_count,
        items=items,
    )


@router.patch(
    "/mark-read",
    summary="Đánh dấu một số thông báo đã đọc",
)
async def mark_read(
    body: MarkReadRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    updated = notif_repo.mark_notifications_read(db, current_user.id, body.notification_ids)
    return {"updated": updated}


@router.patch(
    "/mark-all-read",
    summary="Đánh dấu tất cả thông báo đã đọc",
)
async def mark_all_read(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    updated = notif_repo.mark_all_read(db, current_user.id)
    return {"updated": updated}