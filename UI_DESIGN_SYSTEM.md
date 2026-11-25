# Rebesta Platform — UI Design System

Status: foundation for the customer, restaurant-partner, delivery-partner and admin experiences.

## Product direction

Build a confident, premium Indian food-delivery product with the speed and clarity expected from leading delivery apps, while retaining a distinct Rebesta identity. Do not copy Swiggy/Zomato logos, layouts pixel-for-pixel, illustrations, copy or proprietary assets.

## Experience principles

1. Fast to first action — users should be able to search, discover, accept an order or go online without navigating through decorative screens.
2. Clear hierarchy — one dominant action per screen; concise headings; supporting details visually quieter.
3. Operational clarity — order state, payment state, delivery state, availability and earnings must never depend on colour alone.
4. Trust at every step — show item prices, fees, taxes, delivery address, OTP and cancellation/refund state clearly.
5. Resilient states — every data-driven screen needs loading, empty, error, retry and offline/reconnect states.
6. Accessible by default — scalable text, semantic labels, 48dp minimum touch targets, adequate contrast and clear focus states.
7. Native performance — use Flutter-native components and animations; avoid web-style interaction patterns that feel unnatural on Android.

## Visual language

- Brand primary: Rebesta orange #F45A24 for primary actions and key highlights.
- Deep ink: #17211D for strong text and high-contrast surfaces.
- Fresh green: #18794E for positive operational states and food/freshness cues.
- Warm canvas: #F7F7F2 for the main light background.
- Surface: #FFFFFF for sheets and content surfaces.
- Muted text: #68736D; borders: #E5E9E4.
- Error: #C93636; warning: #A96508.
- Use colour semantically and consistently. Do not use green as a generic decorative accent or orange for destructive actions.

## Typography and shape

- Use the app's existing Google Fonts integration and establish one consistent type scale.
- Screen title: 24–28sp, section title: 18–20sp, body: 14–16sp, metadata: 12–13sp.
- Use 8dp spacing increments; 16dp screen gutters; 12–16dp component radii; 20–24dp for large promotional surfaces.
- Prefer clean surfaces, subtle dividers and restrained elevation. Avoid stacking cards inside cards.
- Motion should communicate state changes; keep transitions short and respect reduced-motion settings.

## App-specific priorities

### Customer app
- Location and serviceability at the top; prominent search; cuisine/category discovery; useful filters; restaurant cards with rating, ETA, cost and offer details.
- Keep cart and checkout totals transparent. Make unavailable items, substitutions, fees and payment outcomes explicit.
- Order tracking must distinguish placed, accepted, preparing, picked up, arriving and delivered states.

### Restaurant partner app
- Prioritize incoming orders, accept/reject deadlines, preparation controls and store availability.
- Use large, unmistakable order actions and clear status timelines.
- Keep menu availability, stock and pricing edits discoverable but guarded against accidental changes.

### Delivery partner app
- Prioritize online/offline status, available offers, active delivery instructions, navigation and OTP completion.
- Show earnings and payout state separately from cash/online collection.
- Design for outdoor readability: high contrast, large touch targets and minimal typing.

### Admin experience
- Prioritize operational queues, role-based access, auditability and safe destructive actions.
- Use dense tables only where they improve review speed; provide filters, pagination and clear empty/error states.
- Refund, KYC rejection and account suspension actions require explicit confirmation and reason capture.

## Implementation rules

- Preserve API contracts, route names, auth guards, payment logic and backend state transitions while redesigning presentation.
- Reuse existing services and state management; do not add mock production data to disguise missing API functionality.
- Never hardcode secrets, customer data, live order data or payment outcomes in UI.
- Keep screens responsive to small Android phones and tablets.
- Add widget tests for critical states and run flutter analyze and flutter test for each changed app.
- Record any feature that cannot be completed because the backend/API contract is missing; do not silently simulate it.

## Review checklist

- [ ] Visual hierarchy and brand tokens are consistent.
- [ ] Loading, empty, error, retry and offline states exist.
- [ ] Touch targets and text scaling are usable.
- [ ] No clipped/overflowing content on small screens.
- [ ] Destructive actions have confirmation and clear consequences.
- [ ] API, navigation and auth behaviour remain intact.
- [ ] Widget tests and analyzer pass.
