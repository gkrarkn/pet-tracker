from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field, HttpUrl

from app.models.enums import SeasonTag, StyleTag, WardrobeItemStatus


class UploadTargetRequest(BaseModel):
    filename: str
    content_type: str
    provider: str = "s3"


class UploadTargetResponse(BaseModel):
    provider: str
    upload_url: HttpUrl
    public_url: HttpUrl
    method: str
    fields: dict[str, str]
    storage_key: str


class WardrobeItemCreateRequest(BaseModel):
    client_id: UUID | None = None
    image_url: HttpUrl
    original_image_url: HttpUrl | None = None
    category: str | None = None
    brand: str | None = None
    color_hex: str | None = None
    seasons: list[SeasonTag] = Field(default_factory=lambda: [SeasonTag.ALL_SEASON])
    styles: list[StyleTag] = Field(default_factory=lambda: [StyleTag.CASUAL])
    price: float | None = None
    ai_metadata: dict = Field(default_factory=dict)


class WardrobeItemUpdateRequest(BaseModel):
    image_url: HttpUrl | None = None
    original_image_url: HttpUrl | None = None
    category: str | None = None
    brand: str | None = None
    color_hex: str | None = None
    seasons: list[SeasonTag] | None = None
    styles: list[StyleTag] | None = None
    price: float | None = None
    ai_metadata: dict | None = None


class WardrobeItemStatusUpdateRequest(BaseModel):
    status: WardrobeItemStatus
    reason: str | None = None


class WardrobeItemDetailResponse(BaseModel):
    id: UUID
    client_id: UUID
    image_url: HttpUrl
    original_image_url: HttpUrl | None = None
    category: str
    brand: str | None = None
    color_hex: str | None = None
    seasons: list[SeasonTag | str]
    styles: list[StyleTag | str]
    price: float | None = None
    status: WardrobeItemStatus | str
    wear_count: int
    last_worn_date: date | None = None
    ai_metadata: dict
    created_at: datetime


class WardrobeItemListResponse(BaseModel):
    items: list[WardrobeItemDetailResponse]
    total: int
    filters: dict[str, str | None]


class ItemProcessResponse(BaseModel):
    item_id: UUID
    requested_by: UUID
    job_id: UUID
    status: str
    message: str


class CalendarLogRequest(BaseModel):
    worn_on: date
    outfit_id: UUID | None = None
    wardrobe_item_ids: list[UUID]
    note: str | None = None


class CostPerWearResponse(BaseModel):
    item_id: UUID
    client_id: UUID
    category: str
    brand: str | None = None
    price: float | None = None
    currency_code: str
    wear_count: int
    last_worn_date: date | None = None
    cost_per_wear: float | None = None
