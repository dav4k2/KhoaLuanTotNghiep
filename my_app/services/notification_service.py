# services/notification_service.py

"""
FCM HTTP v1 — dùng Service Account thay vì Server Key (legacy đã bị disable).

Cách lấy Service Account JSON:
  Firebase Console → Project Settings → Service Accounts
  → "Generate new private key" → tải file JSON về
  → đặt vào thư mục backend, ví dụ: firebase_service_account.json
  → thêm vào .env:  GOOGLE_APPLICATION_CREDENTIALS=firebase_service_account.json
"""

import json
import logging
import httpx
from sqlalchemy.orm import Session

import repositories.notification_repository as notif_repo
from config import settings

logger = logging.getLogger(__name__)

FCM_V1_URL = "https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"


# ── Lấy OAuth2 Access Token từ Service Account ───────────────

def _get_access_token() -> str:
    """
    Dùng google-auth để lấy short-lived access token.
    Cài thư viện: pip install google-auth
    """
    from google.oauth2 import service_account
    import google.auth.transport.requests

    credentials = service_account.Credentials.from_service_account_file(
        settings.FIREBASE_SERVICE_ACCOUNT_PATH,
        scopes=["https://www.googleapis.com/auth/firebase.messaging"],
    )
    request = google.auth.transport.requests.Request()
    credentials.refresh(request)
    return credentials.token


# ── Gửi FCM v1 đến 1 token ───────────────────────────────────

async def _send_fcm_v1(token: str, title: str, body: str, data: dict | None = None) -> bool:
    """
    Gửi đến 1 thiết bị. FCM v1 không hỗ trợ multicast trong 1 request,
    nên gọi lần lượt — dùng httpx async để không block.
    Trả về True nếu thành công.
    """
    if not settings.FIREBASE_SERVICE_ACCOUNT_PATH or not settings.FIREBASE_PROJECT_ID:
        logger.warning("Firebase chưa cấu hình — bỏ qua push notification")
        return False

    try:
        access_token = _get_access_token()
    except Exception as exc:
        logger.error("Không lấy được FCM access token: %s", exc)
        return False

    url = FCM_V1_URL.format(project_id=settings.FIREBASE_PROJECT_ID)
    payload = {
        "message": {
            "token": token,
            "notification": {
                "title": title,
                "body": body,
            },
            "data": {k: str(v) for k, v in (data or {}).items()},  # FCM v1 yêu cầu tất cả value là string
            "android": {
                "priority": "high",
            },
            "apns": {
                "headers": {"apns-priority": "10"},
            },
        }
    }
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
    }

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(url, json=payload, headers=headers)
            if resp.status_code == 200:
                return True
            else:
                logger.warning("FCM v1 lỗi token=%s status=%s body=%s", token[:20], resp.status_code, resp.text)
                return False
    except Exception as exc:
        logger.error("Lỗi khi gửi FCM v1: %s", exc)
        return False


# ── Gửi đến nhiều token của 1 user ───────────────────────────

async def _send_to_user_tokens(user_tokens: list, title: str, body: str, data: dict | None = None) -> None:
    for device in user_tokens:
        await _send_fcm_v1(device.fcm_token, title, body, data)


# ── Hàm nội bộ: lưu DB + push ────────────────────────────────

async def _notify_user(
    db: Session,
    user_id: int,
    notif_type: str,
    title: str,
    body: str,
    data: dict | None = None,
) -> None:
    data_str = json.dumps(data, ensure_ascii=False) if data else None
    notif_repo.create_notification(db, user_id, notif_type, title, body, data_str)

    tokens = notif_repo.get_tokens_by_user(db, user_id)
    await _send_to_user_tokens(tokens, title, body, data)


# ── Public API ────────────────────────────────────────────────

async def notify_ai_result_done(
    db: Session,
    user_id: int,
    scan_id: str,
    disease_name: str,
    severity: str,
) -> None:
    if severity == "high":
        title = "Phát hiện bệnh nghiêm trọng!"
        body  = f"Cây của bạn có thể bị {disease_name}. Cần xử lý ngay."
    else:
        title = "Kết quả phân tích đã sẵn sàng"
        body  = f"AI đã xác định: {disease_name}. Xem gợi ý điều trị."

    await _notify_user(
        db, user_id,
        notif_type="ai_result",
        title=title,
        body=body,
        data={"scan_id": scan_id, "severity": severity},
    )


async def notify_new_comment(
    db: Session,
    post_owner_id: int,
    commenter_name: str,
    post_id: str,
) -> None:
    await _notify_user(
        db, post_owner_id,
        notif_type="community_comment",
        title="Có bình luận mới",
        body=f"{commenter_name} đã bình luận bài viết của bạn.",
        data={"post_id": post_id},
    )


async def notify_new_like(
    db: Session,
    post_owner_id: int,
    liker_name: str,
    post_id: str,
) -> None:
    await _notify_user(
        db, post_owner_id,
        notif_type="community_like",
        title="Bài viết được yêu thích",
        body=f"{liker_name} đã thích bài viết của bạn.",
        data={"post_id": post_id},
    )


async def notify_expert_verified(
    db: Session,
    post_owner_id: int,
    post_id: str,
) -> None:
    await _notify_user(
        db, post_owner_id,
        notif_type="expert_verified",
        title="Chuyên gia đã xác nhận",
        body="Chẩn đoán của bạn đã được chuyên gia kiểm duyệt và xác nhận.",
        data={"post_id": post_id},
    )


async def notify_disease_alert_in_area(
    db: Session,
    user_ids: list[int],
    disease_name: str,
) -> None:
    title = "Cảnh báo dịch bệnh trong khu vực"
    body  = f"Nhiều người gần bạn đang báo cáo bệnh {disease_name}. Hãy kiểm tra cây trồng của bạn."
    for uid in user_ids:
        await _notify_user(
            db, uid,
            notif_type="disease_alert",
            title=title,
            body=body,
            data={"disease_name": disease_name},
        )