# my_app/services/forgot_password_service.py

import random
import string
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from models.otp import OTPCode
from models.user import User
from repositories.auth_repository import AuthRepository
from services.email_service import EmailService


class ForgotPasswordService:

    def __init__(self, db: Session):
        self.db = db
        self.repo = AuthRepository(db)

    # ── Bước 1: Gửi OTP ──────────────────────────────────────

    def send_otp(self, email: str) -> dict:
        """
        1. Kiểm tra email tồn tại
        2. Tạo mã OTP 6 số ngẫu nhiên
        3. Lưu vào DB với thời gian hết hạn 5 phút
        4. Gửi email
        """
        # Kiểm tra email tồn tại
        user = self.repo.get_user_by_email(email)
        if not user:
            # Không tiết lộ email có tồn tại hay không (bảo mật)
            # Vẫn trả về success để tránh user enumeration attack
            return {"message": "Nếu email tồn tại, mã OTP đã được gửi."}

        # Xoá các OTP cũ chưa dùng của email này
        self.db.query(OTPCode).filter(
            OTPCode.email == email,
            OTPCode.is_used == False,
        ).delete()
        self.db.commit()

        # Tạo OTP 6 số
        otp_code = "".join(random.choices(string.digits, k=6))

        # Lưu OTP vào DB, hết hạn sau 5 phút
        otp = OTPCode(
            email=email,
            code=otp_code,
            expired_at=datetime.now(timezone.utc) + timedelta(minutes=5),
        )
        self.db.add(otp)
        self.db.commit()

        # Gửi email
        sent = EmailService.send_otp_email(email, otp_code)
        if not sent:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Không thể gửi email. Vui lòng thử lại sau.",
            )

        return {"message": "Mã OTP đã được gửi đến email của bạn."}

    # ── Bước 2: Xác nhận OTP ─────────────────────────────────

    def verify_otp(self, email: str, otp_code: str) -> dict:
        """
        1. Tìm OTP trong DB
        2. Kiểm tra còn hạn và chưa dùng
        3. Trả về success để Flutter chuyển sang màn nhập mật khẩu mới
        (Chưa đánh dấu is_used — chờ đến khi reset thật sự)
        """
        otp = self._get_valid_otp(email, otp_code)  # raise nếu không hợp lệ
        return {"message": "Mã OTP hợp lệ."}

    # ── Bước 3: Đặt lại mật khẩu ─────────────────────────────

    def reset_password(self, email: str, otp_code: str, new_password: str) -> dict:
        """
        1. Xác nhận OTP lần cuối
        2. Cập nhật mật khẩu mới
        3. Đánh dấu OTP đã dùng
        """
        from passlib.context import CryptContext
        pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

        # Xác nhận OTP
        otp = self._get_valid_otp(email, otp_code)

        # Lấy user
        user = self.repo.get_user_by_email(email)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy tài khoản.",
            )

        # Cập nhật mật khẩu
        self.repo.update_user_password(
            user=user,
            hashed_password=pwd_context.hash(new_password),
        )

        # Đánh dấu OTP đã dùng
        otp.is_used = True
        self.db.commit()

        return {"message": "Mật khẩu đã được đặt lại thành công."}

    # ── Helper ────────────────────────────────────────────────

    def _get_valid_otp(self, email: str, otp_code: str) -> OTPCode:
        """Tìm và validate OTP — raise HTTPException nếu không hợp lệ."""
        otp = self.db.query(OTPCode).filter(
            OTPCode.email   == email,
            OTPCode.code    == otp_code,
            OTPCode.is_used == False,
        ).first()

        if not otp:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Mã OTP không đúng.",
            )

        # Kiểm tra hết hạn
        if datetime.now(timezone.utc) > otp.expired_at:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.",
            )

        return otp