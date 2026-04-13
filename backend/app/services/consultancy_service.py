from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.models.entities import ChatMessage, ChatThread, Consultancy, Notification
from app.models.enums import AppUserRole
from app.schemas.consultancy import ConsultancyMessageCreateRequest, ConsultancyNotifyRequest, ConsultancyUpdateRequest


def list_consultancies(db: Session, *, actor_id: UUID, role: AppUserRole) -> list[Consultancy]:
    query = select(Consultancy)
    if role == AppUserRole.STYLIST:
        query = query.where(Consultancy.stylist_id == actor_id)
    else:
        query = query.where(Consultancy.client_id == actor_id)
    return list(db.scalars(query.order_by(Consultancy.created_at.desc())).all())


def get_consultancy(db: Session, consultancy_id: UUID, *, actor_id: UUID, role: AppUserRole) -> Consultancy:
    consultancy = db.get(Consultancy, consultancy_id)
    if not consultancy:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Consultancy not found.")
    if role == AppUserRole.STYLIST and consultancy.stylist_id != actor_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden.")
    if role == AppUserRole.CLIENT and consultancy.client_id != actor_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden.")
    return consultancy


def update_consultancy(db: Session, *, consultancy: Consultancy, payload: ConsultancyUpdateRequest) -> Consultancy:
    consultancy.status = payload.status
    consultancy.access_notes = payload.access_notes
    db.commit()
    db.refresh(consultancy)
    return consultancy


def create_thread(db: Session, *, consultancy: Consultancy) -> ChatThread:
    existing = db.scalar(select(ChatThread).where(ChatThread.consultancy_id == consultancy.id))
    if existing:
        return existing
    thread = ChatThread(
        consultancy_id=consultancy.id,
        stylist_id=consultancy.stylist_id,
        client_id=consultancy.client_id,
    )
    db.add(thread)
    db.commit()
    db.refresh(thread)
    return thread


def list_messages(db: Session, *, consultancy: Consultancy) -> list[ChatMessage]:
    return list(
        db.scalars(
            select(ChatMessage)
            .join(ChatThread, ChatThread.id == ChatMessage.thread_id)
            .where(ChatThread.consultancy_id == consultancy.id)
            .order_by(ChatMessage.created_at.asc())
        ).all()
    )


def create_message(
    db: Session,
    *,
    consultancy: Consultancy,
    sender_user_id: UUID,
    payload: ConsultancyMessageCreateRequest,
) -> ChatMessage:
    thread = create_thread(db, consultancy=consultancy)
    message = ChatMessage(
        thread_id=thread.id,
        sender_user_id=sender_user_id,
        related_outfit_id=payload.related_outfit_id,
        related_wardrobe_item_id=payload.related_wardrobe_item_id,
        body=payload.body,
    )
    thread.last_message_at = message.created_at
    db.add(message)
    db.commit()
    db.refresh(message)
    return message


def send_notification(
    db: Session,
    *,
    consultancy: Consultancy,
    actor_id: UUID,
    payload: ConsultancyNotifyRequest,
) -> Notification:
    recipient_id = consultancy.client_id if actor_id == consultancy.stylist_id else consultancy.stylist_id
    notification = Notification(
        user_id=recipient_id,
        type=payload.type,
        title=payload.title,
        body=payload.body,
        related_entity_type="consultancy",
        related_entity_id=consultancy.id,
    )
    db.add(notification)
    db.commit()
    db.refresh(notification)
    return notification
