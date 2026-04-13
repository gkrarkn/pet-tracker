from datetime import datetime, timedelta, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.dependencies import CurrentUser, get_current_user, get_db, require_stylist
from app.models.entities import Consultancy, StylistInvite, User
from app.models.enums import ConsultancyStatus, InviteStatus
from app.schemas.auth import (
    AcceptInviteRequest,
    AuthMeResponse,
    CreateInviteRequest,
    InviteResponse,
    LoginRequest,
    RegisterClientRequest,
    RegisterStylistRequest,
    TokenPairResponse,
)
from app.services.auth_service import login_user, refresh_user_token, register_client, register_stylist
from app.security import decode_token


router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register/client", response_model=TokenPairResponse, status_code=status.HTTP_201_CREATED)
def register_client_route(payload: RegisterClientRequest, db: Session = Depends(get_db)) -> TokenPairResponse:
    _, tokens = register_client(db, payload)
    return tokens


@router.post("/register/stylist", response_model=TokenPairResponse, status_code=status.HTTP_201_CREATED)
def register_stylist_route(payload: RegisterStylistRequest, db: Session = Depends(get_db)) -> TokenPairResponse:
    _, tokens = register_stylist(db, payload)
    return tokens


@router.post("/login", response_model=TokenPairResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> TokenPairResponse:
    _, tokens = login_user(db, payload)
    return tokens


@router.post("/refresh", response_model=TokenPairResponse)
def refresh_token(refresh_token: str, db: Session = Depends(get_db)) -> TokenPairResponse:
    payload = decode_token(refresh_token)
    _, tokens = refresh_user_token(db, payload["sub"])
    return tokens


@router.get("/me", response_model=AuthMeResponse)
def get_me(current_user: CurrentUser = Depends(get_current_user), db: Session = Depends(get_db)) -> AuthMeResponse:
    user = db.get(User, current_user.user_id)
    active_consultancy_count = db.query(Consultancy).filter(
        ((Consultancy.stylist_id == current_user.user_id) | (Consultancy.client_id == current_user.user_id)),
        Consultancy.status == ConsultancyStatus.ACTIVE,
    ).count()
    return AuthMeResponse(
        user_id=user.id,
        role=user.role,
        email=user.email,
        full_name=user.full_name,
        subscription_status=user.subscription_status,
        onboarding_completed=bool(user.client_profile or user.stylist_profile),
        active_consultancy_count=active_consultancy_count,
    )


@router.post("/invites", response_model=InviteResponse, status_code=status.HTTP_201_CREATED)
def create_invite(
    payload: CreateInviteRequest,
    current_user: CurrentUser = Depends(require_stylist),
    db: Session = Depends(get_db),
) -> InviteResponse:
    invite_code = uuid4().hex[:10]
    invite = StylistInvite(
        stylist_id=current_user.user_id,
        invite_code=invite_code,
        invite_url=f"{str(payload.base_url).rstrip('/')}/invite/{invite_code}",
        expires_at=datetime.now(timezone.utc) + timedelta(days=7),
    )
    db.add(invite)
    db.commit()
    return InviteResponse(
        invite_code=invite_code,
        invite_url=invite.invite_url,
        status="pending",
    )


@router.post("/invites/{invite_code}/accept", response_model=InviteResponse)
def accept_invite(invite_code: str, payload: AcceptInviteRequest, db: Session = Depends(get_db)) -> InviteResponse:
    invite = db.query(StylistInvite).filter(StylistInvite.invite_code == invite_code).first()
    if invite:
        invite.status = InviteStatus.ACCEPTED
        db.commit()
    return InviteResponse(
        invite_code=invite_code,
        invite_url=f"{str(payload.base_url).rstrip('/')}/invite/{invite_code}",
        status="accepted",
    )
