# ADR-001: Pessimistic Inventory Locking Strategy

## Status

Accepted

---

## Context

Customers purchasing honey products may experience race conditions during checkout when multiple users attempt to purchase the last unit(s) of a product simultaneously. Without proper inventory management, the system could:
- Allow two customers to complete checkout for the same last item
- Create overselling situations where orders cannot be fulfilled
- Damage business reputation as a small, specialty producer

**Key factors:**
- Honey is a specialty product from a small producer (reputation critical)
- Low volume business (~10 orders/week expected)
- Inventory quantities are relatively small (dozens, not thousands)
- Checkout process takes 2-5 minutes typically
- Abandoned cart rate unknown but expected to be low (warm traffic from word-of-mouth)

---

## Decision

We will implement **pessimistic inventory locking** with temporary reservations:

1. When customer clicks "Checkout", backend reserves inventory for 15 minutes
2. `reserved_quantity` field tracks locked inventory per product
3. Available inventory = `quantity - reserved_quantity`
4. If payment succeeds within 15 min: decrement quantity, clear reservation
5. If payment fails or times out: background job releases reservation after 15 min
6. Inventory validation: `available_quantity - reserved_quantity > 0` before allowing reservation

---

## Consequences

### Positive

- **Prevents overselling**: Customers always receive what they order (no fulfillment failures)
- **Protects reputation**: Small producer brand relies on trust and quality
- **Clear inventory state**: Admin always knows true available inventory
- **Predictable customer experience**: No payment success → order failure scenarios
- **Simple refund handling**: No need for "sorry, we oversold" refunds

### Negative

- **Reduces conversion during abandonment**: Reserved inventory temporarily unavailable to other customers
- **Background job complexity**: Requires scheduled task to clean up expired reservations
- **Additional database field**: `reserved_quantity` adds schema complexity
- **Race condition on reservation**: Two simultaneous checkout attempts could still reserve beyond available (requires transaction)
- **Edge case handling**: Admin inventory updates must account for reserved quantities

### Neutral

- Adds `inventory_reservations` collection for tracking (auditing, debugging)
- 15-minute window is arbitrary (could be 10 or 20, needs monitoring)
- Background job adds infrastructure dependency (cron or Cloud Scheduler)

---

## Alternatives Considered

### Alternative 1: Accept Overselling, Admin Handles Manually

**Why considered:**
- Simplest implementation (no locking, no background jobs)
- Maximizes conversion (inventory always appears available)
- Common pattern for low-volume businesses

**Why rejected:**
- **Reputation risk too high**: Small producer cannot afford "sorry, we sold out" emails after payment
- **Bad customer experience**: Customer completes payment, then gets refund notification
- **Admin burden**: Manual resolution of overselling situations is time-consuming
- **Stripe refund fees**: 2.9% + $0.30 lost on each refunded transaction

### Alternative 2: Validate at Payment Confirmation (Stripe Webhook)

**Why considered:**
- No reservation logic needed
- Atomic inventory check at payment success
- Customer only charged if inventory available

**Why rejected:**
- **Poor customer experience**: Customer completes payment form, then gets rejection
- **Stripe refund fees**: Still charges 2.9% + $0.30 even if immediately refunded
- **Race condition still exists**: Two webhooks firing simultaneously could still oversell
- **Frustrating UX**: "Payment successful... just kidding, we're out of stock"
- **Wastes customer time**: Went through entire checkout process for nothing

---

## Implementation Notes

**Database schema changes:**
- Add `reserved_quantity` integer field to `products` collection (default: 0)
- Create `inventory_reservations` collection:
  ```
  {
    id: string,
    product_id: string,
    quantity: int,
    session_id: string,
    reserved_at: timestamp,
    expires_at: timestamp (reserved_at + 15 min)
  }
  ```

**API changes:**
- `POST /api/checkout/reserve` - Reserve inventory for checkout session
- `POST /api/checkout/release` - Explicit release if customer abandons
- Modify `POST /api/orders` - Clear reservation on successful order creation

**Background job:**
- Cloud Scheduler triggers every 5 minutes
- Query `inventory_reservations` where `expires_at < NOW()`
- For each expired reservation:
  - Decrement `products.reserved_quantity`
  - Delete reservation record
- Log expired reservations for monitoring

**Transaction handling:**
- Reserve operation must be atomic:
  ```
  BEGIN TRANSACTION
  SELECT available_qty WHERE product_id = X FOR UPDATE
  IF available_qty - reserved_qty >= requested_qty:
    INSERT INTO reservations
    UPDATE products SET reserved_quantity += requested_qty
  ELSE:
    THROW "Insufficient inventory"
  COMMIT
  ```

**Admin considerations:**
- Admin inventory updates must check `reserved_quantity`
- Warning if admin tries to reduce quantity below reserved amount
- Admin dashboard shows: `Available: X (Y reserved)`

---

## Success Criteria

**How we'll know this decision was correct:**
- Zero overselling incidents in first 3 months
- Abandoned reservation rate < 10% (most reservations convert to orders)
- Background job latency < 1 second for cleanup
- No customer complaints about "out of stock after payment"
- Admin can confidently promise delivery on all accepted orders

**Monitoring metrics:**
- Reservation conversion rate (reserved → paid)
- Average time from reservation to payment
- Expired reservation count per week
- Concurrent reservation attempts (race condition detection)

---

## Review Date

**Review after 3 months of production use** (or sooner if):
- Abandoned reservation rate > 20% (hurting conversion)
- Background job causing performance issues
- Admin reports difficulty managing reserved inventory
- Multiple race condition incidents occur

---

## References

- [requirements.md](../stage-2/requirements.md) - Open Question #2 resolution
- Related ADRs: None (first ADR)
- Firestore transactions: https://firebase.google.com/docs/firestore/manage-data/transactions

---

**Date:** 2026-01-24
**Author(s):** Claude (Systematic Refinement)
**Reviewers:** [Pending]
