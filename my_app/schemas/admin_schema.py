# my_app/schemas/admin_schema.py

from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime
from models.user import UserRole, UserStatus, ExpertRequestStatus


# ── User ──────────────────────────────────────────────────────────────────────
class UserAdminOut(BaseModel):
    id: int
    email: EmailStr
    full_name: Optional[str]
    role: UserRole
    status: UserStatus
    is_active: bool
    is_verified: bool
    created_at: datetime

    class Config:
        from_attributes = True


class UserListOut(BaseModel):
    total: int
    page: int
    page_size: int
    items: List[UserAdminOut]


# ── Expert Request ─────────────────────────────────────────────────────────────
class ExpertRequestOut(BaseModel):
    id: int
    user_id: int
    full_name: Optional[str]
    email: str
    specialization: str
    qualification: str
    description: Optional[str]
    status: ExpertRequestStatus
    rejection_reason: Optional[str]
    created_at: datetime
    reviewed_at: Optional[datetime]

    class Config:
        from_attributes = True


class ExpertRequestListOut(BaseModel):
    total: int
    items: List[ExpertRequestOut]


class ReviewExpertIn(BaseModel):
    action: str                          # "approve" | "reject"
    rejection_reason: Optional[str] = None


# ── Post ──────────────────────────────────────────────────────────────────────
class PostStatus(str):
    pending  = "pending"
    approved = "approved"
    hidden   = "hidden"


class PostAdminOut(BaseModel):
    id: int
    title: str
    author_name: Optional[str]
    author_role: UserRole
    status: str
    created_at: datetime

    class Config:
        from_attributes = True


class PostListOut(BaseModel):
    total: int
    page: int
    page_size: int
    items: List[PostAdminOut]


class UpdatePostStatusIn(BaseModel):
    status: str   # "pending" | "approved" | "hidden"


# ── Disease ───────────────────────────────────────────────────────────────────
class DiseaseOut(BaseModel):
    id: int
    name_en: str
    name_vi: str
    plant: str
    description: Optional[str]

    class Config:
        from_attributes = True


class DiseaseCreateIn(BaseModel):
    name_en: str
    name_vi: str
    plant: str
    description: Optional[str] = None


class DiseaseUpdateIn(BaseModel):
    name_vi: Optional[str] = None
    plant: Optional[str] = None
    description: Optional[str] = None


# ── Dashboard ─────────────────────────────────────────────────────────────────
class DashboardStatsOut(BaseModel):
    total_users: int
    total_experts: int
    total_posts: int
    total_diseases: int
    pending_expert_requests: int
    pending_posts: int
    new_users_today: int