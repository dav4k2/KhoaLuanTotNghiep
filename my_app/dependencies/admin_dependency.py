# my_app/dependencies/admin_dependency.py

from fastapi import Depends, HTTPException, status
from dependencies.auth_dependency import get_current_user
from models.user import User, UserRole


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """
    Chỉ cho phép user có role = admin đi tiếp.
    Dùng: admin: User = Depends(require_admin)
    """
    if current_user.role != UserRole.admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bạn không có quyền truy cập trang quản trị.",
        )
    return current_user