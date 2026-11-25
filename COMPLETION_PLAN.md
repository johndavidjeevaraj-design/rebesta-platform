# Rebesta Platform — Completion Plan (Steps 1–5)

Benchmark: core functional capabilities of major food delivery platforms; not copying proprietary branding or design.

## Step 1 — Audit and remediation
- [x] Repository map: NestJS API, Supabase/Postgres, Cashfree PG (new checkouts), legacy Razorpay transaction fields for historical records, socket.io, Firebase; customer, restaurant-partner, and delivery Flutter apps.
- [x] Inspect startup, CI, auth/payment/order modules and launch runbook.
- [ ] Complete endpoint-by-endpoint authorization review and abuse cases.
- [ ] Complete DB schema, RLS, storage, migration, and RPC review.
- [ ] Audit payment/refund/reconciliation and order state transitions.
- [ ] Audit app UX flows, crash handling, accessibility, device permissions and offline states.
- [ ] Review test coverage and repair CI gates (backend lint and Flutter analyze are still configured as non-blocking baseline checks).
- [ ] Remediate findings in PRs, with tests.

## Initial findings (baseline observations; remediation status is tracked below)
- Baseline: backend CORS was unrestricted and global request validation was absent; both are now remediated in this PR.
- Baseline: lint and Flutter analyze were non-blocking; they remain non-blocking pending cleanup of existing debt.
- Global rate limiting is 100 requests/minute/IP; stricter per-route throttles now cover auth/OTP, checkout payment creation, payment verification, reconciliation and admin refunds.
- CI checks build/test; Android release builds, dependency audit and integration/E2E gates need adding.
- The three apps need independent release tracks and signing identities.

## Security remediation log (PR #27; CI verification pending)
- [x] Customer address update/delete operations are scoped to the authenticated customer; address payload validation is enabled.
- [x] Customer, partner and delivery JWT strategies validate role/subject identity and require a strong JWT secret.
- [x] Customer OTP challenge tokens bind the provider session to the submitted phone number; partner OTP challenge tokens use the same binding.
- [x] New customer profile creation requires a short-lived OTP proof and refuses to mutate an existing account.
- [x] Legacy customer password signup and public partner self-registration are disabled until verified registration/invitation flows are implemented. This is an intentional temporary restriction.
- [x] Customer OTP/profile, cart-add, payment verification and reconciliation request DTOs were added or hardened for the global whitelist pipe.
- [x] Cart item quantities are bounded and checkout verifies menu items belong to the selected restaurant.
- [x] Cashfree payments are checked against the expected order ID, INR payment currency, order amount, payment amount and successful provider status before order conversion (verify, reconcile and webhook paths). Legacy Razorpay fields remain for historical records.
- [ ] Confirm OTP/session changes compile and pass tests on latest PR head.
- [ ] Confirm all DTOs have validation decorators; empty DTO files and inline body types remain under review.
- [x] Admin delivery-KYC rejection now uses a validated DTO (non-empty reason, maximum 500 characters) with DTO unit tests.
- [x] Delivery app completion now opens the OTP flow directly and no longer calls the legacy no-OTP completion endpoint.
- [x] Admin order cancellation now permits only pending orders with unpaid, failed, or already-refunded payment states; the update rechecks state atomically and rejects paid/refund-pending or restaurant-accepted orders. Unit tests cover allowed and blocked states.
- [x] Rider cancellation is now limited to pre-pickup states; `picked_up`, `out_for_delivery`, and later states cannot be returned to the open delivery pool. Added lifecycle unit tests.
- [x] Removed the remaining customer delivery OTP debug log from the rider app.
- [ ] Support API remains a placeholder despite DTO files; implement only after the support-ticket schema and app contract are verified.
- [x] Dispatch now has a database-enforced single-pending-offer-per-order index migration; duplicate concurrent inserts are treated as an already-claimed order, not as a reason to broadcast. Stale fallback broadcasts re-check order readiness, assignment, and pending offers.
- [x] Added a periodic recovery sweep for up to 25 oldest ready/unassigned orders; it retries personal dispatch after transient failures and process restarts, while checking for an active offer before selecting another rider.
- [ ] Apply and verify `20261125170000_one_pending_delivery_offer_per_order.sql` in the staging database before enabling this dispatch guarantee in a deployed environment.
- [x] Rider acceptance now runs through `accept_delivery_order`, which locks the order row, verifies active offer ownership, prevents riders accepting while holding another live offer, and atomically assigns the order/settles offers.
- [x] Dispatch re-checks order state after inserting a personal offer and supersedes it instead of notifying a rider if the order was accepted concurrently.
- [ ] Add staging concurrency tests for simultaneous rider acceptance, dispatch insert vs acceptance, and one-pending-offer constraints.
- [x] COD checkout now explicitly carries `delivery` vs `pickup`; pickup skips address lookup and delivery-fee calculation and records `order_type='pickup'` without changing the existing UI.
- [x] Online payment attempts now persist `order_type`; a follow-up migration carries it into the paid order so online pickup remains pickup instead of silently defaulting to delivery. Legacy attempts are backfilled from the prior checkout contract (null address means pickup); new attempts default to delivery.
- [x] Restaurant acceptance now blocks pending/failed provider-backed orders (legacy Razorpay and Cashfree) while preserving legitimate COD acceptance; unit tests cover COD, captured online, unpaid online, and already-accepted states.
- [ ] Apply `20261125190000_preserve_paid_order_type.sql` in staging before deploying the updated payment service; verify pickup and delivery conversion end-to-end.
- [x] Added optional `menu_items.stock_quantity` tracking; `NULL` preserves unlimited/untracked behavior for existing dishes.
- [x] Added partner-authenticated inventory read/update endpoints (`GET /inventory/partner`, `PATCH /inventory/:menuItemId/stock`) with integer bounds and restaurant ownership scoping.
- [x] Restaurant acceptance now uses a database transaction to lock the order and tracked menu rows, validate availability/stock, deduct stock, and accept the order atomically. Concurrent acceptances cannot oversell tracked quantities.
- [x] Added `20261125220000_restore_stock_on_restaurant_cancellation.sql`; restaurant acceptance records only tracked-stock deductions, and cancellation restores those quantities once in the same transaction as the state change.
- [x] Restaurant cancellation now calls the stock-restoration RPC instead of directly changing order status.
- [x] Restaurant cancellation now rechecks unpaid/failed/refunded payment state atomically for both pending and accepted/preparing orders; paid orders must complete the admin refund flow first.
- [x] Delivery KYC approve/reject actions now update only submissions still in `submitted` state and return a conflict for stale/replayed decisions.
- [x] Rider earnings period summaries exclude reversed ledger entries.
- [x] Admin refund requests use Cashfree for new Cashfree-backed orders; `refund_pending` remains until provider confirmation, with SUCCESS/FAILED/CANCELLED/PENDING/ONHOLD handling. Historical Razorpay identifiers remain for audit; legacy refunds need the original provider path or dashboard.
- [ ] Confirm the actual rider compensation policy before removing the current ₹40-per-completion value; do not equate customer delivery fee with rider earnings without an approved pricing rule.
- [x] New customer online checkout uses Cashfree PG Orders API and the official Cashfree Flutter SDK; Razorpay SDK and backend dependency were removed from the active checkout path.
- [x] Added Cashfree payment verification, retry reconciliation, signed webhook handling, and provider-confirmed refund state transitions. Unit tests cover payment amount/currency/order validation, webhook signature verification, and refund status mapping.
- [x] Added provider-specific Cashfree order/payment/refund identifiers while preserving Razorpay columns and marking legacy attempts as Razorpay for historical compatibility.
- [ ] Apply `20261126090000_cashfree_payment_provider.sql` in staging only after confirming `payment_attempts.razorpay_order_id` exists and reviewing the migration against the live schema.
- [ ] Regenerate and commit `rebesta_customers/pubspec.lock` using `flutter pub get`; the current lockfile still contains `razorpay_flutter` and does not yet record `flutter_cashfree_pg_sdk`.
- [ ] Configure Cashfree sandbox App ID/Secret, webhook secret, HTTPS webhook/notify URL and event subscriptions in staging; do not use production credentials until sandbox E2E passes.
- [ ] Run backend build/tests and all three Flutter app analyses/tests against the latest PR head; current GitHub Actions results do not yet cover the latest Cashfree commits.
- [ ] Apply `20261125200000_atomic_restaurant_stock_acceptance.sql` and `20261125220000_restore_stock_on_restaurant_cancellation.sql` in timestamp order; verify tracked/untracked items, insufficient stock, concurrent acceptance, cancellation restoration and repeated cancellation rejection.
- [x] Admin rider earnings now read actual `delivery_earnings`/wallet balances instead of estimating earnings as a fixed ₹40 multiplied by delivered orders or summing customer order value.
- [x] Added an audited, idempotent manual payout settlement RPC and admin endpoint. It settles pending earning rows, records a unique payout reference, and updates rider wallet/pending-payout balances atomically. This records a bank transfer after an administrator has completed it; it does not initiate a bank transfer.
- [x] Added `20261125210000_atomic_delivery_payout_settlement.sql`; payout references are serialized and idempotent across concurrent retries, and the RPC is service-role-only. Staging verification remains required.
- [ ] Apply `20261125210000_atomic_delivery_payout_settlement.sql` in staging; test repeated payout references, concurrent payout requests, empty balances, and wallet reconciliation.
- [x] Dispatch now also prevents a rider from holding simultaneous pending offers for different orders, with candidate filtering plus a database unique index and retry-on-conflict.
- [x] Removed delivery-app debug logging of full order/customer response payloads where reviewed.
- [x] Updated the delivery-completion migration to provision `delivery_earnings` and the rider wallet/counter columns before creating the OTP completion RPC.
- [ ] Apply and verify the delivery-completion migration in staging; confirm the resulting table/column types, constraints, and service-role grants before enabling OTP earnings settlement.
- [ ] Verify all public tables, policies, storage policies and RPC grants against the live Supabase schema; repository SQL alone cannot establish live database state.
- [ ] Replace temporary public partner signup block with authenticated admin-issued invitations and approval checks.

## Step 2 — Security and infrastructure
- [x] Explicit CORS allowlist and strict global DTO validation.
- [x] Endpoint-specific throttling on customer/partner/delivery auth and customer OTP routes; checkout payment creation, verification, reconciliation and admin refunds now have tighter limits. Support throttling remains pending until a support API exists.
- [ ] Secrets/config validation at startup; no secret leakage in logs.
- [ ] Health/readiness endpoints and structured logging.
- [ ] Docker backend image and local/staging compose.
- [ ] Reverse proxy/TLS and staging deployment configuration.
- [ ] CI gating: build, tests, lint, Flutter analyze, dependency/security checks.
- [ ] Caching only for safe read-only public data; invalidation correctness.
- [ ] Retry/timeout/circuit-breaker protections for external services; idempotency.
- [ ] Load testing, capacity planning and backups.
- [ ] Load balancing / service discovery / Kubernetes only when justified.

## Step 3 — Feature benchmark
### Customer app
- [ ] Location/address, serviceability and address book
- [ ] Restaurant discovery, search, filters, cuisine, dietary tags, sort
- [ ] Restaurant profile, menu/category search, item customization/add-ons where supported
- [ ] Cart validation, single-restaurant rules, price snapshots
- [ ] Coupons/promotions, fees, taxes and transparent totals
- [ ] Checkout, payment methods/provider reconciliation, safe retries
- [ ] Order status/live tracking, contact options, notifications
- [ ] History, reorder, favorites, reviews/ratings
- [ ] Cancellation/refund rules and support tickets
- [ ] Profile and privacy controls

### Restaurant partner app
- [ ] Onboarding and approval states
- [ ] Store availability/hours and serviceability
- [ ] Menu, price, availability and inventory controls
- [ ] Order queue, accept/reject and preparation-time management
- [ ] Order status transitions and handoff
- [ ] Offers/promotions
- [ ] Earnings, payout/reporting and analytics
- [ ] Push alerts and support

### Delivery partner app
- [ ] Signup/login, profile and KYC
- [ ] Online/offline and availability
- [ ] Offer dispatch, accept/reject and expiry
- [ ] Pickup navigation and pickup confirmation
- [ ] Customer delivery navigation and delivery OTP/confirmation
- [ ] GPS location updates, reconnect/offline handling
- [ ] Delivery history, earnings, withdrawals
- [ ] Safety, support and notification reliability

### Admin/back-office
- [ ] Restaurant/rider/customer management and verification
- [ ] Orders, refunds, payment reconciliation
- [ ] KYC moderation, menu/content moderation
- [ ] Coupons, banners, platform settings
- [ ] Support tickets, reporting/audit logs and permissions

## Step 4 — Staging deployment
- [ ] Dedicated staging environment and domain
- [ ] Staging DB project/backup and migrations
- [ ] Test payment credentials/webhook
- [ ] SMS/FCM/map configuration and budgets
- [ ] Dockerized API, reverse proxy, TLS, monitoring
- [ ] Android builds pointed only at staging

## Step 5 — E2E and beta readiness
- [ ] Customer signup/address/discovery/cart/coupon/checkout
- [ ] Payment success/failure/timeout/reconcile and duplicate webhook tests
- [ ] Restaurant accept/prep/ready flow
- [ ] Rider dispatch/accept/pickup/deliver with location and OTP
- [ ] Cancellation/refund/support/review flows
- [ ] Permissions, offline/network failure, reconnect, crash and performance checks
- [ ] Security checks, load tests, backup restore rehearsal
- [ ] Document known issues and beta exit criteria

## Release boundary
Steps 1–5 only. Play Store release preparation and publishing are deferred until staging and end-to-end readiness are achieved.

## Follow-up payment audit (latest PR head; runtime validation still pending)
- [x] Cashfree refund POST retries now reuse the persisted refund ID as the request idempotency key instead of generating a fresh key on each retry.
- [ ] Validate Cashfree refund idempotency header format against provider requirements and sandbox behavior.
- [ ] Review webhook failure-event ordering against payment retries: a failed attempt event must not prematurely block or mislabel an order when later payment attempts may succeed.
- [ ] Confirm SQL conversion RPC preserves all required order metadata and item snapshot fields compared with the original conversion RPC; verify schema and grants in staging.
- [ ] Execute payment tests/build and sandbox payment/refund scenarios; not run in this audit environment.


## Webhook lifecycle audit update
- [x] PAYMENT_FAILED_WEBHOOK no longer directly marks a local attempt terminal; failure webhooks may be out of order or followed by a later successful attempt. Local state is left to authoritative reconciliation.
- [ ] Verify webhook payload/signature/header configuration and event delivery behavior against Cashfree sandbox.
- [ ] Validate the Cashfree SQL conversion against schema: compare order metadata (coupon/subtotal/tax fields, if present), defaults, and constraints. The conversion currently inserts the same core fields as the original conversion but may omit ancillary fields.
- [ ] Add integration tests for webhook ordering (failure followed by success), duplicate success events, and simultaneous verify/webhook conversion; tests remain unexecuted.


## Cashfree conversion/concurrency audit (2026-11-25)
- Reviewed the Cashfree verification, reconciliation, webhook, refund and conversion RPC paths alongside the earlier Razorpay conversion RPC and order-type migration.
- The Cashfree conversion locks its payment_attempt row and checks an existing linked order, then checks for an order matching the Cashfree order ID; concurrent calls for the same attempt are serialized by the row lock. The provider-specific unique indexes provide additional collision protection, but staging race tests remain required.
- The Cashfree conversion RPC validates snapshot JSON after inserting the order row; PostgreSQL transaction rollback should undo the order insert on an exception, but moving validation ahead of insert would improve clarity and should be considered in a follow-up migration.
- The conversion persists discount, delivery fee and total, order type, provider IDs and order items. The attempt also stores subtotal and coupon code, but the reviewed conversion does not copy those into the order; confirm the live orders schema and reporting contract before deciding whether additional order fields are needed.
- The verification and reconciliation paths query Cashfree's authoritative payments list and require a successful payment matching the expected order, amount and INR currency. A success webhook triggers this same authoritative lookup instead of trusting its payload alone.
- Failure webhooks intentionally do not mutate attempt state; reconciliation handles terminal failure/expiry after checking provider state.
- **Not verified:** live schema/types/constraints/grants, RPC race behavior under simultaneous webhook + verify + reconcile, malformed snapshot rollback, duplicate provider payment IDs, sandbox event ordering, and integration tests. No migration applied and no deployment performed.


## Database security / privileged RPC audit notes (2026-11-25)
- Reviewed the public-schema lockdown migration: it enables RLS for all tables currently in the public schema and revokes direct table/sequence privileges from anon and authenticated roles. This is a deliberate API-only architecture boundary; staging must verify all app flows still use backend APIs and the service-role smoke test.
- The migration does not establish default privileges for future public tables; newly created tables/functions must be reviewed separately and secure grants/RLS explicitly.
- RPCs reviewed in this pass use SECURITY DEFINER and explicit search_path, with service_role-only execution grants/revokes for the inspected functions.
- **Concurrency concern for rider assignment:** the acceptance RPC locks the order row, but its check against the rider's other active offer/assignment is not a rider-level serialization lock. Simultaneous accepts of separate orders by the same rider need staging race testing and likely rider-level locking/constraint strategy.
- **Schema review is not live verification:** storage bucket policies, all existing public-table policies, live RPC grants, default privileges, direct mobile Supabase access dependencies and live table ownership remain unverified without database inspection.
- No migration or deployment was performed during this review.


## API authorization audit (2026-11-25; controller/service review, runtime validation pending)
- Customer endpoints examined: address CRUD uses customer ownership filters; order detail/tracking/history filter by authenticated customer; cart and payment attempt flows are customer-ID scoped. Partner order queries/status updates and inventory/profile endpoints use the JWT-derived restaurant partner ID as their scope.
- Delivery status transitions, active orders/history, location, wallet and earnings queries are generally scoped by JWT delivery-partner ID; acceptance and completion rely on database RPCs that bind order and rider IDs.
- Admin endpoints are guarded by a shared static `x-admin-key`. The guard fails closed and compares equal-length keys in constant time, but this remains a single shared-secret model (no individual admin identity, MFA, role permissions, or audit trail); deployment secrets, rotation and access controls must be verified.
- **Finding: delivery available-orders endpoint exposes recipient address details (including address and coordinates) and customer name to every authenticated delivery account**, regardless of KYC status or whether the order is currently offered to that rider. Acceptance is separately KYC-gated and offer-checked, but the listing endpoint still discloses personal data. This needs a privacy-minimizing listing contract (coarse pickup/drop details until a rider is eligible/assigned) and KYC/offer-aware filtering; validate app compatibility before changing its payload.
- Delivery tracking and active-delivery payloads include customer/rider contact and location data. These are expected to be restricted to the authenticated order owner or assigned rider respectively; verify realtime socket room authorization and app-side direct Supabase access in staging.
- No broad authorization bypass was confirmed in the inspected controller/service snippets, but review is not exhaustive: endpoint coverage, sockets, storage, Supabase live policies and runtime abuse tests remain outstanding.
- No code changes to API payloads were made in this audit pass because the available repository tools cannot run app contract tests or validate compatibility safely.


## Realtime/socket authorization review (2026-11-25)
- Customer, restaurant partner and rider room-join handlers compare requested IDs to authenticated token identity; order-room joins query the order and validate ownership/assignment.
- **Critical authorization gap identified:** the `rider_location` socket event checks only that the sender has the delivery role, then relays arbitrary payload/orderId into the corresponding order room. It does not verify the rider is assigned to that order, validate coordinates, or bind the event to server-side rider identity. A rider account could spoof location updates to other order rooms. Fix before staging: authorize active assignment against the database, derive rider ID from JWT, validate payload schema/ranges, and emit server-controlled fields only.
- Admin socket joining uses direct shared-key comparison and has no individual identity/role session. The shared static key approach is a temporary boundary; require server-side access control and key rotation review.
- Socket gateway CORS currently uses wildcard origin; it should be constrained to the approved app/web origins, coordinated with connection auth and client deployment.
- Findings recorded; realtime contract/runtime tests unavailable here, so no socket payload or access behavior changed in this pass.


## Socket rider-location remediation (2026-11-25)
- [x] Rider location socket handler now validates order ID and finite latitude/longitude ranges, looks up an order assigned to the authenticated rider in an active delivery state, and emits only server-derived order/rider identifiers plus validated coordinates and timestamp. Arbitrary payload relay is removed.
- [ ] Add socket integration tests for assigned rider, unassigned rider, wrong rider, invalid coordinates, malformed payload, and inactive order states; run backend tests/build on latest head.
- [ ] Socket CORS wildcard and shared-key admin socket authentication remain follow-up security issues; origin policy and admin identity/permissions need environment and client-contract verification before safely changing them.
- No UI, migration or deployment changes; PR remains open/draft.


## Rider GPS data minimization and socket contract check (2026-11-25)
- [x] Inspected rider Flutter socket service and GPS service: the current GPS publisher sends location updates through the authenticated REST endpoint, not the gateway's `rider_location` Socket.IO event. Thus the socket event's rider-location broadcast is not presently the client publisher contract.
- [x] Removed rider GPS coordinate and full response/error-body debug logging from the Flutter GPS publisher; location values and provider response bodies should not be emitted to routine debug logs.
- [ ] Validate REST location endpoint ownership/active-order scoping, rate/accuracy constraints, and customer tracking contract in runtime/staging; not yet established by this file-level review.
- [ ] Validate socket status names against DB schema/client tracking contract and add integration tests. Gateway rider-location handler should not be treated as end-to-end GPS tracking until a client contract uses it.
- [ ] Available-orders endpoint still exposes customer name and full delivery address/coordinates to authenticated riders before KYC/offer eligibility; needs a verified privacy-minimized app contract before changing response.
- No UI/design changes, DB migration, deployment, or test execution in this pass.


## GPS REST input validation (2026-11-25)
- [x] Added server-side DTO latitude/longitude numeric validation and geographic bounds (-90..90, -180..180), rejecting NaN and infinities.
- [x] Added unit tests for valid boundaries/coordinates and out-of-range/non-finite values; execution remains unverified in this environment.
- [ ] Verify rate limiting, tracking permission/consent, and active-order fan-out behavior in staging; current endpoint updates the rider's stored location and emits to customers on their active assigned orders.
- [ ] Available-order feed still returns recipient details before rider eligibility/assignment; safe contract change requires app compatibility validation.
- No UI/design changes, migrations or deployment.


## Available-orders privacy remediation (2026-11-25)
- [x] Available-order feed now verifies the authenticated rider's KYC status server-side before returning orders; unverified riders receive a forbidden response.
- [x] Unassigned-order feed payload removes customer name, street address, landmark and precise coordinates; it exposes only coarse city/state/pincode while retaining existing card fields to avoid layout changes.
- [ ] Verify delivery app behavior, schema relation shapes, KYC denial and available-order filtering in staging; backend/client tests were not executable in this environment.
- [ ] Socket gateway CORS and shared-key admin socket identity remain pending coordinated client/config review.

- [x] Socket.IO browser CORS now uses the same explicit CORS_ALLOWED_ORIGINS configuration as HTTP rather than wildcard origin; native clients without browser origins remain supported by Socket.IO's origin handling.
- [ ] Confirm staging web origins and native-client connectivity; CORS configuration and authentication need runtime validation.


## Admin socket authentication follow-up (2026-11-25)
- [x] Admin socket room join now fails closed when the admin key is missing and compares equal-length key buffers with a timing-safe comparison, matching the HTTP admin guard's shared-key model.
- [ ] Replace shared admin key with individually authenticated/authorized admin identity and audit trail; staging verification required.


## Shared delivery-feed socket privacy fix (2026-11-25)
- [x] KYC-verified riders only can join the shared delivery feed socket room; the room join now checks server-side rider KYC.
- [x] Shared fallback broadcasts expose only coarse destination area and placeholder customer name, removing street/landmark/coordinates and personal name.
- [ ] Validate rider-app payload compatibility and feed-room join behavior in staging; tests not run in this environment.


## Payment/database RPC audit checkpoint (2026-11-25)
- [x] Inspected Cashfree paid-order conversion SQL: locks payment_attempt row FOR UPDATE, validates provider and order-type/address invariants, creates order/items and updates attempt/cart in one transaction, service_role-only execute grant.
- [x] Inspected delivery acceptance RPC: order row FOR UPDATE, checks ready/unassigned state, validates pending-offer recipient and rider's other live offer, updates assignment and settles offers in same transaction; service_role-only execute grant.
- [x] Inspected restaurant acceptance RPC: row locks order and menu stock, payment guard for Razorpay/Cashfree, decrements inventory and transitions order atomically; service_role-only execute grant.
- [!] Public-schema RLS lockdown migration revokes anon/authenticated table/sequence privileges broadly. This is intentionally high-impact and requires staging smoke-tests for every mobile/backend workflow before application; no migrations executed.
- [ ] Review actual deployment grants, RPC security-definer ownership/search_path, idempotency behavior under concurrency and staging race tests; runtime verification not available here.


## Tracking endpoint log privacy follow-up (2026-11-25)
- [x] Removed tracking endpoint logs that printed customer destination/address, rider identity/location, route coordinates, ETA details, and provider error details that could carry tracking context.
- [ ] Review remaining backend logs for PII, credentials, provider payloads, OTPs and precise GPS; structured logging/redaction and staging verification remain pending.
- No UI changes, migrations, deployment or test execution.


## Payment notification logging review (2026-11-25)
- [x] Reduced severity of best-effort socket/FCM notification failures after atomic order conversion from error to warning; these notification failures must not be mistaken for payment/order-conversion failures.
- [ ] Adopt structured, redacted logs and correlation IDs; review remaining logs repository-wide and validate log retention/permissions.
- [ ] Validate webhook and payment retry/concurrency behavior in sandbox; code review alone is not runtime verification.


## Cashfree error-response hardening (2026-11-25)
- [x] Payment order-creation failure now returns a generic client-facing error instead of forwarding upstream provider error details.
- [ ] Continue reviewing error responses and logs for leakage; payment sandbox and concurrency validation remain outstanding.


## OTP provider error-response hardening (2026-11-25)
- [x] Customer OTP send/verify now return sanitized service-unavailable/provider errors instead of surfacing provider diagnostic details.
- [x] Invalid OTP verification returns a generic authorization error.
- [ ] Verify OTP flows in staging, including provider outages and invalid codes; automated tests/runtime verification remain outstanding.


## OTP profile-completion abuse protection (2026-11-25)
- [x] Added endpoint-specific throttling (5 requests/minute) to customer profile completion, which previously had no route-level throttle.
- [ ] Validate throttling in staging and review distributed throttler storage for multi-instance deployments.


## Partner OTP provider hardening (2026-11-25)
- [x] Partner OTP send/verify now suppress upstream diagnostic details and normalize provider transport/response failures.
- [x] Invalid OTP uses a generic authorization response.
- [ ] Validate provider failure paths and login flows in staging; tests not executed.


## Delivery availability endpoint hardening (2026-11-25)
- [x] Going online now requires account status `approved` and KYC status `verified`.
- [x] Availability endpoint response selects only explicit partner fields instead of returning the complete database row.
- [x] Client-facing database failure response no longer forwards raw update error details.
- [ ] Confirm approval/status values and behavior in staging; tests not executed.


## Delivery completion OTP abuse/input hardening (2026-11-25)
- [x] Validate delivery completion order ID as UUID and OTP as 4–8 numeric digits at DTO boundary.
- [x] Rate limit authenticated delivery completion OTP endpoint to 5 attempts/minute per throttler key.
- [ ] Validate expected OTP format against database function and test in staging; test suites not executed.


## Rider order-state error sanitization (2026-11-25)
- [x] Sanitized database error details returned by rider order lifecycle transitions (arrival, pickup, cancellation/out-for-delivery guarded updates) to avoid leaking internal database diagnostics.
- [x] Existing lifecycle transitions use rider/order-scoped and status-conditional updates; concurrent state change checks retained where present.
- [ ] Validate lifecycle and retry behavior in staging; tests not executed.


## Rider wallet and earnings response hardening (2026-11-25)
- [x] Sanitized rider wallet and earnings database error responses.
- [x] Sanitized delivery completion RPC failure responses to avoid exposing database/provider details.
- [ ] Review completion RPC and ledger uniqueness/atomicity directly in database migrations; verify earnings aggregation completeness and configured payout rules.
- [ ] Runtime validation and tests pending.


## Restaurant partner security audit (2026-11-25; six areas reviewed, runtime verification pending)
- [x] Ownership and scope: partner menu, stock, order listing, order details, and order-status paths use JWT-derived restaurant partner ID filters; no ID is taken from a client body for these scopes in the inspected paths.
- [x] Order isolation: partner order queries and order detail lookups are scoped by restaurant partner ID. Order status writes also use scoped conditional updates or partner-bound atomic RPCs.
- [x] Menu operations: create/update/delete/availability operations are partner-ID scoped; update now omits undefined fields rather than overwriting omitted optional fields. Partner-menu debug output removed and menu database failures sanitized.
- [x] Inventory: stock edits are scoped to partner-owned menu item and DTO bounds quantity to 0–1,000,000. Acceptance/cancellation stock movements rely on reviewed atomic RPCs.
- [x] Acceptance/cancellation: acceptance and stock consumption are performed by atomic RPC; cancellation of accepted/preparing orders uses stock restoration RPC. Pending unpaid online order acceptance guard remains in place.
- [x] Order-status logs/errors: removed noisy partner order query diagnostics and customer-data-bearing log context; sanitized order retrieval and status-transition error responses.
- [!] Findings/follow-up: menu create/update DTO validation and multipart conversion need end-to-end testing; partner JWT currently appears to validate claims rather than re-query account approval/block state on every request; profile updates need a strict DTO and field-level validation review; public restaurant listing and dashboard revenue semantics need reconciliation (e.g. delivered/completed status variants, paid/COD/refunded treatment); payout/admin permissions remain shared-key based.
- [ ] Tests and staging checks for cross-partner access, menu price update, stock bounds, concurrent accept/cancel, cancellation stock restore, blocked partner tokens, and revenue/payout reconciliation. Not executed here.
- No UI changes, migration, merge or deployment.


## Customer order lifecycle review (2026-11-25; code-level, runtime verification pending)
- [x] Customer order history, detail and tracking queries are scoped to authenticated customer ID.
- [x] Removed provider/database error detail exposure in legacy order creation/listing and reduced order notification log context.
- [!] Legacy `POST /orders/checkout` creates a pending order and snapshots item prices from cart rows; it does not independently revalidate menu item ownership/availability/current price or use the Cashfree payment-attempt conversion path. Treat this route as legacy and verify app usage; do not rely on it for paid checkout integrity. Cashfree checkout separately performs server-side cart/menu/price checks.
- [!] Legacy checkout order + item insert is not one RPC transaction; it compensates by deleting the order when item insertion fails, but cleanup failure could leave orphaned rows. Race tests and retirement/replacement with the Cashfree path are recommended.
- [!] Coupon lookup in this legacy checkout path currently calculates no discount; address and restaurant coordinate/fee inputs are checked but live availability and pricing need staging validation.
- [ ] Test cross-customer detail/tracking, stale cart price, unavailable menu items, item-insert rollback, duplicate checkout, and legacy-vs-Cashfree client routing. Tests not executed.
- No UI changes, migrations, deployment or merge.


## Cashfree payment/refund audit pass (2026-11-25; runtime verification pending)
- [x] Customer payment verification and reconciliation lookup scope payment_attempts by customer ID and provider.
- [x] Refund endpoint is AdminGuard-protected and throttled; refund request claims paid -> refund_pending with compare-and-set, persisting a refund ID before provider interaction. Retry fetches existing refund ID and avoids issuing a second refund ID.
- [x] Refund-status webhook updates are scoped to provider order/refund identifiers and refund_pending state; terminal refund failure returns payment state to paid, success to refunded, pending/on-hold stays refund_pending.
- [x] Webhook signature validation uses HMAC SHA256, timestamp + raw body, constant-time compare. Payment success processing queries provider payment data before conversion; failure webhook does not terminalize attempt.
- [x] Sanitized payment attempt lookup, restaurant lookup, insert and atomic-conversion errors to avoid exposing database diagnostics.
- [!] Refund authorization is based on the shared AdminGuard/API key, not individual admin identity or role-level permissions; refunds require stronger auditability and approval policy before production.
- [!] Refund amount is full order total and there is no partial refund workflow; order total/provider refund consistency and refund webhook event dedupe should be verified with Cashfree sandbox and database constraints.
- [!] Reconcile and verify provider fetches are not broadly caught/sanitized at all points; inspect exception handling and test provider outages, malformed payloads, conflicting payment/refund events, and webhook replay.
- [ ] Sandbox tests for concurrent refund calls, provider timeout after refund creation, duplicate/out-of-order webhook delivery, amount mismatch, partial payments, multiple SUCCESS payments, and reconciliation races. Not executed.
- No UI changes, deployment, merge or migrations.


## Customer auth/session audit (2026-11-25; runtime verification pending)
- [x] Customer OTP challenge JWT binds purpose, phone number and provider session; short-lived. OTP verification checks token, phone binding and provider result.
- [x] New-customer profile completion proof is purpose/phone-bound and short-lived; checks existing account and relies on mobile uniqueness to protect races.
- [x] Signup via legacy password route disabled; profile update is JWT-guarded and name-only.
- [x] Customer JWT strategy validates role and matching sub/customerId, expiry, and startup JWT secret length.
- [x] Sanitized profile-query error details.
- [!] Legacy email/password login remains available for historical customers; ensure nullable/legacy passwords and account status are handled, and decide whether to retire it. No account-status/disabled-user lookup in JWT validation identified in reviewed files.
- [!] OTP verify/send and profile completion rely on global in-memory throttling (distributed rate limiting is still pending); confirm provider-session reuse behavior and resend/verification abuse limits under staging.
- [ ] Verify mobile-number normalization/uniqueness, OTP replay, token replay/expiry, blocked account behavior, legacy password account compatibility, profile mutation DTO validation, and duplicate profile creation under concurrency. Tests not executed.
- No UI changes, migrations, deployment or merge.


## Admin security review (2026-11-25; runtime verification pending)
- [x] Admin controller is guarded at controller level with AdminGuard for all routes; guard fails closed without configured key and compares equal-length key buffers timing-safely.
- [x] Admin payout endpoint requires payout reference DTO validation; payout is executed through transactional payout RPC reviewed earlier.
- [x] Admin order cancellation conservatively limits cancellation to pending orders with payment pending/failed/refunded and repeats status predicates in update to reduce races.
- [x] Restaurant approval/rejection/block/unblock use constrained conditional state updates for the restaurant transition paths reviewed.
- [x] Sanitized admin service database errors, including payout RPC error details.
- [!] Single shared ADMIN_API_KEY is broad authorization: all admin routes (customers, order details, KYC, payout, refunds, partner blocking) share same privileges; lacks distinct identity, role/permission controls, key rotation lifecycle, and per-action audit log. High-priority production risk.
- [!] Admin service returns substantial customer/partner/order PII and sensitive profile fields in detail/list operations. Restrict admin access further and audit minimization/retention.
- [!] Block/unblock rider operations currently update availability fields without a distinct account-status/blocked flag in reviewed service paths; ensure rider auth/dispatch logic reliably treats blocked accounts as disabled.
- [!] Admin dashboard/analytics aggregations appear to include orders without consistent paid/refund/COD reconciliation filters; financial definitions require review.
- [ ] Test unauthorized access to every admin route, key rotation, payout/refund restrictions, state-transition races, blocked rider JWT/socket/feed behavior, and PII exposure. Tests not executed.
- No UI changes, deployment, merge or migrations.


## Database/RLS/schema audit (2026-11-25; migration execution/live verification pending)
- [x] Reviewed RLS migration inventory and the public-schema lockdown migration: enables RLS across public tables and revokes table/sequence privileges from anon/authenticated roles.
- [x] Reviewed Cashfree conversion RPC grant restriction: revoke PUBLIC/anon/authenticated and grant execution only to service_role; RPC locks payment attempt and creates order/items in transaction.
- [!] RLS lockdown is migration content only; not confirmed applied to the actual Supabase project. Verify table coverage, policies, grants, storage policies, and service-role connectivity live.
- [!] Default privileges for newly created public tables/sequences and storage bucket policy coverage need explicit audit; table/sequence REVOKE on current tables alone does not establish future defaults.
- [!] SECURITY DEFINER RPCs reviewed in migrations commonly use SET search_path = public. Inspect every function for object qualification/search-path hardening and verify PUBLIC execute revocation/grants for each function.
- [!] Supabase client uses service-role key; privileged API access therefore depends heavily on backend guards, secrets, and endpoint authorization. Key must never appear in client builds or logs.
- [ ] Live SQL verification: all public tables RLS enabled; policies reviewed; anon/authenticated privileges absent; function execute grants scoped; storage bucket permissions audited; tests using direct anon REST requests. Not executed.
- No migration applied, deployment, merge or UI change.


## Infrastructure, CI/CD and resilience audit (2026-11-25; code-level)
- [x] Global Nest throttling is configured at 100 requests/60 seconds; controller-specific tighter limits exist for sensitive OTP routes.
- [!] Global throttler currently uses default in-memory storage: not shared across replicas, resets on restart, and can be bypassed through multiple instances. Distributed store and reliable client-IP handling behind proxy are pending.
- [x] CORS uses explicit allowlist; global validation pipe transforms, whitelists and rejects unknown DTO properties.
- [x] CI backend job installs locked dependencies, verifies Jest setup, builds, runs tests; lint currently continue-on-error. Flutter matrix installs, analyzes and tests; analyze currently continue-on-error.
- [x] Dockerfile multi-stage Node 22 Alpine build/runtime, production-only dependencies, non-root node user, build output only in runtime.
- [!] CI currently targets pushes/PRs to main; the active PR branch is not automatically included in this workflow trigger unless merged/targeted accordingly. CI execution on PR #27 is not verified.
- [!] No cache layer, reverse-proxy config, load balancer, API gateway, orchestrator, service-discovery or circuit-breaker implementation found in inspected backend/repo paths. These are deployment architecture choices, not blindly added to code.
- [!] Docker runtime hardening remains: pin base images/digests, add healthcheck, drop capabilities/read-only filesystem where practical, non-root already present, review secrets/environment handling, and image scanning.
- [ ] Validate forwarded IP / trust-proxy configuration with actual ingress; don't trust arbitrary X-Forwarded-For. Staging multi-instance throttle and fault-injection tests pending.
- [ ] Build/test, CI run, container scan and deployment verification not executed.
- No UI changes, deployment, merge or migrations.


## Cache design and read-path review (2026-11-25)
- Inspected menu, restaurant, category and banner read services/modules.
- Candidate cache boundaries: public restaurant discovery/detail, public restaurant menu, customer menu filtering, category list, active banner list. Use short TTLs and cache version/key namespaces.
- Cache must not bypass restaurant approval/open-state checks or menu availability; cached menu/restaurant data is discovery-only. Checkout and payment must continue fresh authoritative validations and not consume cached price/stock/availability for authorization or financial decisions.
- Partner mutation operations (menu create/update/delete/availability toggle; store profile changes; banner admin CRUD) need coordinated invalidation or bounded TTL. Cache writes must be bypassed on errors and use safe serialization.
- Current code uses Supabase query service directly; Redis client/cache provider is not present in inspected modules. Adding a Redis dependency without choosing/confirming managed Redis endpoint, deployment configuration, secrets, network access, and health/failure behavior would risk breaking availability. No code changes to cache paths in this pass.
- Recommended first implementation: Redis-backed injectable cache provider with fail-open reads/writes (DB remains source of truth), scoped key namespaces, TTL, no caching of personalized/favorite/financial/order/cart/auth data, cache invalidation after successful writes, and bounded TTL fallback if invalidation fails. Add unit tests and integration validation before rollout.
- Redis infrastructure, credentials, connection health, CI verification, staging cache invalidation/consistency tests remain pending. No deployment or runtime tests performed.


## External-service resilience audit (2026-11-25)
- [x] Weather lookup Open-Meteo has 3s timeout and fail-soft returns zero surcharge.
- [x] Geocoder request has 5s timeout and returns null on failure.
- [x] ORS route lookup had no request timeout despite fallback handling; added 8s timeout so failures/timeouts fall through to distance estimation. Commit: 2b849374.
- [!] ORS route handler catches provider errors and returns straight-line estimate; checkout fee calculation should be reviewed for whether estimate is acceptable vs explicit fallback/fee policy and user disclosure.
- [!] Axios Cashfree operations inspected have 15s timeouts; retry/reconciliation strategy remains domain-specific and should avoid duplicate financial actions. Refund IDempotency exists; other payment operation failure paths still need fault-injection testing.
- [!] Notifications, Firebase/FCM, storage and remaining external dependencies require endpoint-by-endpoint timeout, retry/backoff, logging, and queue/delivery reliability audit. Firebase Admin initialization depends on file-based credential at runtime; verify deployment secret provisioning.
- [ ] Circuit breaker and centralized retry/backoff not implemented. Do not apply generic automatic retries to payment/refund/order mutation operations without idempotency protections.
- [ ] CI, unit tests, staging timeouts/provider outage/fault-injection, and live service checks not executed.
- No UI changes, deployment, merge or migrations.


## Push notifications and notification service hardening (2026-11-25)
- [x] FCM customer push path no longer logs customer identifiers, raw token-query errors, token counts or provider response counts. Token lookup failures quietly skip best-effort delivery.
- [x] Customer and partner push sending now catches provider exceptions and logs a generic failure, preventing best-effort push delivery from propagating exceptions.
- [x] Partner FCM token lookup checks query error and empty token list before sending.
- [x] Notification service database errors now return generic messages instead of exposing raw Supabase error strings.
- [!] FCM registration flows (customer/restaurant/delivery) still need consistency review: query/update/insert error handling and duplicate-token race prevention; invalid token cleanup and batching beyond Firebase multicast limits remain.
- [!] Notification persistence and push dispatch are synchronous, not durable queue-based; transactional outbox/background delivery, retries with bounded backoff and delivery observability are future work.
- [!] Storage upload validation, file-size/type/content verification, collision resistance, error sanitization, and private-document access checks require deeper controller/route audit.
- [!] Firebase Admin credentials file path is runtime dependency; secure provisioning/rotation and deployment validation pending.
- [ ] Tests and runtime verification not executed.
- No UI changes, deployment, merge or migrations.


## Storage service hardening (2026-11-25)
- [x] Food image upload service accepts only JPEG/PNG/WebP MIME labels and enforces a 5 MiB buffer limit.
- [x] KYC upload service accepts only JPEG/PNG/PDF MIME labels and enforces a 10 MiB buffer limit; validates partner UUID; generated UUID storage names avoid user-controlled filenames and collisions.
- [x] Upload error responses sanitized; uploads use upsert=false.
- [x] KYC signed URL duration shortened from 60 minutes to 5 minutes; path format validated.
- [!] MIME checks validate declared MIME only, not file magic bytes or malware scanning; route-level multipart limits and authorization must be verified. This service alone does not establish access control for issuing signed URLs (caller authorization must be audited).
- [!] Repository tree inspection found storage service but no dedicated storage controller in backend src; verify actual upload routes and partner/customer call sites before integrating.
- [ ] Tests and build not run; staging storage bucket configuration/access policies not verified.


## Socket identity logging reduction (2026-11-25)
- [x] Removed socket gateway success/denial debug messages that included customer, partner, delivery or JWT subject identifiers; generic comments replace those logs.
- [!] Socket rooms remain process-local; multi-instance delivery requires a Socket.IO adapter/shared pub-sub and deployment validation.
- [!] Socket disconnect/reconnect strategy and durable event replay are not implemented; order state must remain retrievable through REST and client reconciliation.
- [!] Admin socket shared-key model remains broad and needs identity/role-based admin authorization and audit events.


## Cart, checkout and dispatch reliability follow-up (2026-11-25)
- [!] Cart service performs multiple sequential DB operations for cart creation/item updates; concurrent add requests may race without DB uniqueness/atomic upsert safeguards. Error messages in cart paths include raw provider/database details in several places and require sanitization review.
- [!] Checkout computes totals from stored cart item prices; current checkout path inspected does not re-fetch menu item prices/availability to verify freshness. This is a high-priority pricing/availability integrity gap; do not patch casually without atomic checkout/order-item transaction.
- [!] Coupon path in legacy checkout currently does not calculate discount; coupon code lookup is non-authoritative there. Must ensure legacy checkout is disabled/guarded or reconcile with Cashfree verified checkout flow.
- [!] Dispatch recovery uses in-process interval (10s) and can run on multiple instances concurrently; DB offer-claim predicates and uniqueness must be proven against simultaneous dispatchers. Multi-instance job coordination and durable scheduling remain.
- [!] Dispatch fallback and personal-offer timeout/retry require load/concurrency testing and careful state reconciliation.


## Storage / upload audit follow-up (2026-11-25)
- [x] Storage service validates non-empty buffers and declared MIME types, applies 5 MiB food image and 10 MiB KYC document size limits, and generates UUID storage filenames; upsert is disabled.
- [x] KYC documents use a private bucket and storage path is returned rather than a public URL; signed URL duration is 5 minutes and path validation is applied.
- [!] Validation currently relies on client/declarative MIME metadata and does not inspect file magic bytes or scan malware; MIME spoofing risk remains until byte-level validation and scanning are added.
- [!] Signed URL creation accepts a storage path but service-level code shown does not establish partner/customer authorization to that path. Authorization must be enforced at the calling route/controller and verified; source search did not return call sites.
- [!] Upload route multipart parser limits, storage bucket policy configuration, private KYC bucket isolation, image transformation, and access logging/retention were not verifiable in this code-only pass.
- [x] Notification service's customer-read, mark-read and delete paths now return sanitized generic DB failure messages (previously returned raw error.message). Commit: f0ebaafa.
- [ ] Add tests for malformed/magic-byte mismatches, oversized files at route and service layers, cross-partner KYC path access, signed URL expiry/access, storage outage, and notification ownership enforcement. Tests/build not executed.
- No UI changes, migrations, merge or deployment.


## Cart API error/privacy hardening (2026-11-25)
- [x] Replaced customer-facing cart service errors that interpolated database/provider diagnostics or menu item identifiers with generic messages; removed cart-fetch raw error logging.
- [x] Add/update quantity DTOs enforce integer quantities from 1 through 99.
- [!] Add-to-cart remains a multi-query flow (menu availability lookup, cart lookup/create, item lookup, then insert/update); concurrent requests may duplicate cart creation or race quantity increments without DB-level constraints/atomic RPC.
- [!] Cart-item price is stored from the menu lookup at add time; cart display and legacy checkout use stored cart item prices, and legacy checkout does not revalidate authoritative prices/availability. Cashfree checkout separately performs validation; client routing and legacy checkout retirement remain unverified.
- [!] Cart update/remove authorization is checked by reading cart ownership before mutation; concurrent delete/update and ownership policy should be covered by DB constraints/RLS plus tests.
- [ ] Verify unique constraints for customer/restaurant cart and cart/menu item, implement atomic upsert/increment if absent, and test concurrency/price freshness/ownership. Tests/build not executed.
- No UI changes, deployment, merge or migrations.


## Cart price snapshot improvement (2026-11-25)
- [x] When incrementing an existing cart item through add-to-cart, update its stored price to the current menu price alongside the new quantity. This reduces stale-price persistence for this mutation path, but is not an atomic checkout price guarantee.
- [!] Cart reads may still expose stored snapshot prices; cart quantity update endpoint does not refresh price from authoritative menu lookup. Legacy checkout remains unsuitable as an authoritative pricing path until verified/disabled.
- [!] Atomic cart creation/item increment protections remain unresolved; implementing DB RPC/constraints requires migration/schema verification and staging tests, not available in this pass.
- No migrations, deployment, merge, UI change. Build/test execution unavailable.


## Customer mobile privacy/recovery audit (2026-11-25)
- [x] Removed payment reconciliation debug output that included provider order identifiers, full reconciliation responses, exception details, and stack traces. Pending payment is retained when reconciliation throws, allowing later retry.
- [x] Removed customer live-delivery socket debug output that logged customer identifiers, order IDs, delivery location payloads, order status payloads, and socket errors.
- [!] Tracking-screen HTTP response logging, checkout/order-service response logs, auth/session lifecycle, socket rejoin authorization, and interruption/recovery behavior still need review. No runtime verification was performed.
- [!] Android release build currently uses debug signing in its release build type and placeholder application ID `com.example.rebesta_customers`; Play Store release configuration/signing and manifest privacy/permissions review remain outstanding.
- No UI changes, migration, deployment, merge. Flutter build/test execution unavailable.


## Customer checkout and order/tracking log privacy (2026-11-25)
- [x] Removed verbose checkout screen diagnostic logging, including checkout/payment response dumps and address/order context logs.
- [x] Removed order service diagnostic logging of checkout payloads, order-list response bodies, and related identifiers.
- [x] Removed tracking screen diagnostic logging of tracking responses and rider/location/order data.
- [!] Reconnection lifecycle, payment UI callback interruption behavior, and authorization/room-join enforcement still need end-to-end validation. Flutter analysis/build/tests not run.
- No UI changes, migration, deployment or merge.


## Mobile reconnect and error handling follow-up (2026-11-25)
- [x] Reconstructed the customer live delivery socket service after a log-removal edit exposed malformed callback syntax; reconnect enabled and customer-room rejoin occurs on each socket connect, while event payloads remain order-filtered.
- [x] Customer tracking API failures now display a generic message instead of propagating raw exception details into the screen error state.
- [!] Confirm socket server enforces authenticated customer identity for room joins, and run socket reconnection/order-event integration tests. Flutter analysis/build not run.
- [!] CI is PR/main-targeted and Flutter analyze remains non-blocking; Flutter tests are present, but release Android artifact/signing verification is not configured in the reviewed CI file.
- No UI/design changes, deployment, merge or migrations.


## Follow-up audit — customer auth/socket privacy (2026-11-25)
- [x] Customer AuthService no longer prints the saved session token; login-state check is quiet. OTP verification resets the in-memory profile-completion proof before processing a new verification attempt.
- [x] Legacy customer SocketService diagnostic logs removed (including customer-room identifiers and socket IDs/errors).
- [x] Backend socket order-status emission no longer logs order IDs/status payload details.
- [ ] Review legacy SocketService handshake authentication and room-join lifecycle: the reviewed legacy service does not currently attach the customer JWT or handle reconnect room rejoin. Prefer DeliverySocketService for authenticated order tracking; confirm legacy service callers and retire/secure it before release.
- [ ] Review customer logout/session invalidation and secure local token storage; SharedPreferences is currently used for token persistence, and clearing local preferences is not server-side revocation.
- [ ] Run Flutter analyze/tests and socket runtime integration checks; these changes have not been locally executed or staged.

- [x] Customer profile screen no longer prints raw profile API exceptions in debug output.
- [x] Expired customer sessions clear cached token, customer ID, name and email before redirecting to login; pending payment reconciliation data remains untouched.

- [x] Customer logout now removes only authentication/session identity keys instead of clearing all SharedPreferences, preserving pending Cashfree reconciliation and other app state. In-memory OTP proof is also cleared.
- [ ] Replace debug Android release signing, establish the permanent Play Store application ID, configure release signing securely (not committed), and validate release manifest/build. No signing secrets or package identity have been fabricated.


## Socket authorization and tracking audit follow-up (2026-11-25)
- [x] Inspected customer, partner, rider, order-room and admin join handlers in the backend SocketGateway: handshake JWT validation is required; customer/partner/rider joins compare requested room identity against verified token claims; order-room join checks DB ownership; rider location updates are scoped to the assigned rider and active order.
- [!] Customer tracking currently uses the authenticated customer room and filters incoming payloads by order ID client-side. Server-side customer-room authorization is verified, but order-specific delivery location publication and client event names must be reconciled across gateway/service callers before relying on live tracking.
- [x] Traced the actual rider REST location-update path: the JWT-guarded controller derives rider identity from the token, and DeliveryService broadcasts `delivery_location` to each customer's authenticated room for the rider's active orders. This matches the customer's `delivery_location` listener and orderId filter. The separate SocketGateway `rider_location` event emits `rider_location_update` to the order room, but the reviewed customer tracking service does not depend on that event.
- [!] Both location paths still require runtime/integration tests; the separate socket event should be reconciled with app usage before relying on it.
- [!] Legacy customer SocketService is not used by the reviewed tracking screen and lacks JWT handshake auth; its room join is server-denied unless a valid authenticated socket context exists. Confirm no other app feature relies on this legacy service before removal.
- [!] Shared admin socket room uses a static shared API key in handshake, not a scoped admin identity/session; remains a security redesign item.
- No UI change, migration, merge or deployment. Runtime socket tests were not run.


## Customer session and socket follow-up audit (2026-11-25)
- [ ] JWT storage remains in plaintext SharedPreferences (`token`). The dependency list has no secure-storage package; migration requires dependency/lockfile resolution and Android/iOS platform review before implementation.
- [x] Customer tracking screen uses `DeliverySocketService`, which supplies JWT via Socket.IO auth handshake, re-joins customer room on connect/reconnect, and filters tracking events by order ID.
- [ ] Legacy `SocketService` has no JWT auth handshake and emits `join_customer` with a caller-supplied customer ID. Server room authorization rejects unauthenticated identity, but the service should be retired only after complete call-site tracing; it has not been proven unused.
- [ ] Session expiry (`Session.expire`) still removes token and identity keys from SharedPreferences; migrate expiry cleanup to the eventual secure-storage abstraction.
- [x] REST rider-location controller path passes authenticated delivery-partner identity to service. Service persists coordinates and emits customer-room location events for assigned active orders; tracking client filters by order ID. No throttling/rate limiting specific to GPS updates was verified in this pass.
- [ ] Add explicit rider-location throttling/abuse controls, while preserving normal GPS cadence and assignment validation.
- [ ] Secure-storage implementation and legacy socket call-site tracing are pending; no code changes or dependency resolution were performed in this audit pass.


## Legacy customer socket hardening (2026-11-25)
- [x] Legacy SocketService now reads session token/customer identity from stored session, attaches JWT in Socket.IO handshake, avoids connecting without session credentials, and re-joins its verified customer room on reconnect.
- [x] Legacy joinCustomer validates the supplied ID against the locally stored identity before requesting the room. Backend remains responsible for authoritative JWT/room authorization.
- [!] Full call-site tracing remains incomplete; this is hardening, not proof the legacy service can be retired. Flutter analysis/tests and runtime socket tests were not executed.
- Commit: 832a751daf4ac44d96d525e34c587a6165a6ed70. No UI changes, migrations, merge or deployment.


## Rider GPS rate-limit follow-up (2026-11-25)
- [x] Applied route-level throttling to the JWT-protected `POST /delivery/location` endpoint: maximum 30 requests per 60 seconds, complementing global throttling. This limits noisy clients and abuse while allowing a normal GPS cadence.
- [x] Location DTO constrains latitude/longitude to valid numeric geographic ranges (reviewed).
- [!] Throttler storage is in-memory per backend instance per earlier infrastructure audit; limits are not shared across replicas and restart-reset behavior remains. GPS throttling is route/IP-context based according to current throttler configuration, not proven per rider identity. Validate cadence with rider-app telemetry/runtime tests and multi-instance setup before release.
- Commit: e5b75cae8d2f9bc2b3e4cf4de333309a5af01d61. No UI changes, migration, deployment or merge.


## Rider GPS client privacy follow-up (2026-11-25)
- [x] Removed rider location-update HTTP success response and payload logging, including response bodies, from the delivery location service. Failed GPS sends no longer log provider exception details or response payloads.
- [!] GPS stream remains high-accuracy with a 10-metre distance filter; actual cadence, background behavior, connectivity recovery and throttle compatibility require device/runtime testing. Stream errors are intentionally silent in this pass.
- [ ] Verify location-service lifecycle, duplicate subscription prevention, GPS cadence under real devices, and delivery location throttling against backend limits with tests/telemetry.
- Commit: 129f052ae4644e6a2753f7e53bee10bb7a034f93. No UI changes, migrations, merge or deployment.


## Legacy customer socket caller trace (2026-11-25)
- [x] Reviewed customer order tracking screen and active `DeliverySocketService`: the tracking screen uses the order-specific service with JWT handshake, reconnect customer-room join, and order-ID event filtering.
- [!] The separately hardened legacy `SocketService` has no identified call site in the reviewed source tree/search. Search coverage is not runtime proof; avoid deleting it until a complete caller/build trace confirms it is unused.
- [ ] Confirm callers using a full source search and Flutter analysis; then retire or consolidate the duplicate service safely.
- [ ] Secure JWT storage migration remains blocked on dependency/platform/lockfile resolution and testing; don't perform partial storage migration.


## Cart quantity price freshness (2026-11-25)
- [x] Cart item quantity update now fetches the current menu item price and availability from the backend before updating the cart-item price snapshot. Unavailable items are rejected; ownership checks remain in place.
- [!] This is not an atomic cart operation and does not eliminate races between menu changes and cart writes. Checkout remains responsible for authoritative pricing. Runtime/database tests have not been run.
- Commit: 65d07438f259e68647caca4506872ac1597be8ea.


## Cart concurrency audit disposition (2026-11-25)
- [!] Existing cart creation and item quantity updates use separate read/write calls. Concurrent requests may create duplicate carts or lose increments. Do not claim this is fixed by price-snapshot refresh.
- [ ] Resolve safely with database uniqueness constraints and an atomic RPC/transaction approach, plus tests and staging verification. Schema change is intentionally deferred; no migration executed.


## Address API error privacy (2026-11-25)
- [x] Customer address CRUD service now replaces raw Supabase error throws with generic operation-specific errors for create, read, update, and delete, reducing exposure of provider/database error payloads.
- [!] API ownership filters on update/delete remain in place; behavior for missing records and downstream exception mapping has not been runtime tested.
- Commit: ebba20aec72cf50a2650136f1abc7dac89152b52.
