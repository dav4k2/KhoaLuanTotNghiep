# schemas/community_schema.py
from __future__ import annotations
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class PostCreate(BaseModel):
    content: str
    image_urls: Optional[List[str]] = []

class CommentOut(BaseModel):
    id: str
    post_id: str
    author_id: str
    author_name: str
    author_avatar: Optional[str] = None
    author_role: str = "user"          # ← THÊM
    content: str
    created_at: datetime

    class Config:
        from_attributes = True

class LikeOut(BaseModel):
    id: str
    post_id: str
    user_id: str
    created_at: datetime

    class Config:
        from_attributes = True

class PostOut(BaseModel):
    id: str
    author_id: str
    author_name: str
    author_avatar: Optional[str] = None
    author_role: str = "user"
    content: str
    image_urls: Optional[List[str]] = []
    like_count: int = 0
    is_liked_by_me: bool = False
    comment_count: int = 0
    created_at: datetime
    updated_at: datetime
    comments: List[CommentOut] = []

    class Config:
        from_attributes = True

class CommentCreate(BaseModel):
    content: str