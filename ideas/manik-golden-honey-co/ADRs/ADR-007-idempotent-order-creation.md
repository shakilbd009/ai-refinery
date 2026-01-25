# ADR-007: Idempotent Order Creation with Webhook Primary Path

## Status

Accepted

---

## Context

When a customer completes payment via Stripe, two independent sources can trigger order creation:

1. **Stripe webhook** (`payment_intent.succeeded`) - Sent by Stripe servers
2. **Frontend confirmation** (`/confirm-order` API call) - Sent by customer's browser

**Key challenges:**
- Webhook and frontend can arrive in any order (race condition)
- Webhook may arrive multiple times (Stripe retry policy)
- Frontend may timeout or customer may close browser
- Payment succeeds but order creation could fail (Firestore outage)

**Key factors:**
- Must prevent duplicate orders (one payment = one order)
- Must recover from order creation failures (customer charged, no order)
- Must handle webhook retries gracefully (idempotency)
- Customer shouldn't be blocked if browser crashes

**Why this decision needed now:**
Payment processing is critical path. Incorrect handling causes revenue loss, customer service nightmares, and data corruption. Must resolve before implementation.

---

## Decision

**Implement idempotent order creation with webhook as primary path, frontend as fallback.**

**Core mechanism:**
1. Use `stripe_payment_intent_id` as deduplication key
2. Both webhook and frontend use same order creation function
3. Query before create (check if order exists for payment_intent_id)
4. If order exists, return existing order (idempotent success)
5. If order doesn't exist, create in Firestore transaction

**Path priority:**
- **Primary:** Stripe webhook (more reliable, automatic retries)
- **Fallback:** Frontend confirmation (customer-initiated, may timeout)

**Failure recovery:**
- Webhook returns 500 on failure → Stripe retries automatically
- Admin alert on order creation failure (urgent notification)
- Manual order creation from Stripe dashboard data (escalation)

---

## Consequences

### Positive

- **No duplicate orders:** Deduplication prevents race condition
- **Automatic recovery:** Webhook retries handle transient failures
- **Customer resilience:** Works even if customer closes browser
- **Simple mental model:** One payment intent = one order (guaranteed)
- **Audit trail:** Metadata tracks which path created order (webhook vs frontend)

### Negative

- **Increased complexity:** Two code paths for same operation
- **Harder testing:** Must simulate webhook/frontend races
- **Dependency on Stripe:** Relies on Stripe webhook reliability
- **Alert fatigue risk:** Transient Firestore issues trigger urgent alerts

### Neutral

- Both paths must stay in sync (changes require updating both)
- Query before create adds 50-100ms latency (acceptable)
- Firestore transaction ensures atomicity (existing capability)

---

## Alternatives Considered

### Alternative 1: Webhook Only (No Frontend Confirmation)

**Why considered:**
- Simpler (one code path)
- Stripe webhooks are reliable (99.9% delivery rate)
- Eliminates race condition entirely

**Why rejected:**
- Customer doesn't see immediate confirmation (poor UX)
- If webhook delayed (5+ seconds), customer waits on loading spinner
- No fallback if webhook fails (customer stuck)
- Frontend needs webhook result to show order confirmation page

### Alternative 2: Frontend Only (No Webhook)

**Why considered:**
- Instant customer feedback (no waiting)
- Simpler infrastructure (no webhook endpoint)
- Customer controls retry (refresh page)

**Why rejected:**
- Customer closes browser before confirmation → order never created
- No automatic retry on failure
- Must poll Stripe API for payment status (inefficient)
- Misses Stripe's built-in retry mechanism (reinventing wheel)

### Alternative 3: Reservation System (Lock Redemption Slot)

**Why considered:**
- Reserve "order slot" when payment intent created
- Prevent race condition at source (before payment)
- Clearer state machine (reserved → confirmed)

**Why rejected:**
- Increased complexity (another state to manage)
- Reservation could expire during payment (customer confusion)
- Doesn't solve failure recovery (still need retry logic)
- Over-engineering for problem already solved by deduplication

---

## Implementation Notes

**Shared order creation function:**
```
createOrderFromPayment(payment_intent_id, source):
  1. BEGIN Firestore transaction
  2. Query: orders WHERE stripe_payment_intent_id = payment_intent_id
  3. IF found: RETURN existing order (idempotent)
  4. Fetch payment details from Stripe API
  5. Create order document (stripe_payment_intent_id indexed)
  6. Decrement product inventory
  7. Delete reservation document
  8. COMMIT transaction
  9. Send confirmation email (async, best-effort)
  10. RETURN created order
```

**Webhook handler:**
```
POST /webhooks/stripe:
  1. Verify webhook signature (security)
  2. Extract payment_intent_id
  3. Call createOrderFromPayment(payment_intent_id, "webhook")
  4. Return 200 OK (tell Stripe received)
  5. On error: Return 500 (Stripe retries)
```

**Frontend confirmation:**
```
POST /api/confirm-order:
  1. Verify customer session
  2. Extract payment_intent_id from request
  3. Query Stripe API: GET /v1/payment_intents/{id}
  4. IF status != "succeeded": RETURN error
  5. Call createOrderFromPayment(payment_intent_id, "frontend")
  6. RETURN order (customer sees confirmation page)
```

**Critical validation:**
- Firestore unique constraint on `stripe_payment_intent_id` (via query)
- Webhook signature verification prevents spoofing
- Payment status double-check via Stripe API (don't trust webhook payload alone)

---

## Success Criteria

**Reliability:**
- Zero duplicate orders in production (query logs for payment_intent_id duplicates)
- 99.9%+ order creation success rate (payment success → order created)
- < 1% manual order creation (admin escalation)

**Performance:**
- Order creation completes in < 2 seconds (P95)
- Webhook processing time < 1 second (P95)
- Idempotency check adds < 100ms (query overhead)

**Monitoring:**
- Alert fires within 60 seconds of order creation failure
- Admin dashboard shows webhook vs frontend creation ratio (expect 95% webhook)
- Track duplicate webhook delivery rate (Stripe behavior baseline)

**Customer Experience:**
- Customer sees order confirmation within 5 seconds of payment
- No "payment succeeded but no order" support tickets
- Order confirmation email sent within 2 minutes

---

## Review Date

**3 months post-launch** - Review actual webhook/frontend split, failure rates, manual intervention frequency. Adjust alert thresholds based on real data.

**Triggers for early review:**
- Manual order creation > 5% (indicates webhook reliability issue)
- Duplicate order incidents (indicates deduplication bug)
- Customer complaints about missing orders (indicates failure recovery gap)

---

## References

- [checkout-payment-errors-L2.md](../stage-5/checkout-payment-errors-L2.md) - Detailed problem analysis
- [Stripe Webhooks Documentation](https://stripe.com/docs/webhooks)
- [Firestore Transactions](https://firebase.google.com/docs/firestore/manage-data/transactions)
- Related ADRs: None (foundational decision)

---

**Date:** 2026-01-24
**Author(s):** Manik Golden Honey Co Design Team
**Reviewers:** Pending L2 Review
