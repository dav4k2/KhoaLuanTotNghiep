# my_app/routers/admin_router.py

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session
from typing import Optional

from database import get_db
from dependencies.admin_dependency import require_admin
from models.user import User
from services.admin_service import admin_service
from schemas.admin_schema import ReviewExpertIn, UpdatePostStatusIn, DiseaseCreateIn, DiseaseUpdateIn

router = APIRouter(prefix="/admin", tags=["Admin"])


# ── Dashboard ──────────────────────────────────────────────────────────────────
@router.get("/dashboard")
def dashboard(db: Session = Depends(get_db), _: User = Depends(require_admin)):
    return admin_service.get_stats(db)


# ── Users ──────────────────────────────────────────────────────────────────────
@router.get("/users")
def list_users(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    status: Optional[str] = Query(None),
    role: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    return admin_service.list_users(db, page, page_size, status, role, search)


@router.patch("/users/{user_id}/ban")
def ban_user(user_id: int, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    return admin_service.ban_user(db, user_id, admin.id)


@router.patch("/users/{user_id}/unban")
def unban_user(user_id: int, db: Session = Depends(get_db), _: User = Depends(require_admin)):
    return admin_service.unban_user(db, user_id)


class SetRoleIn(BaseModel):
    role: str   # "user" | "expert"

@router.patch("/users/{user_id}/role")
def set_user_role(
    user_id: int,
    body: SetRoleIn,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    """Nâng lên Expert hoặc hạ xuống User trực tiếp."""
    return admin_service.set_role(db, user_id, body.role, admin.id)


# ── Expert Requests ────────────────────────────────────────────────────────────
@router.get("/expert-requests")
def list_expert_requests(
    status: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    return admin_service.list_expert_requests(db, status)


@router.patch("/expert-requests/{req_id}/review")
def review_expert(
    req_id: int,
    body: ReviewExpertIn,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    return admin_service.review_expert_request(db, req_id, body.action, admin.id, body.rejection_reason)


# ── Posts ──────────────────────────────────────────────────────────────────────
@router.get("/posts")
def list_posts(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    status: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    return admin_service.list_posts(db, page, page_size, status, search)


@router.patch("/posts/{post_id}/status")
def update_post_status(
    post_id: int,
    body: UpdatePostStatusIn,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    return admin_service.update_post_status(db, post_id, body.status)


# ── Diseases ───────────────────────────────────────────────────────────────────
@router.get("/diseases")
def list_diseases(
    search: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    return admin_service.list_diseases(db, search)


@router.post("/diseases")
def create_disease(body: DiseaseCreateIn, db: Session = Depends(get_db), _: User = Depends(require_admin)):
    return admin_service.create_disease(db, body.name_en, body.name_vi, body.plant, body.description)


@router.patch("/diseases/{disease_id}")
def update_disease(
    disease_id: int, body: DiseaseUpdateIn,
    db: Session = Depends(get_db), _: User = Depends(require_admin),
):
    return admin_service.update_disease(db, disease_id, body.name_vi, body.plant, body.description)


@router.delete("/diseases/{disease_id}")
def delete_disease(disease_id: int, db: Session = Depends(get_db), _: User = Depends(require_admin)):
    return admin_service.delete_disease(db, disease_id)