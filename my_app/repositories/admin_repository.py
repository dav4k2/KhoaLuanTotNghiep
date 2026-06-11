# my_app/repositories/admin_repository.py

from sqlalchemy.orm import Session, joinedload
from sqlalchemy import cast, Date
from datetime import date, datetime
from typing import Optional

from models.user import User, UserRole, UserStatus, ExpertRequest, ExpertRequestStatus
from models.community import Post          # model bài đăng hiện có của bạn
from models.disease import Disease


class AdminRepository:

    # ── Dashboard ─────────────────────────────────────────────────────────────
    def get_stats(self, db: Session) -> dict:
        today = date.today()
        # Đếm pending posts — điều chỉnh field nếu model Post dùng tên khác
        try:
            total_posts   = db.query(Post).count()
            pending_posts = 0   # Post chưa có field status
        except Exception:
            pending_posts = 0
            total_posts   = 0
        return {
            "total_users":              db.query(User).filter(User.role == UserRole.user).count(),
            "total_experts":            db.query(User).filter(User.role == UserRole.expert).count(),
            "total_posts":              total_posts,
            "total_diseases":           db.query(Disease).count(),
            "pending_expert_requests":  db.query(ExpertRequest).filter(ExpertRequest.status == ExpertRequestStatus.pending).count(),
            "pending_posts":            pending_posts,
            "new_users_today":          db.query(User).filter(cast(User.created_at, Date) == today).count(),
        }

    # ── Users ──────────────────────────────────────────────────────────────────
    def list_users(self, db: Session, page: int, page_size: int,
                   status: Optional[UserStatus], role: Optional[UserRole], search: Optional[str]):
        q = db.query(User)
        if status: q = q.filter(User.status == status)
        if role:   q = q.filter(User.role == role)
        if search:
            like = f"%{search}%"
            q = q.filter(User.full_name.ilike(like) | User.email.ilike(like))
        total = q.count()
        items = q.order_by(User.created_at.desc()).offset((page - 1) * page_size).limit(page_size).all()
        return total, items

    def get_user(self, db: Session, user_id: int) -> Optional[User]:
        return db.query(User).filter(User.id == user_id).first()

    def set_user_status(self, db: Session, user_id: int, status: UserStatus) -> Optional[User]:
        u = self.get_user(db, user_id)
        if not u: return None
        u.status = status
        db.commit(); db.refresh(u)
        return u

    def set_user_role(self, db: Session, user_id: int, role: UserRole) -> Optional[User]:
        u = self.get_user(db, user_id)
        if not u: return None
        u.role = role
        db.commit(); db.refresh(u)
        return u

    # ── Expert Requests ────────────────────────────────────────────────────────
    def list_expert_requests(self, db: Session, status: Optional[ExpertRequestStatus]):
        q = db.query(ExpertRequest).options(joinedload(ExpertRequest.user))
        if status: q = q.filter(ExpertRequest.status == status)
        items = q.order_by(ExpertRequest.created_at.desc()).all()
        return len(items), items

    def review_expert_request(self, db: Session, req_id: int, action: str,
                               admin_id: int, rejection_reason: Optional[str] = None):
        req = db.query(ExpertRequest).filter(ExpertRequest.id == req_id).first()
        if not req: return None
        if action == "approve":
            req.status = ExpertRequestStatus.approved
            self.set_user_role(db, req.user_id, UserRole.expert)
        else:
            req.status = ExpertRequestStatus.rejected
            req.rejection_reason = rejection_reason
        req.reviewed_at = datetime.utcnow()
        req.reviewed_by = admin_id
        db.commit(); db.refresh(req)
        return req

    # ── Posts ──────────────────────────────────────────────────────────────────
    # Model Post KHÔNG có field status/title — chỉ có content, author_name, author_id
    def list_posts(self, db: Session, page: int, page_size: int,
                   status: Optional[str], search: Optional[str]):
        q = db.query(Post)
        # Post không có title, tìm trong content
        if search: q = q.filter(Post.content.ilike(f"%{search}%"))
        total = q.count()
        items = q.order_by(Post.created_at.desc()).offset((page - 1) * page_size).limit(page_size).all()
        return total, items

    def set_post_status(self, db: Session, post_id: str, status: str):
        # Post chưa có field status — cần thêm vào model hoặc bỏ qua
        post = db.query(Post).filter(Post.id == post_id).first()
        if not post: return None
        return post

    # ── Diseases ───────────────────────────────────────────────────────────────
    def list_diseases(self, db: Session, search: Optional[str]):
        q = db.query(Disease)
        if search:
            q = q.filter(Disease.name_vi.ilike(f"%{search}%") | Disease.name_en.ilike(f"%{search}%"))
        return q.order_by(Disease.id).all()

    def create_disease(self, db: Session, name_en: str, name_vi: str, plant: str, description=None):
        d = Disease(name_en=name_en, name_vi=name_vi, plant=plant, description=description)
        db.add(d); db.commit(); db.refresh(d)
        return d

    def update_disease(self, db: Session, disease_id: int, **kwargs):
        d = db.query(Disease).filter(Disease.id == disease_id).first()
        if not d: return None
        for k, v in kwargs.items():
            if v is not None: setattr(d, k, v)
        db.commit(); db.refresh(d)
        return d

    def delete_disease(self, db: Session, disease_id: int) -> bool:
        d = db.query(Disease).filter(Disease.id == disease_id).first()
        if not d: return False
        db.delete(d); db.commit()
        return True


admin_repo = AdminRepository()