# routers/community_router.py

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
import json

from database import get_db
from dependencies.auth_dependency import get_current_user
from models.user import User
from models.community import Post, Comment, Like
from schemas.community_schema import (
    PostCreate, PostOut,
    CommentCreate, CommentOut,
    LikeOut,
)
from services.notification_service import notify_new_comment, notify_new_like

router = APIRouter(prefix="/community", tags=["Community"])


# ═══════════════════════════════════════════════════════════════
# POST
# ═══════════════════════════════════════════════════════════════

@router.post("/posts", response_model=PostOut, status_code=status.HTTP_201_CREATED)
async def create_post(
    content: str = Form(...),
    image_urls: Optional[str] = Form(None),   # JSON string: '["url1","url2"]'
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Tạo bài viết mới.
    image_urls truyền dưới dạng JSON string vì multipart/form-data
    không hỗ trợ array trực tiếp.
    """
    parsed_urls = []
    if image_urls:
        try:
            parsed_urls = json.loads(image_urls)
        except json.JSONDecodeError:
            parsed_urls = []

    post = Post(
        author_id=str(current_user.id),
        author_name=current_user.full_name or current_user.email,
        author_avatar=None,         # mở rộng sau khi có avatar feature
        content=content,
        image_urls=parsed_urls,
    )
    db.add(post)
    db.commit()
    db.refresh(post)
    return post


@router.get("/posts", response_model=List[PostOut])
def get_posts(
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Danh sách bài viết mới nhất (feed)."""
    return (
        db.query(Post)
        .options(joinedload(Post.comments), joinedload(Post.likes))
        .order_by(Post.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )


@router.get("/posts/{post_id}", response_model=PostOut)
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
    return post


@router.delete("/posts/{post_id}", status_code=status.HTTP_200_OK)
def delete_post(
    post_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Chỉ tác giả mới xoá được bài của mình."""
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Không tìm thấy bài viết")
    if post.author_id != str(current_user.id):
        raise HTTPException(status_code=403, detail="Không có quyền xoá bài viết này")

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
    """
    Thêm bình luận vào bài viết.
    Sau khi tạo thành công → push notification cho chủ bài (nếu không phải chính mình).
    """
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Không tìm thấy bài viết")

    comment = Comment(
        post_id=post_id,
        author_id=str(current_user.id),
        author_name=current_user.full_name or current_user.email,
        author_avatar=None,
        content=body.content,
    )
    db.add(comment)
    db.commit()
    db.refresh(comment)

    # Gửi notification cho chủ bài — bỏ qua nếu tự comment bài mình
    if post.author_id != str(current_user.id):
        try:
            owner_id = int(post.author_id)
            await notify_new_comment(
                db=db,
                post_owner_id=owner_id,
                commenter_name=current_user.full_name or current_user.email,
                post_id=post_id,
            )
        except (ValueError, TypeError):
            pass    # author_id không parse được → bỏ qua, không crash

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
    """Tác giả comment hoặc tác giả bài viết đều có thể xoá."""
    comment = db.query(Comment).filter(
        Comment.id == comment_id,
        Comment.post_id == post_id,
    ).first()
    if not comment:
        raise HTTPException(status_code=404, detail="Không tìm thấy bình luận")

    post = db.query(Post).filter(Post.id == post_id).first()
    is_comment_owner = comment.author_id == str(current_user.id)
    is_post_owner    = post and post.author_id == str(current_user.id)

    if not (is_comment_owner or is_post_owner):
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
    """
    Toggle like:
    - Chưa like → tạo Like + gửi notification cho chủ bài.
    - Đã like   → xoá Like (unlike), không gửi notification.
    """
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Không tìm thấy bài viết")

    existing_like = db.query(Like).filter(
        Like.post_id == post_id,
        Like.user_id == str(current_user.id),
    ).first()

    if existing_like:
        db.delete(existing_like)
        db.commit()
        return {"liked": False, "message": "Đã bỏ thích"}

    like = Like(post_id=post_id, user_id=str(current_user.id))
    db.add(like)
    db.commit()

    # Gửi notification cho chủ bài — bỏ qua nếu tự like bài mình
    if post.author_id != str(current_user.id):
        try:
            owner_id = int(post.author_id)
            await notify_new_like(
                db=db,
                post_owner_id=owner_id,
                liker_name=current_user.full_name or current_user.email,
                post_id=post_id,
            )
        except (ValueError, TypeError):
            pass

    return {"liked": True, "message": "Đã thích bài viết"}


@router.get("/posts/{post_id}/likes", response_model=List[LikeOut])
def get_likes(
    post_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Danh sách user đã like bài viết."""
    return db.query(Like).filter(Like.post_id == post_id).all()