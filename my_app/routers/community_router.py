# routers/community_router.py
import os
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File as FastAPIFile
from sqlalchemy.orm import Session, joinedload
from typing import List

from database import get_db
from dependencies.auth_dependency import get_current_user
from models.user import User
from models.community import Post, Comment, Like
from schemas.community_schema import (
    PostCreate, PostOut,
    CommentCreate, CommentOut,
)
from services.notification_service import notify_new_comment, notify_new_like
from services.cloudinary_service import upload_image, delete_image   # ← dùng service

router = APIRouter(prefix="/community", tags=["Community"])


# ── Helper: build dict chuẩn cho Flutter ─────────────────────
def _post_dict(post: Post, current_user_id: str) -> dict:
    return {
        "id":             post.id,
        "author_id":      post.author_id,
        "author_name":    post.author_name,
        "author_avatar":  post.author_avatar,
        "author_role":    post.author_role,
        "content":        post.content,
        "image_urls":     post.image_urls or [],
        "like_count":     len(post.likes),
        "is_liked_by_me": any(l.user_id == current_user_id for l in post.likes),
        "comment_count":  len(post.comments),
        "created_at":     post.created_at.isoformat(),
        "updated_at":     post.updated_at.isoformat(),
        "comments": [
            {
                "id":            c.id,
                "post_id":       c.post_id,
                "author_id":     c.author_id,
                "author_name":   c.author_name,
                "author_avatar": c.author_avatar,
                "author_role":   c.author_role,
                "content":       c.content,
                "created_at":    c.created_at.isoformat(),
            }
            for c in sorted(post.comments, key=lambda c: c.created_at)
        ],
    }


# ═══════════════════════════════════════════════════════════════
# UPLOAD IMAGES
# ═══════════════════════════════════════════════════════════════

@router.post("/upload-images", status_code=status.HTTP_200_OK)
async def upload_images(
    files: List[UploadFile] = FastAPIFile(...),
    current_user: User = Depends(get_current_user),
):
    """Upload ảnh lên Cloudinary, trả về danh sách URL."""
    urls = []
    for file in files:
        contents = await file.read()
        try:
            result = await upload_image(
                file_bytes=contents,
                filename=file.filename or "upload",
                folder="leafdoctor/community",
            )
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))
        except Exception as e:
            raise HTTPException(status_code=502, detail=f"Upload Cloudinary thất bại: {e}")
        urls.append(result["url"])
    return {"urls": urls}


# ═══════════════════════════════════════════════════════════════
# POST
# ═══════════════════════════════════════════════════════════════

@router.post("/posts", status_code=status.HTTP_201_CREATED)
def create_post(
    payload: PostCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Tạo bài viết mới — Flutter gửi JSON body (image_urls đã upload trước)."""
    role = current_user.role
    role_str = role.value if hasattr(role, "value") else str(role)

    post = Post(
        author_id     = str(current_user.id),
        author_name   = current_user.full_name or current_user.email,
        author_avatar = None,
        author_role   = role_str,
        content       = payload.content,
        image_urls    = payload.image_urls or [],
    )
    db.add(post)
    db.commit()
    db.refresh(post)

    post = (
        db.query(Post)
        .options(joinedload(Post.comments), joinedload(Post.likes))
        .filter(Post.id == post.id)
        .first()
    )
    return _post_dict(post, str(current_user.id))


@router.get("/posts")
def get_posts(
    page:  int = 1,
    size:  int = 10,
    skip:  int = 0,
    limit: int = 0,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Danh sách bài viết — hỗ trợ cả page/size lẫn skip/limit."""
    if limit > 0:
        offset, page_size = skip, limit
    else:
        offset    = (page - 1) * size
        page_size = size

    posts = (
        db.query(Post)
        .options(joinedload(Post.comments), joinedload(Post.likes))
        .order_by(Post.created_at.desc())
        .offset(offset)
        .limit(page_size)
        .all()
    )
    total = db.query(Post).count()
    uid   = str(current_user.id)
    return {
        "items": [_post_dict(p, uid) for p in posts],
        "total": total,
    }


@router.get("/posts/{post_id}")
def get_post(
    post_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Chi tiết một bài viết."""
    post = (
        db.query(Post)
        .options(joinedload(Post.comments), joinedload(Post.likes))
        .filter(Post.id == post_id)
        .first()
    )
    if not post:
        raise HTTPException(status_code=404, detail="Không tìm thấy bài viết")
    return _post_dict(post, str(current_user.id))


@router.delete("/posts/{post_id}", status_code=status.HTTP_200_OK)
async def delete_post(
    post_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Chỉ tác giả mới xoá được bài của mình. Ảnh trên Cloudinary cũng bị xoá."""
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Không tìm thấy bài viết")
    if post.author_id != str(current_user.id):
        raise HTTPException(status_code=403, detail="Không có quyền xoá bài viết này")

    # Xoá ảnh trên Cloudinary (public_id = phần path sau domain)
    # URL dạng: https://res.cloudinary.com/<cloud>/image/upload/v.../leafdoctor/community/<id>
    for url in (post.image_urls or []):
        try:
            # Trích public_id từ secure_url: bỏ phần trước "/upload/" và bỏ extension
            if "/upload/" in url:
                public_id_with_ext = url.split("/upload/", 1)[1]
                # Bỏ version prefix nếu có (v1234567890/)
                parts = public_id_with_ext.split("/")
                if parts[0].startswith("v") and parts[0][1:].isdigit():
                    parts = parts[1:]
                public_id = "/".join(parts).rsplit(".", 1)[0]
                await delete_image(public_id)
        except Exception:
            pass  # Không để lỗi Cloudinary block việc xoá DB

    db.delete(post)
    db.commit()
    return {"message": "Đã xoá bài viết"}


# ═══════════════════════════════════════════════════════════════
# COMMENT
# ═══════════════════════════════════════════════════════════════

@router.post("/posts/{post_id}/comments", response_model=CommentOut, status_code=status.HTTP_201_CREATED)
async def create_comment(
    post_id: str,
    body: CommentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Không tìm thấy bài viết")

    role = current_user.role
    role_str = role.value if hasattr(role, "value") else str(role)
    comment = Comment(
        post_id       = post_id,
        author_id     = str(current_user.id),
        author_name   = current_user.full_name or current_user.email,
        author_avatar = None,
        author_role   = role_str,
        content       = body.content,
    )
    db.add(comment)
    db.commit()
    db.refresh(comment)

    if post.author_id != str(current_user.id):
        try:
            await notify_new_comment(
                db=db,
                post_owner_id=int(post.author_id),
                commenter_name=current_user.full_name or current_user.email,
                post_id=post_id,
            )
        except (ValueError, TypeError):
            pass

    return comment


@router.get("/posts/{post_id}/comments", response_model=List[CommentOut])
def get_comments(
    post_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return (
        db.query(Comment)
        .filter(Comment.post_id == post_id)
        .order_by(Comment.created_at.asc())
        .all()
    )


@router.delete("/posts/{post_id}/comments/{comment_id}", status_code=status.HTTP_200_OK)
def delete_comment(
    post_id: str,
    comment_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    comment = db.query(Comment).filter(
        Comment.id == comment_id,
        Comment.post_id == post_id,
    ).first()
    if not comment:
        raise HTTPException(status_code=404, detail="Không tìm thấy bình luận")

    post = db.query(Post).filter(Post.id == post_id).first()
    if not (comment.author_id == str(current_user.id) or
            (post and post.author_id == str(current_user.id))):
        raise HTTPException(status_code=403, detail="Không có quyền xoá bình luận này")

    db.delete(comment)
    db.commit()
    return {"message": "Đã xoá bình luận"}


# ═══════════════════════════════════════════════════════════════
# LIKE / UNLIKE
# ═══════════════════════════════════════════════════════════════

@router.post("/posts/{post_id}/like", status_code=status.HTTP_200_OK)
async def toggle_like(
    post_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    post = (
        db.query(Post)
        .options(joinedload(Post.likes))
        .filter(Post.id == post_id)
        .first()
    )
    if not post:
        raise HTTPException(status_code=404, detail="Không tìm thấy bài viết")

    uid = str(current_user.id)
    existing = db.query(Like).filter(
        Like.post_id == post_id,
        Like.user_id == uid,
    ).first()

    if existing:
        db.delete(existing)
        db.commit()
        like_count = db.query(Like).filter(Like.post_id == post_id).count()
        return {"action": "unliked", "like_count": like_count}

    db.add(Like(post_id=post_id, user_id=uid))
    db.commit()
    like_count = db.query(Like).filter(Like.post_id == post_id).count()

    if post.author_id != uid:
        try:
            await notify_new_like(
                db=db,
                post_owner_id=int(post.author_id),
                liker_name=current_user.full_name or current_user.email,
                post_id=post_id,
            )
        except (ValueError, TypeError):
            pass

    return {"action": "liked", "like_count": like_count}