# my_app/repositories/auth_repository.py — thêm full_name vào create_user()

from typing import Optional
from sqlalchemy.orm import Session
from models.user import User


class AuthRepository:

    def __init__(self, db: Session):
        self.db = db

    def get_user_by_email(self, email: str) -> Optional[User]:
        return self.db.query(User).filter(User.email == email).first()

    def get_user_by_id(self, user_id: int) -> Optional[User]:
        return self.db.query(User).filter(User.id == user_id).first()

    def create_user(self, email: str, hashed_password: str,
                    full_name: Optional[str] = None) -> User:   # ← THÊM full_name
        new_user = User(
            email=email,
            hashed_password=hashed_password,
            full_name=full_name,                                 # ← THÊM
        )
        self.db.add(new_user)
        self.db.commit()
        self.db.refresh(new_user)
        return new_user

    def update_user_password(self, user: User, hashed_password: str) -> User:
        user.hashed_password = hashed_password
        self.db.commit()
        self.db.refresh(user)
        return user