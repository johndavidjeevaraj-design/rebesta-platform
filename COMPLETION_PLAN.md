# Rebesta Platform — Completion Plan (Steps 1–5)

Benchmark: core functional capabilities of major food delivery platforms; not copying proprietary branding or design.

## Step 1 — Audit and remediation
- [x] Repository map: NestJS API, Supabase/Postgres, Razorpay, socket.io, Firebase; customer, restaurant-partner, and delivery Flutter apps.
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
- [x] Captured Razorpay payments are checked against the expected checkout amount, currency and order before order conversion (verify, reconcile and webhook paths).
- [ ] Confirm OTP/session changes compile and pass tests on latest PR head.
- [ ] Confirm all DTOs have validation decorators; empty DTO files and inline body types remain under review.
- [x] Admin delivery-KYC rejection now uses a validated DTO (non-empty reason, maximum 500 characters) with DTO unit tests.
- [x] Delivery app completion now opens the OTP flow directly and no longer calls the legacy no-OTP completion endpoint.
- [x] Admin order cancellation now permits only pending orders with unpaid, failed, or already-refunded payment states; the update rechecks state atomically and rejects paid/refund-pending or restaurant-accepted orders. Unit tests cover allowed and blocked states.
- [x] Rider cancellation is now limited to pre-pickup states; `picked_up`, `out_for_delivery`, and later states cannot be returned to the open delivery pool. Added lifecycle unit tests.
- [x] Removed the remaining customer delivery OTP debug log from the rider app.
- [ ] Support API remains a placeholder despite DTO files; implement only after the support-ticket schema and app contract are verified.
- [x] Dispatch now has a database-enforced single-pending-offer-per-order index migration; duplicate concurrent inserts are treated as an already-claimed order, not as a reason to broadcast. Stale fallback broadcasts re-check order readiness, assignment, and pending offers.
- [ ] Apply and verify `20261125170000_one_pending_delivery_offer_per_order.sql` in the staging database before enabling this dispatch guarantee in a deployed environment.
- [ ] Dispatch fairness still needs a separate concurrency strategy to prevent one rider receiving simultaneous pending offers for different orders.
- [x] Removed delivery-app debug logging of full order/customer response payloads where reviewed.
- [ ] Verify the delivery completion RPC against the live schema: `delivery_earnings` table and `delivery_partners` wallet/counter columns are referenced but are not created by repository migrations. Do not apply the migration until schema and grants are confirmed.
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