# my_app/routers/conversation_router.py

from fastapi import APIRouter, Depends, status, UploadFile, File, HTTPException
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from dependencies.auth_dependency import get_current_user
from models.user import User
from models.conversation import Conversation, Message
from services.cloudinary_service import upload_image
from schemas.conversation_schema import (
    ConversationIn, ConversationOut, MessageOut, ImageUploadResponse,
)

router = APIRouter(prefix="/conversations", tags=["Conversations"])

# ── Upload ảnh chat lên Cloudinary ────────────────────────────

@router.post("/upload-image", response_model=ImageUploadResponse)
async def upload_chat_image(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    file_bytes = await file.read()
    try:
        result = await upload_image(
            file_bytes,
            file.filename,
            folder=f"chat/{current_user.id}",
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    return result

# ── Lưu / đồng bộ toàn bộ cuộc trò chuyện ────────────────────

@router.post("/sync", status_code=status.HTTP_200_OK)
def sync_conversation(
    payload: ConversationIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Flutter gọi API này sau mỗi tin nhắn để sync lên backend.
    Nếu conversation chưa có → tạo mới.
    Nếu đã có → cập nhật.
    """
    # Upsert conversation
    conv = db.query(Conversation).filter(
        Conversation.id == payload.id,
        Conversation.user_id == current_user.id,
    ).first()

    if conv:
        conv.title         = payload.title
        conv.last_message  = payload.last_message
        conv.message_count = payload.message_count
        conv.updated_at    = payload.updated_at
    else:
        conv = Conversation(
            id            = payload.id,
            user_id       = current_user.id,
            title         = payload.title,
            last_message  = payload.last_message,
            message_count = payload.message_count,
            created_at    = payload.created_at,
            updated_at    = payload.updated_at,
        )
        db.add(conv)

    # Upsert messages
    seen_ids = set()
    for msg in payload.messages:
        if msg.id in seen_ids:
            continue
        seen_ids.add(msg.id)

        existing = db.query(Message).filter(Message.id == msg.id).first()
        if not existing:
            db.add(Message(
                id              = msg.id,
                conversation_id = payload.id,
                role            = msg.role,
                type            = msg.type,
                content         = msg.content,
                image_path      = msg.image_path,
                disease_result  = msg.disease_result,
                confidence      = int(msg.confidence * 100) if msg.confidence else None,
                created_at      = msg.created_at,
            ))

    db.commit()
    return {"message": "Đồng bộ thành công"}


# ── Lấy danh sách cuộc trò chuyện ────────────────────────────

@router.get("/", response_model=List[ConversationOut])
def get_conversations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return db.query(Conversation).filter(
        Conversation.user_id == current_user.id
    ).order_by(Conversation.updated_at.desc()).all()


# ── Lấy tin nhắn của một cuộc trò chuyện ──────────────────────

@router.get("/{conversation_id}/messages", response_model=List[MessageOut])
def get_messages(
    conversation_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Kiểm tra conversation thuộc về user hiện tại
    conv = db.query(Conversation).filter(
        Conversation.id == conversation_id,
        Conversation.user_id == current_user.id,
    ).first()

    if not conv:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Không tìm thấy cuộc trò chuyện")

    return db.query(Message).filter(
        Message.conversation_id == conversation_id
    ).order_by(Message.created_at.asc()).all()


# ── Xoá cuộc trò chuyện ───────────────────────────────────────

@router.delete("/{conversation_id}", status_code=status.HTTP_200_OK)
def delete_conversation(
    conversation_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    conv = db.query(Conversation).filter(
        Conversation.id == conversation_id,
        Conversation.user_id == current_user.id,
    ).first()

    if conv:
        db.query(Message).filter(
            Message.conversation_id == conversation_id
        ).delete()
        db.delete(conv)
        db.commit()

    return {"message": "Đã xoá cuộc trò chuyện"}