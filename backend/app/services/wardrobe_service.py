from datetime import datetime, timezone
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import Select, select
from sqlalchemy.orm import Session

from app.models.entities import WardrobeCalendar, WardrobeCalendarItem, WardrobeItem, WardrobeItemStatusHistory
from app.models.enums import AppUserRole
from app.schemas.wardrobe import CalendarLogRequest, WardrobeItemCreateRequest, WardrobeItemStatusUpdateRequest, WardrobeItemUpdateRequest


def _base_query_for_user(user_id: UUID, role: AppUserRole) -> Select[tuple[WardrobeItem]]:
    query = select(WardrobeItem)
    if role == AppUserRole.CLIENT:
        query = query.where(WardrobeItem.client_id == user_id)
    return query


def create_item(db: Session, *, actor_id: UUID, client_id: UUID, payload: WardrobeItemCreateRequest) -> WardrobeItem:
    item = WardrobeItem(
        client_id=client_id,
        created_by_user_id=actor_id,
        image_url=str(payload.image_url),
        original_image_url=str(payload.original_image_url) if payload.original_image_url else None,
        category=payload.category or "unclassified",
        brand=payload.brand,
        color_hex=payload.color_hex,
        seasons=payload.seasons,
        styles=payload.styles,
        price=payload.price,
        ai_metadata=payload.ai_metadata,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def list_items(
    db: Session,
    *,
    actor_id: UUID,
    role: AppUserRole,
    client_id: UUID | None = None,
    status_filter: str | None = None,
    category: str | None = None,
    brand: str | None = None,
) -> list[WardrobeItem]:
    query = _base_query_for_user(actor_id, role)
    if role == AppUserRole.STYLIST and client_id:
        query = query.where(WardrobeItem.client_id == client_id)
    if status_filter:
        query = query.where(WardrobeItem.status == status_filter)
    if category:
        query = query.where(WardrobeItem.category == category)
    if brand:
        query = query.where(WardrobeItem.brand == brand)
    return list(db.scalars(query.order_by(WardrobeItem.created_at.desc())).all())


def get_item(db: Session, *, item_id: UUID) -> WardrobeItem:
    item = db.get(WardrobeItem, item_id)
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Wardrobe item not found.")
    return item


def update_item(db: Session, *, item: WardrobeItem, payload: WardrobeItemUpdateRequest) -> WardrobeItem:
    update_data = payload.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if key in {"image_url", "original_image_url"} and value is not None:
            value = str(value)
        setattr(item, key, value)
    db.commit()
    db.refresh(item)
    return item


def update_item_status(
    db: Session,
    *,
    actor_id: UUID,
    item: WardrobeItem,
    payload: WardrobeItemStatusUpdateRequest,
) -> WardrobeItem:
    previous_status = item.status
    item.status = payload.status
    db.add(
        WardrobeItemStatusHistory(
            wardrobe_item_id=item.id,
            changed_by_user_id=actor_id,
            old_status=previous_status,
            new_status=payload.status,
            reason=payload.reason,
        )
    )
    db.commit()
    db.refresh(item)
    return item


def log_calendar(db: Session, *, actor_id: UUID, client_id: UUID, payload: CalendarLogRequest) -> WardrobeCalendar:
    calendar = WardrobeCalendar(
        client_id=client_id,
        outfit_id=payload.outfit_id,
        worn_on=payload.worn_on,
        marked_by_user_id=actor_id,
        note=payload.note,
    )
    db.add(calendar)
    db.flush()

    for item_id in payload.wardrobe_item_ids:
        db.add(WardrobeCalendarItem(calendar_id=calendar.id, wardrobe_item_id=item_id))

    db.commit()
    db.refresh(calendar)
    return calendar


def cost_per_wear(items: list[WardrobeItem]) -> list[dict]:
    results: list[dict] = []
    for item in items:
        cost = None
        if item.price is not None and item.wear_count:
            cost = round(float(item.price) / item.wear_count, 2)
        results.append(
            {
                "item_id": item.id,
                "client_id": item.client_id,
                "category": item.category,
                "brand": item.brand,
                "price": float(item.price) if item.price is not None else None,
                "currency_code": item.currency_code,
                "wear_count": item.wear_count,
                "last_worn_date": item.last_worn_date,
                "cost_per_wear": cost,
            }
        )
    return results
