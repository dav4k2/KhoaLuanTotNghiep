# my_app/services/admin_service.py

from fastapi import HTTPException
from sqlalchemy.orm import Session
from typing import Optional

from repositories.admin_repository import admin_repo
from models.user import UserRole, UserStatus, ExpertRequestStatus
from schemas.admin_schema import (
    DashboardStatsOut, UserListOut, UserAdminOut,
    ExpertRequestListOut, ExpertRequestOut,
    PostListOut, PostAdminOut,
    DiseaseOut,
)


class AdminService:

    # ── Dashboard ─────────────────────────────────────────────────────────────
    def get_stats(self, db: Session) -> DashboardStatsOut:
        return DashboardStatsOut(**admin_repo.get_stats(db))

    # ── Users ──────────────────────────────────────────────────────────────────
    def list_users(self, db, page, page_size, status, role, search):
        s = UserStatus(status) if status else None
        r = UserRole(role)     if role   else None
        total, items = admin_repo.list_users(db, page, page_size, s, r, search)
        return UserListOut(
            total=total, page=page, page_size=page_size,
            items=[UserAdminOut.from_orm(u) for u in items],
        )

    def ban_user(self, db, user_id, admin_id):
        if user_id == admin_id:
            raise HTTPException(400, "Không thể tự khóa tài khoản của mình.")
        u = admin_repo.set_user_status(db, user_id, UserStatus.banned)
        if not u: raise HTTPException(404, "Không tìm thấy người dùng.")
        return UserAdminOut.from_orm(u)

    def unban_user(self, db, user_id):
        u = admin_repo.set_user_status(db, user_id, UserStatus.active)
        if not u: raise HTTPException(404, "Không tìm thấy người dùng.")
        return UserAdminOut.from_orm(u)

    def set_role(self, db, user_id: int, role: str, admin_id: int):
        if user_id == admin_id:
            raise HTTPException(400, "Không thể thay đổi role của chính mình.")
        if role not in ("user", "expert"):
            raise HTTPException(400, "Role chỉ được là 'user' hoặc 'expert'.")
        u = admin_repo.get_user(db, user_id)
        if not u:
            raise HTTPException(404, "Không tìm thấy người dùng.")
        if u.role == UserRole.admin:
            raise HTTPException(400, "Không thể thay đổi role của admin khác.")
        updated = admin_repo.set_user_role(db, user_id, UserRole(role))
        label = "Chuyên gia" if role == "expert" else "Người dùng"
        return {"message": f"Đã cập nhật {updated.full_name or updated.email} thành {label}.",
                "user": UserAdminOut.from_orm(updated)}

    # ── Expert Requests ────────────────────────────────────────────────────────
    def list_expert_requests(self, db, status):
        s = ExpertRequestStatus(status) if status else None
        total, items = admin_repo.list_expert_requests(db, s)
        out = []
        for r in items:
            out.append(ExpertRequestOut(
                id=r.id, user_id=r.user_id,
                full_name=r.user.full_name if r.user else None,
                email=r.user.email if r.user else "",
                specialization=r.specialization, qualification=r.qualification,
                description=r.description, status=r.status,
                rejection_reason=r.rejection_reason,
                created_at=r.created_at, reviewed_at=r.reviewed_at,
            ))
        return ExpertRequestListOut(total=total, items=out)

    def review_expert_request(self, db, req_id, action, admin_id, rejection_reason):
        if action not in ("approve", "reject"):
            raise HTTPException(400, "action phải là 'approve' hoặc 'reject'.")
        if action == "reject" and not rejection_reason:
            raise HTTPException(400, "Cần nhập lý do từ chối.")
        req = admin_repo.review_expert_request(db, req_id, action, admin_id, rejection_reason)
        if not req: raise HTTPException(404, "Không tìm thấy yêu cầu.")
        return {"message": "Duyệt thành công." if action == "approve" else "Đã từ chối yêu cầu."}

    # ── Posts ──────────────────────────────────────────────────────────────────
    def list_posts(self, db, page, page_size, status, search):
        total, items = admin_repo.list_posts(db, page, page_size, status, search)
        out = []
        for p in items:
            # Post lưu author_name trực tiếp, không có relationship User
            title = (p.content[:60] + '...') if len(p.content) > 60 else p.content
            out.append(PostAdminOut(
                id=str(p.id),
                title=title,
                author_name=p.author_name,
                author_role=UserRole.user,   # Post không lưu role
                status='approved',           # Post chưa có field status
                created_at=p.created_at,
            ))
        return PostListOut(total=total, page=page, page_size=page_size, items=out)

    def update_post_status(self, db, post_id, status):
        # Post chưa có field status — cần thêm migration
        return {"message": "Tính năng này cần thêm field status vào bảng posts trước."}

    # ── Diseases ───────────────────────────────────────────────────────────────
    def list_diseases(self, db, search):
        return [DiseaseOut.from_orm(d) for d in admin_repo.list_diseases(db, search)]

    def create_disease(self, db, name_en, name_vi, plant, description):
        d = admin_repo.create_disease(db, name_en, name_vi, plant, description)
        return DiseaseOut.from_orm(d)

    def update_disease(self, db, disease_id, name_vi, plant, description):
        d = admin_repo.update_disease(db, disease_id, name_vi=name_vi, plant=plant, description=description)
        if not d: raise HTTPException(404, "Không tìm thấy danh mục bệnh.")
        return DiseaseOut.from_orm(d)

    def delete_disease(self, db, disease_id):
        if not admin_repo.delete_disease(db, disease_id):
            raise HTTPException(404, "Không tìm thấy danh mục bệnh.")
        return {"message": "Đã xóa danh mục bệnh."}


admin_service = AdminService()