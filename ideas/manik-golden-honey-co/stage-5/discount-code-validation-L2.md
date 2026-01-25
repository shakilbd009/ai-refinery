# L2: Discount Code Validation & Race Conditions

**Component:** Promotional Code Application & Enforcement
**Stage:** L2 (Refine L2 - Detailed Design)
**Date:** 2026-01-24

---

## Critical Questions from L1

1. **What if code reaches max redemptions during customer's checkout?**
2. **What if discount code expires during checkout?**

---

## Problem 1: Max Redemptions Race Condition

### Scenario

```
Promo code: "LAUNCH10"
- max_redemptions: 100
- used_count: 99
- One redemption remaining

Timeline:
T+0ms:  Customer A applies code → validates → used_count = 99 ✓
T+5ms:  Customer B applies code → validates → used_count = 99 ✓
T+10ms: Customer A completes payment → increments used_count = 100
T+15ms: Customer B completes payment → increments used_count = 101 ❌

Result: 101 redemptions on code with max_redemptions = 100 (over-redemption).
```

**Impact:**
- Marketing budget exceeded (unexpected discount costs)
- Fraud potential (attacker spams code applications)
- Analytics inaccurate (used_count > max_redemptions)

---

## Solution: Optimistic Redemption with Triple Validation

### High-Level Algorithm

**Three validation points:**

1. **Application time** (when customer enters code)
2. **Payment intent time** (when creating Stripe payment)
3. **Order creation time** (when confirming order)

---

### Validation 1: Code Application (Frontend UX)

**Endpoint:** `POST /api/apply-promo-code`

```
FUNCTION applyPromoCode(code, customerId, cartTotal):
  1. READ promo_codes WHERE code = {code}

  2. IF not found:
       RETURN error "Invalid code"

  3. IF promo.active == false:
       RETURN error "Code no longer active"

  4. IF promo.expires_at < now:
       RETURN error "Code expired"

  5. IF promo.min_order_value > cartTotal:
       RETURN error "Minimum order ${promo.min_order_value} required"

  6. IF promo.used_count >= promo.max_redemptions:
       RETURN error "Code fully redeemed"

  7. QUERY promo_code_usage:
       WHERE code = {code} AND customer_id = {customerId}

     IF usage found AND promo.one_time_per_customer:
       RETURN error "Code already used"

  8. RETURN success:
       {
         "discount_percent": promo.discount_percent,
         "discount_amount": cartTotal * (promo.discount_percent / 100),
         "valid": true
       }
```

**Key point:** No state changes at application time (read-only validation).

**Why not reserve redemption?**
- Customer might abandon cart (reservation never released)
- Complexity not warranted for MVP (acceptable over-redemption risk)

---

### Validation 2: Payment Intent Creation (Critical Path)

**Endpoint:** `POST /api/create-payment-intent`

```
FUNCTION createPaymentIntent(reservationId, promoCode):
  1. BEGIN Firestore transaction

  2. IF promoCode provided:
       a. READ promo_codes WHERE code = {promoCode}

       b. VALIDATE (same checks as application):
          - active == true
          - expires_at >= now
          - min_order_value <= cartTotal
          - used_count < max_redemptions

       c. IF validation fails:
            ROLLBACK transaction
            RETURN error (code no longer valid)

  3. CREATE Stripe PaymentIntent:
       amount = cartTotal - discountAmount
       metadata:
         reservation_id: reservationId
         promo_code: promoCode (if applied)
         original_amount: cartTotal
         discount_amount: discountAmount

  4. COMMIT transaction

  5. RETURN payment_intent (customer proceeds to Stripe checkout)
```

**Key point:** Re-validate code, but don't increment `used_count` yet (payment might fail).

---

### Validation 3: Order Creation (Final Enforcement)

**Endpoint:** `POST /api/confirm-order` (or webhook)

```
FUNCTION createOrderFromPayment(payment_intent_id):
  1. BEGIN Firestore transaction

  2. Extract metadata from payment_intent:
       promo_code = metadata.promo_code

  3. IF promo_code:
       a. READ promo_codes WHERE code = {promo_code}

       b. VALIDATE (final check):
          - active == true
          - expires_at >= now (might expire during payment)
          - used_count < max_redemptions (might reach limit)

       c. IF validation FAILS:
            // Payment succeeded but code invalid
            Log warning: "Promo code invalid at order creation"

            DECISION: Create order WITHOUT discount?
                     OR fail order creation + refund?

            For MVP: Create order without discount (customer keeps payment)
            // Reasoning: Customer already paid, better UX to honor order

       d. IF validation succeeds:
            // Increment usage atomically
            UPDATE promo_codes:
              used_count += 1

            CREATE promo_code_usage:
              code: promo_code
              customer_id: customerId
              order_id: orderId
              discount_applied: discountAmount
              redeemed_at: now

  4. CREATE order document:
       promo_code: promo_code
       discount_amount: discountAmount
       total: payment_intent.amount

  5. COMMIT transaction (all-or-nothing)

  6. RETURN order
```

**Critical decision point:** Handle code invalidation gracefully.

---

## Race Condition Handling: Max Redemptions

### Case 1: Two Customers, One Slot Remaining

```
Code: used_count = 99, max_redemptions = 100

Customer A flow:
T+0:  Apply code → validates (99 < 100) ✓
T+10: Create payment intent → validates (99 < 100) ✓
T+20: Pay with Stripe → succeeds
T+30: Confirm order transaction:
      - READ promo_codes → used_count = 99
      - VALIDATE 99 < 100 ✓
      - UPDATE used_count = 100
      - CREATE usage record
      - COMMIT ✓

Customer B flow (overlapping):
T+5:  Apply code → validates (99 < 100) ✓
T+15: Create payment intent → validates (99 < 100) ✓
T+25: Pay with Stripe → succeeds
T+35: Confirm order transaction:
      - READ promo_codes → used_count = 100 (A committed)
      - VALIDATE 100 < 100 → FAIL ✗
      - DECISION: Create order without discount
      - COMMIT (order created, no discount)
```

**Outcome:**
- Customer A: Gets discount (first-come-first-served)
- Customer B: Pays full price (code exhausted)

**Customer B experience:**
- Payment succeeds (already charged full price at payment intent)
- Order confirmation shows: "Code expired during checkout, full price applied"
- Email notification explains situation
- Customer support can offer manual discount/refund (goodwill)

---

### Case 2: Three Customers, Two Slots Remaining

```
Code: used_count = 98, max_redemptions = 100

Customer A, B, C all apply code and pay simultaneously:

Order creation transactions (serialized by Firestore):
1. Transaction A: used_count = 98 → validates → increments to 99 ✓
2. Transaction B: used_count = 99 → validates → increments to 100 ✓
3. Transaction C: used_count = 100 → validates 100 < 100 → FAIL ✗

Outcome:
- A and B: Get discount (race winners)
- C: Pays full price (too slow)
```

**Fairness:** First-to-commit wins (not first-to-apply). Acceptable for MVP.

---

## Problem 2: Code Expiration During Checkout

### Scenario

```
Promo code: "WEEKEND20"
- expires_at: 2026-01-26 23:59:59 UTC (Sunday midnight)

Customer checkout flow:
T+0 (23:55): Customer applies code → validates (not expired) ✓
T+5 (23:57): Customer fills shipping info
T+10 (00:02): Customer completes payment → code expired ❌

Question: Should payment succeed? With or without discount?
```

**User expectations:**
- Customer saw code validated successfully
- Expects discount to be honored
- But code expired before payment completed

**Business expectations:**
- Weekend promotion ended at midnight
- Don't want to honor expired codes (margin pressure)

---

## Solution: Grace Period + Clear Communication

### High-Level Algorithm

**Validation with grace period:**

```
FUNCTION validatePromoCode(code, validationTime):
  1. READ promo_codes WHERE code = {code}

  2. IF promo.expires_at < validationTime:
       // Code expired

       gracePeriod = 5 minutes
       IF validationTime <= promo.expires_at + gracePeriod:
         // Within grace period, allow with warning
         RETURN {
           valid: true,
           warning: "Code expires soon, complete checkout quickly"
         }
       ELSE:
         // Beyond grace period, reject
         RETURN {
           valid: false,
           error: "Code expired"
         }

  3. RETURN { valid: true }
```

**Grace period rationale:**
- 5-minute buffer for customers already checking out
- Prevents frustration (code validated, then rejected)
- Low business risk (few redemptions in 5-min window)

---

## Expiration Handling at Each Stage

### Stage 1: Application (23:55)

```
Customer applies code at 23:55 (5 min before expiration):

Validation:
- expires_at = 23:59:59
- now = 23:55:00
- expires_at > now ✓

Response:
{
  "valid": true,
  "warning": "Code expires in 4 minutes. Complete checkout soon."
}

Frontend shows warning badge:
  ⚠️ Code expires in 4 minutes
```

**UX improvement:** Countdown timer on checkout page.

### Stage 2: Payment Intent (23:57)

```
Customer creates payment intent at 23:57 (2 min before expiration):

Validation:
- expires_at = 23:59:59
- now = 23:57:00
- expires_at > now ✓

Stripe PaymentIntent created with discount.

Customer redirected to Stripe checkout (might take 3-10 min to complete).
```

### Stage 3: Order Creation (00:02) - Expired

```
Customer completes payment at 00:02 (2 min AFTER expiration):

Validation:
- expires_at = 23:59:59
- now = 00:02:00
- expires_at < now ❌

Grace period check:
- gracePeriod = 5 minutes
- now (00:02) <= expires_at + 5min (00:04:59) ✓
- Within grace period, ALLOW

Action:
- Increment used_count
- Create order WITH discount
- Log grace period redemption (analytics)

Customer email:
  "Your code expired during checkout but we honored it as a courtesy."
```

### Stage 4: Order Creation (00:10) - Beyond Grace

```
Customer completes payment at 00:10 (10 min AFTER expiration):

Grace period check:
- now (00:10) > expires_at + 5min (00:04:59) ✗
- Beyond grace period, REJECT discount

Action:
- Order created WITHOUT discount (customer already paid full price)
- Customer charged full amount (payment intent had full price due to validation failure)

WAIT - This is a problem. Payment intent was created WITH discount at 23:57.
If we reject discount at order creation, customer paid discounted amount but we don't record discount.
```

**Issue identified:** Payment intent amount locked in at creation. Can't change later.

---

## Revised Solution: Lock-In Validation at Payment Intent

### Design Decision: Payment Intent Validation is Binding

```
RULE: If code validates at payment intent creation, honor it at order creation.

Rationale:
- Stripe charges customer based on payment intent amount
- Can't retroactively change amount after payment
- Better UX: Customer sees final price before paying

Implementation:
- Validation at payment intent creation is final
- Order creation uses code from payment_intent.metadata (trusted)
- No re-validation at order creation (causes UX issues)
```

**Updated algorithm:**

```
FUNCTION createPaymentIntent(reservationId, promoCode):
  1. IF promoCode:
       Validate code (with grace period)
       IF invalid: REJECT (customer fixes code before paying)

  2. Calculate discounted amount

  3. Create Stripe PaymentIntent with discounted amount

  4. Store in metadata:
       promo_code: code
       discount_locked_in: true
       validation_time: now


FUNCTION createOrderFromPayment(payment_intent_id):
  1. Extract metadata.promo_code

  2. IF promo_code AND metadata.discount_locked_in:
       // Trust payment intent validation (no re-validation)
       Increment used_count
       Create order with discount

       // Log if code expired between payment intent and order creation
       IF code.expires_at < now:
         Log "Code expired during payment, honored due to lock-in"

  3. Create order with discount from payment_intent.amount
```

**Key change:** No re-validation at order creation (except for race condition check on max_redemptions).

---

## Revised Max Redemptions Handling

**Problem:** If we don't re-validate, over-redemption is guaranteed (no enforcement).

**Solution: Best-effort validation with refund fallback**

```
FUNCTION createOrderFromPayment(payment_intent_id):
  1. Extract metadata.promo_code

  2. IF promo_code:
       BEGIN transaction

       READ promo_codes (get current used_count)

       IF used_count >= max_redemptions:
         // Code exhausted between payment and order creation
         Log "Code over-redeemed (race condition)"

         DECISION POINT:
           A) Create order with discount anyway (honor payment intent)
           B) Create order without discount, refund difference
           C) Fail order creation, full refund

         MVP Decision: (A) Honor discount (customer paid discounted price)
         // Accept over-redemption (rare, low business impact)
         // Admin can review over-redemptions and adjust future campaigns

       INCREMENT used_count (even if over limit)
       CREATE usage record

       COMMIT transaction

  3. Create order
```

**Accepted risk:** Over-redemption by 1-3 uses per code (rare, low cost).

**Monitoring:** Alert if `used_count > max_redemptions` (review for fraud).

---

## Edge Cases Discovered

### Edge Case 1: Admin Deactivates Code During Checkout

```
Timeline:
T+0:  Customer applies code "LAUNCH10" → validates ✓
T+5:  Admin deactivates code (campaign ended early)
T+10: Customer creates payment intent → validates → FAIL (active = false)

Customer experience:
- Error: "Code no longer active"
- Must remove code and pay full price
- Clear messaging: "This promotion has ended"
```

**Handled by validation at payment intent creation.**

### Edge Case 2: Admin Changes Discount Percentage Mid-Checkout

```
Timeline:
T+0:  Code "SAVE20" has discount_percent = 20
T+1:  Customer applies code → sees 20% discount
T+5:  Admin changes discount_percent = 10 (typo correction)
T+10: Customer creates payment intent → re-reads code → uses 10%

Customer experience:
- Saw 20% discount at application
- Charged for 10% discount
- Confusion, potential customer service issue
```

**Mitigation: Lock discount at application time**

```
FRONTEND: When code applied, store discount_percent in session
PAYMENT INTENT: Use stored discount_percent (not re-read from DB)
METADATA: Include discount_percent in payment_intent.metadata (audit trail)
```

**Tradeoff:** Slight staleness vs customer trust (honor shown discount).

### Edge Case 3: Code Expires Exactly at Midnight (DST Transition)

```
Code expires_at: 2026-03-09 00:00:00 America/New_York (DST transition)

Issue: Daylight saving time creates 23-hour day (spring forward).
Customer in different timezone sees different expiration.

Mitigation:
- Store expires_at in UTC (already planned)
- Display expiration in customer's timezone (frontend conversion)
- Grace period handles timezone confusion
```

**No code change needed.** UTC storage + grace period solves this.

### Edge Case 4: Multiple Tabs, Same Code Application

```
Customer has two tabs open:
Tab A: Applies code at T+0
Tab B: Applies code at T+1

Both validate successfully (read-only).
Customer completes payment in Tab A → code used.
Customer tries to complete payment in Tab B → code already used (one_time_per_customer).

Validation at payment intent creation:
- READ promo_code_usage (check if customer used code)
- IF found: REJECT "Code already used"
```

**Prevented by one_time_per_customer check at payment intent creation.**

---

## Monitoring & Alerts

### Critical Metrics

1. **Over-Redemption Detection**
   - Query: `WHERE used_count > max_redemptions`
   - Alert if any found (review for fraud)
   - Dashboard: Over-redeemed codes list

2. **Grace Period Redemptions**
   - Track redemptions within grace period (expires + 5min)
   - Dashboard: % of redemptions using grace period
   - High percentage = expiration UX issue (extend grace?)

3. **Code Validation Failure Rate**
   - Track validation failures at payment intent stage
   - Alert if > 20% failure rate (code configuration issue)
   - Dashboard: Failure reasons (expired, max redemptions, inactive)

4. **Discount Amount Variance**
   - Compare discount at application vs order creation
   - Alert if mismatch (admin changed discount mid-checkout)
   - Dashboard: Variance by code

### Admin Dashboard Indicators

- **"Over-Redeemed"** badge: used_count > max_redemptions (review needed)
- **"Expiring Soon"** warning: expires_at < now + 24 hours
- **"High Failure Rate"** alert: > 30% validations failing (misconfigured code)

---

## Testing Scenarios

### Unit Tests

1. **Max redemptions race**
   - Mock two concurrent order creations
   - Code has max_redemptions = 100, used_count = 99
   - Assert: Both orders created (one with discount, over-redemption logged)

2. **Expiration with grace period**
   - Code expires_at = T+0
   - Validate at T+3 (within 5-min grace)
   - Assert: Validation succeeds with warning

3. **Expiration beyond grace**
   - Code expires_at = T+0
   - Validate at T+10 (beyond grace)
   - Assert: Validation fails

### Integration Tests

1. **End-to-end checkout with expiring code**
   - Apply code 2 min before expiration
   - Complete payment 3 min after expiration (within grace)
   - Assert: Order created with discount
   - Assert: Grace period redemption logged

2. **Admin deactivation during checkout**
   - Customer applies code
   - Admin deactivates code
   - Customer attempts payment
   - Assert: Payment intent creation fails
   - Assert: Clear error message shown

3. **One-time-per-customer enforcement**
   - Customer completes order with code
   - Same customer tries to use code again
   - Assert: Validation fails at payment intent creation
   - Assert: Error message: "Code already used"

---

## L1 Questions Answered

### Q1: What if code reaches max redemptions during customer's checkout?

**Answer:**

**Best-effort validation with graceful degradation:**

1. **Validation at payment intent creation** (before customer pays):
   - Check `used_count < max_redemptions`
   - If exhausted, customer sees error BEFORE paying (good UX)

2. **Validation at order creation** (after payment):
   - Re-check `used_count < max_redemptions`
   - If exhausted (race condition), two options:
     - **MVP:** Honor discount anyway (accept over-redemption)
     - **Future:** Create order without discount, refund difference

3. **Accepted risk:**
   - 1-3 over-redemptions per code (rare, happens when multiple customers pay simultaneously)
   - Business impact: ~$50-150 (acceptable for MVP)
   - Monitoring alerts for review (prevent fraud)

**First-come-first-served:** Transaction commit order determines winners.

### Q2: What if discount code expires during checkout?

**Answer:**

**Grace period + lock-in at payment intent creation:**

1. **Grace period (5 minutes):**
   - Code expired < 5 min ago → Still valid
   - Customer completes checkout within grace → Gets discount
   - Customer exceeds grace → Code rejected at payment intent creation

2. **Lock-in at payment intent:**
   - Once payment intent created with discount, discount honored
   - No re-validation at order creation (prevents UX issues)
   - Customer charged discounted amount, order reflects discount

3. **Customer experience:**
   - Code validates at application → Shows expiration warning
   - If code expires before payment intent → Rejected early (before paying)
   - If code expires after payment intent → Honored (customer already paid)

**Grace period rationale:** Prevent frustration (code showed valid, then rejected). 5-minute window balances customer trust vs business rules.

---

**Last Updated:** 2026-01-24
**Stage:** L2
**Status:** ✅ Critical questions resolved
