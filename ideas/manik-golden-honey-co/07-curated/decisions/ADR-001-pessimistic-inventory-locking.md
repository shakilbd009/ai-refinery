# ADR-001: Pessimistic Inventory Locking Strategy

## Status

Accepted

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
- Abandoned cart rate expected to be low (warm traffic from word-of-mouth)

## Decision

We will implement **pessimistic inventory locking** with temporary reservations:

1. When customer clicks "Checkout", backend reserves inventory for 15 minutes
2. `reserved_quantity` field tracks locked inventory per product
3. Available inventory = `quantity - reserved_quantity`
4. If payment succeeds within 15 min: decrement quantity, clear reservation
5. If payment fails or times out: background job releases reservation after 15 min
6. Inventory validation: `available_quantity - reserved_quantity > 0` before allowing reservation

## Rationale

### Why not accept overselling and handle manually?

While simpler to implement, this approach was rejected because:
- **Reputation risk too high**: Small producer cannot afford "sorry, we sold out" emails after payment
- **Bad customer experience**: Customer completes payment, then gets refund notification
- **Admin burden**: Manual resolution of overselling situations is time-consuming
- **Stripe refund fees**: 2.9% + $0.30 lost on each refunded transaction

### Why not validate at payment confirmation (Stripe webhook)?

This approach was rejected because:
- **Poor customer experience**: Customer completes payment form, then gets rejection
- **Stripe fees still apply**: 2.9% + $0.30 charged even if immediately refunded
- **Race condition still exists**: Two webhooks firing simultaneously could still oversell
- **Frustrating UX**: "Payment successful... just kidding, we're out of stock"

## Consequences

### Positive

- **Prevents overselling**: Customers always receive what they order (no fulfillment failures)
- **Protects reputation**: Small producer brand relies on trust and quality
- **Clear inventory state**: Admin always knows true available inventory
- **Predictable customer experience**: No payment success followed by order failure scenarios
- **Simple refund handling**: No need for "sorry, we oversold" refunds

### Negative

- **Reduces conversion during abandonment**: Reserved inventory temporarily unavailable to other customers
- **Background job complexity**: Requires scheduled task to clean up expired reservations
- **Additional database field**: `reserved_quantity` adds schema complexity
- **Race condition on reservation**: Two simultaneous checkout attempts could still reserve beyond available (requires transaction)
- **Edge case handling**: Admin inventory updates must account for reserved quantities

### Neutral

- Adds `inventory_reservations` collection for tracking (auditing, debugging)
- 15-minute window is configurable (could be 10 or 20, needs monitoring)
- Background job adds infrastructure dependency (cron or Cloud Scheduler)
