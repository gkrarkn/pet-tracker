from collections.abc import Generator
from uuid import UUID

from fastapi import Depends, Header, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db import SessionLocal
from app.models.entities import User
from app.models.enums import AppUserRole
from app.security import decode_token


class CurrentUser(BaseModel):
    user_id: UUID
    role: AppUserRole


bearer_scheme = HTTPBearer(auto_error=False)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
    x_user_id: str | None = Header(default=None),
    x_user_role: str | None = Header(default=None),
) -> CurrentUser:
    if credentials:
        try:
            payload = decode_token(credentials.credentials)
            user_id = UUID(str(payload["sub"]))
            user = db.get(User, user_id)
            if not user:
                raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found.")
            db.execute(text("SELECT 1"))
            return CurrentUser(user_id=user.id, role=user.role)
        except Exception as exc:  # pragma: no cover - defensive auth boundary
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid bearer token.",
            ) from exc

    if not x_user_id or not x_user_role:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing X-User-Id or X-User-Role header.",
        )

    try:
        user = db.get(User, UUID(x_user_id))
        if user:
            return CurrentUser(user_id=user.id, role=user.role)
        return CurrentUser(user_id=UUID(x_user_id), role=AppUserRole(x_user_role))
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication headers.",
        ) from exc


def require_stylist(user: CurrentUser = Depends(get_current_user)) -> CurrentUser:
    if user.role != AppUserRole.STYLIST:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Stylist role required.",
        )
    return user


def require_client(user: CurrentUser = Depends(get_current_user)) -> CurrentUser:
    if user.role != AppUserRole.CLIENT:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Client role required.",
        )
    return user
