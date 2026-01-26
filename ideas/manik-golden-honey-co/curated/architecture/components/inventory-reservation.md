# Component: Inventory Reservation

## Overview

Prevents overselling by temporarily locking product quantities during checkout using pessimistic locking (ADR-001) with background cleanup.

**Core invariant:** `available = quantity - reserved_quantity >= 0`

**Key responsibilities:**
- Atomic reservation creation via Firestore transactions
- 15-minute TTL with automatic expiration
- Background cleanup job (every 5 min)
- Admin inventory validation

## Design

### Reservation Flow
```
1. Customer clicks checkout
2. Transaction: FOR EACH item
   - Read product, check available >= requested
   - If any insufficient: ROLLBACK entire cart
3. Create reservation document (expires_at = now + 15 min)
4. Update product.reserved_quantity += item.quantity
5. Return reservation_id to frontend
```

**Atomicity:** All-or-nothing. Entire cart reserved or none.

### Race Condition Handling
Two customers, one unit available:
1. Both transactions read available=1
2. First commits → reserved_quantity updated
3. Second detects conflict → retries → sees available=0 → fails

**Guarantee:** Exactly one customer succeeds.

### Multi-Layer Cleanup (ADR-009)
1. **Cloud Scheduler:** Every 5 min, releases expired reservations
2. **Health monitoring:** Alert if no successful run in 15 min
3. **Manual trigger:** Admin API endpoint
4. **Lazy cleanup:** Checkout checks for expired on product access
5. **Alerting:** Slack notification on failures

## Implementation Details

### Status Lifecycle
```
active → completing (payment started, blocks cleanup)
       → completed (order created)
       → expired (cleanup released)
       → admin_cancelled (manual)
```

### Admin Inventory Validation
Cannot set quantity below reserved_quantity:
```
IF new_quantity < reserved_quantity:
  RETURN error with resolution options:
  - Wait for reservations to expire
  - Cancel reservations manually
  - Set to minimum allowed
```

## Edge Cases

**Two customers, last item:**
- Transaction conflict → automatic retry
- First to commit wins
- Second sees "Out of stock"

**Reservation expires during payment:**
- "completing" status blocks cleanup during payment
- If still expires: order creation re-checks inventory
- Worst case: refund customer (rare)

**Cleanup job crashes:**
- Next run processes remaining
- Each release is idempotent (status check first)
- Lazy cleanup continues during checkouts

## Failure Modes

**Negative inventory detected:**
- Query: `WHERE quantity - reserved_quantity < 0`
- CRITICAL alert
- Reconciliation: recalculate reserved from active reservations

**High contention (flash sale):**
- Transaction conflicts increase
- P95 latency degrades to ~1s
- 5-10% see "High demand, try again"

## Performance Targets

| Metric | Target |
|--------|--------|
| Single-item reservation P95 | <150ms |
| 5-item reservation P95 | <300ms |
| Cleanup job duration | <30s for 100 reservations |
