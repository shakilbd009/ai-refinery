# L2: Inventory Operations & Validation

**Component:** Background Jobs & Admin Inventory Management
**Stage:** L2 (Refine L2 - Detailed Design)
**Date:** 2026-01-24

---

## Critical Questions from L1

1. **What if background job fails to run (Cloud Scheduler down)?**
2. **What if admin updates inventory below reserved amount?**

---

## Problem 1: Background Job Failure & Mitigation

### Scenario

```
Background cleanup job scheduled every 5 minutes via Cloud Scheduler.

Failure scenarios:
1. Cloud Scheduler service outage (GCP incident)
2. Cloud Run service down (deployment, quota exceeded)
3. Firestore timeout (slow queries)
4. Job crashes mid-execution (OOM, bug)

Impact if job stops running:
- Expired reservations never released
- Inventory permanently locked
- Customers see "Out of stock" for available inventory
- Revenue loss (can't sell inventory)
```

**Critical question:** How long can system survive without cleanup job?

---

## Solution: Multi-Layered Failure Mitigation

### Layer 1: Cloud Scheduler Reliability

**GCP SLA:** 99.95% uptime (26 minutes/month downtime expected)

**Scheduler configuration:**
```
Schedule: */5 * * * * (every 5 minutes)
Timezone: UTC
Retry policy:
  - Max retry attempts: 3
  - Max retry duration: 10 minutes
  - Min/max backoff: 5s / 300s
```

**Expected behavior:**
- Job runs 288 times/day (every 5 min)
- If trigger fails, retries up to 3 times
- Most failures resolve within retry window

**Limitation:** Extended GCP outage (> 30 min) not covered by retries.

---

### Layer 2: Job Health Monitoring

**Algorithm: Heartbeat Detection**

```
Collection: job_runs
Document structure:
  job_run_id: "cleanup-2026-01-24-10-05"
  job_type: "cleanup_reservations"
  started_at: timestamp
  completed_at: timestamp
  reservations_cleaned: 12
  status: "success" | "failed" | "timeout"

Monitor query:
  SELECT * FROM job_runs
  WHERE job_type = "cleanup_reservations"
  WHERE started_at > now - 15 minutes
  ORDER BY started_at DESC
  LIMIT 1

IF no results OR last_run.completed_at == null:
  ALERT "Cleanup job not running" (critical)
```

**Alert destinations:**
- Slack channel (#critical-alerts)
- Email to admin
- PagerDuty (if configured)

**Alert threshold:** 15 minutes without successful job completion.

---

### Layer 3: Fallback Cleanup via API Endpoint

**Manual trigger endpoint:**

```
POST /admin/api/cleanup-reservations
Authorization: Admin JWT token

Response:
{
  "job_run_id": "manual-2026-01-24-10-30",
  "reservations_cleaned": 15,
  "duration_ms": 342,
  "status": "success"
}
```

**Admin dashboard:**
- **"Run Cleanup Now"** button (manual trigger)
- Shows last cleanup job status
- Shows count of expired reservations pending cleanup

**When to use:**
- Automated job fails (scheduler outage)
- Admin sees inventory locked alert
- After deploying job fix (verify it works)

---

### Layer 4: Lazy Cleanup on Checkout

**Algorithm: Clean while checking availability**

```
FUNCTION checkInventoryAvailability(productId, quantity):
  1. BEGIN transaction

  2. READ product document
     available = product.quantity - product.reserved_quantity

  3. QUERY reservations:
       WHERE product_id = productId
       WHERE status = "active"
       WHERE expires_at < now
       LIMIT 10

  4. IF expired reservations found:
       FOR EACH expired in expiredReservations:
         releaseReservation(expired.id) // Inline cleanup

       // Recalculate available after cleanup
       READ product document again
       available = product.quantity - product.reserved_quantity

  5. RETURN available >= quantity

  6. COMMIT transaction
```

**Benefits:**
- Self-healing system (cleans during normal operations)
- Reduces impact of scheduler failure
- Customers benefit immediately from freed inventory

**Tradeoffs:**
- Adds latency to checkout (1-2 sec for cleanup)
- Not exhaustive (LIMIT 10 to prevent timeout)
- Only cleans for accessed products

**Decision:** Implement as safety net, not primary cleanup mechanism.

---

### Layer 5: TTL-Based Expiration (Future Enhancement)

**Firestore TTL policy (if available in future):**

```
Collection: reservations
TTL field: expires_at
Automatic deletion: When expires_at < now

Benefits:
- No background job needed
- Firestore handles cleanup automatically
- Zero maintenance

Limitations:
- TTL not yet available for Firestore (only Cloud Firestore DeleteOps)
- Still need to decrement reserved_quantity (requires Cloud Function trigger)
```

**Not viable for MVP:** TTL + trigger complexity exceeds current approach.

---

## Failure Impact Analysis

### Scenario 1: Cleanup Job Down for 1 Hour

```
Assumptions:
- Reservations created at rate of 20/hour (1 every 3 min)
- Average checkout completion: 70% (14 orders, 6 abandonments)
- Abandoned reservations accumulate

Impact timeline:
T+0:    Last successful cleanup (0 expired reservations)
T+5min: 1 reservation expires (not cleaned)
T+10:   2 reservations expired (not cleaned)
T+15:   3 expired, 15 units locked
T+30:   6 expired, 30 units locked
T+60:   12 expired, ~60 units locked

Revenue impact:
- If average cart = 5 units, ~12 carts blocked
- If conversion rate = 10%, ~1 lost sale
- Lost revenue: ~$50 (honey product average $50)

Customer impact:
- Customers see "Out of stock" incorrectly
- Negative experience, potential churn
```

**Mitigation:** 15-minute alert + manual trigger → 20 min max downtime → 4 expired reservations → Acceptable for MVP.

### Scenario 2: Cleanup Job Down for 24 Hours (Extreme)

```
Impact:
- 480 reservations created/day
- 144 abandoned (30% abandonment rate)
- ~720 units locked (avg 5 units/cart)

Revenue impact:
- If total inventory = 200 units across 20 products (avg 10/product)
- 720 locked units >> total inventory → Severe impact

Mitigation:
- Manual cleanup API endpoint (admin runs hourly)
- Lazy cleanup on checkout (self-healing)
- Alert fatigue → Admin acts within hours, not days
```

**Accepted risk:** 24-hour outage unlikely (GCP SLA 99.95%). Manual intervention sufficient.

---

## Problem 2: Admin Inventory Update Validation

### Scenario

```
Current state:
- Product: quantity = 20, reserved_quantity = 15, available = 5
- 15 customers currently checking out (reservations active)

Admin updates:
1. Admin sees "20 units in stock" in dashboard
2. Admin counts physical inventory → only 10 units
3. Admin updates quantity = 10 (correcting error)

Result:
- New state: quantity = 10, reserved_quantity = 15
- Available = 10 - 15 = -5 (NEGATIVE INVENTORY)
- Invariant violated: available_quantity >= 0
```

**Impact:**
- Checkout flow breaks (negative available shown to customers)
- Existing reservations cannot be fulfilled (oversold)
- Data corruption visible in admin dashboard

---

## Solution: Inventory Update Validation with Admin Override

### High-Level Algorithm

**Update product inventory (admin endpoint):**

```
FUNCTION updateProductInventory(productId, newQuantity, adminUserId):
  1. BEGIN transaction

  2. READ product document
     current_quantity = product.quantity
     reserved_quantity = product.reserved_quantity

  3. VALIDATE: newQuantity >= 0
     IF invalid: RETURN error "Quantity cannot be negative"

  4. CALCULATE: future_available = newQuantity - reserved_quantity

  5. IF future_available < 0:
       // Attempting to set quantity below reserved amount
       Log warning: "Admin {adminUserId} attempted invalid inventory update"

       RETURN validation error:
       {
         "error": "insufficient_inventory_for_reservations",
         "message": "Cannot set quantity below reserved amount",
         "details": {
           "requested_quantity": newQuantity,
           "reserved_quantity": reserved_quantity,
           "minimum_allowed": reserved_quantity,
           "active_reservations_count": <count>
         },
         "resolution": "Cancel active reservations or wait for expiration"
       }

  6. UPDATE product:
       quantity = newQuantity
       updated_at = now
       updated_by = adminUserId

  7. COMMIT transaction

  8. Log inventory change:
       "Admin {adminUserId} updated {productId} quantity: {old} → {new}"

  9. RETURN success
```

**Key validation:** `newQuantity >= reserved_quantity`

---

## Admin Dashboard UX

### Inventory Update Form

```
Product: Wildflower Honey 12oz
Current Quantity: 20
Reserved: 15 (view reservations)
Available: 5

New Quantity: [____]

[Update Inventory]
```

**If admin enters invalid quantity (e.g., 10):**

```
❌ Error: Cannot set quantity below reserved amount

Current reservations: 15 units
Minimum allowed quantity: 15

You have 15 active reservations. To reduce inventory below 15:
1. Wait for reservations to expire (next cleanup: 3 min)
2. View and cancel specific reservations manually
3. Contact customers to complete or cancel orders

[View Active Reservations]
```

**Admin actions:**

1. **Wait for expiration:**
   - Reservations expire in 15 min
   - Cleanup job releases them
   - Try update again

2. **Cancel reservations manually:**
   - View reservation list (customer email, quantity, expires_at)
   - Select reservations to cancel
   - Email customers ("Sorry, product unavailable")
   - Release reservations immediately

3. **Override (Future Feature - Not MVP):**
   - Force update with `--override` flag
   - Cancels all conflicting reservations automatically
   - Requires admin confirmation + reason

---

## Edge Cases: Inventory Updates

### Edge Case 1: Admin Increases Inventory

```
State: quantity = 10, reserved = 8, available = 2
Admin updates: quantity = 20

Validation:
- newQuantity (20) >= reserved_quantity (8) ✓
- Update succeeds

New state: quantity = 20, reserved = 8, available = 12

Impact: More inventory available to customers (positive).
```

**No issues.** Increasing inventory always safe.

### Edge Case 2: Admin Sets Quantity = Reserved Exactly

```
State: quantity = 20, reserved = 15, available = 5
Admin updates: quantity = 15

Validation:
- newQuantity (15) >= reserved_quantity (15) ✓
- Update succeeds

New state: quantity = 15, reserved = 15, available = 0

Impact: No new reservations possible until existing reservations resolve.
```

**Edge allowed:** Admin might want to prevent new orders while fulfilling existing.

**Admin dashboard shows:**
- **"Available: 0"** badge (no new orders possible)
- **"Reserved: 15"** indicator (pending orders)

### Edge Case 3: Concurrent Inventory Update + Reservation

```
Timeline:
T+0:  Admin starts update (quantity = 20 → 10)
T+1:  Customer starts reservation (current available = 5)
T+2:  Customer reserves 5 units (reserved_quantity = 15 → 20)
T+3:  Admin update commits (quantity = 10)

Race condition:
- Admin validation saw reserved_quantity = 15 ✓
- Customer increased reserved_quantity to 20
- Admin update commits with quantity = 10
- New state: quantity = 10, reserved = 20 → available = -10 ❌
```

**Solution: Transaction prevents race**

```
Admin transaction:
  1. READ product → reserved = 15
  2. VALIDATE newQuantity (10) < reserved (15) → FAIL
  3. ROLLBACK, RETURN error

Customer transaction (parallel):
  1. READ product → reserved = 15
  2. CREATE reservation (5 units)
  3. UPDATE reserved = 20
  4. COMMIT ✓

Admin transaction (retry):
  1. READ product → reserved = 20 (customer committed)
  2. VALIDATE newQuantity (10) < reserved (20) → FAIL
  3. ROLLBACK, RETURN error (correct behavior)
```

**Firestore transaction ensures admin sees latest `reserved_quantity` before committing.**

### Edge Case 4: Admin Sets Quantity to 0 (Discontinue Product)

```
State: quantity = 10, reserved = 0, available = 10
Admin updates: quantity = 0 (discontinuing product)

Validation:
- newQuantity (0) >= reserved_quantity (0) ✓
- Update succeeds

New state: quantity = 0, reserved = 0, available = 0

Impact: Product unavailable for purchase.
```

**Allowed.** Admin might discontinue products.

**Future enhancement:** Soft-delete (set `active = false` instead of quantity = 0).

---

## Monitoring & Alerts

### Critical Metrics

1. **Cleanup Job Health**
   - Last successful run timestamp
   - Alert if > 15 minutes since last success
   - Dashboard: Job run history (24 hours)

2. **Expired Reservations Backlog**
   - Count of active reservations past expires_at
   - Alert if > 50 (job likely failing)
   - Dashboard: Backlog trend over time

3. **Admin Inventory Update Errors**
   - Track validation failures (quantity < reserved)
   - Alert if > 5 errors/hour (admin workflow issue)
   - Dashboard: Error rate by admin user

4. **Negative Inventory Detection (Critical)**
   - Query: `WHERE quantity - reserved_quantity < 0`
   - Alert immediately if any found (data corruption)
   - Auto-trigger investigation workflow

### Admin Dashboard Indicators

- **"Cleanup Job Failing"** (red banner): Last run > 15 min ago
- **"Expired Reservations Pending"** (count badge): Backlog awaiting cleanup
- **"Inventory Locked"** (product-level): Reserved > available (needs admin action)

---

## Recovery Procedures

### Procedure 1: Cleanup Job Failure Recovery

**Symptoms:**
- Alert: "Cleanup job not running"
- Dashboard shows expired reservations accumulating

**Steps:**
1. Check Cloud Scheduler status page (GCP console)
2. Check Cloud Run service logs (errors/crashes)
3. Trigger manual cleanup via API endpoint
4. Monitor job completion (should clear backlog)
5. If manual trigger fails, investigate Firestore/permissions
6. Document incident, review logs for root cause

**Escalation:** If manual trigger works, schedule temporary cron (higher frequency) until scheduler recovered.

### Procedure 2: Negative Inventory Recovery

**Symptoms:**
- Alert: "Negative inventory detected"
- Product shows available < 0 in dashboard

**Steps:**
1. Identify affected product (alert provides product ID)
2. Read current state: `quantity`, `reserved_quantity`
3. Query active reservations: `WHERE product_id = X, status = active`
4. Calculate correct reserved: `SUM(reservation.quantity)`
5. Compare to product.reserved_quantity:
   - If mismatch: Update product.reserved_quantity (data corruption)
   - If match: Admin must increase quantity or cancel reservations
6. Document root cause (bug vs admin error)

**Prevention:** Negative inventory shouldn't happen (validation prevents). If detected, indicates bug.

---

## Testing Scenarios

### Unit Tests

1. **Inventory validation: quantity < reserved**
   - Set reserved_quantity = 15
   - Attempt update quantity = 10
   - Assert: Error returned, update rejected

2. **Inventory validation: quantity = reserved**
   - Set reserved_quantity = 15
   - Attempt update quantity = 15
   - Assert: Success, available = 0

3. **Concurrent update + reservation race**
   - Mock two transactions (admin update, customer reservation)
   - Assert: Only one succeeds, validation prevents negative

### Integration Tests

1. **Cleanup job failure simulation**
   - Disable Cloud Scheduler
   - Create 10 reservations, wait for expiration
   - Trigger manual cleanup API
   - Assert: All reservations released

2. **Lazy cleanup on checkout**
   - Create expired reservations
   - Trigger checkout flow (checkInventoryAvailability)
   - Assert: Expired reservations cleaned inline
   - Assert: Inventory available updated

3. **Admin update with active reservations**
   - Create 5 active reservations (25 units)
   - Attempt admin update quantity = 20
   - Assert: Validation error, update rejected
   - Assert: Helpful error message with resolution steps

---

## L1 Questions Answered

### Q1: What if background job fails to run (Cloud Scheduler down)?

**Answer:**

**Multi-layered mitigation prevents inventory lockup:**

1. **Monitoring (15 min):** Alert fires if job hasn't run in 15 minutes
2. **Manual trigger (immediate):** Admin runs cleanup via API endpoint
3. **Lazy cleanup (self-healing):** Checkout flow cleans expired reservations inline
4. **Impact (low):** 15-20 min max downtime → ~4 expired reservations → Acceptable revenue impact

**Worst-case scenario (24-hour outage):**
- Manual API endpoint allows hourly cleanup
- Lazy cleanup prevents complete lockup
- Revenue impact < $500 (acceptable risk for MVP)

**Long-term solution:** Monitoring + runbooks ensure rapid response (< 30 min).

### Q2: What if admin updates inventory below reserved amount?

**Answer:**

**Validation prevents negative inventory with clear resolution path.**

**How it works:**
1. Admin attempts update: `newQuantity = 10`
2. Backend validates: `newQuantity (10) >= reserved_quantity (15)?`
3. Validation fails → Update rejected
4. Error response shows:
   - Current reservations: 15 units
   - Minimum allowed: 15
   - Resolution options: Wait for expiration, cancel reservations

**Admin actions:**
- **Wait:** Reservations expire in ≤15 min, then update succeeds
- **Cancel manually:** View reservations, cancel specific ones, update
- **Increase instead:** Correct inventory count might be higher

**Edge case handled:** Concurrent update + reservation prevented by Firestore transaction (admin sees latest reserved_quantity before validation).

**Guarantee:** `available_quantity >= 0` invariant always maintained.

---

**Last Updated:** 2026-01-24
**Stage:** L2
**Status:** ✅ Critical questions resolved
