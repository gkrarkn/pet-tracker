from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, HttpUrl

from app.models.enums import FeedbackSentiment, OutfitStatus


class OutfitCreateRequest(BaseModel):
    client_id: UUID
    title: str
    status: OutfitStatus = OutfitStatus.DRAFT
    occasion: str | None = None
    suggested_for_date: date | None = None
    cover_image_url: HttpUrl | None = None
    notes: str | None = None


class OutfitItemInput(BaseModel):
    wardrobe_item_id: UUID
    slot_label: str | None = None
    layer_order: int = 0


class OutfitItemAttachRequest(BaseModel):
    items: list[OutfitItemInput]


class OutfitUpdateRequest(BaseModel):
    title: str | None = None
    status: OutfitStatus | None = None
    occasion: str | None = None
    suggested_for_date: date | None = None
    cover_image_url: HttpUrl | None = None
    notes: str | None = None


class DailyPickRequest(BaseModel):
    suggestion_date: date


class OutfitFeedbackRequest(BaseModel):
    sentiment: FeedbackSentiment
    feedback_note: str | None = None


class OutfitSuggestionRequest(BaseModel):
    client_id: UUID
    city: str
    event_type: str
    temperature_c: float | None = None


class OutfitItemResponse(BaseModel):
    wardrobe_item_id: UUID
    slot_label: str | None = None
    layer_order: int = 0


class OutfitDetailResponse(BaseModel):
    id: UUID
    client_id: UUID
    stylist_id: UUID | None = None
    title: str
    status: OutfitStatus | str
    occasion: str | None = None
    suggested_for_date: date | None = None
    cover_image_url: HttpUrl | None = None
    notes: str | None = None
    items: list[OutfitItemResponse]
    created_at: datetime


class OutfitSuggestionEntry(BaseModel):
    title: str
    reason: str
    wardrobe_item_ids: list[UUID]


class OutfitSuggestionResponse(BaseModel):
    client_id: UUID
    requested_by: UUID
    weather_summary: str
    suggestions: list[OutfitSuggestionEntry]
