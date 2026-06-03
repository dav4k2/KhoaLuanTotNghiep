# main.py

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import settings
from database import Base, engine
from routers import auth_router, forgot_password_router, community_router, conversation_router, notification_router

# Import models để SQLAlchemy tạo bảng
from models import user, otp, community, conversation, notification                      # ← đổi community_model → community

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.APP_NAME,
    debug=settings.DEBUG,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router.router)
app.include_router(forgot_password_router.router)
app.include_router(community_router.router)
app.include_router(conversation_router.router)
app.include_router(notification_router.router)

@app.get("/", tags=["Health"])
def health_check():
    return {"status": "ok", "app": settings.APP_NAME}