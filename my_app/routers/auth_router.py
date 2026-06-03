# backend/routers/auth_router.py

from fastapi import APIRouter, Depends, status

from dependencies.auth_dependency import get_auth_service, get_current_user
from models.user import User
from schemas.auth_schema import (
    LoginRequest,
    RegisterRequest,
    TokenResponse,
    UserResponse,
)
from services.auth_service import AuthService

router = APIRouter(
    prefix="/auth",   # Tất cả route trong file này bắt đầu bằng /auth
    tags=["Auth"],    # Nhóm trong Swagger UI (/docs)
)


@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Đăng ký tài khoản mới",
)
def register(
    payload: RegisterRequest,                      # Body từ Flutter
    service: AuthService = Depends(get_auth_service),  # Inject service
):
    """
    Tạo tài khoản mới với email và mật khẩu.
    Trả về JWT token và thông tin user.
    """
    return service.register(payload)


@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Đăng nhập",
)
def login(
    payload: LoginRequest,
    service: AuthService = Depends(get_auth_service),
):
    """
    Đăng nhập bằng email và mật khẩu.
    Trả về JWT token và thông tin user.
    """
    return service.login(
        email=payload.email,
        password=payload.password,
    )


@router.get(
    "/me",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Lấy thông tin user hiện tại",
)
def get_me(
    current_user: User = Depends(get_current_user),  # Xác thực JWT tự động
):
    """
    Route được bảo vệ — yêu cầu JWT hợp lệ trong header.
    Trả về thông tin của user đang đăng nhập.
    """
    return current_user
