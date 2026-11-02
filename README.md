# Rebesta — Multi-App Food Delivery Platform

A multi-application food-delivery platform organized around a NestJS backend and three Flutter clients: customer, restaurant partner and delivery rider.

The repository includes a launch runbook covering infrastructure setup, database migrations, backend deployment, app builds and production smoke tests. Treat that runbook as the operational source of truth and verify every step against the current deployment environment before launch.

## System architecture

| Component | Directory | Technology |
| --- | --- | --- |
| Backend API | `rebesta_backend/` | NestJS, Supabase Postgres, Razorpay, Socket.IO |
| Customer application | `rebesta_customers/` | Flutter |
| Restaurant partner application | `rebesta_partner/` | Flutter |
| Delivery rider application | `rebesta_delivery/` | Flutter |
| Database migrations | `rebesta_backend/supabase/migrations/` | SQL / Supabase |

All mobile clients communicate with the backend API. The runbook specifies that privileged database access remains server-side and that row-level security is enabled for the database tables.

## Platform workflows

- Customer registration and OTP login.
- Restaurant discovery, menu browsing, cart and checkout.
- Razorpay payment integration and webhook verification.
- Restaurant order acceptance and preparation workflow.
- Rider offers, delivery status updates and KYC gating.
- Live order / rider updates using Socket.IO.
- Admin operations for restaurant approval, delivery KYC and analytics.

## Getting started

Start with [LAUNCH.md](LAUNCH.md). It documents required service accounts and environment variables, database migration order, backend setup, mobile build commands and a production smoke-test checklist.

### Backend

```bash
cd rebesta_backend
npm ci
npm run build
npm run start:prod
```

### Flutter apps

Pass the deployed API URL at build time:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://<your-backend-domain>
```

Repeat in each of the three app directories. Do not ship release builds using the Android emulator development URL.

## Security and operations

- Keep Supabase service-role credentials, JWT secrets, admin keys, Razorpay secrets, webhook secrets and OTP provider keys in server-side deployment secrets.
- Never commit `.env` files, signing keys, keystores or customer data.
- Verify Razorpay webhooks using the configured webhook secret and authoritative payment state.
- Confirm database row-level security policies after migrations.
- Keep rider KYC approval as a server-enforced gate, not only a client-side UI condition.
- Run the full production smoke test in [LAUNCH.md](LAUNCH.md) before announcing a release.

## Next engineering priorities

1. Add CI for backend lint/build/tests and Flutter analyze/tests for all apps.
2. Add automated integration tests for checkout, webhook idempotency, partner order state transitions and rider offer acceptance.
3. Add end-to-end authorization tests for customer, partner, rider and admin roles.
4. Add observability for payment/webhook failures, socket disconnects, dispatch latency and delivery completion.
5. Document API contracts and database entity relationships.
6. Add privacy, data-retention and incident-response documentation.

## Project status

This README summarizes the repository's launch runbook and declared architecture. It does not independently certify that production deployment, payment settlement, all device builds or the full end-to-end smoke test have passed.

