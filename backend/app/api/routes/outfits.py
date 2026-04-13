from datetime import date
from uuid import UUID

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.dependencies import CurrentUser, get_current_user, get_db
from app.schemas.common import MessageResponse
from app.schemas.outfits import (
    DailyPickRequest,
    OutfitCreateRequest,
    OutfitDetailResponse,
    OutfitFeedbackRequest,
    OutfitItemAttachRequest,
    OutfitSuggestionRequest,
    OutfitSuggestionResponse,
    OutfitUpdateRequest,
)
from app.services.outfit_service import (
    attach_items as attach_items_service,
    create_feedback as create_feedback_service,
    create_outfit as create_outfit_service,
    get_outfit as get_outfit_service,
    list_outfits as list_outfits_service,
    mark_daily_pick as mark_daily_pick_service,
    suggest_outfits as suggest_outfits_service,
    update_outfit as update_outfit_service,
)


router = APIRouter(prefix="/outfits", tags=["outfits"])


@router.post("", response_model=OutfitDetailResponse, status_code=status.HTTP_201_CREATED)
def create_outfit_route(
    payload: OutfitCreateRequest,
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> OutfitDetailResponse:
    outfit = create_outfit_service(
        db,
        stylist_id=current_user.user_id if current_user.role == "stylist" else None,
        payload=payload,
    )
    return OutfitDetailResponse(
        id=outfit.id,
        client_id=outfit.client_id,
        stylist_id=outfit.stylist_id,
        title=outfit.title,
        status=outfit.status,
        occasion=outfit.occasion,
        suggested_for_date=outfit.suggested_for_date,
        cover_image_url=outfit.cover_image_url,
        notes=outfit.notes,
        items=[],
        created_at=outfit.created_at,
    )


@router.post("/{outfit_id}/items", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
def attach_outfit_items(
    outfit_id: UUID,
    payload: OutfitItemAttachRequest,
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    del current_user
    count = attach_items_service(db, outfit_id=outfit_id, payload=payload)
    return MessageResponse(message=f"{count} items attached to outfit {outfit_id}.")


@router.patch("/{outfit_id}", response_model=OutfitDetailResponse)
def update_outfit_route(
    outfit_id: UUID,
    payload: OutfitUpdateRequest,
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> OutfitDetailResponse:
    del current_user
    outfit = update_outfit_service(db, outfit=get_outfit_service(db, outfit_id), payload=payload)
    return OutfitDetailResponse(
        id=outfit.id,
        client_id=outfit.client_id,
        stylist_id=outfit.stylist_id,
        title=outfit.title,
        status=outfit.status,
        occasion=outfit.occasion,
        suggested_for_date=outfit.suggested_for_date,
        cover_image_url=outfit.cover_image_url,
        notes=outfit.notes,
        items=[],
        created_at=outfit.created_at,
    )


@router.post("/{outfit_id}/daily-pick", response_model=MessageResponse)
def mark_daily_pick_route(
    outfit_id: UUID,
    payload: DailyPickRequest,
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    outfit = get_outfit_service(db, outfit_id)
    mark_daily_pick_service(db, actor_id=current_user.user_id, outfit=outfit, payload=payload)
    return MessageResponse(
        message=f"Outfit {outfit_id} marked as daily pick for {payload.suggestion_date.isoformat()} by {current_user.user_id}."
    )


@router.get("", response_model=list[OutfitDetailResponse])
def list_outfits_route(
    client_id: UUID | None = Query(default=None),
    status_filter: str | None = Query(default=None, alias="status"),
    suggested_for_date: date | None = Query(default=None),
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[OutfitDetailResponse]:
    del suggested_for_date
    outfits = list_outfits_service(
        db,
        actor_id=current_user.user_id,
        role=current_user.role,
        client_id=client_id,
        status_filter=status_filter,
    )
    return [
        OutfitDetailResponse(
            id=outfit.id,
            client_id=outfit.client_id,
            stylist_id=outfit.stylist_id,
            title=outfit.title,
            status=outfit.status,
            occasion=outfit.occasion,
            suggested_for_date=outfit.suggested_for_date,
            cover_image_url=outfit.cover_image_url,
            notes=outfit.notes,
            items=[],
            created_at=outfit.created_at,
        )
        for outfit in outfits
    ]


@router.get("/{outfit_id}", response_model=OutfitDetailResponse)
def get_outfit_route(
    outfit_id: UUID,
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> OutfitDetailResponse:
    del current_user
    outfit = get_outfit_service(db, outfit_id)
    return OutfitDetailResponse(
        id=outfit.id,
        client_id=outfit.client_id,
        stylist_id=outfit.stylist_id,
        title=outfit.title,
        status=outfit.status,
        occasion=outfit.occasion,
        suggested_for_date=outfit.suggested_for_date,
        cover_image_url=outfit.cover_image_url,
        notes=outfit.notes,
        items=[],
        created_at=outfit.created_at,
    )


@router.post("/{outfit_id}/feedback", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
def create_feedback_route(
    outfit_id: UUID,
    payload: OutfitFeedbackRequest,
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    create_feedback_service(db, actor_id=current_user.user_id, outfit_id=outfit_id, payload=payload)
    return MessageResponse(
        message=f"Feedback '{payload.sentiment}' saved for outfit {outfit_id} by {current_user.user_id}."
    )


@router.post("/suggest", response_model=OutfitSuggestionResponse)
def suggest_outfits_route(
    payload: OutfitSuggestionRequest,
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> OutfitSuggestionResponse:
    suggestions = suggest_outfits_service(db, payload)
    return OutfitSuggestionResponse(
        client_id=payload.client_id,
        requested_by=current_user.user_id,
        weather_summary=f"{payload.city} {payload.event_type}",
        suggestions=suggestions,
    )
