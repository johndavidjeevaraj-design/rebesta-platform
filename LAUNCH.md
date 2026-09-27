# REBESTA — Launch Runbook

Everything needed to take the platform from this repo to production, in order.
Each step says exactly what to do and how to verify it worked.

---

## 0. System overview

| Component | Path | What it is |
|---|---|---|
| Backend API | `rebesta_backend/` | NestJS + Supabase (Postgres) + Razorpay + socket.io, port from `PORT` (default 3000) |
| Customer app | `rebesta_customers/` | Flutter — browse, cart, pay, live order tracking |
| Partner app | `rebesta_partner/` | Flutter — restaurant dashboard: orders, menu, store status/hours, earnings |
| Rider app | `rebesta_delivery/` | Flutter — order pool, active delivery, KYC, earnings |
| Database migrations | `rebesta_backend/supabase/migrations/` | Run manually in the Supabase SQL Editor |

All three apps talk **only** to the backend API — no app talks to Supabase directly
(the anon key is locked out by RLS; the backend uses the service-role key).

---

## 1. Accounts & keys you need before starting

| Key | Used for | Where to get it |
|---|---|---|
| `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` | Database | Supabase → Project Settings → API |
| `JWT_SECRET` | Signs every login token (all 3 apps) | Any long random string — keep it secret & stable |
| `ADMIN_API_KEY` | Unlocks every `/admin/*` route | Any long random string you invent |
| `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET` | Payments | Razorpay Dashboard → Settings → API Keys |
| `RAZORPAY_WEBHOOK_SECRET` | Verifies payment webhooks | Razorpay Dashboard → Settings → Webhooks |
| `TWO_FACTOR_API_KEY` | Customer OTP SMS (signup/login) — **required, no dev fallback** | 2Factor.in |
| `ORS_API_KEY` | Rider ETA / distance | openrouteservice.org |

> **JWT_SECRET warning:** changing it after launch logs every user out. Set it once, before go-live.

---

## 2. Database — run the migrations (Supabase SQL Editor)

Run in this order, one file at a time, in **Supabase → SQL Editor**:

1. `rebesta_backend/supabase/migrations/20260926_add_delivery_kyc.sql`
   — `kyc_status` on `delivery_partners` + `delivery_kyc_documents` table
2. `rebesta_backend/supabase/migrations/20260926_create_delivery_offers.sql`
   — `delivery_offers` table for rider dispatch offers
3. `rebesta_backend/supabase/migrations/20260927_enable_rls_lockdown.sql`
   — RLS deny-by-default on **all 25 tables**
4. `rebesta_backend/supabase/migrations/20260927_add_store_hours.sql`
   — `opening_time` / `closing_time` / `closed_days` on `restaurants`

**Verify** (queries are included at the bottom of each file):
- All 25 tables show `rowsecurity = t`, and `SELECT ... FROM pg_policies` returns nothing unexpected.
- `information_schema.columns` shows the three store-hours columns on `restaurants`.

> Storage buckets (menu/restaurant images): Dashboard → Storage → Policies.
> The image bucket should allow **public read only**; writes happen via the backend service role.

---

## 3. Backend — configure, build, deploy

1. Copy `rebesta_backend/.env.example` → `.env` and fill every value (table in step 1).
   `ADMIN_API_KEY` **must** be set — without it every admin request is rejected (fails closed).
2. Install & build:
   ```powershell
   cd rebesta_backend
   npm ci
   npm run build
   npm run start:prod     # node dist/main
   ```
3. **Razorpay webhook** — in the Razorpay Dashboard create a webhook:
   - URL: `https://<your-backend-domain>/payments/webhook`
   - Event: `payment.captured`
   - Secret: the same value as `RAZORPAY_WEBHOOK_SECRET` in `.env`
4. Sanity checks after deploy:
   - `GET /restaurants` returns your restaurant list.
   - `GET /admin/dashboard` **without** a header returns 401 (that's the guard working).

---

## 4. Admin operations (all need the `x-admin-key` header)

Every admin call: `-H "x-admin-key: <ADMIN_API_KEY>"`

| Task | Endpoint |
|---|---|
| Restaurant approval | `PATCH /admin/restaurants/{id}/approve` (also `reject`, `block`, `unblock`) |
| List rider KYC submissions | `GET /admin/delivery-kyc` |
| **Approve rider KYC** | `PATCH /admin/delivery-kyc/{id}/approve` |
| Dashboards | `GET /admin/dashboard`, `GET /admin/analytics`, `GET /admin/orders` |

> **KYC gating is live:** riders can only receive offers / accept orders after their KYC
> is `verified`. Flow: rider uploads all 4 documents in the app → admin approves above.

---

## 5. Build the apps

All three apps take the backend URL at build time — no keys are bundled
(the Razorpay key is fetched from the backend at checkout):

```powershell
# Customer
cd rebesta_customers
flutter build apk --release --dart-define=API_BASE_URL=https://<your-backend-domain>

# Partner
cd rebesta_partner
flutter build apk --release --dart-define=API_BASE_URL=https://<your-backend-domain>

# Rider
cd rebesta_delivery
flutter build apk --release --dart-define=API_BASE_URL=https://<your-backend-domain>
```

The default URL inside each app is only a dev fallback (`http://10.0.2.2:3000`) —
**always pass `--dart-define` for release builds.**

---

## 6. Go-live smoke test (end-to-end, ~15 minutes)

Do this on production infra with production keys before announcing anything.

**Setup (once)**
- [ ] Partner account created, restaurant approved via admin API
- [ ] Rider account created, all 4 KYC documents uploaded, KYC **approved** via admin API

**Order flow**
- [ ] Customer signs up with a real phone (OTP SMS arrives via 2Factor)
- [ ] Restaurant page shows store hours (if the partner set them)
- [ ] Add items to cart, apply address, place + **pay** with Razorpay (test mode first)
- [ ] Order appears in the partner dashboard instantly (socket), with a sound/notification
- [ ] Partner: accept → preparing → **ready**
- [ ] Rider app: order offer arrives (socket); unverified riders are refused at accept
- [ ] Rider: accept → reached restaurant → picked up → out for delivery
- [ ] Customer app: live rider location on the tracking map
- [ ] Rider: arrived at customer → delivery OTP (customer reads it out) → **complete**
- [ ] Payment shows as PAID in partner Reports with correct earnings totals
- [ ] Rider earnings reflect the delivery

**Store controls**
- [ ] Partner toggles store OFFLINE → customer app shows the restaurant closed
- [ ] Partner sets store hours + a closed day → customer restaurant page reflects them

**Safety checks**
- [ ] `GET /admin/dashboard` without `x-admin-key` → 401
- [ ] Direct Supabase REST call with the anon key → no rows (RLS)
- [ ] OTP spam (4+ requests in a minute) → HTTP 429 from rate limiter

---

## 7. Security posture (already enforced in code)

- **Sockets:** JWT-verified handshake; every room join checked against the token identity
- **Admin API:** locked behind `x-admin-key`, fails closed
- **Rate limiting:** 100 req/min/IP globally; OTP 3/min, logins 10/min, signups 5/min
- **Payments:** server-side pricing, HMAC-verified Razorpay webhook (timing-safe compare)
- **Database:** RLS deny-by-default on all tables; apps never touch Supabase directly
- **Dispatch:** only KYC-verified riders receive offers and can accept deliveries

---

## 8. Known parked items

| Item | Status |
|---|---|
| Rider push notifications (FCM) | Backend `fcm_tokens` table ready; needs `google-services.json` (Firebase project) dropped into the rider app |
| Menu add-ons / extras | Not started — next feature round |
| Store hours auto open/close | Hours are informational; the partner toggle remains the live control (deliberate) |

---

*Last updated: 2026-09-27 · main @ `1912b17`*
