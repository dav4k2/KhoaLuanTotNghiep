# my_app/routers/forgot_password_router.py

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from database import get_db
from schemas.forgot_password_schema import (
    ForgotPasswordRequest,
    MessageResponse,
    ResetPasswordRequest,
    VerifyOTPRequest,
)
from services.forgot_password_service import ForgotPasswordService

router = APIRouter(
    prefix="/auth",
    tags=["Forgot Password"],
)


@router.post(
    "/forgot-password",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Bước 1 — Gửi OTP qua email",
)
def forgot_password(
    payload: ForgotPasswordRequest,
    db: Session = Depends(get_db),
):
    service = ForgotPasswordService(db)
    return service.send_otp(payload.email)


@router.post(
    "/verify-otp",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Bước 2 — Xác nhận mã OTP",
)
def verify_otp(
    payload: VerifyOTPRequest,
    db: Session = Depends(get_db),
):
    service = ForgotPasswordService(db)
    return service.verify_otp(payload.email, payload.otp_code)


@router.post(
    "/reset-password",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Bước 3 — Đặt lại mật khẩu mới",
)
def reset_password(
    payload: ResetPasswordRequest,
    db: Session = Depends(get_db),
):
    service = ForgotPasswordService(db)
    return service.reset_password(
        email=payload.email,
        otp_code=payload.otp_code,
        new_password=payload.new_password,
    )