# my_app/models/user.py — thêm cột full_name

import enum
from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, ForeignKey, Enum as SAEnum
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from database import Base


# ── Enums ──────────────────────────────────────────────────────────────────────
class UserRole(str, enum.Enum):
    user   = "user"
    expert = "expert"
    admin  = "admin"


class UserStatus(str, enum.Enum):
    active = "active"
    banned = "banned"


class ExpertRequestStatus(str, enum.Enum):
    pending  = "pending"
    approved = "approved"
    rejected = "rejected"


# ── User ───────────────────────────────────────────────────────────────────────
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)

    email = Column(String(255), unique=True, index=True, nullable=False)

    full_name = Column(String(255), nullable=True)

    hashed_password = Column(String(255), nullable=False)

    is_active   = Column(Boolean, default=True,  nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)

    # ── Thêm mới cho admin ────────────────────────────────────────────────────
    role   = Column(SAEnum(UserRole),   default=UserRole.user,     nullable=False)
    status = Column(SAEnum(UserStatus), default=UserStatus.active, nullable=False)
    # ─────────────────────────────────────────────────────────────────────────

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(),
                        onupdate=func.now(), nullable=False)

    def __repr__(self):
        return f"<User id={self.id} email={self.email} name={self.full_name} role={self.role}>"

    device_tokens = relationship(
        "DeviceToken", back_populates="user", cascade="all, delete-orphan"
    )
    notifications = relationship(
        "Notification", back_populates="user", cascade="all, delete-orphan"
    )
    expert_request = relationship(
        "ExpertRequest", back_populates="user",
        foreign_keys="ExpertRequest.user_id", uselist=False
    )


# ── ExpertRequest ──────────────────────────────────────────────────────────────
class ExpertRequest(Base):
    """Yêu cầu nâng cấp lên vai trò chuyên gia — do user tự gửi."""
    __tablename__ = "expert_requests"

    id           = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id      = Column(Integer, ForeignKey("users.id"), nullable=False, unique=True)
    specialization = Column(String(255), nullable=False)   # vd: "Bệnh lúa & ngô"
    qualification  = Column(String(255), nullable=False)   # vd: "Tiến sĩ Nông học"
    description    = Column(Text, nullable=True)
    status         = Column(SAEnum(ExpertRequestStatus),
                            default=ExpertRequestStatus.pending, nullable=False)
    rejection_reason = Column(Text, nullable=True)         # lý do từ chối
    reviewed_by    = Column(Integer, ForeignKey("users.id"), nullable=True)  # admin đã duyệt

    created_at  = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    reviewed_at = Column(DateTime(timezone=True), nullable=True)

    user = relationship("User", foreign_keys=[user_id], back_populates="expert_request")