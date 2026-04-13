from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.dependencies import CurrentUser, get_current_user, get_db
from app.schemas.common import MessageResponse
from app.schemas.wardrobe import (
    CalendarLogRequest,
    CostPerWearResponse,
    ItemProcessResponse,
    UploadTargetRequest,
    UploadTargetResponse,
    WardrobeItemCreateRequest,
    WardrobeItemDetailResponse,
    WardrobeItemListResponse,
    WardrobeItemStatusUpdateRequest,
    WardrobeItemUpdateRequest,
)
from app.services.storage import get_storage_service
from app.services.wardrobe_service import (
    cost_per_wear,
    create_item as create_item_service,
    get_item as get_item_service,
    list_items as list_items_service,
    log_calendar as log_calendar_service,
    update_item as update_item_service,
    update_item_status as update_item_status_service,
)


router = APIRouter(prefix="/wardrobe", tags=["wardrobe"])


@router.post("/upload-url", response_model=UploadTargetResponse)
def create_upload_target(
    payload: UploadTargetRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> UploadTargetResponse:
    target = get_storage_service().create_upload_target(
        user_id=current_user.user_id,
        filename=payload.filename,
        content_type=payload.content_type,
    )
    return UploadTargetResponse(**target.__dict__)


@router.post("/items", response_model=WardrobeItemDetailResponse, status_code=status.HTTP_201_CREATED)
def create_item_route(
    payload: WardrobeItemCreateRequest,
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> WardrobeItemDetailResponse:
    item = create_item_service(
        db,
        actor_id=current_user.user_id,
        client_id=payload.client_id or current_user.user_id,
        payload=payload,
    )
    return WardrobeItemDetailResponse(
        id=item.id,
        client_id=item.client_id,
        image_url=item.image_url,
        original_image_url=item.original_image_url,
        category=item.category,
        brand=item.brand,
        color_hex=item.color_hex,
        seasons=item.seasons,
        styles=item.styles,
        price=float(item.price) if item.price is not None else None,
        status=item.status,
        wear_count=item.wear_count,
        last_worn_date=item.last_worn_date,
        ai_metadata=item.ai_metadata,
        created_at=item.created_at,
    )


@router.post("/items/{item_id}/process", response_model=ItemProcessResponse, status_code=status.HTTP_202_ACCEPTED)
def process_item(item_id: UUID, current_user: CurrentUser = Depends(get_current_user)) -> ItemProcessResponse:
    return ItemProcessResponse(
        item_id=item_id,
        requested_by=current_user.user_id,
        job_id=uuid4(),
        status="queued",
        message="Background removal and AI tagging queued.",
    )


@router.get("/items", response_model=WardrobeItemListResponse)
def list_items_route(
    client_id: UUID | None = Query(default=None),
    status_filter: str | None = Query(default=None, alias="status"),
    category: str | None = Query(default=None),
    brand: str | None = Query(default=None),
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> WardrobeItemListResponse:
    items = list_items_service(
        db,
        actor_id=current_user.user_id,
        role=current_user.role,
        client_id=client_id,
        status_filter=status_filter,
        category=category,
        brand=brand,
    )
    response_items = [
        WardrobeItemDetailResponse(
            id=item.id,
            client_id=item.client_id,
            image_url=item.image_url,
            original_image_url=item.original_image_url,
            category=item.category,
            brand=item.brand,
            color_hex=item.color_hex,
            seasons=item.seasons,
            styles=item.styles,
            price=float(item.price) if item.price is not None else None,
            status=item.status,
            wear_count=item.wear_count,
            last_worn_date=item.last_worn_date,
            ai_metadata=item.ai_metadata,
            created_at=item.created_at,
        )
        for item in items
    ]
    return WardrobeItemListResponse(
        items=response_items,
        total=len(response_items),
        filters={"status": status_filter, "category": category, "brand": brand},
    )


@router.get("/items/{item_id}", response_model=WardrobeItemDetailResponse)
def get_item(
    item_id: UUID,
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> WardrobeItemDetailResponse:
    del current_user
    item = get_item_service(db, item_id=item_id)
    return WardrobeItemDetailResponse(
        id=item.id,
        client_id=item.client_id,
        image_url=item.image_url,
        original_image_url=item.original_image_url,
        category=item.category,
        brand=item.brand,
        color_hex=item.color_hex,
        seasons=item.seasons,
        styles=item.styles,
        price=float(item.price) if item.price is not None else None,
        status=item.status,
        wear_count=item.wear_count,
        last_worn_date=item.last_worn_date,
        ai_metadata=item.ai_metadata,
        created_at=item.created_at,
    )


@router.patch("/items/{item_id}", response_model=WardrobeItemDetailResponse)
def update_item_route(
    item_id: UUID,
    payload: WardrobeItemUpdateRequest,
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> WardrobeItemDetailResponse:
    del current_user
    item = update_item_service(db, item=get_item_service(db, item_id=item_id), payload=payload)
    return WardrobeItemDetailResponse(
        id=item.id,
        client_id=item.client_id,
        image_url=item.image_url,
        original_image_url=item.original_image_url,
        category=item.category,
        brand=item.brand,
        color_hex=item.color_hex,
        seasons=item.seasons,
        styles=item.styles,
        price=float(item.price) if item.price is not None else None,
        status=item.status,
        wear_count=item.wear_count,
        last_worn_date=item.last_worn_date,
        ai_metadata=item.ai_metadata,
        created_at=item.created_at,
    )


@router.patch("/items/{item_id}/status", response_model=MessageResponse)
def update_item_status_route(
    item_id: UUID,
    payload: WardrobeItemStatusUpdateRequest,
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    item = update_item_status_service(
        db,
        actor_id=current_user.user_id,
        item=get_item_service(db, item_id=item_id),
        payload=payload,
    )
    return MessageResponse(message=f"Item {item.id} status updated to {item.status}.")


@router.post("/calendar", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
def log_calendar_route(
    payload: CalendarLogRequest,
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    calendar = log_calendar_service(
        db,
        actor_id=current_user.user_id,
        client_id=current_user.user_id,
        payload=payload,
    )
    return MessageResponse(message=f"Wardrobe usage logged for {calendar.worn_on.isoformat()}.")


@router.get("/analytics/cost-per-wear", response_model=list[CostPerWearResponse])
def get_cost_per_wear(
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[CostPerWearResponse]:
    items = list_items_service(db, actor_id=current_user.user_id, role=current_user.role)
    return [CostPerWearResponse(**row) for row in cost_per_wear(items)]
