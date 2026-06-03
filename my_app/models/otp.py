# my_app/models/otp.py

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean
from sqlalchemy.sql import func

from database import Base


class OTPCode(Base):
    __tablename__ = "otp_codes"

    id = Column(Integer, primary_key=True, autoincrement=True)

    email = Column(
        String(255),
        nullable=False,
        index=True,  # Query nhanh theo email
    )

    code = Column(
        String(6),
        nullable=False,  # Mã OTP 6 số
    )

    is_used = Column(
        Boolean,
        default=False,   # False = chưa dùng, True = đã dùng
        nullable=False,
    )

    expired_at = Column(
        DateTime(timezone=True),
        nullable=False,  # Thời điểm hết hạn (tạo lúc tạo OTP + 5 phút)
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    def __repr__(self):
        return f"<OTPCode email={self.email} code={self.code} used={self.is_used}>"