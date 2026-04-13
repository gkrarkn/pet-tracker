from uuid import UUID

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.dependencies import CurrentUser, get_current_user, get_db
from app.schemas.common import MessageResponse
from app.schemas.consultancy import (
    ConsultancyDetailResponse,
    ConsultancyMessageCreateRequest,
    ConsultancyMessageResponse,
    ConsultancyNotifyRequest,
    ConsultancySummaryResponse,
    ConsultancyUpdateRequest,
)
from app.models.entities import User
from app.services.consultancy_service import (
    create_message as create_message_service,
    create_thread as create_thread_service,
    get_consultancy as get_consultancy_service,
    list_consultancies as list_consultancies_service,
    list_messages as list_messages_service,
    send_notification as send_notification_service,
    update_consultancy as update_consultancy_service,
)


router = APIRouter(prefix="/consultancies", tags=["consultancy"])


@router.get("", response_model=list[ConsultancySummaryResponse])
def list_consultancies_route(
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[ConsultancySummaryResponse]:
    consultancies = list_consultancies_service(db, actor_id=current_user.user_id, role=current_user.role)
    return [
        ConsultancySummaryResponse(
            id=consultancy.id,
            stylist_id=consultancy.stylist_id,
            client_id=consultancy.client_id,
            status=consultancy.status,
            client_name=(db.get(User, consultancy.client_id).full_name if db.get(User, consultancy.client_id) else "Unknown Client"),
        )
        for consultancy in consultancies
    ]


@router.get("/{consultancy_id}", response_model=ConsultancyDetailResponse)
def get_consultancy_route(
    consultancy_id: UUID,
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ConsultancyDetailResponse:
    consultancy = get_consultancy_service(db, consultancy_id, actor_id=current_user.user_id, role=current_user.role)
    return ConsultancyDetailResponse(
        id=consultancy.id,
        stylist_id=consultancy.stylist_id,
        client_id=consultancy.client_id,
        status=consultancy.status,
        access_notes=consultancy.access_notes,
        latest_feedback=None,
        wardrobe_item_count=0,
        unread_message_count=0,
    )


@router.patch("/{consultancy_id}", response_model=MessageResponse)
def update_consultancy_route(
    consultancy_id: UUID,
    payload: ConsultancyUpdateRequest,
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    consultancy = get_consultancy_service(db, consultancy_id, actor_id=current_user.user_id, role=current_user.role)
    consultancy = update_consultancy_service(db, consultancy=consultancy, payload=payload)
    return MessageResponse(message=f"Consultancy {consultancy.id} updated to {consultancy.status}.")


@router.post("/{consultancy_id}/thread", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
def create_thread_route(
    consultancy_id: UUID,
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    consultancy = get_consultancy_service(db, consultancy_id, actor_id=current_user.user_id, role=current_user.role)
    thread = create_thread_service(db, consultancy=consultancy)
    return MessageResponse(message=f"Chat thread {thread.id} created for consultancy {consultancy_id}.")


@router.get("/{consultancy_id}/messages", response_model=list[ConsultancyMessageResponse])
def list_messages_route(
    consultancy_id: UUID,
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[ConsultancyMessageResponse]:
    consultancy = get_consultancy_service(db, consultancy_id, actor_id=current_user.user_id, role=current_user.role)
    return [
        ConsultancyMessageResponse(
            id=message.id,
            consultancy_id=consultancy_id,
            sender_user_id=message.sender_user_id,
            body=message.body,
        )
        for message in list_messages_service(db, consultancy=consultancy)
    ]


@router.post("/{consultancy_id}/messages", response_model=ConsultancyMessageResponse, status_code=status.HTTP_201_CREATED)
def create_message_route(
    consultancy_id: UUID,
    payload: ConsultancyMessageCreateRequest,
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ConsultancyMessageResponse:
    consultancy = get_consultancy_service(db, consultancy_id, actor_id=current_user.user_id, role=current_user.role)
    message = create_message_service(
        db,
        consultancy=consultancy,
        sender_user_id=current_user.user_id,
        payload=payload,
    )
    return ConsultancyMessageResponse(
        id=message.id,
        consultancy_id=consultancy_id,
        sender_user_id=current_user.user_id,
        body=message.body,
    )


@router.post("/{consultancy_id}/notify", response_model=MessageResponse)
def send_notification_route(
    consultancy_id: UUID,
    payload: ConsultancyNotifyRequest,
    current_user: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    consultancy = get_consultancy_service(db, consultancy_id, actor_id=current_user.user_id, role=current_user.role)
    notification = send_notification_service(
        db,
        consultancy=consultancy,
        actor_id=current_user.user_id,
        payload=payload,
    )
    return MessageResponse(
        message=f"Notification '{notification.type}' queued for consultancy {consultancy_id} by {current_user.user_id}."
    )
