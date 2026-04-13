from enum import Enum


class AppUserRole(str, Enum):
    STYLIST = "stylist"
    CLIENT = "client"


class SubscriptionStatus(str, Enum):
    TRIAL = "trial"
    ACTIVE = "active"
    PAST_DUE = "past_due"
    CANCELED = "canceled"
    INACTIVE = "inactive"


class ConsultancyStatus(str, Enum):
    PENDING = "pending"
    ACTIVE = "active"
    PAUSED = "paused"
    REVOKED = "revoked"
    COMPLETED = "completed"


class InviteStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    EXPIRED = "expired"
    REVOKED = "revoked"


class WardrobeItemStatus(str, Enum):
    DRAFT = "draft"
    ACTIVE = "active"
    ARCHIVED = "archived"
    DISCARDED = "discarded"


class ItemConditionStatus(str, Enum):
    NEW = "new"
    GOOD = "good"
    WORN = "worn"
    RETIRED = "retired"


class SeasonTag(str, Enum):
    SPRING = "spring"
    SUMMER = "summer"
    AUTUMN = "autumn"
    WINTER = "winter"
    ALL_SEASON = "all_season"


class StyleTag(str, Enum):
    CASUAL = "casual"
    FORMAL = "formal"
    SMART_CASUAL = "smart_casual"
    SPORT = "sport"
    BUSINESS = "business"
    EVENING = "evening"
    TRAVEL = "travel"


class OutfitStatus(str, Enum):
    DRAFT = "draft"
    SUGGESTED = "suggested"
    APPROVED = "approved"
    ARCHIVED = "archived"


class FeedbackSentiment(str, Enum):
    LOVE_IT = "love_it"
    LIKE = "like"
    NEUTRAL = "neutral"
    DISLIKE = "dislike"
    FIT_ISSUE = "fit_issue"


class NotificationType(str, Enum):
    OUTFIT_SUGGESTION = "outfit_suggestion"
    CHAT_MESSAGE = "chat_message"
    INVENTORY_UPDATE = "inventory_update"
    PACKING_PLAN = "packing_plan"


class TravelPurpose(str, Enum):
    BUSINESS = "business"
    VACATION = "vacation"
