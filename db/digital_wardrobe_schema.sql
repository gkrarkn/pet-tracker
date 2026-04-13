CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

CREATE TYPE app_user_role AS ENUM ('stylist', 'client');
CREATE TYPE subscription_status AS ENUM ('trial', 'active', 'past_due', 'canceled', 'inactive');
CREATE TYPE consultancy_status AS ENUM ('pending', 'active', 'paused', 'revoked', 'completed');
CREATE TYPE invite_status AS ENUM ('pending', 'accepted', 'expired', 'revoked');
CREATE TYPE wardrobe_item_status AS ENUM ('draft', 'active', 'archived', 'discarded');
CREATE TYPE item_condition_status AS ENUM ('new', 'good', 'worn', 'retired');
CREATE TYPE season_tag AS ENUM ('spring', 'summer', 'autumn', 'winter', 'all_season');
CREATE TYPE style_tag AS ENUM ('casual', 'formal', 'smart_casual', 'sport', 'business', 'evening', 'travel');
CREATE TYPE outfit_status AS ENUM ('draft', 'suggested', 'approved', 'archived');
CREATE TYPE feedback_sentiment AS ENUM ('love_it', 'like', 'neutral', 'dislike', 'fit_issue');
CREATE TYPE notification_type AS ENUM ('outfit_suggestion', 'chat_message', 'inventory_update', 'packing_plan');
CREATE TYPE travel_purpose AS ENUM ('business', 'vacation');

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id UUID UNIQUE,
  email CITEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  role app_user_role NOT NULL,
  subscription_status subscription_status NOT NULL DEFAULT 'trial',
  timezone TEXT NOT NULL DEFAULT 'UTC',
  avatar_url TEXT,
  push_token TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE stylist_profiles (
  user_id UUID PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
  business_name TEXT,
  bio TEXT,
  qr_invite_slug TEXT UNIQUE,
  stripe_customer_id TEXT UNIQUE,
  stripe_subscription_id TEXT UNIQUE,
  subscription_tier TEXT,
  max_clients INTEGER NOT NULL DEFAULT 10,
  affiliate_code TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE client_profiles (
  user_id UUID PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
  preferred_sizes JSONB NOT NULL DEFAULT '{}'::JSONB,
  style_preferences JSONB NOT NULL DEFAULT '{}'::JSONB,
  address_city TEXT,
  country_code CHAR(2),
  onboarding_completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE auth_credentials (
  user_id UUID PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
  password_hash TEXT NOT NULL,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE consultancy (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stylist_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  status consultancy_status NOT NULL DEFAULT 'pending',
  access_notes TEXT,
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT consultancy_unique_pair UNIQUE (stylist_id, client_id),
  CONSTRAINT consultancy_distinct_users CHECK (stylist_id <> client_id)
);

CREATE TABLE stylist_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stylist_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  consultancy_id UUID REFERENCES consultancy (id) ON DELETE SET NULL,
  invite_code TEXT NOT NULL UNIQUE,
  invite_url TEXT NOT NULL UNIQUE,
  status invite_status NOT NULL DEFAULT 'pending',
  expires_at TIMESTAMPTZ NOT NULL,
  accepted_by_client_id UUID REFERENCES users (id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE wardrobe_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  created_by_user_id UUID REFERENCES users (id) ON DELETE SET NULL,
  image_url TEXT NOT NULL,
  original_image_url TEXT,
  category TEXT NOT NULL,
  subcategory TEXT,
  brand TEXT,
  color_name TEXT,
  color_hex CHAR(7),
  seasons season_tag[] NOT NULL DEFAULT ARRAY['all_season']::season_tag[],
  styles style_tag[] NOT NULL DEFAULT ARRAY['casual']::style_tag[],
  purchase_date DATE,
  price NUMERIC(12,2) CHECK (price IS NULL OR price >= 0),
  currency_code CHAR(3) NOT NULL DEFAULT 'USD',
  last_worn_date DATE,
  wear_count INTEGER NOT NULL DEFAULT 0 CHECK (wear_count >= 0),
  status wardrobe_item_status NOT NULL DEFAULT 'draft',
  condition_status item_condition_status NOT NULL DEFAULT 'good',
  notes TEXT,
  ai_metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
  background_removed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT wardrobe_items_color_hex_format
    CHECK (color_hex IS NULL OR color_hex ~ '^#[0-9A-Fa-f]{6}$')
);

CREATE TABLE outfits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  stylist_id UUID REFERENCES users (id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  cover_image_url TEXT,
  occasion TEXT,
  notes TEXT,
  status outfit_status NOT NULL DEFAULT 'draft',
  suggested_for_date DATE,
  is_stylist_selected_daily_pick BOOLEAN NOT NULL DEFAULT FALSE,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE outfit_items (
  outfit_id UUID NOT NULL REFERENCES outfits (id) ON DELETE CASCADE,
  wardrobe_item_id UUID NOT NULL REFERENCES wardrobe_items (id) ON DELETE CASCADE,
  slot_label TEXT,
  layer_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (outfit_id, wardrobe_item_id)
);

CREATE TABLE outfit_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  outfit_id UUID NOT NULL REFERENCES outfits (id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  sentiment feedback_sentiment NOT NULL,
  feedback_note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE wardrobe_item_status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wardrobe_item_id UUID NOT NULL REFERENCES wardrobe_items (id) ON DELETE CASCADE,
  changed_by_user_id UUID REFERENCES users (id) ON DELETE SET NULL,
  old_status wardrobe_item_status,
  new_status wardrobe_item_status NOT NULL,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE daily_outfit_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  outfit_id UUID NOT NULL REFERENCES outfits (id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  stylist_id UUID REFERENCES users (id) ON DELETE SET NULL,
  suggestion_date DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (client_id, suggestion_date)
);

CREATE TABLE wardrobe_calendar (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  outfit_id UUID REFERENCES outfits (id) ON DELETE SET NULL,
  worn_on DATE NOT NULL,
  marked_by_user_id UUID REFERENCES users (id) ON DELETE SET NULL,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (client_id, worn_on)
);

CREATE TABLE wardrobe_calendar_items (
  calendar_id UUID NOT NULL REFERENCES wardrobe_calendar (id) ON DELETE CASCADE,
  wardrobe_item_id UUID NOT NULL REFERENCES wardrobe_items (id) ON DELETE CASCADE,
  PRIMARY KEY (calendar_id, wardrobe_item_id)
);

CREATE TABLE chat_threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  consultancy_id UUID NOT NULL REFERENCES consultancy (id) ON DELETE CASCADE,
  stylist_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  last_message_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (consultancy_id)
);

CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id UUID NOT NULL REFERENCES chat_threads (id) ON DELETE CASCADE,
  sender_user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  related_outfit_id UUID REFERENCES outfits (id) ON DELETE SET NULL,
  related_wardrobe_item_id UUID REFERENCES wardrobe_items (id) ON DELETE SET NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  read_at TIMESTAMPTZ
);

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  related_entity_type TEXT,
  related_entity_id UUID,
  payload JSONB NOT NULL DEFAULT '{}'::JSONB,
  sent_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE item_analysis_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wardrobe_item_id UUID NOT NULL REFERENCES wardrobe_items (id) ON DELETE CASCADE,
  classifier_provider TEXT NOT NULL,
  classification_result JSONB NOT NULL DEFAULT '{}'::JSONB,
  dominant_color_hex CHAR(7),
  dominant_color_name TEXT,
  inferred_seasons season_tag[] NOT NULL DEFAULT ARRAY[]::season_tag[],
  inferred_styles style_tag[] NOT NULL DEFAULT ARRAY[]::style_tag[],
  processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE packing_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  stylist_id UUID REFERENCES users (id) ON DELETE SET NULL,
  destination_city TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  purpose travel_purpose NOT NULL,
  weather_snapshot JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT packing_plans_dates CHECK (end_date >= start_date)
);

CREATE TABLE packing_plan_items (
  packing_plan_id UUID NOT NULL REFERENCES packing_plans (id) ON DELETE CASCADE,
  wardrobe_item_id UUID NOT NULL REFERENCES wardrobe_items (id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  checklist_note TEXT,
  PRIMARY KEY (packing_plan_id, wardrobe_item_id)
);

CREATE TABLE packing_plan_outfits (
  packing_plan_id UUID NOT NULL REFERENCES packing_plans (id) ON DELETE CASCADE,
  outfit_id UUID NOT NULL REFERENCES outfits (id) ON DELETE CASCADE,
  planned_for_date DATE,
  PRIMARY KEY (packing_plan_id, outfit_id)
);

CREATE INDEX idx_users_role ON users (role);
CREATE INDEX idx_consultancy_stylist_status ON consultancy (stylist_id, status);
CREATE INDEX idx_consultancy_client_status ON consultancy (client_id, status);
CREATE INDEX idx_invites_stylist_status ON stylist_invites (stylist_id, status);
CREATE INDEX idx_wardrobe_items_client_status ON wardrobe_items (client_id, status);
CREATE INDEX idx_wardrobe_items_category ON wardrobe_items (client_id, category);
CREATE INDEX idx_wardrobe_items_last_worn_date ON wardrobe_items (client_id, last_worn_date DESC);
CREATE INDEX idx_outfits_client_status ON outfits (client_id, status);
CREATE INDEX idx_daily_suggestions_client_date ON daily_outfit_suggestions (client_id, suggestion_date DESC);
CREATE INDEX idx_calendar_client_date ON wardrobe_calendar (client_id, worn_on DESC);
CREATE INDEX idx_chat_messages_thread_created_at ON chat_messages (thread_id, created_at DESC);
CREATE INDEX idx_notifications_user_created_at ON notifications (user_id, created_at DESC);

CREATE OR REPLACE FUNCTION refresh_item_wear_stats()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  target_item_id UUID;
BEGIN
  target_item_id := COALESCE(NEW.wardrobe_item_id, OLD.wardrobe_item_id);

  UPDATE wardrobe_items wi
  SET
    wear_count = COALESCE(src.wear_count, 0),
    last_worn_date = src.last_worn_date,
    updated_at = NOW()
  FROM (
    SELECT
      wci.wardrobe_item_id,
      COUNT(*)::INTEGER AS wear_count,
      MAX(wc.worn_on) AS last_worn_date
    FROM wardrobe_calendar_items wci
    JOIN wardrobe_calendar wc ON wc.id = wci.calendar_id
    WHERE wci.wardrobe_item_id = target_item_id
    GROUP BY wci.wardrobe_item_id
  ) AS src
  WHERE wi.id = src.wardrobe_item_id;

  UPDATE wardrobe_items
  SET
    wear_count = 0,
    last_worn_date = NULL,
    updated_at = NOW()
  WHERE id = target_item_id
    AND NOT EXISTS (
      SELECT 1
      FROM wardrobe_calendar_items
      WHERE wardrobe_item_id = target_item_id
    );

  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_stylist_profiles_updated_at
BEFORE UPDATE ON stylist_profiles
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_client_profiles_updated_at
BEFORE UPDATE ON client_profiles
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_auth_credentials_updated_at
BEFORE UPDATE ON auth_credentials
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_consultancy_updated_at
BEFORE UPDATE ON consultancy
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_stylist_invites_updated_at
BEFORE UPDATE ON stylist_invites
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_wardrobe_items_updated_at
BEFORE UPDATE ON wardrobe_items
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_outfits_updated_at
BEFORE UPDATE ON outfits
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_chat_threads_updated_at
BEFORE UPDATE ON chat_threads
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_packing_plans_updated_at
BEFORE UPDATE ON packing_plans
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_calendar_items_after_insert
AFTER INSERT ON wardrobe_calendar_items
FOR EACH ROW
EXECUTE FUNCTION refresh_item_wear_stats();

CREATE TRIGGER trg_calendar_items_after_delete
AFTER DELETE ON wardrobe_calendar_items
FOR EACH ROW
EXECUTE FUNCTION refresh_item_wear_stats();

CREATE VIEW wardrobe_item_analytics AS
SELECT
  wi.id,
  wi.client_id,
  wi.category,
  wi.brand,
  wi.price,
  wi.currency_code,
  wi.wear_count,
  wi.last_worn_date,
  CASE
    WHEN wi.price IS NULL OR wi.wear_count = 0 THEN NULL
    ELSE ROUND(wi.price / wi.wear_count, 2)
  END AS cost_per_wear
FROM wardrobe_items wi;

COMMENT ON TABLE consultancy IS 'Stylist ile client arasindaki erisim ve danismanlik iliskisi.';
COMMENT ON TABLE wardrobe_items IS 'AI etiketleme sonrasi draft olarak kaydedilen kiyafetler dahil tum gardirop urunleri.';
COMMENT ON TABLE outfits IS 'Stylist veya sistem tarafindan olusturulan kombinler.';
COMMENT ON TABLE wardrobe_calendar IS 'Musterinin hangi gun hangi kombini giydigini loglar.';
COMMENT ON TABLE chat_messages IS 'Stylist-client iletisimi ve kombin geri bildirim notlari.';

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultancy ENABLE ROW LEVEL SECURITY;
ALTER TABLE wardrobe_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE outfits ENABLE ROW LEVEL SECURITY;
ALTER TABLE wardrobe_calendar ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY users_self_access
ON users
USING (id = current_setting('app.current_user_id', TRUE)::UUID);

CREATE POLICY consultancy_member_access
ON consultancy
USING (
  stylist_id = current_setting('app.current_user_id', TRUE)::UUID
  OR client_id = current_setting('app.current_user_id', TRUE)::UUID
);

CREATE POLICY wardrobe_items_consultancy_access
ON wardrobe_items
USING (
  client_id = current_setting('app.current_user_id', TRUE)::UUID
  OR EXISTS (
    SELECT 1
    FROM consultancy c
    WHERE c.client_id = wardrobe_items.client_id
      AND c.stylist_id = current_setting('app.current_user_id', TRUE)::UUID
      AND c.status IN ('active', 'pending')
  )
);

CREATE POLICY outfits_consultancy_access
ON outfits
USING (
  client_id = current_setting('app.current_user_id', TRUE)::UUID
  OR stylist_id = current_setting('app.current_user_id', TRUE)::UUID
);

CREATE POLICY calendar_consultancy_access
ON wardrobe_calendar
USING (
  client_id = current_setting('app.current_user_id', TRUE)::UUID
  OR EXISTS (
    SELECT 1
    FROM consultancy c
    WHERE c.client_id = wardrobe_calendar.client_id
      AND c.stylist_id = current_setting('app.current_user_id', TRUE)::UUID
      AND c.status IN ('active', 'pending')
  )
);

CREATE POLICY chat_thread_member_access
ON chat_threads
USING (
  stylist_id = current_setting('app.current_user_id', TRUE)::UUID
  OR client_id = current_setting('app.current_user_id', TRUE)::UUID
);

CREATE POLICY chat_message_member_access
ON chat_messages
USING (
  EXISTS (
    SELECT 1
    FROM chat_threads ct
    WHERE ct.id = chat_messages.thread_id
      AND (
        ct.stylist_id = current_setting('app.current_user_id', TRUE)::UUID
        OR ct.client_id = current_setting('app.current_user_id', TRUE)::UUID
      )
  )
);

CREATE POLICY notifications_owner_access
ON notifications
USING (user_id = current_setting('app.current_user_id', TRUE)::UUID);
