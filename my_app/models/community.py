# models/community.py

import uuid
from sqlalchemy import Column, String, Text, DateTime, ForeignKey, ARRAY, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from database import Base


def _uuid() -> str:
    return str(uuid.uuid4())


# ── Post (bài viết) ───────────────────────────────
class Post(Base):
    __tablename__ = "posts"

    id            = Column(UUID(as_uuid=False), primary_key=True, default=_uuid)
    author_id     = Column(String,      nullable=False)
    author_name   = Column(String(120), nullable=False)
    author_avatar = Column(String,      nullable=True)
    content       = Column(Text,        nullable=False)
    image_urls    = Column(ARRAY(Text), default=list)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(),
                        onupdate=func.now())

    comments = relationship(
        "Comment", back_populates="post",
        cascade="all, delete-orphan",
        order_by="Comment.created_at",
    )
    likes = relationship(
        "Like", back_populates="post",
        cascade="all, delete-orphan",
    )


# ── Comment (bình luận) ───────────────────────────
class Comment(Base):
    __tablename__ = "comments"

    id            = Column(UUID(as_uuid=False), primary_key=True, default=_uuid)
    post_id       = Column(UUID(as_uuid=False),
                           ForeignKey("posts.id", ondelete="CASCADE"),
                           nullable=False)
    author_id     = Column(String,      nullable=False)
    author_name   = Column(String(120), nullable=False)
    author_avatar = Column(String,      nullable=True)
    content       = Column(Text,        nullable=False)
    created_at    = Column(DateTime(timezone=True), server_default=func.now())

    post = relationship("Post", back_populates="comments")


# ── Like ──────────────────────────────────────────
class Like(Base):
    __tablename__ = "likes"

    id         = Column(UUID(as_uuid=False), primary_key=True, default=_uuid)
    post_id    = Column(UUID(as_uuid=False),
                        ForeignKey("posts.id", ondelete="CASCADE"),
                        nullable=False)
    user_id    = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    post = relationship("Post", back_populates="likes")