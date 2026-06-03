# repositories/notification_repository.py

from sqlalchemy.orm import Session
from models.notification import DeviceToken, Notification


# ── DeviceToken ───────────────────────────────────────────────

def upsert_device_token(db: Session, user_id: int, fcm_token: str, platform: str | None) -> DeviceToken:
    """
    Nếu token đã tồn tại → cập nhật user_id (phòng trường hợp đổi tài khoản trên cùng thiết bị).
    Nếu chưa → tạo mới.
    """
    existing = db.query(DeviceToken).filter(DeviceToken.fcm_token == fcm_token).first()
    if existing:
        existing.user_id = user_id
        existing.platform = platform
        db.commit()
        db.refresh(existing)
        return existing

    token = DeviceToken(user_id=user_id, fcm_token=fcm_token, platform=platform)
    db.add(token)
    db.commit()
    db.refresh(token)
    return token


def get_tokens_by_user(db: Session, user_id: int) -> list[DeviceToken]:
    """Lấy tất cả FCM token của một user (nhiều thiết bị)."""
    return db.query(DeviceToken).filter(DeviceToken.user_id == user_id).all()


def delete_token(db: Session, fcm_token: str, user_id: int) -> bool:
    """Xoá token khi user logout."""
    row = (
        db.query(DeviceToken)
        .filter(DeviceToken.fcm_token == fcm_token, DeviceToken.user_id == user_id)
        .first()
    )
    if not row:
        return False
    db.delete(row)
    db.commit()
    return True


# ── Notification history ──────────────────────────────────────

def create_notification(
    db: Session,
    user_id: int,
    notif_type: str,
    title: str,
    body: str,
    data: str | None = None,
) -> Notification:
    notif = Notification(
        user_id=user_id,
        notif_type=notif_type,
        title=title,
        body=body,
        data=data,
    )
    db.add(notif)
    db.commit()
    db.refresh(notif)
    return notif


def get_notifications_by_user(
    db: Session,
    user_id: int,
    skip: int = 0,
    limit: int = 30,
) -> tuple[list[Notification], int, int]:
    """
    Trả về (items, total, unread_count).
    """
    query = db.query(Notification).filter(Notification.user_id == user_id)
    total = query.count()
    unread_count = query.filter(Notification.is_read == False).count()
    items = (
        query.order_by(Notification.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    return items, total, unread_count


def mark_notifications_read(db: Session, user_id: int, notification_ids: list[str]) -> int:
    """Đánh dấu đã đọc, trả về số bản ghi được cập nhật."""
    updated = (
        db.query(Notification)
        .filter(
            Notification.user_id == user_id,
            Notification.id.in_(notification_ids),
            Notification.is_read == False,
        )
        .update({"is_read": True}, synchronize_session=False)
    )
    db.commit()
    return updated


def mark_all_read(db: Session, user_id: int) -> int:
    updated = (
        db.query(Notification)
        .filter(Notification.user_id == user_id, Notification.is_read == False)
        .update({"is_read": True}, synchronize_session=False)
    )
    db.commit()
    return updated