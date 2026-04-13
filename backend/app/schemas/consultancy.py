from uuid import UUID

from pydantic import BaseModel

from app.models.enums import ConsultancyStatus, NotificationType


class ConsultancySummaryResponse(BaseModel):
    id: UUID
    stylist_id: UUID
    client_id: UUID
    status: ConsultancyStatus
    client_name: str


class ConsultancyDetailResponse(BaseModel):
    id: UUID
    stylist_id: UUID
    client_id: UUID
    status: ConsultancyStatus
    access_notes: str | None = None
    latest_feedback: str | None = None
    wardrobe_item_count: int
    unread_message_count: int


class ConsultancyUpdateRequest(BaseModel):
    status: ConsultancyStatus
    access_notes: str | None = None


class ConsultancyMessageCreateRequest(BaseModel):
    body: str
    related_outfit_id: UUID | None = None
    related_wardrobe_item_id: UUID | None = None


class ConsultancyMessageResponse(BaseModel):
    id: UUID
    consultancy_id: UUID
    sender_user_id: UUID
    body: str


class ConsultancyNotifyRequest(BaseModel):
    type: NotificationType
    title: str
    body: str
