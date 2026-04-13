from uuid import UUID

from pydantic import BaseModel, EmailStr, HttpUrl

from app.models.enums import AppUserRole, InviteStatus, SubscriptionStatus


class RegisterClientRequest(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    invite_code: str


class RegisterStylistRequest(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    business_name: str | None = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenPairResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str
    expires_in: int


class AuthMeResponse(BaseModel):
    user_id: UUID
    role: AppUserRole
    email: EmailStr
    full_name: str
    subscription_status: SubscriptionStatus
    onboarding_completed: bool
    active_consultancy_count: int


class CreateInviteRequest(BaseModel):
    base_url: HttpUrl


class AcceptInviteRequest(BaseModel):
    base_url: HttpUrl


class InviteResponse(BaseModel):
    invite_code: str
    invite_url: HttpUrl
    status: InviteStatus
