# L2: Inventory Race Condition Prevention

**Component:** Inventory Reservation & Cleanup
**Stage:** L2 (Refine L2 - Detailed Design)
**Date:** 2026-01-24

---

## Critical Questions from L1

1. **Race condition: Two customers checkout simultaneously for last unit?**
2. **What if two background jobs run simultaneously (concurrent cleanup)?**

---

## Problem 1: Concurrent Checkout Race Condition

### Scenario

```
Initial state: Product has quantity=10, reserved_quantity=9, available=1 (last unit)

Timeline:
T+0ms:  Customer A clicks "Checkout" → reads available=1 ✓
T+5ms:  Customer B clicks "Checkout" → reads available=1 ✓
T+10ms: Customer A attempts reservation → writes reserved_quantity=10
T+10ms: Customer B attempts reservation → writes reserved_quantity=10
T+20ms: Both succeed (no conflict detected)

Result: reserved_quantity=10, but two customers think they reserved the last unit.
When one pays, the other's reservation will fail → bad UX, lost sale.
```

**Root cause:** Non-atomic read-check-write operation.

---

## Solution: Firestore Transaction with Pessimistic Locking

### High-Level Algorithm

**Reserve inventory (atomic):**

```
FUNCTION reserveInventory(productId, customerId, quantity):
  1. BEGIN Firestore transaction

  2. READ product document (productId)
     - Get current quantity, reserved_quantity

  3. CALCULATE available_quantity = quantity - reserved_quantity

  4. IF available_quantity < requested_quantity:
       ROLLBACK transaction
       RETURN error "Insufficient inventory"

  5. CREATE reservation document:
       - reservation_id: auto-generated
       - product_id: productId
       - customer_id: customerId
       - quantity: requested_quantity
       - expires_at: now + 15 minutes
       - status: "active"

  6. UPDATE product document:
       - reserved_quantity += requested_quantity

  7. COMMIT transaction
     IF commit fails (conflict detected):
       Retry transaction (up to 3 attempts)
       IF still failing: RETURN error "High demand, try again"

  8. RETURN reservation (success)
```

**Key property:** All operations happen atomically within Firestore transaction.

---

## Firestore Transaction Guarantees

### Isolation Level: Serializable

**What this means:**
- Transactions execute as if they ran one-at-a-time
- No two transactions see intermediate states
- If conflict detected, one aborts and retries

**Conflict detection:**
- Firestore detects when two transactions read same document
- If both try to write, second commit fails with conflict error
- Application retries transaction automatically

### Example: Two Customers, One Unit

```
Customer A transaction:
T+0:  BEGIN transaction A
T+1:  READ product → quantity=10, reserved=9, available=1
T+2:  CHECK available >= 1 → PASS
T+3:  CREATE reservation (A)
T+4:  UPDATE reserved_quantity = 10
T+5:  COMMIT transaction A → SUCCESS

Customer B transaction (overlapping):
T+0:  BEGIN transaction B
T+1:  READ product → quantity=10, reserved=9, available=1 (same snapshot)
T+2:  CHECK available >= 1 → PASS
T+3:  CREATE reservation (B)
T+4:  UPDATE reserved_quantity = 10
T+5:  COMMIT transaction B → CONFLICT DETECTED
        (product document modified by transaction A)
T+6:  RETRY transaction B
T+7:  READ product → quantity=10, reserved=10, available=0
T+8:  CHECK available >= 1 → FAIL
T+9:  ROLLBACK, RETURN "Insufficient inventory"
```

**Outcome:** Customer A gets the unit, Customer B sees "Out of stock".

---

## Transaction Retry Logic

### Automatic Retry Strategy

```
FUNCTION reserveInventoryWithRetry(productId, customerId, quantity):
  maxRetries = 3
  retryDelay = 100ms

  FOR attempt in 1..maxRetries:
    TRY:
      RETURN reserveInventory(productId, customerId, quantity)
    CATCH TransactionConflictError:
      IF attempt < maxRetries:
        Log "Inventory reservation conflict, retrying (attempt {attempt})"
        Sleep(retryDelay * attempt) // Exponential backoff
        CONTINUE
      ELSE:
        Log "Inventory reservation failed after {maxRetries} attempts"
        RETURN error "High demand, please try again"
```

**Why retry?**
- Transient conflicts resolve quickly (winner commits, loser retries)
- Most retries succeed (< 100ms delay)
- Gives customer fair chance at inventory

**Why limit retries?**
- Prevents infinite loops
- Fails fast if persistent issue (Firestore overload)
- Clear error message to customer

---

## Edge Cases: Concurrent Checkout

### Edge Case 1: Three Customers, Two Units

```
State: quantity=10, reserved=8, available=2

Customers A, B, C all want 1 unit simultaneously:
- Transaction A starts → reads available=2 → reserves 1 → commits ✓
- Transaction B starts → reads available=2 → reserves 1 → commits (conflict)
  - Retry → reads available=1 → reserves 1 → commits ✓
- Transaction C starts → reads available=2 → reserves 1 → commits (conflict)
  - Retry → reads available=0 → FAILS ✗
```

**Outcome:** A and B get units, C sees "Out of stock". Fair race.

### Edge Case 2: Customer Wants 5, Only 3 Available

```
State: quantity=10, reserved=7, available=3
Customer requests quantity=5

Transaction:
1. READ product → available=3
2. CHECK available >= 5 → FAIL
3. ROLLBACK, RETURN "Only 3 units available"
```

**Policy decision (from L1):** All-or-nothing for MVP.
- Customer must reduce quantity to 3 or less
- No partial fulfillment
- Clear error message: "Only X units available"

**Future enhancement:** Offer partial ("Only 3 available, add them?")

### Edge Case 3: Cart with Multiple Products

```
Customer cart:
- Product A: 2 units (available=2)
- Product B: 1 unit (available=1)

Reservation strategy: Reserve all or none (transaction spans multiple products)
```

**Algorithm:**

```
FUNCTION reserveCartInventory(cart):
  1. BEGIN Firestore transaction

  2. FOR EACH item in cart:
       READ product (item.productId)
       CHECK available >= item.quantity
       IF insufficient: ROLLBACK, RETURN error for that product

  3. FOR EACH item in cart:
       CREATE reservation for item
       UPDATE product.reserved_quantity += item.quantity

  4. COMMIT transaction (all reservations succeed or all fail)

  RETURN all reservations
```

**Atomicity guarantee:** Either entire cart reserved, or nothing reserved.

---

## Problem 2: Concurrent Cleanup Race Condition

### Scenario

```
Background cleanup job runs every 5 minutes (Cloud Scheduler).

Timeline:
T+0:00: Job 1 starts (Cloud Scheduler trigger)
T+0:30: Job 1 processing reservation R1 (expired)
T+0:31: Job 2 starts (duplicate trigger due to Cloud Scheduler bug)
T+0:32: Job 1 deletes reservation R1, decrements reserved_quantity
T+0:32: Job 2 processes same reservation R1, decrements reserved_quantity again

Result: reserved_quantity decremented twice for one reservation → inventory corruption.
```

**Root cause:** Non-idempotent cleanup operation.

---

## Solution: Idempotent Cleanup with Transaction

### High-Level Algorithm

**Cleanup expired reservations:**

```
FUNCTION cleanupExpiredReservations():
  1. QUERY reservations:
       WHERE status = "active"
       WHERE expires_at < now

  2. FOR EACH reservation in expiredReservations:
       releaseReservation(reservation.id)

  3. Log "Cleaned up {count} expired reservations"


FUNCTION releaseReservation(reservationId):
  1. BEGIN Firestore transaction

  2. READ reservation document (reservationId)
     IF not found OR status != "active":
       ROLLBACK (already released, idempotent)
       RETURN "Already released"

  3. READ product document (reservation.product_id)

  4. UPDATE reservation:
       - status = "expired"
       - released_at = now

  5. UPDATE product:
       - reserved_quantity -= reservation.quantity

  6. COMMIT transaction
     IF conflict: RETRY (another job already released)

  7. RETURN "Released successfully"
```

**Key idempotency mechanism:** Check `status = "active"` before releasing.

---

## Concurrent Cleanup Handling

### Example: Two Jobs Process Same Reservation

```
Reservation R1: expires_at = T+0:00, status = "active", quantity = 2
Product P1: reserved_quantity = 10

Job 1 transaction:
T+0:  BEGIN transaction J1
T+1:  READ R1 → status = "active"
T+2:  READ P1 → reserved_quantity = 10
T+3:  UPDATE R1 → status = "expired"
T+4:  UPDATE P1 → reserved_quantity = 8
T+5:  COMMIT J1 → SUCCESS

Job 2 transaction (overlapping):
T+0:  BEGIN transaction J2
T+1:  READ R1 → status = "active" (J1 not committed yet)
T+2:  READ P1 → reserved_quantity = 10
T+3:  UPDATE R1 → status = "expired"
T+4:  UPDATE P1 → reserved_quantity = 8
T+5:  COMMIT J2 → CONFLICT DETECTED (R1 modified by J1)
T+6:  RETRY transaction J2
T+7:  READ R1 → status = "expired" (J1 already released)
T+8:  ROLLBACK, RETURN "Already released" (idempotent)
```

**Outcome:** R1 released once, reserved_quantity decremented once. Safe.

---

## Edge Cases: Cleanup Operations

### Edge Case 1: Reservation Released During Checkout

```
Timeline:
T+0:  Customer adds to cart, reservation created (expires T+15:00)
T+14:59: Customer completes payment (order creation starts)
T+15:00: Background job finds expired reservation
T+15:01: Job releases reservation, decrements reserved_quantity
T+15:02: Order creation decrements inventory, tries to delete reservation → not found

Issue: Inventory decremented twice (once by cleanup, once by order).
```

**Solution: Order creation handles missing reservation gracefully**

```
FUNCTION createOrderFromPayment(payment_intent_id):
  1. BEGIN transaction

  2. Create order document

  3. FOR EACH item in order:
       UPDATE product.quantity -= item.quantity

       TRY delete reservation (from payment metadata)
       IF reservation not found:
         Log "Reservation already released (expired during checkout)"
         // Don't decrement reserved_quantity (already done by cleanup)
       ELSE:
         UPDATE product.reserved_quantity -= item.quantity

  4. COMMIT transaction
```

**Better solution: Mark reservation as "completing" during payment**

```
FUNCTION createPaymentIntent(reservationId):
  1. BEGIN transaction
  2. READ reservation
  3. UPDATE reservation.status = "completing" (prevents cleanup)
  4. Create Stripe PaymentIntent
  5. COMMIT transaction

Cleanup job:
  Query: WHERE status = "active" (skips "completing" reservations)
```

**Tradeoff:** Adds complexity, prevents rare edge case.
**Decision for MVP:** Handle missing reservation gracefully (simpler).

### Edge Case 2: Cloud Scheduler Duplicate Triggers

**Cloud Scheduler behavior:**
- Guarantees "at-least-once" delivery (not exactly-once)
- May send duplicate triggers within seconds
- Documented GCP limitation

**Mitigation: Job run deduplication**

```
FUNCTION cleanupExpiredReservations():
  1. Generate job_run_id = "{date}-{hour}-{minute}" // e.g., "2026-01-24-10-05"

  2. BEGIN transaction
     READ job_runs where job_run_id = {job_run_id}
     IF found:
       ROLLBACK, RETURN "Job already running" (deduplicate)
     ELSE:
       CREATE job_runs document (job_run_id, started_at)
       COMMIT

  3. QUERY expired reservations...

  4. FOR EACH reservation: releaseReservation(...)

  5. UPDATE job_runs (completed_at, reservations_cleaned)

  6. RETURN summary
```

**Deduplication window:** 1 minute (job_run_id granularity).

**Why not use Firestore locks?**
- Firestore transactions provide locking implicitly
- Job run document acts as distributed lock
- Simple, no external lock service needed

### Edge Case 3: Cleanup Job Crashes Mid-Run

```
Scenario:
1. Job starts, finds 100 expired reservations
2. Releases 50 reservations successfully
3. Cloud Run instance crashes (OOM, deployment, etc.)
4. Cloud Scheduler triggers new job run (5 min later)
5. New job finds remaining 50 reservations, releases them

Outcome: All reservations eventually released (safe).
```

**No issue:** Each reservation release is idempotent. Partial progress is fine.

**Monitoring:** Alert if cleanup job takes > 2 minutes (abnormal).

---

## Risks & Mitigations

### Risk 1: Firestore Transaction Limit (500 writes/transaction)

**Scenario:**
- Customer has 600 items in cart (unlikely but possible)
- Reservation transaction tries 600 writes → exceeds limit

**Mitigation:**
- Frontend enforces cart limit (50 items max)
- Backend validates cart size before reservation
- If limit exceeded, batch into multiple reservations

**Algorithm:**
```
IF cart.items.length > 50:
  RETURN error "Cart limit exceeded (max 50 items)"
```

### Risk 2: High Contention on Popular Products

**Scenario:**
- New product launch, 1000 customers checkout simultaneously
- Same product document updated 1000 times
- Most transactions conflict and retry → slow checkout

**Mitigation:**
- Firestore handles contention automatically (retries)
- Exponential backoff reduces thundering herd
- Clear error message if retries exhausted

**Monitoring:**
- Track transaction conflict rate per product
- Alert if > 50% conflict rate (abnormal demand)
- Admin can manually increase inventory or pause sales

### Risk 3: Clock Skew (Reservation Expiration)

**Scenario:**
- Backend server clock off by 5 minutes
- Reservations expire too early or too late
- Customer loses reservation during checkout

**Mitigation:**
- Use Firestore server timestamp (not local clock)
- Firestore timestamps are authoritative (NTP-synced)
- Cleanup job uses Firestore server time for comparison

**Algorithm:**
```
CREATE reservation:
  expires_at = FieldValue.serverTimestamp() + 15 minutes

QUERY expired:
  WHERE expires_at < FieldValue.serverTimestamp()
```

---

## Monitoring & Alerts

### Critical Metrics

1. **Transaction Conflict Rate**
   - Track per product (identify hot products)
   - Alert if > 30% conflicts (contention issue)
   - Dashboard: Conflict rate by hour

2. **Cleanup Job Performance**
   - Track reservations cleaned per run
   - Alert if > 100 in single run (unusual abandonment)
   - Alert if job duration > 2 minutes (performance issue)

3. **Reservation Expiration Rate**
   - Track % of reservations that expire vs convert
   - Dashboard: Conversion rate (order/reservation)
   - High expiration = UX problem (15min too short?)

4. **Inventory Reservation Errors**
   - Track "Insufficient inventory" error rate
   - Alert if sudden spike (demand surge or bug)
   - Dashboard: Errors per product

### Admin Dashboard Indicators

- **"High Demand"** badge: Product with frequent reservation conflicts
- **"Inventory Low"** alert: Product with available < 5
- **"Cleanup Lag"** warning: Expired reservations not cleaned (job failure)

---

## Testing Scenarios

### Unit Tests

1. **Concurrent reservation simulation**
   - Mock two transactions reserving last unit
   - Assert: One succeeds, one fails with "Insufficient inventory"

2. **Idempotent cleanup**
   - Release same reservation twice
   - Assert: reserved_quantity decremented once

3. **Cart reservation atomicity**
   - Cart with 3 products, one insufficient inventory
   - Assert: No reservations created (all-or-nothing)

### Integration Tests

1. **High concurrency checkout**
   - Spawn 100 parallel reservation requests for product with quantity=10
   - Assert: Exactly 10 succeed, 90 fail
   - Assert: reserved_quantity = 10 (no corruption)

2. **Cleanup job deduplication**
   - Trigger cleanup job twice simultaneously
   - Assert: Each reservation released once
   - Assert: reserved_quantity accurate

3. **Reservation expiration during order creation**
   - Create reservation, wait 15 minutes
   - Trigger cleanup (releases reservation)
   - Complete payment (order creation)
   - Assert: Inventory decremented once, not twice

---

## Performance Optimization

### Query Optimization

**Cleanup job query:**
```
Collection: reservations
WHERE: status = "active"
WHERE: expires_at < now
INDEX: (status, expires_at)
```

**Required Firestore index:** Composite on `(status, expires_at)`

**Expected performance:**
- Query time: < 100ms for 1000 reservations
- Transaction time: < 50ms per reservation
- Total cleanup time: < 30 seconds for 500 expired reservations

### Batch Processing

**Current:** Process reservations sequentially (one transaction per reservation).

**Future optimization:** Batch releases in transaction groups of 100.
- Reduces transaction overhead
- Faster cleanup (10x improvement)
- More complex error handling

**Tradeoff:** Not needed for MVP (low volume).

---

## L1 Questions Answered

### Q1: Race condition - Two customers checkout simultaneously for last unit?

**Answer:**

**Firestore transactions prevent data corruption through serializable isolation.**

**How it works:**
1. Both customers start transactions simultaneously
2. Both read product document (same snapshot)
3. Both attempt to increment `reserved_quantity`
4. First transaction commits successfully
5. Second transaction detects conflict, retries automatically
6. Retry sees updated inventory (available=0), fails with "Insufficient inventory"

**Guarantee:** Exactly one customer gets the unit. No overselling.

**Customer experience:**
- Winner: Reservation succeeds, proceeds to payment
- Loser: "Out of stock" error, clear message

**Retry mechanism:** Up to 3 automatic retries with exponential backoff handles transient conflicts.

### Q2: What if two background jobs run simultaneously (concurrent cleanup)?

**Answer:**

**Idempotent cleanup prevents double-decrements.**

**How it works:**
1. Both jobs query expired reservations (same result set)
2. Both attempt to release reservation R1
3. Each release transaction checks `status = "active"` before proceeding
4. First transaction updates status to "expired", decrements `reserved_quantity`
5. Second transaction retries, sees status = "expired", exits early (idempotent)

**Guarantee:** Each reservation released exactly once. No inventory corruption.

**Additional safety:**
- Job run deduplication prevents duplicate scheduler triggers
- Transaction conflicts handled automatically by Firestore
- Cleanup job monitoring alerts on anomalies

---

**Last Updated:** 2026-01-24
**Stage:** L2
**Status:** ✅ Critical questions resolved
