# External Integrations

**Analysis Date:** 2026-06-16

## APIs & External Services

**Government Recall Data (Primary Data Source):**
- Service: `data.economie.gouv.fr` — French Ministry of Economy open data platform
- Dataset: `rappelconso-v2-gtin-espaces` (v2, with GTIN/barcode fields)
- Base URL (hard-coded): `https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets/rappelconso-v2-gtin-espaces`
- Defined in: `lib/utils/constants.dart` (`AppConstants.apiBaseUrl`)
- Used in: `lib/services/rappel_service.dart`
- Auth: None (public API)
- Protocol: REST, JSON responses
- Endpoints used:
  - `GET /records?limit=N&where=<filter>&order_by=<field>` — filtered recall listings
  - `GET /records?limit=N&order_by=date_publication desc` — latest recalls (home screen)
- Known API constraints (documented in `lib/services/rappel_service.dart`):
  - `sort` parameter is ignored by the API — results always arrive in ascending ID order
  - `offset + limit` cannot exceed 10,000 — deep pagination is not available
  - Workaround: filter by `date_publication >= "YYYY-01-01"` + local sort

**Government Recall Data (Newsletter Digest):**
- Dataset: `rappelconso0` (alternate/older dataset used by the newsletter backend)
- Used in: `newsletter-api/index.js` (`sendWeeklyDigest()`)
- URL: `https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets/rappelconso0/records`
- Note: different dataset ID from the Flutter app — may return different fields

## Data Storage

**Databases:**
- None — no relational or NoSQL database is used by the Flutter app

**Local Storage (Flutter App):**
- `shared_preferences` — key-value store backed by platform native storage
  - Used by: `lib/services/favorites_service.dart`, `lib/services/rappel_service.dart`, `lib/main.dart`
  - Keys stored:
    - `favorites` — JSON-encoded list of favorited recall objects
    - `cached_rappels_v4_<categoryKey>` — per-category API response cache (5-minute TTL)
    - `last_fetch_v4_<categoryKey>` — epoch ms timestamp of last successful fetch
    - `notifications_requested` — bool, whether push permission was already requested
    - `onboarding_shown` — bool, whether onboarding screen was already displayed

**Subscriber List (Newsletter API):**
- Storage: flat JSON file — `newsletter-api/subscribers.json` (local filesystem, not a database)
- Read/written by: `loadSubscribers()` / `saveSubscribers()` in `newsletter-api/index.js`
- Risk: file-based storage is not suitable for multi-instance or cloud deployments

**File Storage:**
- Local filesystem only (newsletter subscribers JSON)
- No cloud object storage (S3, GCS, etc.)

**Caching:**
- In-app: `shared_preferences` for API responses (5-minute TTL, cache-on-error fallback)
- Image: `cached_network_image` package handles HTTP image caching natively

## Authentication & Identity

**Auth Provider:**
- None — the Flutter app has no user accounts or login system
- The government API is fully public (no API key required)
- The newsletter API has no authentication on its POST endpoints (open `POST /newsletter`)

## Push Notifications

**Provider:** OneSignal
- SDK: `onesignal_flutter` `^5.2.6`
- App ID: `eb3fd80e-1a70-468f-ab2e-e1d2eb9592ab` (hard-coded in `lib/main.dart`)
- Implementation: `lib/services/notification_service_mobile.dart` (Android/iOS)
- Web stub: `lib/services/notification_service_web.dart` (no-op — OneSignal not supported on web)
- Platform selector: `lib/services/subscribe_to_newsletter.dart` (conditional export)
- Initialization: called at app startup in `lib/main.dart`
- Permission flow: requested once on first launch, persisted via `shared_preferences`
- Operations: `initialize()`, `subscribe()` (opt-in), `unsubscribe()` (opt-out), `isSubscribed()`

## Email / Newsletter

**SMTP Provider:** Brevo (formerly Sendinblue)
- Host: `smtp-relay.brevo.com` (port 587, STARTTLS)
- Client: `nodemailer` in `newsletter-api/index.js`
- Auth env vars: `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `FROM_EMAIL`

**Newsletter API Endpoints:**
- `POST /newsletter` — subscribe email: validates, stores, sends welcome email + admin notification
- `POST /send-email` — generic transactional email send (to, subject, text/html)
- `GET /health` — health check returning subscriber count and next digest info

**Weekly Digest:**
- Schedule: every Monday at 09:00 Europe/Paris (via `node-cron`)
- Content: 10 most recent recalls fetched from government API
- Sent to: all subscribers in `subscribers.json`

## Barcode / QR Scanning

**Provider:** `mobile_scanner` `^6.0.10`
- Screen: `lib/screens/barcode_scanner.dart`
- Requires camera permission (managed by `permission_handler`)
- Used for scanning product barcodes to look up recalls

## Social Sharing

**Provider:** `share_plus` `^10.0.0`
- Invokes native OS share sheet
- Used on recall detail cards to share recall information

## URL Handling

**Provider:** `url_launcher` `^6.1.14`
- Opens official government recall URLs (`lien_vers_la_liste_des_produits` field) in the default browser
- Used on recall detail and card screens

## Monitoring & Observability

**Error Tracking:**
- None — no Sentry, Firebase Crashlytics, or equivalent configured

**Logs:**
- Flutter app: `debugPrint()` calls in `lib/services/rappel_service.dart` (dev-only, stripped in release)
- Newsletter API: `console.log()` / `console.error()` (stdout/stderr)

## CI/CD & Deployment

**Hosting:**
- Not configured — no CI pipeline, no deployment scripts detected

**CI Pipeline:**
- None detected

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None (OneSignal push is SDK-initiated, not webhook-based)

## Environment Configuration Summary

**Flutter App (values currently inlined in code):**
- `ONESIGNAL_APP_ID` — documented in `.env.example` but read from `lib/main.dart` constant
- `API_BASE_URL` — documented in `.env.example` but read from `lib/utils/constants.dart` constant

**Newsletter API (`.env` file, see `newsletter-api/.env.example`):**
- `SMTP_HOST` — SMTP relay hostname
- `SMTP_PORT` — SMTP port (default: `587`)
- `SMTP_USER` — SMTP authentication username
- `SMTP_PASS` — SMTP / Brevo API key
- `FROM_EMAIL` — sender email address
- `PORT` — HTTP server port (default: `3000`)
- `APP_URL` — public-facing app URL (used in email links)

---

*Integration audit: 2026-06-16*
