# my_app/services/auth_service.py — thêm full_name vào register()

from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status
from jose import jwt, JWTError
from passlib.context import CryptContext

from config import settings
from models.user import User
from repositories.auth_repository import AuthRepository
from schemas.auth_schema import RegisterRequest, TokenResponse, UserResponse

_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class AuthService:

    def __init__(self, repository: AuthRepository):
        self.repo = repository

    def _hash_password(self, password: str) -> str:
        return _pwd_context.hash(password)

    def _verify_password(self, plain: str, hashed: str) -> bool:
        return _pwd_context.verify(plain, hashed)

    def _create_access_token(self, user_id: int, email: str) -> str:
        expire = datetime.now(timezone.utc) + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )
        return jwt.encode(
            {"sub": str(user_id), "email": email, "exp": expire,
             "iat": datetime.now(timezone.utc)},
            settings.SECRET_KEY, algorithm=settings.ALGORITHM,
        )

    def decode_token(self, token: str) -> dict:
        try:
            return jwt.decode(token, settings.SECRET_KEY,
                              algorithms=[settings.ALGORITHM])
        except JWTError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token không hợp lệ hoặc đã hết hạn.",
                headers={"WWW-Authenticate": "Bearer"},
            )

    def register(self, payload: RegisterRequest) -> TokenResponse:
        # Kiểm tra email trùng
        if self.repo.get_user_by_email(payload.email):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email này đã được đăng ký.",
            )

        # Tạo user — truyền thêm full_name
        new_user = self.repo.create_user(
            email=payload.email,
            hashed_password=self._hash_password(payload.password),
            full_name=payload.full_name,         # ← THÊM
        )

        token = self._create_access_token(new_user.id, new_user.email)
        return TokenResponse(
            access_token=token,
            user=UserResponse.model_validate(new_user),
        )

    def login(self, email: str, password: str) -> TokenResponse:
        user = self.repo.get_user_by_email(email)
        err  = HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                             detail="Email hoặc mật khẩu không đúng.")
        if not user or not self._verify_password(password, user.hashed_password):
            raise err
        if not user.is_active:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                                detail="Tài khoản đã bị vô hiệu hóa.")

        token = self._create_access_token(user.id, user.email)
        return TokenResponse(
            access_token=token,
            user=UserResponse.model_validate(user),
        )