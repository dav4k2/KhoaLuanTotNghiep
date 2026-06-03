# backend/dependencies/auth_dependency.py

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from database import get_db
from models.user import User
from repositories.auth_repository import AuthRepository
from services.auth_service import AuthService

# HTTPBearer: Tự động đọc header "Authorization: Bearer <token>"
_bearer_scheme = HTTPBearer()


def get_auth_repository(db: Session = Depends(get_db)) -> AuthRepository:
    """Tạo AuthRepository với session hiện tại."""
    return AuthRepository(db)


def get_auth_service(
    repo: AuthRepository = Depends(get_auth_repository),
) -> AuthService:
    """Tạo AuthService với repository hiện tại."""
    return AuthService(repo)


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer_scheme),
    service: AuthService = Depends(get_auth_service),
    db: Session = Depends(get_db),
) -> User:
    """
    Dependency dùng cho các route cần xác thực.
    Đọc JWT từ header → giải mã → trả về User object.

    Dùng như sau:
        @router.get("/profile")
        def get_profile(current_user: User = Depends(get_current_user)):
            ...
    """
    # Giải mã token
    payload = service.decode_token(credentials.credentials)
    user_id = payload.get("sub")

    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token không hợp lệ.",
        )

    # Tìm user trong DB
    repo = AuthRepository(db)
    user = repo.get_user_by_id(int(user_id))

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Không tìm thấy tài khoản.",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tài khoản đã bị vô hiệu hóa.",
        )

    return user
