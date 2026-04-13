# Digital Wardrobe API Plan

Bu plan, PostgreSQL semasi ile uyumlu FastAPI servis alanlarini ve oncelik sirasini tanimlar.

## 1. Auth

Amaç: stylist ve client rollerini guvenli sekilde sisteme almak, invite akisini role-aware hale getirmek.

Temel endpoint'ler:

- `POST /auth/register/client`
  - Invite code ile client hesap olusturur.
  - `users`, `client_profiles`, `consultancy`, `stylist_invites` tablolarini gunceller.
- `POST /auth/register/stylist`
  - Stylist hesabi ve `stylist_profiles` kaydi olusturur.
- `POST /auth/login`
  - Email/password veya harici auth saglayicidan JWT verir.
- `POST /auth/refresh`
  - Refresh token ile yeni access token dondurur.
- `GET /auth/me`
  - Rol, abonelik durumu, aktif consultancy sayisi, onboarding state dondurur.
- `POST /auth/invites`
  - Stylist yeni invite link/QR uretir.
- `POST /auth/invites/{invite_code}/accept`
  - Client invite'i kabul eder, consultancy `active` olur.

Notlar:

- JWT icine `sub`, `role`, `active_consultancy_ids` claim'leri konur.
- RLS kullaniliyorsa her request'te DB session icin `SET app.current_user_id = :user_id` uygulanir.
- Davet kabulunde stylist `max_clients` limiti kontrol edilir.

## 2. Wardrobe

Amaç: item yukleme, background removal, AI tagging ve draft onayi akisini hizli tutmak.

Temel endpoint'ler:

- `POST /wardrobe/upload-url`
  - S3 presigned POST veya Cloudinary signed upload parametreleri dondurur.
- `POST /wardrobe/items`
  - Yuklenen orijinal gorselden draft item olusturur.
  - Response: `wardrobe_item_id`, `upload_status`.
- `POST /wardrobe/items/{item_id}/process`
  - Background removal servisini tetikler.
  - Ardindan classification, dominant color, season/style tahmini calisir.
  - Sonuc `item_analysis_jobs` ve `wardrobe_items.ai_metadata` alanina yazilir.
- `GET /wardrobe/items`
  - Filtreler: `status`, `category`, `season`, `style`, `last_worn_before`, `brand`.
- `GET /wardrobe/items/{item_id}`
  - Tek item detay, analysis sonucu ve giyilme ozetini dondurur.
- `PATCH /wardrobe/items/{item_id}`
  - Kullanici AI sonucunu onaylar veya duzeltir.
- `PATCH /wardrobe/items/{item_id}/status`
  - `draft -> active`, `active -> discarded` gibi akislari yonetir.
  - `wardrobe_item_status_history` tablosuna log yazar.
- `POST /wardrobe/calendar`
  - Belirli tarihte giyilen outfit/item'lari kaydeder.
  - Trigger ile `wear_count` ve `last_worn_date` guncellenir.
- `GET /wardrobe/analytics/cost-per-wear`
  - `wardrobe_item_analytics` view uzerinden verimlilik raporu.

Notlar:

- Processing isi senkron degilse `202 Accepted` + job id dondurmek iyi olur.
- Mobile akista `upload -> process -> draft review` tek ekran deneyimi olarak kurgulanmali.

## 3. Outfits

Amaç: stylist'in kombin olusturmasi, gunluk oneriyi secmesi, feedback ve push dongusunu yonetmek.

Temel endpoint'ler:

- `POST /outfits`
  - Stylist veya sistem yeni outfit olusturur.
- `POST /outfits/{outfit_id}/items`
  - Outfit'e wardrobe item baglar.
- `PATCH /outfits/{outfit_id}`
  - Baslik, occasion, notes, status gunceller.
- `POST /outfits/{outfit_id}/daily-pick`
  - O gunun onerisi olarak isaretler, `daily_outfit_suggestions` ve `notifications` yazar.
- `GET /outfits`
  - Client bazli filtre, `suggested_for_date`, `status`, `stylist_id`.
- `GET /outfits/{outfit_id}`
  - Kombin detay ve feedback listesi.
- `POST /outfits/{outfit_id}/feedback`
  - Client sentiment ve not birakir.
- `POST /outfits/suggest`
  - Hava durumu, etkinlik tipi ve gardirop verisine gore AI destekli 3 kombin onerisi uretir.

Notlar:

- `POST /outfits/suggest` akisi weather adaptor + style rules prompt + mevcut wardrobe filtreleme adimlarini ayirmali.
- Daily pick endpoint'i push notification ile atomik calismali.

## 4. Consultancy

Amaç: B2B iliskiyi, client onboarding'i ve stylist-client iletisimini tek yerde toplamak.

Temel endpoint'ler:

- `GET /consultancies`
  - Stylist icin aktif/pending client listesi.
- `GET /consultancies/{consultancy_id}`
  - Client profile, wardrobe ozetleri, son feedback, son chat preview.
- `PATCH /consultancies/{consultancy_id}`
  - Durum degisikligi: `pending`, `active`, `paused`, `revoked`, `completed`.
- `POST /consultancies/{consultancy_id}/thread`
  - Chat thread olusturur.
- `GET /consultancies/{consultancy_id}/messages`
  - Mesaj gecmisi.
- `POST /consultancies/{consultancy_id}/messages`
  - Mesaj gonderir, gerekirse `related_outfit_id` veya `related_wardrobe_item_id` baglar.
- `POST /consultancies/{consultancy_id}/notify`
  - Manuel push veya system-driven bildirim gonderir.

Notlar:

- Realtime icin FastAPI + WebSocket veya Supabase Realtime/Firebase tercih edilebilir.
- DB source of truth kalmali; realtime katman sadece dagitim gorevi gormeli.

## 5. Storage Plan

Amaç: orijinal gorsel, background-removed gorsel ve outfit cover gorsellerini guvenli saklamak.

### S3 yaklasimi

- Bucket ayrimi:
  - `wardrobe-originals`
  - `wardrobe-processed`
  - `outfit-covers`
- Yol deseni:
  - `stylists/{stylist_id}/clients/{client_id}/items/{item_id}/original.jpg`
  - `stylists/{stylist_id}/clients/{client_id}/items/{item_id}/processed.png`
- API akisi:
  1. Client `POST /wardrobe/upload-url` cagirir.
  2. Backend yetki kontrolu yapar ve presigned URL doner.
  3. Mobil istemci dosyayi dogrudan S3'e yukler.
  4. Backend `POST /wardrobe/items` ile DB kaydini acar.
  5. Processing tamamlaninca `image_url` processed dosyaya guncellenir.

### Cloudinary yaklasimi

- Avantaj:
  - Kolay image transform, CDN, signed upload.
- API akisi:
  1. Backend signed upload parametreleri uretir.
  2. Client dogrudan Cloudinary'ye yukler.
  3. `public_id` ve secure URL DB'ye yazilir.
  4. Background removal sonrasi yeni derived asset URL'i `image_url` olur.

### Soyutlama onerisi

- `StorageService` interface:
  - `create_upload_target(user_id, folder, content_type) -> upload payload`
  - `finalize_asset(...) -> public url`
  - `delete_asset(asset_ref)`
- `settings.storage_backend` ile `s3` veya `cloudinary` secilir.
- Veritabaninda minimum su alanlar saklanir:
  - `original_image_url`
  - `image_url`
  - gelecekte gerekirse `storage_provider`, `storage_key`, `mime_type`

## 6. Oncelikli Delivery Sirasi

1. Auth + stylist invite kabul akisi
2. Storage upload endpoint'i
3. Wardrobe draft item olusturma
4. Background removal + AI tagging pipeline
5. Outfit CRUD + daily pick
6. Consultancy chat/notification
