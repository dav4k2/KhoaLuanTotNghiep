# my_app/models/conversation.py

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from sqlalchemy.sql import func
from database import Base


class Conversation(Base):
    __tablename__ = "conversations"

    id         = Column(String(50), primary_key=True)
    user_id    = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    title      = Column(String(255), nullable=False)
    last_message = Column(Text, nullable=True)
    message_count = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())


class Message(Base):
    __tablename__ = "chat_messages"

    id              = Column(String(50), primary_key=True)
    conversation_id = Column(String(50), ForeignKey("conversations.id"), nullable=False, index=True)
    role            = Column(String(20), nullable=False)   # "user" | "assistant"
    type            = Column(String(20), nullable=False)   # "text" | "image"
    content         = Column(Text, nullable=False)
    image_path = Column(String, nullable=True)
    disease_result  = Column(String(255), nullable=True)
    confidence      = Column(Integer, nullable=True)       # 0-100
    created_at      = Column(DateTime(timezone=True), server_default=func.now())