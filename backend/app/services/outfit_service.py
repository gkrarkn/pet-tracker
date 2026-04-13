from datetime import datetime, timezone
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.entities import DailyOutfitSuggestion, Notification, Outfit, OutfitFeedback, OutfitItem, WardrobeItem
from app.models.enums import AppUserRole, NotificationType
from app.schemas.outfits import DailyPickRequest, OutfitCreateRequest, OutfitFeedbackRequest, OutfitItemAttachRequest, OutfitSuggestionRequest, OutfitUpdateRequest


def create_outfit(db: Session, *, stylist_id: UUID | None, payload: OutfitCreateRequest) -> Outfit:
    outfit = Outfit(
        client_id=payload.client_id,
        stylist_id=stylist_id,
        title=payload.title,
        status=payload.status,
        occasion=payload.occasion,
        suggested_for_date=payload.suggested_for_date,
        cover_image_url=str(payload.cover_image_url) if payload.cover_image_url else None,
        notes=payload.notes,
    )
    db.add(outfit)
    db.commit()
    return get_outfit(db, outfit.id)


def get_outfit(db: Session, outfit_id: UUID) -> Outfit:
    outfit = db.scalar(
        select(Outfit)
        .options(selectinload(Outfit.items))
        .where(Outfit.id == outfit_id)
    )
    if not outfit:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Outfit not found.")
    return outfit


def list_outfits(
    db: Session,
    *,
    actor_id: UUID,
    role: AppUserRole,
    client_id: UUID | None,
    status_filter: str | None,
) -> list[Outfit]:
    query = select(Outfit).options(selectinload(Outfit.items))
    if role == AppUserRole.CLIENT:
        query = query.where(Outfit.client_id == actor_id)
    elif client_id:
        query = query.where(Outfit.client_id == client_id)
    if status_filter:
        query = query.where(Outfit.status == status_filter)
    return list(db.scalars(query.order_by(Outfit.created_at.desc())).all())


def attach_items(db: Session, *, outfit_id: UUID, payload: OutfitItemAttachRequest) -> int:
    for item in payload.items:
        existing = db.get(OutfitItem, {"outfit_id": outfit_id, "wardrobe_item_id": item.wardrobe_item_id})
        if existing:
            existing.slot_label = item.slot_label
            existing.layer_order = item.layer_order
            continue
        db.add(
            OutfitItem(
                outfit_id=outfit_id,
                wardrobe_item_id=item.wardrobe_item_id,
                slot_label=item.slot_label,
                layer_order=item.layer_order,
            )
        )
    db.commit()
    return len(payload.items)


def update_outfit(db: Session, *, outfit: Outfit, payload: OutfitUpdateRequest) -> Outfit:
    data = payload.model_dump(exclude_unset=True)
    for key, value in data.items():
        if key == "cover_image_url" and value is not None:
            value = str(value)
        setattr(outfit, key, value)
    db.commit()
    return get_outfit(db, outfit.id)


def mark_daily_pick(db: Session, *, actor_id: UUID, outfit: Outfit, payload: DailyPickRequest) -> DailyOutfitSuggestion:
    suggestion = DailyOutfitSuggestion(
        outfit_id=outfit.id,
        client_id=outfit.client_id,
        stylist_id=actor_id,
        suggestion_date=payload.suggestion_date,
    )
    db.add(suggestion)
    db.add(
        Notification(
            user_id=outfit.client_id,
            type=NotificationType.OUTFIT_SUGGESTION,
            title="New daily outfit",
            body=f"{outfit.title} was selected for today.",
            related_entity_type="outfit",
            related_entity_id=outfit.id,
        )
    )
    outfit.is_stylist_selected_daily_pick = True
    db.commit()
    db.refresh(suggestion)
    return suggestion


def create_feedback(db: Session, *, actor_id: UUID, outfit_id: UUID, payload: OutfitFeedbackRequest) -> OutfitFeedback:
    feedback = OutfitFeedback(
        outfit_id=outfit_id,
        client_id=actor_id,
        sentiment=payload.sentiment,
        feedback_note=payload.feedback_note,
    )
    db.add(feedback)
    db.commit()
    db.refresh(feedback)
    return feedback


def suggest_outfits(db: Session, payload: OutfitSuggestionRequest) -> list[dict]:
    items = list(
        db.scalars(
            select(WardrobeItem)
            .where(
                WardrobeItem.client_id == payload.client_id,
                WardrobeItem.status == "active",
            )
            .order_by(WardrobeItem.wear_count.asc(), WardrobeItem.created_at.desc())
        ).all()
    )

    chunks = [items[i:i + 3] for i in range(0, min(len(items), 9), 3)]
    suggestions: list[dict] = []
    for index, chunk in enumerate(chunks, start=1):
        suggestions.append(
            {
                "title": f"Look {index}",
                "reason": f"{payload.city} icin {payload.event_type} baglaminda secildi.",
                "wardrobe_item_ids": [item.id for item in chunk],
            }
        )
    return suggestions
