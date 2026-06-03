# my_app/schemas/forgot_password_schema.py

from pydantic import BaseModel, EmailStr, field_validator
import re


class ForgotPasswordRequest(BaseModel):
    """Bước 1 — Gửi OTP: nhận email"""
    email: EmailStr


class VerifyOTPRequest(BaseModel):
    """Bước 2 — Xác nhận OTP: nhận email + mã 6 số"""
    email: EmailStr
    otp_code: str

    @field_validator("otp_code")
    @classmethod
    def validate_otp(cls, v: str) -> str:
        if not re.fullmatch(r"\d{6}", v):
            raise ValueError("Mã OTP phải gồm đúng 6 chữ số.")
        return v


class ResetPasswordRequest(BaseModel):
    """Bước 3 — Đặt lại mật khẩu: nhận email + otp + mật khẩu mới"""
    email: EmailStr
    otp_code: str
    new_password: str

    @field_validator("new_password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Mật khẩu phải có ít nhất 8 ký tự.")
        if not re.search(r"[A-Z]", v):
            raise ValueError("Mật khẩu phải có ít nhất 1 chữ hoa.")
        if not re.search(r"[0-9]", v):
            raise ValueError("Mật khẩu phải có ít nhất 1 chữ số.")
        return v


class MessageResponse(BaseModel):
    message: str