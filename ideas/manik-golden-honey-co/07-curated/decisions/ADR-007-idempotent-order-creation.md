# ADR-007: Idempotent Order Creation with Webhook Primary Path

## Status

Accepted

## Context

When a customer completes payment via Stripe, two independent sources can trigger order creation:

1. **Stripe webhook** (`payment_intent.succeeded`) - Sent by Stripe servers
2. **Frontend confirmation** (`/confirm-order` API call) - Sent by customer's browser

**Key challenges:**
- Webhook and frontend can arrive in any order (race condition)
- Webhook may arrive multiple times (Stripe retry policy)
- Frontend may timeout or customer may close browser
- Payment succeeds but order creation could fail (Firestore outage)

**Requirements:**
- Must prevent duplicate orders (one payment = one order)
- Must recover from order creation failures (customer charged, no order)
- Must handle webhook retries gracefully (idempotency)
- Customer shouldn't be blocked if browser crashes

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

**Shared order creation flow:**
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

## Consequences

### Positive

- **No duplicate orders:** Deduplication key prevents race condition
- **Automatic recovery:** Webhook retries handle transient failures
- **Customer resilience:** Works even if customer closes browser
- **Simple mental model:** One payment intent = one order (guaranteed)
- **Audit trail:** Metadata tracks which path created order

### Negative

- **Increased complexity:** Two code paths for same operation
- **Harder testing:** Must simulate webhook/frontend races
- **Dependency on Stripe:** Relies on Stripe webhook reliability
- **Alert fatigue risk:** Transient Firestore issues trigger urgent alerts

### Trade-offs

| Approach | Reliability | UX | Complexity |
|----------|-------------|-----|------------|
| Webhook + Frontend | Highest | Best (immediate feedback) | Medium |
| Webhook Only | High | Poor (customer waits for webhook) | Low |
| Frontend Only | Medium | Best | Low |

## Alternatives Rejected

**Webhook Only:** Customer doesn't see immediate confirmation, poor UX if webhook delayed 5+ seconds, no fallback if webhook fails.

**Frontend Only:** Order never created if customer closes browser before confirmation, no automatic retry on failure, misses Stripe's built-in retry mechanism.

**Reservation System (Lock Slot):** Increased complexity with another state to manage, reservation could expire during payment, over-engineering when deduplication solves the problem.

## References

- Stripe Webhooks: https://stripe.com/docs/webhooks
- Firestore Transactions: https://firebase.google.com/docs/firestore/manage-data/transactions
- ADR-008: Firestore Transaction Strategy (transaction implementation)
