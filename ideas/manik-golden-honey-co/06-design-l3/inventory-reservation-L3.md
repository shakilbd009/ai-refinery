# L3: Inventory Reservation - Exhaustive Design

**Component:** Pessimistic Inventory Locking with Background Cleanup (Critical Integrity System)
**Stage:** L3 (Refine L3 - Exhaustive Coverage)
**Date:** 2026-01-24

---

## L3 Pass: Exhaustive Coverage (Stage 6: Refine L3)

### Complete Flow Variants

All possible inventory reservation paths documented with precise handling.

---

## Variant 1: Happy Path - Single Product Reservation (Expected 70% of Checkouts)

**Preconditions:**
- Customer has valid session
- Cart contains 1 product
- Product is active and in stock
- No existing reservation for this cart

**Flow:**

```
1. Customer clicks "Checkout" button
   → Frontend: POST /api/reserve-inventory
   Body: {
     cart_id: "cart_abc123",
     items: [{ product_id: "prod_wildflower", quantity: 2 }]
   }

2. Backend validates request:
   Duration: 5-10ms

   VALIDATE cart_id is valid UUID
   VALIDATE items.length > 0
   VALIDATE items.length <= 50 (cart limit)
   FOR EACH item:
     VALIDATE product_id is valid UUID
     VALIDATE quantity > 0
     VALIDATE quantity <= 100 (single item limit)

3. Backend reserves inventory (Firestore transaction):
   Duration: 50-150ms (P50-P95)

   BEGIN transaction

     // Phase 1: Read all products (validate availability)
     FOR EACH item in cart:
       READ product document (item.product_id)
       IF product.active == false:
         ROLLBACK
         RETURN 400 "Product no longer available"

       available = product.quantity - product.reserved_quantity
       IF available < item.quantity:
         ROLLBACK
         RETURN 400 {
           "error": "insufficient_inventory",
           "product_id": item.product_id,
           "requested": item.quantity,
           "available": available
         }

     // Phase 2: Create reservations (all validated, now lock)
     reservation_id = generate_uuid()
     expires_at = now + 15 minutes

     CREATE reservation document:
       id: reservation_id
       cart_id: cart_id
       customer_id: session.customer_id
       items: [
         { product_id: "prod_wildflower", quantity: 2 }
       ]
       status: "active"
       created_at: now
       expires_at: expires_at

     // Phase 3: Update product reserved quantities
     FOR EACH item in cart:
       UPDATE product (item.product_id):
         reserved_quantity += item.quantity

   COMMIT transaction

4. Backend returns success:
   Duration: 5-10ms

   Response: 200 OK
   {
     "reservation_id": "res_abc123",
     "expires_at": "2026-01-24T15:15:00Z",
     "items": [
       {
         "product_id": "prod_wildflower",
         "name": "Wildflower Honey 12oz",
         "quantity": 2,
         "unit_price": 1800,
         "reserved": true
       }
     ]
   }

5. Customer sees checkout page:
   - Items listed with prices
   - Reservation countdown timer starts (15:00)
   - Frontend polls /api/reservation-status every 30 seconds

6. Reservation lifecycle:

   A) Payment succeeds within 15 minutes:
      - Order creation webhook/frontend deletes reservation
      - Product.reserved_quantity -= item.quantity
      - Product.quantity -= item.quantity (actual sale)

   B) Customer abandons checkout:
      - Reservation remains active until expires_at
      - Background cleanup job releases after expiration
      - Product.reserved_quantity -= item.quantity

Total duration: 60-200ms
Transaction time: 50-150ms
Network overhead: 10-50ms
```

**Success criteria:**
- Reservation created < 200ms (P95)
- Transaction conflict rate < 5%
- Zero overselling events

---

## Variant 2: Multi-Product Cart Reservation (25% of Checkouts)

**Preconditions:**
- Cart contains 2-50 products
- All products active and in stock

**Flow:**

```
1. Customer clicks "Checkout" (cart has 4 items)
   → POST /api/reserve-inventory
   Body: {
     cart_id: "cart_xyz789",
     items: [
       { product_id: "prod_wildflower", quantity: 2 },
       { product_id: "prod_clover", quantity: 1 },
       { product_id: "prod_buckwheat", quantity: 3 },
       { product_id: "prod_comb", quantity: 1 }
     ]
   }

2. Backend reserves ALL items atomically:
   Duration: 100-300ms (scales with item count)

   BEGIN transaction

     // Read and validate ALL products first
     products = []
     FOR EACH item in cart:
       product = READ product (item.product_id)
       available = product.quantity - product.reserved_quantity
       IF available < item.quantity:
         ROLLBACK
         RETURN 400 {
           "error": "insufficient_inventory",
           "product_id": item.product_id,
           "product_name": product.name,
           "requested": item.quantity,
           "available": available
         }
       products.push({ product, requested: item.quantity })

     // All validated, now lock all
     CREATE reservation document (all items)

     FOR EACH { product, requested } in products:
       UPDATE product:
         reserved_quantity += requested

   COMMIT transaction

3. Transaction atomicity guarantee:
   - Either ALL items reserved, or NONE reserved
   - No partial reservations
   - Customer sees "out of stock" for specific item, not partial cart

4. Frontend displays reservation:
   All items shown with "Reserved for 15 minutes" badge
   Countdown timer applies to entire reservation
```

**Edge case: Second item out of stock**

```
Cart:
  - Wildflower Honey: want 2, available 10 ✓
  - Clover Honey: want 5, available 2 ✗
  - Buckwheat Honey: want 3, available 20 ✓

Result:
  ROLLBACK (Clover insufficient)
  RETURN 400 {
    "error": "insufficient_inventory",
    "product_id": "prod_clover",
    "product_name": "Clover Honey 12oz",
    "requested": 5,
    "available": 2
  }

Frontend:
  "Not enough inventory

   Only 2 units of Clover Honey 12oz available.
   You requested 5 units.

   [Update to 2] [Remove Item] [Cancel]"

No products reserved. Customer must fix cart and retry.
```

**Performance scaling:**
- 1 item: 50-150ms
- 5 items: 100-300ms
- 20 items: 200-500ms
- 50 items: 400-800ms (max cart size)

---

## Variant 3: Concurrent Checkout - Race Condition Handling (5% of Peak Traffic)

**Trigger:** Two customers checkout simultaneously for last available unit(s)

**Flow:**

```
Initial state:
  Product: Wildflower Honey
  quantity: 10
  reserved_quantity: 9
  available: 1 (last unit)

Timeline:
T+0ms:   Customer A clicks "Checkout" → Transaction A begins
T+5ms:   Customer B clicks "Checkout" → Transaction B begins
T+10ms:  Transaction A reads product (available = 1)
T+15ms:  Transaction B reads product (available = 1) [same snapshot]
T+20ms:  Transaction A validates (1 >= 1) ✓
T+25ms:  Transaction B validates (1 >= 1) ✓
T+30ms:  Transaction A creates reservation
T+35ms:  Transaction A updates reserved_quantity = 10
T+40ms:  Transaction A COMMITS → SUCCESS

T+45ms:  Transaction B creates reservation
T+50ms:  Transaction B updates reserved_quantity = 10
T+55ms:  Transaction B COMMITS → CONFLICT DETECTED
         (product document modified since read)

T+60ms:  Transaction B auto-retries (attempt 2)
T+65ms:  Transaction B reads product (reserved_quantity = 10, available = 0)
T+70ms:  Transaction B validates (0 >= 1) → FAIL
T+75ms:  Transaction B ROLLBACK

Response to Customer B:
  400 {
    "error": "insufficient_inventory",
    "message": "Sorry, this item just sold out",
    "product_id": "prod_wildflower",
    "requested": 1,
    "available": 0
  }

Frontend shows:
  "Item sold out

   Wildflower Honey 12oz just sold out while you were shopping.

   [View Similar Products] [Continue with Other Items]"
```

**Guarantee:** Exactly one customer gets the last unit. No overselling.

**Retry mechanism:**

```
FUNCTION reserveWithRetry(cart):
  max_retries = 3
  retry_delay = [100ms, 200ms, 400ms] // Exponential backoff

  FOR attempt in 1..max_retries:
    TRY:
      RETURN reserveInventory(cart)
    CATCH TransactionConflictError:
      IF attempt < max_retries:
        Log "Reservation conflict, retrying (attempt {attempt})"
        Sleep(retry_delay[attempt] + random_jitter(±20%))
        CONTINUE
      ELSE:
        // Still failing after retries
        RETURN 503 {
          "error": "high_demand",
          "message": "High demand for this product. Please try again.",
          "retryable": true
        }

Customer experience on high demand:
  - Most conflicts resolve on first retry (< 100ms delay)
  - Customer rarely sees "high demand" message
  - Fair race: first to commit wins
```

---

## Variant 4: Reservation Expiration & Background Cleanup (5-10% of Reservations)

**Trigger:** Customer abandons checkout (closes tab, gets distracted, etc.)

**Flow:**

```
1. Reservation created at T+0:
   {
     id: "res_abc123",
     status: "active",
     created_at: "2026-01-24T15:00:00Z",
     expires_at: "2026-01-24T15:15:00Z",
     items: [{ product_id: "prod_wildflower", quantity: 2 }]
   }

   Product state:
     quantity: 10
     reserved_quantity: 2 (this reservation)

2. Customer abandons (closes browser at T+5 min)
   No explicit release action
   Reservation remains active

3. T+15 minutes: Reservation expires
   expires_at = T+15 < now

4. Background cleanup job runs (every 5 minutes via Cloud Scheduler):
   Job started at T+18 (next run after expiration)

   FUNCTION cleanupExpiredReservations():
     // Query all expired active reservations
     expired = QUERY reservations
       WHERE status = "active"
       WHERE expires_at < now
       ORDER BY expires_at ASC
       LIMIT 100 (batch processing)

     cleaned_count = 0
     FOR EACH reservation in expired:
       result = releaseReservation(reservation.id)
       IF result.success:
         cleaned_count++
       ELSE:
         Log warning "Failed to release {reservation.id}: {result.error}"

     Log info "Cleaned up {cleaned_count} expired reservations"
     RETURN { cleaned: cleaned_count, errors: expired.length - cleaned_count }

5. Release individual reservation (idempotent):

   FUNCTION releaseReservation(reservation_id):
     BEGIN transaction

       READ reservation document
       IF not found:
         RETURN { success: true, reason: "not_found" } // Already deleted

       IF status != "active":
         RETURN { success: true, reason: "already_released" } // Idempotent

       // Update reservation status
       UPDATE reservation:
         status = "expired"
         released_at = now
         released_by = "cleanup_job"

       // Release inventory for each item
       FOR EACH item in reservation.items:
         READ product (item.product_id)
         UPDATE product:
           reserved_quantity -= item.quantity

     COMMIT transaction

     Log info "Released reservation {reservation_id}: {items.length} items"
     RETURN { success: true, reason: "released" }

6. Product state after cleanup:
   quantity: 10
   reserved_quantity: 0 (released)
   available: 10 (back in pool)

7. Another customer can now purchase:
   New checkout finds available = 10
   Reservation succeeds
```

**Cleanup job scheduling:**
```
Cloud Scheduler configuration:
  Name: cleanup-expired-reservations
  Schedule: */5 * * * * (every 5 minutes)
  Target: POST https://api.manikgoldenhoney.com/admin/cleanup-reservations
  Timezone: UTC
  Retry config:
    max_attempts: 3
    max_retry_duration: 10 minutes
    min_backoff: 5 seconds
    max_backoff: 300 seconds
```

---

## Variant 5: Reservation Released During Payment (Edge Case, < 1%)

**Trigger:** Customer completes payment at the exact moment reservation expires

**Flow:**

```
Timeline:
T+0:00    Customer creates reservation (expires T+15:00)
T+14:30   Customer enters payment details on Stripe
T+14:59   Customer clicks "Pay" (Stripe processes)
T+15:00   Reservation expires (expires_at reached)
T+15:01   Cleanup job runs, finds expired reservation
T+15:02   Cleanup job releases reservation:
          Product.reserved_quantity -= 2
T+15:05   Stripe payment succeeds
T+15:06   Webhook arrives: POST /webhooks/stripe

Problem:
  - Payment succeeded
  - But reservation already released
  - Inventory already returned to pool
  - Another customer might have reserved same units

Order creation must handle this gracefully:
```

**Solution A: Reservation marked "completing" during payment (Chosen)**

```
When creating PaymentIntent:
  FUNCTION createPaymentIntent(reservation_id):
    BEGIN transaction
      READ reservation
      IF status != "active":
        ROLLBACK
        RETURN 400 "Reservation expired or already completing"

      IF expires_at < now:
        ROLLBACK
        RETURN 400 "Reservation expired"

      // Mark as completing (prevents cleanup)
      UPDATE reservation:
        status = "completing"
        payment_started_at = now

    COMMIT

    // Create Stripe PaymentIntent
    payment_intent = stripe.paymentIntents.create({...})

    RETURN payment_intent

Cleanup job query:
  WHERE status = "active"  // Skips "completing" reservations

"Completing" status:
  - Reservation not cleaned up
  - Customer has 30 more minutes to complete payment
  - If payment fails, status returns to "active" with new expires_at
  - If customer abandons on Stripe page, separate timeout releases "completing"
```

**Solution B: Handle missing reservation gracefully (Simpler, backup)**

```
FUNCTION createOrderFromPayment(payment_intent_id):
  BEGIN transaction

    // Extract reservation from metadata
    reservation_id = payment_intent.metadata.reservation_id

    // Try to find reservation
    reservation = READ reservation (reservation_id)

    IF reservation not found OR reservation.status == "expired":
      Log warning "Reservation {reservation_id} already released"

      // Verify inventory still available (re-reserve atomically)
      FOR EACH item in items_from_metadata:
        available = product.quantity - product.reserved_quantity
        IF available < item.quantity:
          // Inventory gone! Another customer got it
          Log critical "Overselling prevented: {product_id}"
          ROLLBACK
          RETURN error "Inventory no longer available"

      // Inventory available, proceed without reservation
      // Don't decrement reserved_quantity (already released)
      FOR EACH item:
        UPDATE product.quantity -= item.quantity

    ELSE:
      // Normal path: reservation exists
      FOR EACH item:
        UPDATE product.quantity -= item.quantity
        UPDATE product.reserved_quantity -= item.quantity
      DELETE reservation

    CREATE order document

  COMMIT

Outcome:
  - Order created if inventory available
  - Refund initiated if inventory gone (rare edge case)
```

**Decision:** Use Solution A (status = "completing") as primary. Solution B as safety net.

---

## Variant 6: Admin Inventory Update During Active Reservations (Operations Scenario)

**Trigger:** Admin counts physical inventory, finds discrepancy, updates quantity

**Flow:**

```
Current state:
  Product: Wildflower Honey
  quantity: 20
  reserved_quantity: 15 (3 active reservations)
  available: 5

Admin scenario:
  Admin counts physical inventory → only 12 jars exist
  Admin wants to update quantity = 12

Problem:
  new_available = 12 - 15 = -3 (NEGATIVE)
  Cannot have negative available inventory

System behavior:
```

**Update validation algorithm:**

```
FUNCTION updateProductInventory(product_id, new_quantity, admin_user_id):
  BEGIN transaction

    READ product document

    // Validation 1: Non-negative quantity
    IF new_quantity < 0:
      RETURN 400 "Quantity cannot be negative"

    // Validation 2: Quantity >= reserved
    IF new_quantity < product.reserved_quantity:
      RETURN 400 {
        "error": "insufficient_for_reservations",
        "message": "Cannot set quantity below reserved amount",
        "current_quantity": product.quantity,
        "requested_quantity": new_quantity,
        "reserved_quantity": product.reserved_quantity,
        "minimum_allowed": product.reserved_quantity,
        "resolution_options": [
          "Wait for reservations to expire (next cleanup: 3 min)",
          "Cancel active reservations manually",
          "Set quantity to minimum allowed (15)"
        ]
      }

    // Validation passed, update
    UPDATE product:
      quantity = new_quantity
      updated_at = now
      updated_by = admin_user_id

    // Audit log
    CREATE audit_log:
      action: "inventory_update"
      product_id: product_id
      old_quantity: product.quantity
      new_quantity: new_quantity
      admin_user_id: admin_user_id
      timestamp: now

  COMMIT

  RETURN 200 { success: true, new_available: new_quantity - reserved_quantity }
```

**Admin dashboard UX:**

```
Product: Wildflower Honey 12oz
┌─────────────────────────────────────────┐
│ Current Quantity: 20                    │
│ Reserved: 15 (3 active reservations)    │
│ Available: 5                            │
├─────────────────────────────────────────┤
│ New Quantity: [12_________]             │
│                                         │
│ ⚠️ Warning: 15 units currently reserved │
│    Minimum allowed: 15                  │
│                                         │
│ [Update Inventory] (disabled)           │
│ [View Reservations] [Force Release All] │
└─────────────────────────────────────────┘

Admin clicks "View Reservations":

Active Reservations (3):
┌──────────────────────────────────────────────────────┐
│ 1. Customer: alice@example.com                       │
│    Quantity: 5 units                                 │
│    Expires: 12 min                                   │
│    [Cancel & Notify Customer]                        │
├──────────────────────────────────────────────────────┤
│ 2. Customer: bob@example.com                         │
│    Quantity: 5 units                                 │
│    Expires: 8 min                                    │
│    [Cancel & Notify Customer]                        │
├──────────────────────────────────────────────────────┤
│ 3. Customer: carol@example.com                       │
│    Quantity: 5 units                                 │
│    Expires: 3 min                                    │
│    [Cancel & Notify Customer]                        │
└──────────────────────────────────────────────────────┘

[Cancel All & Update Inventory]
```

**Admin cancellation flow:**

```
FUNCTION adminCancelReservation(reservation_id, admin_user_id, reason):
  BEGIN transaction

    READ reservation
    IF status != "active":
      RETURN 400 "Reservation already released"

    // Release inventory
    FOR EACH item in reservation.items:
      UPDATE product:
        reserved_quantity -= item.quantity

    // Update reservation
    UPDATE reservation:
      status = "admin_cancelled"
      cancelled_at = now
      cancelled_by = admin_user_id
      cancellation_reason = reason

  COMMIT

  // Notify customer (async)
  queue_email({
    to: reservation.customer_email,
    template: "reservation_cancelled",
    data: {
      reason: reason,
      items: reservation.items
    }
  })

  RETURN 200 { success: true }
```

---

## Variant 7: Lazy Cleanup on Checkout (Self-Healing Fallback)

**Trigger:** Background cleanup job fails to run (scheduler outage)

**Flow:**

```
Scenario:
  - Cloud Scheduler down for 30 minutes
  - Multiple reservations expired but not cleaned
  - New customer tries to checkout

Self-healing behavior:
```

```
FUNCTION checkInventoryAvailability(product_id, quantity):
  BEGIN transaction

    READ product document
    available = product.quantity - product.reserved_quantity

    // Check for expired reservations on this product
    expired = QUERY reservations
      WHERE product_id = product_id
      WHERE status = "active"
      WHERE expires_at < now
      LIMIT 10 (cap to prevent timeout)

    IF expired.length > 0:
      Log info "Lazy cleanup: found {expired.length} expired reservations"

      FOR EACH reservation in expired:
        // Release inline (same transaction for consistency)
        UPDATE reservation:
          status = "expired"
          released_at = now
          released_by = "lazy_cleanup"

        UPDATE product:
          reserved_quantity -= reservation.items[product_id].quantity

      // Recalculate available after cleanup
      READ product document (fresh)
      available = product.quantity - product.reserved_quantity

  COMMIT

  RETURN available >= quantity
```

**Benefits:**
- System self-heals during normal operations
- Reduces impact of scheduler failure
- Customer immediately benefits from freed inventory

**Tradeoffs:**
- Adds 50-200ms to checkout (expired reservation query + cleanup)
- Only cleans reservations for accessed product
- LIMIT 10 means large backlogs need background job

**Decision:** Implement as safety net. Primary cleanup via background job.

---

## Timeout Handling (Complete Specification)

### Timeout 1: Reservation Transaction

**Timeout:** 10 seconds (Firestore transaction limit)

```
Backend transaction configuration:
  Firestore SDK timeout: 10 seconds (default)
  Custom timeout wrapper: 8 seconds (leave buffer)

Implementation:
  const RESERVATION_TIMEOUT_MS = 8000

  const timeoutPromise = new Promise((_, reject) => {
    setTimeout(() => reject(new Error("Reservation timeout")), RESERVATION_TIMEOUT_MS)
  })

  try {
    const result = await Promise.race([
      reserveInventory(cart),
      timeoutPromise
    ])
    return result
  } catch (error) {
    if (error.message === "Reservation timeout") {
      // Transaction may or may not have committed
      // Query to check state
      const reservation = await findReservationByCartId(cart.cart_id)
      if (reservation) {
        return { success: true, reservation } // Transaction succeeded
      }
      return { error: "reservation_timeout", retryable: true }
    }
    throw error
  }

Timeout scenarios:

Scenario A: Firestore slow, transaction uncommitted
  - Firestore rolls back automatically
  - No reservation created
  - No reserved_quantity incremented
  - Customer retries, succeeds

Scenario B: Firestore slow, transaction committed after timeout
  - Reservation exists but client timed out
  - Backend query finds existing reservation
  - Return success (reservation valid)

Frontend handling:
  On timeout:
    Show "Checkout taking longer than usual..."
    Auto-retry (up to 3 times)
    If all fail: "Please try again in a moment"
```

### Timeout 2: Background Cleanup Job

**Timeout:** 5 minutes (Cloud Run max)

```
Job configuration:
  Cloud Run timeout: 5 minutes
  Expected duration: < 30 seconds (normal load)
  Max reservations per run: 100 (batching)

If job times out:
  - Partially cleaned reservations remain clean (each is atomic)
  - Uncleaned reservations wait for next run
  - No data corruption

Mitigation:
  IF reservations.length > 100:
    Process first 100
    Log warning "Cleanup backlog: {remaining} reservations pending"
    Alert if backlog > 200 (unusual)
```

### Timeout 3: Reservation Release Transaction

**Timeout:** 10 seconds (per reservation)

```
Single reservation release:
  Target: < 100ms
  Timeout: 10 seconds

If timeout on release:
  - Transaction rolls back
  - Reservation remains active
  - Next cleanup run will retry
  - Idempotent design ensures no double-release
```

---

## Retry Logic (Exhaustive)

### Retry Strategy 1: Transaction Conflicts (Concurrent Checkouts)

```
Configuration:
  max_retries: 3
  base_delay: 100ms
  backoff: exponential (100ms, 200ms, 400ms)
  jitter: ±20%

Retry conditions:
  - ABORTED: Transaction conflict (another write to same document)
  - UNAVAILABLE: Temporary Firestore issue
  - DEADLINE_EXCEEDED: Transaction took too long (retry with simpler query)

Non-retry conditions:
  - FAILED_PRECONDITION: Data validation failed (user error)
  - NOT_FOUND: Product doesn't exist
  - PERMISSION_DENIED: Auth issue

Example timeline:
  T+0ms:    Transaction attempt 1 → ABORTED (conflict)
  T+100ms:  Wait 100ms ± 20ms
  T+120ms:  Transaction attempt 2 → ABORTED (still conflicting)
  T+320ms:  Wait 200ms ± 40ms
  T+380ms:  Transaction attempt 3 → SUCCESS

Customer experience:
  - Total time: ~400ms (feels instant)
  - No error shown
  - Checkout proceeds
```

### Retry Strategy 2: Cleanup Job Failures

```
Configuration:
  Cloud Scheduler retries: 3
  Retry backoff: 5s, 30s, 300s
  Max retry duration: 10 minutes

If all retries fail:
  - Alert fires (cleanup not running)
  - Manual trigger API available
  - Lazy cleanup continues to work

Recovery:
  Admin uses dashboard to trigger manual cleanup
  OR waits for next scheduled run
```

### Retry Strategy 3: Admin Inventory Update Conflicts

```
Scenario:
  Admin updating inventory while customer reserving

Resolution:
  Admin transaction retries automatically
  Admin sees "Please try again" if persistent
  No data corruption possible
```

---

## Error Scenarios (Exhaustive List)

### Category 1: Inventory Errors

**E1.1: Product not found**
```
Trigger: Product deleted between cart and checkout
Response: 400 "Product no longer available"
Customer action: Remove from cart
Admin alert: None (expected behavior)
```

**E1.2: Product inactive**
```
Trigger: Admin deactivates product
Response: 400 "Product is currently unavailable"
Customer action: Remove from cart
Admin action: None (intentional deactivation)
```

**E1.3: Insufficient inventory**
```
Trigger: available < requested quantity
Response: 400 with available count
Customer action: Reduce quantity or remove
[Covered in Variant 3]
```

**E1.4: Inventory corrupted (negative available)**
```
Trigger: Bug in reservation/release logic
Detection: available_quantity < 0 in any query
Response: 500 "Inventory error, please contact support"
Alert: CRITICAL - immediate investigation
Recovery: Manual reconciliation of reserved_quantity
```

---

### Category 2: Reservation Errors

**E2.1: Reservation not found**
```
Trigger: Reservation deleted (cleaned up, order created)
Response: 400 "Reservation expired or completed"
Customer action: Return to cart, re-reserve
```

**E2.2: Reservation expired**
```
Trigger: expires_at < now
Response: 400 "Reservation expired"
[Covered in Variant 4]
```

**E2.3: Duplicate reservation attempt**
```
Trigger: Customer clicks checkout twice rapidly
Detection: Existing active reservation for cart_id
Response: 200 { existing_reservation } (idempotent)
```

**E2.4: Reservation status invalid**
```
Trigger: Attempt to use "expired" or "completed" reservation
Response: 400 "Reservation is no longer active"
Customer action: Return to cart
```

---

### Category 3: Transaction Errors

**E3.1: Transaction conflict (retryable)**
```
Trigger: Concurrent modification of same product
Handling: Automatic retry (up to 3)
Response (if retries exhausted): 503 "High demand, please retry"
```

**E3.2: Transaction timeout**
```
Trigger: Firestore slow (> 10 seconds)
Handling: Query to check if committed
Response: 504 "Request timed out"
[Covered in Timeout Handling]
```

**E3.3: Transaction limit exceeded**
```
Trigger: Cart > 500 writes (Firestore limit)
Detection: items.length > 50 (pre-check)
Response: 400 "Cart too large (max 50 items)"
Prevention: Frontend enforces limit
```

---

### Category 4: Cleanup Job Errors

**E4.1: Scheduler not triggering**
```
Trigger: Cloud Scheduler outage
Detection: No job runs in 15 minutes
Alert: CRITICAL - cleanup job not running
Recovery: Manual trigger, lazy cleanup fallback
```

**E4.2: Job crashes mid-execution**
```
Trigger: OOM, deployment, infrastructure issue
Detection: Job run started but not completed
Alert: WARNING - job incomplete
Recovery: Next run processes remaining
```

**E4.3: Double cleanup (idempotent handling)**
```
Trigger: Duplicate scheduler trigger, or concurrent jobs
Handling: Status check before release
Result: Second attempt sees status != "active", skips
Guarantee: reserved_quantity decremented exactly once
```

**E4.4: Cleanup releases reservation during payment**
```
Trigger: Reservation expires during Stripe checkout
Prevention: "completing" status blocks cleanup
Fallback: Order creation handles missing reservation
[Covered in Variant 5]
```

---

### Category 5: Admin Errors

**E5.1: Admin reduces quantity below reserved**
```
Trigger: Physical inventory count lower than reserved
Response: 400 with resolution options
[Covered in Variant 6]
```

**E5.2: Concurrent admin update and reservation**
```
Trigger: Admin and customer racing
Handling: Transaction isolation prevents corruption
Result: One succeeds, one retries
```

---

## Performance Characteristics

### Latency Budget (Per Operation)

**Reservation Creation (Single Item):**
- Target: P50 < 75ms, P95 < 150ms, P99 < 300ms
- Components:
  - Request parsing: 2-5ms
  - Product read: 20-40ms
  - Reservation write: 20-40ms
  - Product update: 20-40ms
  - Response serialization: 2-5ms
- Total: 64-130ms typical

**Reservation Creation (5 Items):**
- Target: P50 < 150ms, P95 < 300ms, P99 < 500ms
- Components:
  - Request parsing: 2-5ms
  - Product reads (5x parallel in transaction): 30-60ms
  - Reservation write: 20-40ms
  - Product updates (5x): 50-100ms
  - Response serialization: 2-5ms
- Total: 104-210ms typical

**Reservation Release:**
- Target: P50 < 50ms, P95 < 100ms, P99 < 200ms
- Components:
  - Reservation read: 15-30ms
  - Status update: 15-30ms
  - Product update: 15-30ms
- Total: 45-90ms typical

**Cleanup Job (100 reservations):**
- Target: < 30 seconds
- Per reservation: 50-100ms
- Total: 5-10 seconds (with parallelism)

---

### Throughput Estimates

**Concurrent Reservations:**
- Firestore limit: 10,000 writes/second (global)
- Per product contention: ~50 concurrent before conflict rate > 10%
- Expected volume: < 10 concurrent (year 1)
- Headroom: 5x capacity

**Cleanup Job Throughput:**
- Sequential processing: 10 reservations/second
- With batching: 50 reservations/second
- Expected backlog: < 20 reservations per run

---

### Scaling Limits

**Hot Product Contention:**
- Symptom: Popular product causes > 30% transaction conflicts
- Detection: Track conflict rate per product
- Mitigation: Automatic retry handles most conflicts
- Escalation: Admin increases inventory or splits SKUs

**Large Cart Checkout:**
- Limit: 50 items per cart (enforced)
- Beyond limit: 400 error before transaction
- Reason: Firestore 500-write limit, latency management

---

## Security Considerations

### Attack Vector 1: Inventory Locking DoS

**Attack:** Bot creates reservations, never pays, locks inventory

**Mitigations:**
```
1. Reservation TTL (15 minutes)
   - Inventory automatically released
   - Attack requires continuous effort

2. Rate limiting per customer
   - Max 3 active reservations per customer
   - Detection: Query reservations by customer_id before creating
   - Response: 429 "Too many active reservations"

3. Rate limiting per IP
   - Max 10 reservations per IP per hour
   - Detection: Redis counter by IP
   - Response: 429 "Rate limit exceeded"

4. CAPTCHA on checkout
   - Required if > 5 reservations from IP in 10 minutes
   - Blocks automated bots

5. Monitoring & Alerting
   - Alert if > 50 active reservations (unusual)
   - Alert if abandonment rate > 50% (attack indicator)
   - Admin can force-release suspicious reservations
```

### Attack Vector 2: Race Condition Exploitation

**Attack:** Attempt to create duplicate reservations for same inventory

**Mitigations:**
```
1. Firestore transaction atomicity
   - Prevents double-reservation
   - One commit succeeds, others conflict

2. Idempotency key
   - Same cart_id returns existing reservation
   - No duplicate creation possible

3. Reserved quantity consistency
   - Always checked in transaction
   - Cannot exceed available
```

### Attack Vector 3: Reservation ID Guessing

**Attack:** Guess reservation_id to view/cancel other customers' reservations

**Mitigations:**
```
1. UUID v4 reservation IDs
   - 2^122 possible values
   - Infeasible to guess

2. Customer ownership validation
   - Every reservation operation validates customer_id matches session
   - 403 "Access denied" for mismatched customer

3. Rate limiting on reservation queries
   - 10 queries per minute per IP
   - Prevents enumeration
```

---

## Monitoring & Observability

### Critical Metrics

**1. Reservation Lifecycle**
```
- active_reservations_count (gauge)
- reservation_created_total (counter)
- reservation_expired_total (counter)
- reservation_completed_total (counter)
- reservation_cancelled_total (counter)

Targets:
  - Active reservations: < 30 at any time
  - Completion rate: > 60%
  - Expiration rate: < 40%
  - Admin cancellation rate: < 1%
```

**2. Transaction Performance**
```
- reservation_create_latency_ms (histogram)
- reservation_release_latency_ms (histogram)
- transaction_conflict_rate (percentage)

Targets:
  - Create latency P95: < 200ms
  - Release latency P95: < 100ms
  - Conflict rate: < 5%

Alerts:
  - P95 > 500ms: WARNING
  - P95 > 1000ms: CRITICAL
  - Conflict rate > 20%: CRITICAL
```

**3. Cleanup Job Health**
```
- cleanup_job_last_success_timestamp (gauge)
- cleanup_job_reservations_cleaned (counter per run)
- cleanup_job_duration_ms (histogram)
- expired_reservations_backlog (gauge)

Targets:
  - Last success: < 15 minutes ago
  - Duration: < 30 seconds
  - Backlog: < 20

Alerts:
  - No run in 15 minutes: CRITICAL
  - Duration > 2 minutes: WARNING
  - Backlog > 50: CRITICAL
```

**4. Inventory Integrity**
```
- negative_inventory_detected (counter)
- reserved_quantity_mismatch (counter)

Targets:
  - Both should be ZERO always

Alerts:
  - Any occurrence: CRITICAL (data corruption)
```

---

### Logging Strategy

**INFO level:**
```
- Reservation created (id, customer, items, expires_at)
- Reservation completed (id, order_id)
- Reservation expired (id, customer)
- Cleanup job completed (count, duration)
```

**WARN level:**
```
- Transaction conflict (product_id, attempt_count)
- Reservation near expiration during payment (id, remaining_time)
- High abandonment rate detected
- Cleanup job slow (> 1 minute)
```

**ERROR level:**
```
- Reservation creation failed (reason, cart)
- Transaction timeout (product_ids, duration)
- Cleanup job failed (error, reservations_pending)
```

**CRITICAL level:**
```
- Negative inventory detected (product_id, values)
- Reserved quantity mismatch (product_id, expected, actual)
- Cleanup job not running (last_run, gap)
```

---

### Admin Dashboard Indicators

**Reservation Health Panel:**
```
┌──────────────────────────────────────────┐
│ Active Reservations: 12                  │
│ ████████░░░░░░░░ 40% capacity           │
│                                          │
│ Avg Time to Complete: 4.2 min            │
│ Completion Rate: 68%                     │
│ Expiration Rate: 32%                     │
│                                          │
│ Last Cleanup: 3 min ago ✓                │
│ Backlog: 0 reservations                  │
└──────────────────────────────────────────┘
```

**Inventory Status Panel:**
```
┌──────────────────────────────────────────┐
│ Low Stock Alerts:                        │
│ • Wildflower 12oz: 3 available (8 reserved) │
│ • Buckwheat 8oz: 1 available (0 reserved)   │
│                                          │
│ High Contention Products:                │
│ • Comb Honey: 15% conflict rate          │
│                                          │
│ ✓ All inventory consistent              │
└──────────────────────────────────────────┘
```

---

## Testing Strategy

### Unit Tests (Per Function)

**reserveInventory():**
```
- Happy path: single item, sufficient inventory
- Happy path: multiple items, all available
- Insufficient inventory: single item
- Insufficient inventory: second item in cart fails all
- Product not found
- Product inactive
- Invalid quantities (0, negative, > 100)
- Cart limit exceeded (> 50 items)
- Idempotency: same cart_id returns existing
- Transaction conflict simulation
- Transaction timeout simulation

Total: 12 test cases
```

**releaseReservation():**
```
- Happy path: active reservation released
- Idempotency: already released (status = "expired")
- Idempotency: already completed (status = "completed")
- Not found: reservation doesn't exist
- Multi-item: all products updated correctly
- Transaction conflict simulation

Total: 6 test cases
```

**cleanupExpiredReservations():**
```
- Happy path: 10 expired reservations cleaned
- No expired: nothing to clean
- Mixed: some active, some expired (only expired cleaned)
- Large batch: 100 reservations processed
- Partial failure: some release fail, others succeed
- Deduplication: concurrent job runs

Total: 6 test cases
```

**updateProductInventory():**
```
- Happy path: increase quantity
- Happy path: decrease within available
- Validation: quantity < reserved (rejected)
- Validation: quantity = reserved exactly (allowed)
- Validation: negative quantity (rejected)
- Concurrent: admin update during reservation

Total: 6 test cases
```

**Total unit tests: 30 test cases**

---

### Integration Tests (End-to-End)

**Test 1: Complete reservation lifecycle**
```
1. POST /api/reserve-inventory (single item) → 200
2. Verify product.reserved_quantity incremented
3. Wait 15 minutes (mock time)
4. Trigger cleanup job
5. Verify reservation.status = "expired"
6. Verify product.reserved_quantity decremented
```

**Test 2: Concurrent checkout race**
```
1. Set product available = 1
2. POST /api/reserve-inventory (Customer A) → 200
3. POST /api/reserve-inventory (Customer B) → 400 (insufficient)
4. Verify only one reservation exists
5. Verify reserved_quantity = 1
```

**Test 3: Multi-product atomic reservation**
```
1. POST /api/reserve-inventory (3 items, second insufficient) → 400
2. Verify NO reservations created (all-or-nothing)
3. Verify NO reserved_quantity changes
```

**Test 4: Reservation completion**
```
1. Create reservation
2. Simulate payment success
3. POST /api/confirm-order → 200
4. Verify reservation deleted
5. Verify product.quantity decremented
6. Verify product.reserved_quantity decremented
```

**Test 5: Idempotent cleanup**
```
1. Create expired reservation
2. Trigger cleanup job (run 1) → 1 cleaned
3. Trigger cleanup job (run 2) → 0 cleaned (idempotent)
4. Verify reserved_quantity decremented only once
```

**Test 6: Lazy cleanup fallback**
```
1. Create expired reservation
2. Disable cleanup job
3. POST /api/reserve-inventory (same product) → triggers lazy cleanup
4. Verify expired reservation released
5. Verify new reservation created successfully
```

**Test 7: Admin inventory update validation**
```
1. Create reservation (5 units)
2. POST /admin/api/update-inventory (quantity = 3) → 400 (< reserved)
3. POST /admin/api/update-inventory (quantity = 5) → 200 (= reserved)
4. POST /admin/api/update-inventory (quantity = 10) → 200 (> reserved)
```

**Total integration tests: 7 scenarios**

---

### Load Tests (Performance Validation)

**Scenario 1: Normal load**
```
- 10 concurrent reservation requests
- 100 reservations over 10 minutes
- Measure: P95 latency, conflict rate

Success criteria:
  - P95 < 200ms
  - Conflict rate < 5%
  - Zero data corruption
```

**Scenario 2: Peak load (flash sale)**
```
- 50 concurrent reservation requests
- Single "hot" product
- Measure: Conflict rate, success rate

Success criteria:
  - All conflicts resolved via retry
  - No overselling
  - P95 < 1000ms (with retries)
```

**Scenario 3: Cleanup backlog**
```
- Create 200 expired reservations
- Trigger single cleanup job
- Measure: Duration, completeness

Success criteria:
  - All 200 cleaned
  - Duration < 1 minute
  - No crashes or timeouts
```

---

## Dependencies

**External Services:**
- Firestore (transaction storage)
- Cloud Scheduler (cleanup job trigger)

**Internal Services:**
- Auth service (customer session validation)
- Product service (inventory lookups)
- Order service (reservation completion)

**Libraries:**
- Firestore SDK (v9.x)
- Express (v4.x)

---

## Configuration

**Environment Variables:**
```
FIRESTORE_PROJECT_ID=manik-honey-prod
RESERVATION_TTL_MINUTES=15
CLEANUP_JOB_INTERVAL_MINUTES=5
CLEANUP_BATCH_SIZE=100
MAX_CART_ITEMS=50
MAX_ITEM_QUANTITY=100
TRANSACTION_TIMEOUT_MS=8000
MAX_TRANSACTION_RETRIES=3
RESERVATION_RATE_LIMIT_PER_CUSTOMER=3
RESERVATION_RATE_LIMIT_PER_IP_HOURLY=10
```

---

## Success Criteria (Quantified)

**Reliability:**
- Zero overselling events (100% inventory integrity)
- Zero negative inventory states
- < 0.1% reservation operations require manual intervention

**Performance:**
- P95 reservation creation < 200ms
- P95 reservation release < 100ms
- Cleanup job duration < 30 seconds (normal load)

**Availability:**
- Cleanup job runs every 5 minutes (± 1 minute tolerance)
- Lazy cleanup provides fallback for scheduler outage
- System self-heals within 15 minutes of any failure

**Customer Experience:**
- Clear error messages for inventory issues
- Automatic conflict resolution (customer doesn't see retries)
- Fair race condition handling (first to commit wins)

**Business:**
- Reservation conversion rate > 60%
- Expiration rate < 40%
- Admin intervention < 1/week

---

## Open Questions Resolved

All 7 L1 questions answered:

**Q1: What if background job fails to run?**
✅ Multi-layer mitigation: monitoring, manual trigger, lazy cleanup fallback

**Q2: What if two background jobs run simultaneously?**
✅ Idempotent design: status check prevents double-release

**Q3: What if admin updates inventory below reserved?**
✅ Validation prevents with clear resolution options

**Q4: What if customer's session expires mid-checkout?**
✅ Reservation persists independently of session; re-auth possible

**Q5: Can customer see reservation time remaining?**
✅ expires_at returned in API, frontend shows countdown

**Q6: What if product deleted while reservations exist?**
✅ Product deletion validates no active reservations; or cascades cancel

**Q7: Race condition handling?**
✅ Firestore transaction atomicity with automatic retry

---

**Last Updated:** 2026-01-24
**Stage:** L3
**Status:** ✅ Complete - Exhaustive scenario coverage achieved
**Confidence Level:** 95%+
