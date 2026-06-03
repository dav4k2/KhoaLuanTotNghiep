# my_app/schemas/auth_schema.py — thêm full_name

from pydantic import BaseModel, EmailStr, field_validator
from datetime import datetime
from typing import Optional
import re


class RegisterRequest(BaseModel):
    email:     EmailStr
    password:  str
    full_name: str          # ← THÊM — bắt buộc khi đăng ký

    @field_validator("full_name")
    @classmethod
    def validate_full_name(cls, v: str) -> str:
        v = v.strip()
        if len(v) < 2:
            raise ValueError("Họ tên phải có ít nhất 2 ký tự.")
        if len(v) > 100:
            raise ValueError("Họ tên không được quá 100 ký tự.")
        return v

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Mật khẩu phải có ít nhất 8 ký tự.")
        if not re.search(r"[A-Z]", v):
            raise ValueError("Mật khẩu phải có ít nhất 1 chữ hoa.")
        if not re.search(r"[0-9]", v):
            raise ValueError("Mật khẩu phải có ít nhất 1 chữ số.")
        return v


class LoginRequest(BaseModel):
    email:    EmailStr
    password: str


class UserResponse(BaseModel):
    id:          int
    email:       str
    full_name:   Optional[str] = None   # ← THÊM
    is_active:   bool
    is_verified: bool
    created_at:  datetime

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    token_type:   str = "bearer"
    user:         UserResponse


class MessageResponse(BaseModel):
    message: str