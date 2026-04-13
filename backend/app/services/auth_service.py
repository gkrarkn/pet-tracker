from datetime import datetime, timezone
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.entities import AuthCredential, ClientProfile, Consultancy, StylistInvite, StylistProfile, User
from app.models.enums import ConsultancyStatus, InviteStatus, SubscriptionStatus
from app.schemas.auth import LoginRequest, RegisterClientRequest, RegisterStylistRequest, TokenPairResponse
from app.security import create_access_token, create_refresh_token, hash_password, verify_password


def _token_pair(user: User) -> TokenPairResponse:
    return TokenPairResponse(
        access_token=create_access_token(str(user.id), user.role.value),
        refresh_token=create_refresh_token(str(user.id)),
        token_type="bearer",
        expires_in=3600,
    )


def register_stylist(db: Session, payload: RegisterStylistRequest) -> tuple[User, TokenPairResponse]:
    existing = db.scalar(select(User).where(User.email == payload.email))
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered.")

    user = User(
        email=str(payload.email),
        full_name=payload.full_name,
        role="stylist",
        subscription_status=SubscriptionStatus.TRIAL,
    )
    db.add(user)
    db.flush()

    db.add(
        StylistProfile(
            user_id=user.id,
            business_name=payload.business_name,
            max_clients=10,
        )
    )
    db.add(AuthCredential(user_id=user.id, password_hash=hash_password(payload.password)))
    db.commit()
    db.refresh(user)
    return user, _token_pair(user)


def register_client(db: Session, payload: RegisterClientRequest) -> tuple[User, TokenPairResponse]:
    existing = db.scalar(select(User).where(User.email == payload.email))
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered.")

    invite = db.scalar(
        select(StylistInvite).where(
            StylistInvite.invite_code == payload.invite_code,
            StylistInvite.status == InviteStatus.PENDING,
        )
    )
    if not invite:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invite not found or expired.")

    user = User(
        email=str(payload.email),
        full_name=payload.full_name,
        role="client",
        subscription_status=SubscriptionStatus.TRIAL,
    )
    db.add(user)
    db.flush()

    db.add(ClientProfile(user_id=user.id))
    db.add(AuthCredential(user_id=user.id, password_hash=hash_password(payload.password)))

    consultancy = db.scalar(
        select(Consultancy).where(
            Consultancy.stylist_id == invite.stylist_id,
            Consultancy.client_id == user.id,
        )
    )
    if not consultancy:
        consultancy = Consultancy(
            stylist_id=invite.stylist_id,
            client_id=user.id,
            status=ConsultancyStatus.ACTIVE,
            started_at=datetime.now(timezone.utc),
        )
        db.add(consultancy)

    invite.accepted_by_client_id = user.id
    invite.status = InviteStatus.ACCEPTED
    db.commit()
    db.refresh(user)
    return user, _token_pair(user)


def login_user(db: Session, payload: LoginRequest) -> tuple[User, TokenPairResponse]:
    user = db.scalar(select(User).where(User.email == payload.email))
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials.")

    creds = db.scalar(select(AuthCredential).where(AuthCredential.user_id == user.id))
    if not creds or not verify_password(payload.password, creds.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials.")

    creds.last_login_at = datetime.now(timezone.utc)
    db.commit()
    return user, _token_pair(user)


def refresh_user_token(db: Session, user_id: UUID) -> tuple[User, TokenPairResponse]:
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")
    return user, _token_pair(user)
