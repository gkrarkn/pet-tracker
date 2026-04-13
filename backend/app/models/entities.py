from __future__ import annotations

import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Any

from sqlalchemy import (
    JSON,
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import ARRAY, CITEXT, JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin
from app.models.enums import (
    AppUserRole,
    ConsultancyStatus,
    FeedbackSentiment,
    InviteStatus,
    ItemConditionStatus,
    NotificationType,
    OutfitStatus,
    SeasonTag,
    StyleTag,
    SubscriptionStatus,
    TravelPurpose,
    WardrobeItemStatus,
)


class User(TimestampMixin, Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    auth_user_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), unique=True)
    email: Mapped[str] = mapped_column(CITEXT(), unique=True, nullable=False)
    full_name: Mapped[str] = mapped_column(Text, nullable=False)
    role: Mapped[AppUserRole] = mapped_column(Enum(AppUserRole, name="app_user_role"), nullable=False)
    subscription_status: Mapped[SubscriptionStatus] = mapped_column(
        Enum(SubscriptionStatus, name="subscription_status"),
        nullable=False,
        default=SubscriptionStatus.TRIAL,
        server_default=SubscriptionStatus.TRIAL.value,
    )
    timezone: Mapped[str] = mapped_column(Text, nullable=False, default="UTC", server_default="UTC")
    avatar_url: Mapped[str | None] = mapped_column(Text)
    push_token: Mapped[str | None] = mapped_column(Text)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True, server_default="true")

    auth_credential: Mapped[AuthCredential | None] = relationship(back_populates="user", uselist=False)
    stylist_profile: Mapped[StylistProfile | None] = relationship(back_populates="user", uselist=False)
    client_profile: Mapped[ClientProfile | None] = relationship(back_populates="user", uselist=False)
    stylist_consultancies: Mapped[list[Consultancy]] = relationship(
        back_populates="stylist", foreign_keys="Consultancy.stylist_id"
    )
    client_consultancies: Mapped[list[Consultancy]] = relationship(
        back_populates="client", foreign_keys="Consultancy.client_id"
    )
    wardrobe_items: Mapped[list[WardrobeItem]] = relationship(
        back_populates="client", foreign_keys="WardrobeItem.client_id"
    )
    created_items: Mapped[list[WardrobeItem]] = relationship(
        back_populates="created_by", foreign_keys="WardrobeItem.created_by_user_id"
    )
    styled_outfits: Mapped[list[Outfit]] = relationship(back_populates="stylist", foreign_keys="Outfit.stylist_id")
    client_outfits: Mapped[list[Outfit]] = relationship(back_populates="client", foreign_keys="Outfit.client_id")


class StylistProfile(TimestampMixin, Base):
    __tablename__ = "stylist_profiles"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    business_name: Mapped[str | None] = mapped_column(Text)
    bio: Mapped[str | None] = mapped_column(Text)
    qr_invite_slug: Mapped[str | None] = mapped_column(Text, unique=True)
    stripe_customer_id: Mapped[str | None] = mapped_column(Text, unique=True)
    stripe_subscription_id: Mapped[str | None] = mapped_column(Text, unique=True)
    subscription_tier: Mapped[str | None] = mapped_column(Text)
    max_clients: Mapped[int] = mapped_column(Integer, nullable=False, default=10, server_default="10")
    affiliate_code: Mapped[str | None] = mapped_column(Text)

    user: Mapped[User] = relationship(back_populates="stylist_profile")


class ClientProfile(TimestampMixin, Base):
    __tablename__ = "client_profiles"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    preferred_sizes: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False, default=dict, server_default="{}")
    style_preferences: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False, default=dict, server_default="{}")
    address_city: Mapped[str | None] = mapped_column(Text)
    country_code: Mapped[str | None] = mapped_column(String(2))
    onboarding_completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    user: Mapped[User] = relationship(back_populates="client_profile")


class AuthCredential(TimestampMixin, Base):
    __tablename__ = "auth_credentials"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    password_hash: Mapped[str] = mapped_column(Text, nullable=False)
    last_login_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    user: Mapped[User] = relationship(back_populates="auth_credential")


class Consultancy(TimestampMixin, Base):
    __tablename__ = "consultancy"
    __table_args__ = (
        UniqueConstraint("stylist_id", "client_id", name="consultancy_unique_pair"),
        CheckConstraint("stylist_id <> client_id", name="consultancy_distinct_users"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    stylist_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    client_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    status: Mapped[ConsultancyStatus] = mapped_column(
        Enum(ConsultancyStatus, name="consultancy_status"),
        nullable=False,
        default=ConsultancyStatus.PENDING,
        server_default=ConsultancyStatus.PENDING.value,
    )
    access_notes: Mapped[str | None] = mapped_column(Text)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    stylist: Mapped[User] = relationship(back_populates="stylist_consultancies", foreign_keys=[stylist_id])
    client: Mapped[User] = relationship(back_populates="client_consultancies", foreign_keys=[client_id])
    invites: Mapped[list[StylistInvite]] = relationship(back_populates="consultancy")
    thread: Mapped[ChatThread | None] = relationship(back_populates="consultancy", uselist=False)


class StylistInvite(TimestampMixin, Base):
    __tablename__ = "stylist_invites"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    stylist_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    consultancy_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("consultancy.id", ondelete="SET NULL")
    )
    invite_code: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    invite_url: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    status: Mapped[InviteStatus] = mapped_column(
        Enum(InviteStatus, name="invite_status"),
        nullable=False,
        default=InviteStatus.PENDING,
        server_default=InviteStatus.PENDING.value,
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    accepted_by_client_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )

    consultancy: Mapped[Consultancy | None] = relationship(back_populates="invites")


class WardrobeItem(TimestampMixin, Base):
    __tablename__ = "wardrobe_items"
    __table_args__ = (
        CheckConstraint("price IS NULL OR price >= 0", name="price_positive"),
        CheckConstraint("wear_count >= 0", name="wear_count_non_negative"),
        CheckConstraint(
            "color_hex IS NULL OR color_hex ~ '^#[0-9A-Fa-f]{6}$'",
            name="valid_color_hex",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    client_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    created_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    image_url: Mapped[str] = mapped_column(Text, nullable=False)
    original_image_url: Mapped[str | None] = mapped_column(Text)
    category: Mapped[str] = mapped_column(Text, nullable=False)
    subcategory: Mapped[str | None] = mapped_column(Text)
    brand: Mapped[str | None] = mapped_column(Text)
    color_name: Mapped[str | None] = mapped_column(Text)
    color_hex: Mapped[str | None] = mapped_column(String(7))
    seasons: Mapped[list[SeasonTag]] = mapped_column(
        ARRAY(Enum(SeasonTag, name="season_tag", create_type=False)),
        nullable=False,
        default=lambda: [SeasonTag.ALL_SEASON],
        server_default="{all_season}",
    )
    styles: Mapped[list[StyleTag]] = mapped_column(
        ARRAY(Enum(StyleTag, name="style_tag", create_type=False)),
        nullable=False,
        default=lambda: [StyleTag.CASUAL],
        server_default="{casual}",
    )
    purchase_date: Mapped[date | None] = mapped_column(Date)
    price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))
    currency_code: Mapped[str] = mapped_column(String(3), nullable=False, default="USD", server_default="USD")
    last_worn_date: Mapped[date | None] = mapped_column(Date)
    wear_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    status: Mapped[WardrobeItemStatus] = mapped_column(
        Enum(WardrobeItemStatus, name="wardrobe_item_status"),
        nullable=False,
        default=WardrobeItemStatus.DRAFT,
        server_default=WardrobeItemStatus.DRAFT.value,
    )
    condition_status: Mapped[ItemConditionStatus] = mapped_column(
        Enum(ItemConditionStatus, name="item_condition_status"),
        nullable=False,
        default=ItemConditionStatus.GOOD,
        server_default=ItemConditionStatus.GOOD.value,
    )
    notes: Mapped[str | None] = mapped_column(Text)
    ai_metadata: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False, default=dict, server_default="{}")
    background_removed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    client: Mapped[User] = relationship(back_populates="wardrobe_items", foreign_keys=[client_id])
    created_by: Mapped[User | None] = relationship(back_populates="created_items", foreign_keys=[created_by_user_id])
    outfit_links: Mapped[list[OutfitItem]] = relationship(back_populates="wardrobe_item")
    calendar_links: Mapped[list[WardrobeCalendarItem]] = relationship(back_populates="wardrobe_item")
    analysis_jobs: Mapped[list[ItemAnalysisJob]] = relationship(back_populates="wardrobe_item")


class Outfit(TimestampMixin, Base):
    __tablename__ = "outfits"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    client_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    stylist_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    title: Mapped[str] = mapped_column(Text, nullable=False)
    cover_image_url: Mapped[str | None] = mapped_column(Text)
    occasion: Mapped[str | None] = mapped_column(Text)
    notes: Mapped[str | None] = mapped_column(Text)
    status: Mapped[OutfitStatus] = mapped_column(
        Enum(OutfitStatus, name="outfit_status"),
        nullable=False,
        default=OutfitStatus.DRAFT,
        server_default=OutfitStatus.DRAFT.value,
    )
    suggested_for_date: Mapped[date | None] = mapped_column(Date)
    is_stylist_selected_daily_pick: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, server_default="false"
    )
    approved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    client: Mapped[User] = relationship(back_populates="client_outfits", foreign_keys=[client_id])
    stylist: Mapped[User | None] = relationship(back_populates="styled_outfits", foreign_keys=[stylist_id])
    items: Mapped[list[OutfitItem]] = relationship(back_populates="outfit")
    feedback_entries: Mapped[list[OutfitFeedback]] = relationship(back_populates="outfit")


class OutfitItem(Base):
    __tablename__ = "outfit_items"

    outfit_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("outfits.id", ondelete="CASCADE"), primary_key=True
    )
    wardrobe_item_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("wardrobe_items.id", ondelete="CASCADE"), primary_key=True
    )
    slot_label: Mapped[str | None] = mapped_column(Text)
    layer_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    outfit: Mapped[Outfit] = relationship(back_populates="items")
    wardrobe_item: Mapped[WardrobeItem] = relationship(back_populates="outfit_links")


class OutfitFeedback(Base):
    __tablename__ = "outfit_feedback"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    outfit_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("outfits.id", ondelete="CASCADE"), nullable=False
    )
    client_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    sentiment: Mapped[FeedbackSentiment] = mapped_column(
        Enum(FeedbackSentiment, name="feedback_sentiment"), nullable=False
    )
    feedback_note: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    outfit: Mapped[Outfit] = relationship(back_populates="feedback_entries")


class WardrobeItemStatusHistory(Base):
    __tablename__ = "wardrobe_item_status_history"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    wardrobe_item_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("wardrobe_items.id", ondelete="CASCADE"), nullable=False
    )
    changed_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    old_status: Mapped[WardrobeItemStatus | None] = mapped_column(
        Enum(WardrobeItemStatus, name="wardrobe_item_status", create_type=False)
    )
    new_status: Mapped[WardrobeItemStatus] = mapped_column(
        Enum(WardrobeItemStatus, name="wardrobe_item_status", create_type=False), nullable=False
    )
    reason: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )


class DailyOutfitSuggestion(Base):
    __tablename__ = "daily_outfit_suggestions"
    __table_args__ = (UniqueConstraint("client_id", "suggestion_date", name="daily_suggestion_per_day"),)

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    outfit_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("outfits.id", ondelete="CASCADE"), nullable=False
    )
    client_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    stylist_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    suggestion_date: Mapped[date] = mapped_column(Date, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )


class WardrobeCalendar(Base):
    __tablename__ = "wardrobe_calendar"
    __table_args__ = (UniqueConstraint("client_id", "worn_on", name="wardrobe_unique_worn_day"),)

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    client_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    outfit_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("outfits.id", ondelete="SET NULL")
    )
    worn_on: Mapped[date] = mapped_column(Date, nullable=False)
    marked_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    note: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    items: Mapped[list[WardrobeCalendarItem]] = relationship(back_populates="calendar")


class WardrobeCalendarItem(Base):
    __tablename__ = "wardrobe_calendar_items"

    calendar_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("wardrobe_calendar.id", ondelete="CASCADE"), primary_key=True
    )
    wardrobe_item_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("wardrobe_items.id", ondelete="CASCADE"), primary_key=True
    )

    calendar: Mapped[WardrobeCalendar] = relationship(back_populates="items")
    wardrobe_item: Mapped[WardrobeItem] = relationship(back_populates="calendar_links")


class ChatThread(TimestampMixin, Base):
    __tablename__ = "chat_threads"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    consultancy_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("consultancy.id", ondelete="CASCADE"), nullable=False, unique=True
    )
    stylist_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    client_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    last_message_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    consultancy: Mapped[Consultancy] = relationship(back_populates="thread")
    messages: Mapped[list[ChatMessage]] = relationship(back_populates="thread")


class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    thread_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("chat_threads.id", ondelete="CASCADE"), nullable=False
    )
    sender_user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    related_outfit_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("outfits.id", ondelete="SET NULL")
    )
    related_wardrobe_item_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("wardrobe_items.id", ondelete="SET NULL")
    )
    body: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    thread: Mapped[ChatThread] = relationship(back_populates="messages")


class Notification(Base):
    __tablename__ = "notifications"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    type: Mapped[NotificationType] = mapped_column(
        Enum(NotificationType, name="notification_type"), nullable=False
    )
    title: Mapped[str] = mapped_column(Text, nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    related_entity_type: Mapped[str | None] = mapped_column(Text)
    related_entity_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True))
    payload: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False, default=dict, server_default="{}")
    sent_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )


class ItemAnalysisJob(Base):
    __tablename__ = "item_analysis_jobs"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    wardrobe_item_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("wardrobe_items.id", ondelete="CASCADE"), nullable=False
    )
    classifier_provider: Mapped[str] = mapped_column(Text, nullable=False)
    classification_result: Mapped[dict[str, Any]] = mapped_column(
        JSONB, nullable=False, default=dict, server_default="{}"
    )
    dominant_color_hex: Mapped[str | None] = mapped_column(String(7))
    dominant_color_name: Mapped[str | None] = mapped_column(Text)
    inferred_seasons: Mapped[list[SeasonTag]] = mapped_column(
        ARRAY(Enum(SeasonTag, name="season_tag", create_type=False)),
        nullable=False,
        default=list,
        server_default="{}",
    )
    inferred_styles: Mapped[list[StyleTag]] = mapped_column(
        ARRAY(Enum(StyleTag, name="style_tag", create_type=False)),
        nullable=False,
        default=list,
        server_default="{}",
    )
    processed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    wardrobe_item: Mapped[WardrobeItem] = relationship(back_populates="analysis_jobs")


class PackingPlan(TimestampMixin, Base):
    __tablename__ = "packing_plans"
    __table_args__ = (CheckConstraint("end_date >= start_date", name="packing_plans_dates"),)

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    client_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    stylist_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    destination_city: Mapped[str] = mapped_column(Text, nullable=False)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    purpose: Mapped[TravelPurpose] = mapped_column(
        Enum(TravelPurpose, name="travel_purpose"), nullable=False
    )
    weather_snapshot: Mapped[dict[str, Any]] = mapped_column(
        JSONB, nullable=False, default=dict, server_default="{}"
    )

    items: Mapped[list[PackingPlanItem]] = relationship(back_populates="packing_plan")
    outfits: Mapped[list[PackingPlanOutfit]] = relationship(back_populates="packing_plan")


class PackingPlanItem(Base):
    __tablename__ = "packing_plan_items"

    packing_plan_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("packing_plans.id", ondelete="CASCADE"), primary_key=True
    )
    wardrobe_item_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("wardrobe_items.id", ondelete="CASCADE"), primary_key=True
    )
    quantity: Mapped[int] = mapped_column(Integer, nullable=False, default=1, server_default="1")
    checklist_note: Mapped[str | None] = mapped_column(Text)

    packing_plan: Mapped[PackingPlan] = relationship(back_populates="items")


class PackingPlanOutfit(Base):
    __tablename__ = "packing_plan_outfits"

    packing_plan_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("packing_plans.id", ondelete="CASCADE"), primary_key=True
    )
    outfit_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("outfits.id", ondelete="CASCADE"), primary_key=True
    )
    planned_for_date: Mapped[date | None] = mapped_column(Date)

    packing_plan: Mapped[PackingPlan] = relationship(back_populates="outfits")
