# Trade-Offs Summary

Key architectural and business decisions for Manik Golden Honey Co e-commerce platform, with rationale and accepted trade-offs.

---

## Inventory Management

### Pessimistic Inventory Locking
**Decision:** Reserve inventory at checkout start with 15-minute TTL.

**Rationale:** Small producer cannot afford overselling. Reputation damage from "sorry, we oversold" emails outweighs minor conversion reduction from temporarily locked inventory.

**Accepted trade-offs:**
- Temporarily reduces available inventory during checkout (abandoned carts lock stock)
- Requires background job for reservation cleanup
- Adds database complexity (`reserved_quantity` field)

**Reference:** [ADR-001](./decisions/ADR-001-pessimistic-inventory-locking.md)

### Firestore Transactions for Race Prevention
**Decision:** All inventory operations use Firestore transactions with automatic conflict retry.

**Rationale:** Data integrity is non-negotiable. Overselling or negative inventory causes operational chaos. Transaction overhead (50-100ms) acceptable for guaranteed consistency.

**Accepted trade-offs:**
- Transaction retry delays during high contention (100-500ms)
- 500 writes per transaction limit (constrains cart size)
- Higher Firestore costs (transactions count as multiple operations)

**Reference:** [ADR-008](./decisions/ADR-008-firestore-transaction-strategy.md)

---

## Order Processing

### Idempotent Order Creation (Webhook Primary)
**Decision:** Stripe webhook is primary order creation path; frontend confirmation is fallback. Both paths deduplicate via `stripe_payment_intent_id`.

**Rationale:** Customer must receive order even if browser crashes. Webhook provides automatic retries and reliability. Frontend provides immediate UX feedback.

**Accepted trade-offs:**
- Two code paths to maintain
- Relies on Stripe webhook reliability (99.9% delivery rate)
- Potential alert fatigue from transient Firestore failures

**Reference:** [ADR-007](./decisions/ADR-007-idempotent-order-creation.md)

### Cancellation Request with Admin Approval
**Decision:** Customer submits cancellation request; admin approves or denies within 24 hours.

**Rationale:** Stripe refund fees (2.9% + $0.30) not recoverable. Admin review allows fixing addressable issues (wrong address) without refunding. Protects small business from cancellation abuse.

**Accepted trade-offs:**
- Not instant (customer waits up to 24 hours)
- Admin workload for each cancellation
- May frustrate customers expecting self-service

**Reference:** [ADR-003](./decisions/ADR-003-cancellation-request-workflow.md)

---

## Customer Reviews

### Immediate Review Submission
**Decision:** Customers can submit reviews immediately after ordering, without waiting for delivery.

**Rationale:** Simpler implementation (no delivery tracking), higher participation rate (capture engagement immediately), and admin moderation provides quality gate. MVP timeline constraints favor simplicity.

**Accepted trade-offs:**
- Reviews may not reflect actual product experience
- Admin must reject premature "can't wait to try it!" reviews
- Potential customer confusion about when to review

**Reference:** [ADR-002](./decisions/ADR-002-review-timing-immediate.md)

### Approve/Reject-Only Moderation
**Decision:** Admin can only approve or reject reviews. No editing allowed.

**Rationale:** Trust is paramount. Admin-edited reviews create authenticity questions ("Did customer really write this?"). Rejection with reasons guides customer self-correction while preserving ownership.

**Accepted trade-offs:**
- More back-and-forth for fixable issues (typos, etc.)
- Customer friction from rejection
- Risk of abandonment after rejection

**Reference:** [ADR-011](./decisions/ADR-011-review-moderation-workflow.md)

---

## Discount Codes

### Order-Wide Discounts Only
**Decision:** Discount codes apply to entire cart, not specific products.

**Rationale:** Single product category (honey) makes product-specific codes unnecessary. Order-wide is simpler to implement, explain, and administer. Reduces edge cases and testing burden.

**Accepted trade-offs:**
- Cannot run product-specific promotions
- Cannot incentivize slow-moving products specifically
- Margin impact applies to all products equally

**Reference:** [ADR-004](./decisions/ADR-004-discount-code-scope-order-wide.md)

### Discount Lock-In at Payment Intent
**Decision:** Discount percentage locked when PaymentIntent created. 5-minute grace period for expired codes.

**Rationale:** Customer trust requires "price shown = price charged." Stripe PaymentIntent amount is immutable. Lock-in prevents surprises at order creation.

**Accepted trade-offs:**
- Over-redemption possible (max_redemptions race condition accepted)
- Admin changes don't affect in-flight checkouts
- Slightly stale discounts within grace period

**Reference:** [ADR-012](./decisions/ADR-012-discount-code-lock-in.md)

---

## Background Jobs

### Cloud Scheduler + Cloud Run
**Decision:** GCP Cloud Scheduler triggers dedicated Cloud Run service for reservation cleanup (every 5 minutes).

**Rationale:** Maintains serverless architecture (scale to zero). Clean separation from main API. HTTP-based (easy to test manually). Native GCP monitoring and retries.

**Accepted trade-offs:**
- Cold starts (2-3 seconds, acceptable for background job)
- Additional service to deploy and manage
- Cloud Scheduler cost ($0.10/job/month)

**Reference:** [ADR-005](./decisions/ADR-005-background-job-infrastructure.md)

### Multi-Layered Failure Mitigation
**Decision:** Five defensive layers: Cloud Scheduler, health monitoring, manual trigger, lazy cleanup on checkout, alerting.

**Rationale:** Prolonged cleanup failure locks inventory indefinitely, causing revenue loss. Multiple fallbacks ensure recovery within 20 minutes. No single point of failure.

**Accepted trade-offs:**
- Five layers to test and maintain
- Lazy cleanup adds 1-2 seconds to checkout (only when backlog exists)
- Alert fatigue risk from transient failures
- Not fully automated (admin must respond to alerts)

**Reference:** [ADR-009](./decisions/ADR-009-multi-layered-job-failure-mitigation.md)

---

## Admin Notifications

### Dashboard Badges + Email
**Decision:** Visual badges in admin dashboard plus immediate email notifications for action-required events.

**Rationale:** Dual awareness ensures no missed events. Email provides backup when admin not checking dashboard. More cost-effective than SMS for 24-hour SLA. Mobile-friendly (email + responsive dashboard).

**Accepted trade-offs:**
- Potential email fatigue (multiple events = multiple emails)
- Not instant (relies on admin checking email)
- Email could be filtered/ignored

**Reference:** [ADR-006](./decisions/ADR-006-admin-notification-strategy.md)

---

## Data Management

### Soft-Delete Pattern
**Decision:** Products set `active = false` instead of hard delete. 90-day restore window.

**Rationale:** Hard deletes break order history, orphan reviews, corrupt analytics. Storage is cheap. Soft-delete preserves data integrity and enables recovery from mistakes.

**Accepted trade-offs:**
- Deleted products accumulate (minor storage cost)
- All queries must filter `active = true`
- "Delete" semantics confusing (doesn't actually delete)
- No hard delete UI for admin (edge cases require developer intervention)

**Reference:** [ADR-010](./decisions/ADR-010-soft-delete-pattern.md)

---

## Lower-Priority Decisions (Documented, No ADRs)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Email provider | Mailgun | Better deliverability for small senders |
| Review edit limit | 3 edits max | Prevents abuse, reasonable allowance |
| Checkout sessions | JWT with session_id | Stateless, secure, aligns with auth pattern |
| Image storage | `/products/{id}/{name}` | Standard GCS pattern |
| API rate limiting | Cloud Run built-in | Follow GCP best practices |

---

## Summary Table

| Category | Decision | Key Trade-off |
|----------|----------|---------------|
| Inventory | Pessimistic locking | Conversion vs. overselling risk |
| Orders | Admin-approved cancellation | Speed vs. Stripe fee protection |
| Reviews | Immediate submission | Participation vs. authenticity |
| Reviews | No admin editing | Efficiency vs. trust preservation |
| Discounts | Order-wide only | Flexibility vs. simplicity |
| Background | Cloud Scheduler | Simplicity vs. cold starts |
| Notifications | Email + badges | Coverage vs. email fatigue |
| Data | Soft-delete | Storage cost vs. data integrity |
