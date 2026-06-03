# my_app/schemas/conversation_schema.py

from pydantic import BaseModel, field_validator
from datetime import datetime
from typing import Optional, List


class MessageIn(BaseModel):
    id: str
    role: str
    type: str
    content: str
    disease_result: Optional[str] = None
    confidence: Optional[float] = None
    created_at: datetime


class ConversationIn(BaseModel):
    id: str
    title: str
    last_message: Optional[str] = None
    message_count: int = 0
    messages: List[MessageIn] = []
    created_at: datetime
    updated_at: datetime


class ConversationOut(BaseModel):
    id: str
    title: str
    last_message: Optional[str] = None
    message_count: int
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class MessageOut(BaseModel):
    id: str
    conversation_id: str
    role: str
    type: str
    content: str
    disease_result: Optional[str] = None
    # DB lưu int (0-100), trả về float (0.0-1.0) cho Flutter
    confidence: Optional[float] = None
    created_at: datetime

    model_config = {"from_attributes": True}

    @field_validator("confidence", mode="before")
    @classmethod
    def normalize_confidence(cls, v):
        """Chuyển int 0-100 từ DB về float 0.0-1.0 cho Flutter."""
        if v is None:
            return None
        if isinstance(v, int) and v > 1:
            return v / 100.0
        return float(v)