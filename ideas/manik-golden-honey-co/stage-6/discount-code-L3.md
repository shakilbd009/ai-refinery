# L3: Discount Code System - Exhaustive Design

**Component:** Promotional Discount Codes (Order-Wide, Percentage-Based)
**Stage:** L3 (Refine L3 - Exhaustive Coverage)
**Date:** 2026-01-24

---

## L3 Pass: Exhaustive Coverage (Stage 6: Refine L3)

### Complete Flow Variants

All possible discount code paths documented with precise handling.

---

## Variant 1: Happy Path - Code Application & Redemption (Expected 80% of Code Usage)

**Preconditions:**
- Customer has valid session
- Cart total meets minimum order value
- Code is active, not expired, not exhausted
- Customer hasn't used this code before (if one_time_per_customer)

**Flow:**

```
1. Customer clicks "Have a promo code?" on checkout page
   → Frontend: Expands promo code input field

2. Customer enters code "LAUNCH10"
   → Frontend: POST /api/apply-promo-code
   Body: {
     code: "LAUNCH10",
     cart_total: 5000  // $50.00 in cents
   }

3. Backend validates code (read-only):
   Duration: 20-50ms

   READ promo_codes WHERE code = "LAUNCH10"

   Validation chain:
   a) EXISTS: code found ✓
   b) ACTIVE: active == true ✓
   c) NOT_EXPIRED: expires_at > now ✓
   d) MIN_ORDER: min_order_value <= cart_total ✓
   e) NOT_EXHAUSTED: used_count < max_redemptions ✓
   f) NOT_USED_BY_CUSTOMER:
      QUERY promo_code_usage
        WHERE code = "LAUNCH10"
        AND customer_id = session.customer_id
      IF found AND one_time_per_customer: FAIL
      ELSE: ✓

   Response: 200 OK
   {
     "valid": true,
     "code": "LAUNCH10",
     "discount_percent": 10,
     "discount_amount": 500,  // $5.00 off
     "new_total": 4500,       // $45.00
     "message": "10% discount applied!"
   }

4. Frontend updates UI:
   - Shows "LAUNCH10 applied: -$5.00"
   - Updates order total to $45.00
   - Shows [Remove Code] button
   - Stores code in checkout session state

5. Customer continues to shipping address
   No backend calls (code stored in session)

6. Customer clicks "Continue to Payment"
   → Frontend: POST /api/create-payment-intent
   Body: {
     reservation_id: "res_abc123",
     promo_code: "LAUNCH10"
   }

7. Backend creates PaymentIntent with locked discount:
   Duration: 200-500ms

   BEGIN transaction

     // Re-validate code (might have changed since application)
     READ promo_codes WHERE code = "LAUNCH10"
     VALIDATE all checks (same as application)

     IF validation fails:
       ROLLBACK
       RETURN 400 "Code no longer valid"

     // Calculate discount
     discount_amount = cart_total * (discount_percent / 100)
     final_amount = cart_total - discount_amount

     // Create Stripe PaymentIntent
     payment_intent = stripe.paymentIntents.create({
       amount: final_amount,  // 4500 cents
       currency: "usd",
       metadata: {
         reservation_id: "res_abc123",
         promo_code: "LAUNCH10",
         discount_percent: 10,          // Locked value
         discount_amount: 500,          // Locked value
         original_amount: 5000,
         discount_locked: true,
         validation_time: now
       }
     })

   COMMIT transaction

   Response: 200 OK
   {
     "client_secret": "pi_xyz_secret_abc",
     "amount": 4500
   }

8. Customer completes payment on Stripe
   Stripe charges $45.00

9. Stripe webhook: payment_intent.succeeded
   → POST /webhooks/stripe

10. Backend creates order with locked discount:
    Duration: 100-300ms

    BEGIN transaction

      // Extract locked discount from metadata (no re-validation for expiration/percentage)
      promo_code = metadata.promo_code
      discount_amount = metadata.discount_amount

      // ONLY check max_redemptions (accept over-redemption if race)
      READ promo_codes WHERE code = promo_code
      IF used_count >= max_redemptions:
        Log "Over-redemption (race condition), honoring anyway"
        // Continue (customer already paid discounted price)

      // Increment usage
      UPDATE promo_codes:
        used_count += 1

      // Track customer usage
      CREATE promo_code_usage:
        code: "LAUNCH10"
        customer_id: customer_id
        order_id: order_id
        discount_percent: 10
        discount_amount: 500
        redeemed_at: now

      // Create order with discount
      CREATE order:
        promo_code: "LAUNCH10"
        discount_amount: 500
        subtotal: 5000
        total: 4500
        ...

    COMMIT transaction

11. Customer sees order confirmation:
    "Order #1234 confirmed
     Subtotal: $50.00
     Discount (LAUNCH10): -$5.00
     Total: $45.00"

Total duration: 2-8 minutes (customer-dependent)
Backend processing: < 1 second total
```

**Success criteria:**
- Code validation < 50ms
- Payment intent creation < 500ms
- Order creation < 300ms
- Customer sees correct discount throughout

---

## Variant 2: Code Expires During Checkout - Grace Period (5-10% of Code Usage)

**Trigger:** Customer starts checkout near code expiration time

**Flow:**

```
Timeline:
T+0 (23:55): Customer applies "WEEKEND20" (expires 23:59:59)
T+2 (23:57): Customer enters shipping address
T+5 (00:00): Code expires (midnight)
T+8 (00:03): Customer clicks "Pay Now"

1. Code application at 23:55:
   → POST /api/apply-promo-code

   Validation:
     expires_at = 2026-01-26 23:59:59
     now = 2026-01-26 23:55:00
     expires_at > now ✓

   Response: 200 OK
   {
     "valid": true,
     "discount_percent": 20,
     "warning": "Code expires in 4 minutes. Complete checkout soon."
   }

   Frontend shows:
     ⚠️ "WEEKEND20 expires in 4 minutes"
     Countdown timer starts

2. Customer continues (5 minutes pass, code expires)

3. Payment intent creation at 00:03 (4 min after expiration):
   → POST /api/create-payment-intent

   Validation with grace period:
     expires_at = 2026-01-26 23:59:59
     now = 2026-01-27 00:03:00
     expires_at < now (EXPIRED)

     grace_period = 5 minutes
     grace_deadline = expires_at + 5min = 00:04:59

     now (00:03) < grace_deadline (00:04:59) ✓
     WITHIN GRACE PERIOD - ALLOW

   Log:
     "Grace period redemption: WEEKEND20 (expired 4 min ago)"

   Payment intent created with discount
   Metadata includes: within_grace: true

4. Customer completes payment at 00:05

5. Order creation:
   Discount honored (locked at payment intent)
   used_count incremented

6. Confirmation email:
   "Your order is confirmed!
    Note: Your promo code expired during checkout, but we honored it as a courtesy."
```

**Beyond grace period (> 5 minutes after expiration):**

```
Payment intent creation at 00:10 (11 min after expiration):

Validation:
  expires_at = 23:59:59
  now = 00:10:00
  grace_deadline = 00:04:59
  now > grace_deadline ✗
  BEYOND GRACE PERIOD - REJECT

Response: 400
{
  "error": "promo_code_expired",
  "message": "Code WEEKEND20 expired",
  "expired_at": "2026-01-26T23:59:59Z"
}

Frontend shows:
  "Promo code expired

   Code WEEKEND20 is no longer valid.

   [Remove Code & Continue] [Cancel]"

Customer clicks "Remove Code & Continue":
  Session clears promo_code
  Retries payment intent (full price)
```

---

## Variant 3: Max Redemptions Race Condition (1-3% of High-Demand Codes)

**Trigger:** Multiple customers redeem last available slot(s) simultaneously

**Flow:**

```
Code state:
  code: "FLASH50"
  max_redemptions: 100
  used_count: 99
  (1 slot remaining)

Timeline:
T+0ms:   Customer A applies code → validates (99 < 100) ✓
T+5ms:   Customer B applies code → validates (99 < 100) ✓
T+10ms:  Customer C applies code → validates (99 < 100) ✓

T+60s:   Customer A creates payment intent → validates (99 < 100) ✓
T+62s:   Customer B creates payment intent → validates (99 < 100) ✓
T+65s:   Customer C creates payment intent → validates (99 < 100) ✓

T+180s:  Customer A completes payment → webhook received

Order creation (Customer A):
  BEGIN transaction
    READ promo_codes → used_count = 99
    99 < 100 ✓
    UPDATE used_count = 100
    CREATE order with discount
  COMMIT ✓

T+185s:  Customer B completes payment → webhook received

Order creation (Customer B):
  BEGIN transaction
    READ promo_codes → used_count = 100
    100 < 100 ✗ (EXHAUSTED)

    DECISION: Honor locked discount (customer already paid discounted price)

    Log warning: "Over-redemption: FLASH50 (used: 101, max: 100)"
    UPDATE used_count = 101 (track actual usage)
    CREATE order with discount
  COMMIT ✓

T+190s:  Customer C completes payment → webhook received

Order creation (Customer C):
  BEGIN transaction
    READ promo_codes → used_count = 101
    101 < 100 ✗ (EXHAUSTED)

    Same handling as Customer B

    Log warning: "Over-redemption: FLASH50 (used: 102, max: 100)"
    UPDATE used_count = 102
    CREATE order with discount
  COMMIT ✓
```

**Result:**
- 102 redemptions on 100-max code (2 over-redemptions)
- All customers honored (already paid discounted price)
- Over-redemption logged for admin review
- Alert triggered for fraud analysis

**Why accept over-redemption:**
1. Customer already paid discounted amount (Stripe charged them)
2. Can't charge more post-payment without customer action
3. Refund + re-charge is terrible UX
4. 2-3 extra redemptions = ~$50-100 (acceptable for MVP)

**Fraud prevention:**
- Monitor over-redemption patterns
- Alert if > 10% over-redemption (unusual)
- Review accounts with multiple over-redemptions

---

## Variant 4: Cart Changes After Code Application (10-15% of Checkouts)

**Trigger:** Customer removes items or changes quantities after applying code

**Sub-variant 4A: Cart still meets minimum after change**

```
Initial state:
  Cart: $60.00
  Code: SAVE10 (10% off, min order $30)
  Discount: $6.00
  Total: $54.00

Customer removes $10 item:
  New cart: $50.00

Frontend recalculates:
  Discount: $5.00 (10% of $50)
  Total: $45.00
  Code still valid ✓

No backend call needed until payment intent.
Payment intent validates: $50 >= $30 min ✓
```

**Sub-variant 4B: Cart falls below minimum**

```
Initial state:
  Cart: $40.00
  Code: PREMIUM15 (15% off, min order $50)
  Discount: $6.00
  Total: $34.00 (INVALID - below min but displayed)

Wait - this shouldn't happen. Validation should have caught this.

ACTUAL flow:
  Customer applies code → 400 "Minimum order $50 required"
  Code NOT applied if cart < min

But what if customer ADDS item, applies code, then REMOVES item?

Flow:
1. Cart: $60.00 (above min)
2. Apply PREMIUM15 → validates ✓, discount applied
3. Customer removes $20 item
4. New cart: $40.00 (below min)

Frontend behavior:
  On cart change, re-check minimum:
    cart_total ($40) < min_order_value ($50) ✗

  Show warning:
    "⚠️ Cart below minimum for PREMIUM15
     Add $10.00 more to keep your discount, or code will be removed."

  Options:
    [Add More Items] [Remove Code & Continue]

  If customer clicks "Continue to Payment" with invalid code:
    POST /api/create-payment-intent
    → 400 "Cart below minimum order for code PREMIUM15"
    → Frontend forces code removal or cart adjustment
```

**Backend enforcement:**

```
FUNCTION createPaymentIntent(reservation_id, promo_code):
  IF promo_code:
    READ promo_codes
    IF cart_total < promo.min_order_value:
      RETURN 400 {
        "error": "minimum_not_met",
        "message": "Cart below minimum order value",
        "min_order_value": promo.min_order_value,
        "cart_total": cart_total,
        "difference": promo.min_order_value - cart_total
      }

  // Continue with payment intent creation
```

---

## Variant 5: One-Time-Per-Customer Enforcement (5-10% of Repeat Customers)

**Trigger:** Customer attempts to reuse a one_time_per_customer code

**Flow:**

```
1. Customer used "WELCOME20" on Order #1234 (2 weeks ago)

2. Customer starts new order, tries to apply "WELCOME20"
   → POST /api/apply-promo-code

3. Backend validates:
   READ promo_codes WHERE code = "WELCOME20"
   → one_time_per_customer = true

   QUERY promo_code_usage
     WHERE code = "WELCOME20"
     AND customer_id = customer_id
   → FOUND (used on Order #1234)

   RETURN 400 {
     "error": "code_already_used",
     "message": "You've already used this code",
     "used_on_order": "Order #1234",
     "used_at": "2026-01-10"
   }

4. Frontend shows:
   "Code already used

    You used WELCOME20 on Order #1234 (Jan 10, 2026).
    This code can only be used once per customer.

    [Try Different Code] [Continue Without Code]"
```

**Edge case: Same code, different account (fraud attempt)**

```
Scenario:
  Customer creates new account to reuse code

Detection:
  NOT detected at code validation (new customer_id)
  Codes are per-account, not per-person

Mitigation options (not for MVP):
  1. IP tracking (same IP = warning)
  2. Email domain analysis (same email pattern)
  3. Shipping address matching
  4. Payment method fingerprinting

MVP approach:
  Accept per-account limitation
  Monitor for suspicious patterns
  Manual review if > 5 accounts from same IP use same code
```

---

## Variant 6: Admin Code Management (Operations Scenario)

**Sub-variant 6A: Admin creates new code**

```
1. Admin navigates to Promo Codes in admin dashboard
   → GET /admin/api/promo-codes (list existing)

2. Admin clicks "Create New Code"
   → Shows form:
     Code: [SUMMER25______]
     Discount: [25___]%
     Min Order: $[0_____]
     Max Uses: [100___] (blank = unlimited)
     One-Time: [✓] per customer
     Expires: [2026-08-31]

3. Admin submits
   → POST /admin/api/promo-codes
   Body: {
     code: "SUMMER25",
     discount_percent: 25,
     min_order_value: 0,
     max_redemptions: 100,
     one_time_per_customer: true,
     expires_at: "2026-08-31T23:59:59Z"
   }

4. Backend validates and creates:

   FUNCTION createPromoCode(data, admin_user_id):
     BEGIN transaction

       // Validate code uniqueness
       existing = READ promo_codes WHERE code = data.code
       IF existing:
         RETURN 400 "Code already exists"

       // Validate discount range
       IF data.discount_percent < 1 OR data.discount_percent > 100:
         RETURN 400 "Discount must be 1-100%"

       // Create code
       CREATE promo_codes:
         code: data.code.toUpperCase()  // Normalize to uppercase
         discount_percent: data.discount_percent
         min_order_value: data.min_order_value || 0
         max_redemptions: data.max_redemptions || null  // null = unlimited
         one_time_per_customer: data.one_time_per_customer || false
         expires_at: data.expires_at || null  // null = never expires
         active: true
         used_count: 0
         created_at: now
         created_by: admin_user_id

       // Audit log
       CREATE audit_log:
         action: "promo_code_created"
         code: data.code
         admin_user_id: admin_user_id
         timestamp: now

     COMMIT transaction

   Response: 201 Created
   { code: "SUMMER25", ... }

5. Admin sees success:
   "Code SUMMER25 created successfully"
```

**Sub-variant 6B: Admin deactivates code mid-campaign**

```
1. Admin sees "FLASH50" is being abused (fraud detected)

2. Admin clicks "Deactivate" on code
   → POST /admin/api/promo-codes/FLASH50/deactivate

3. Backend deactivates:

   FUNCTION deactivatePromoCode(code, admin_user_id, reason):
     BEGIN transaction

       READ promo_codes WHERE code = code
       IF not found:
         RETURN 404 "Code not found"

       IF active == false:
         RETURN 400 "Code already inactive"

       UPDATE promo_codes:
         active = false
         deactivated_at = now
         deactivated_by = admin_user_id
         deactivation_reason = reason

       CREATE audit_log:
         action: "promo_code_deactivated"
         code: code
         reason: reason
         admin_user_id: admin_user_id
         timestamp: now

     COMMIT transaction

   Response: 200 OK
   { code: "FLASH50", active: false }

4. Impact on in-flight checkouts:
   - Customers who already have payment intent: HONORED (locked)
   - Customers who try to create payment intent: REJECTED (active = false)
   - Customers who apply code after deactivation: REJECTED

5. Admin sees:
   "Code FLASH50 deactivated
    12 customers currently have this code in checkout.
    They will still receive the discount if they complete payment."
```

**Sub-variant 6C: Admin modifies discount percentage (dangerous)**

```
Scenario:
  Code "SAVE20" has discount_percent = 20
  Admin realizes typo, meant 10%
  Changes to 10%

Impact:
  Customers who applied code at 20%:
    - Application showed 20% discount
    - Payment intent (if created before change) has 20% locked
    - Payment intent (if created after change) will recalculate at 10%

Customer experience:
  If payment intent already created: Gets 20% (locked)
  If payment intent not yet created: Gets 10% (might be confused)

Mitigation:
  Admin warning before change:
    "⚠️ Warning: 5 customers currently have this code in checkout.
     Changing the discount will affect customers who haven't completed payment yet.

     [Change Anyway] [Cancel]"

  Audit log includes before/after values
  Dashboard shows "Modified during active checkouts"
```

---

## Variant 7: Refund & Usage Reconciliation (Post-Order Scenario)

**Trigger:** Order with discount code is refunded

**Flow:**

```
1. Order #1234 placed with "LAUNCH10"
   - Subtotal: $50.00
   - Discount: -$5.00
   - Total paid: $45.00
   - promo_code_usage record created

2. Customer requests refund (3 days later)
   Admin processes full refund via Stripe

3. Question: Should used_count decrement?

Decision: NO - Usage count NOT decremented on refund

Rationale:
  - Prevents fraud: Use code, refund, use code again
  - Simplifies accounting (usage = attempts, not successful orders)
  - one_time_per_customer still enforced (usage record exists)
  - Admin can manually adjust if legitimate case

What happens on refund:

  FUNCTION processRefund(order_id, admin_user_id, reason):
    BEGIN transaction

      READ order
      refund = stripe.refunds.create({ payment_intent: order.stripe_payment_intent_id })

      UPDATE order:
        status = "refunded"
        refunded_at = now
        refunded_by = admin_user_id
        refund_reason = reason

      // promo_code_usage record KEPT (audit trail)
      // used_count on promo_codes NOT decremented

      CREATE audit_log:
        action: "order_refunded"
        order_id: order_id
        promo_code: order.promo_code
        discount_amount: order.discount_amount
        refund_amount: order.total
        reason: reason

    COMMIT transaction

4. Customer tries to use "LAUNCH10" again:
   → Validation fails: "Code already used"

5. If legitimate re-use needed (edge case):
   Admin manually deletes usage record
   → DELETE /admin/api/promo-code-usage/{usage_id}
   Customer can now use code again
```

---

## Timeout Handling (Complete Specification)

### Timeout 1: Code Application Validation

**Timeout:** 5 seconds (read-only query)

```
Frontend: POST /api/apply-promo-code (timeout: 5s)

Backend:
  Firestore read: 20-50ms typical
  Query promo_code_usage: 20-50ms
  Total: 40-100ms typical

If timeout:
  Frontend shows: "Checking code..."
  Auto-retry (up to 2 times)
  If still failing: "Unable to validate code. Try again."

No data impact: Read-only operation
```

### Timeout 2: Payment Intent with Code

**Timeout:** 30 seconds (Stripe API + validation)

```
Frontend: POST /api/create-payment-intent (timeout: 30s)

Backend:
  Code validation: 50-100ms
  Stripe API: 200-500ms
  Total: 250-600ms typical

If timeout:
  Code validation might have passed, Stripe call uncertain
  Frontend shows: "Processing... please wait"
  Query payment intent status before retry
  If payment intent exists: Continue to checkout
  If not: Retry payment intent creation
```

### Timeout 3: Order Creation with Usage Tracking

**Timeout:** 30 seconds (transaction + usage update)

```
Webhook processing:
  Code usage update: 50-100ms
  Order creation: 100-200ms
  Total: 150-300ms typical

If timeout:
  Stripe retries webhook
  Idempotent creation prevents duplicates
  Usage increment is atomic within order transaction
```

---

## Retry Logic (Exhaustive)

### Retry Strategy 1: Code Application

```
Configuration:
  max_retries: 2
  delay: 1 second

Retry conditions:
  - 500/502/503/504 (server errors)
  - Network errors

Non-retry conditions:
  - 400 (validation failed - user error)
  - 404 (code not found)
```

### Retry Strategy 2: Usage Increment Race

```
Scenario:
  Two webhooks for same order arrive simultaneously

Protection:
  Order creation is idempotent (checks existing order first)
  Usage increment inside order transaction
  Second webhook finds order exists, returns 200 (no duplicate usage)
```

---

## Error Scenarios (Exhaustive List)

### Category 1: Code Validation Errors

**E1.1: Code not found**
```
Trigger: Typo or fake code
Response: 400 "Invalid promo code"
Customer action: Re-enter correct code
Frontend: Shake animation + red border
```

**E1.2: Code inactive**
```
Trigger: Admin deactivated code
Response: 400 "This promotion has ended"
Customer action: Remove code, try different one
```

**E1.3: Code expired**
```
Trigger: Past expiration date
Response: 400 "Code expired on [date]"
Customer action: Remove code
Edge case: Grace period might still allow (see Variant 2)
```

**E1.4: Code exhausted (max redemptions)**
```
Trigger: used_count >= max_redemptions
Response: 400 "Code fully redeemed"
Customer action: Try different code
Race condition: Might still be honored at order creation (Variant 3)
```

**E1.5: Minimum order not met**
```
Trigger: cart_total < min_order_value
Response: 400 {
  "error": "minimum_not_met",
  "min_order_value": 5000,
  "cart_total": 3500,
  "difference": 1500
}
Customer action: Add $15 more or remove code
Frontend: "Add $15.00 more to use this code"
```

**E1.6: Code already used by customer**
```
Trigger: one_time_per_customer AND usage exists
Response: 400 "You've already used this code"
Customer action: Try different code
Frontend: Shows when/where previously used
```

**E1.7: Multiple codes attempted**
```
Trigger: Customer tries to apply second code
Response: 400 "Only one code per order"
Customer action: Remove current code first
Frontend: "Remove CURRENT_CODE to apply different code"
```

---

### Category 2: Cart State Errors

**E2.1: Cart empty**
```
Trigger: No items in cart when applying code
Response: 400 "Add items to cart first"
Customer action: Add items
```

**E2.2: Cart total changed after validation**
```
Trigger: Price change or item removal between validation and payment
Detection: Payment intent validation re-checks minimum
Response: 400 "Cart total changed, code no longer valid"
Customer action: Re-apply code or adjust cart
```

**E2.3: Product removed made cart invalid**
```
Trigger: Removed item drops below minimum
Frontend: Warning before checkout
Backend: Validates at payment intent creation
```

---

### Category 3: Timing Errors

**E3.1: Code expires during checkout**
```
[Covered in Variant 2 - Grace Period]
```

**E3.2: Code deactivated during checkout**
```
Trigger: Admin deactivates while customer checking out
Detection: Payment intent creation fails (active = false)
Response: 400 "Promotion ended"
Locked codes: If payment intent already created, HONORED
```

**E3.3: Discount percentage changed during checkout**
```
Trigger: Admin modifies discount_percent
Effect: New payment intents use new percentage
Locked: Existing payment intents use old percentage
Monitoring: Flag variance between application and order
```

---

### Category 4: Admin Errors

**E4.1: Duplicate code creation**
```
Trigger: Admin creates code that already exists
Response: 400 "Code already exists"
Prevention: Unique constraint + form validation
```

**E4.2: Invalid discount percentage**
```
Trigger: Admin enters 0%, 101%, or negative
Response: 400 "Discount must be 1-100%"
Prevention: Frontend input validation
```

**E4.3: Expiration in past**
```
Trigger: Admin sets expiration to past date
Response: 400 "Expiration must be in future"
Prevention: Date picker minimum = tomorrow
```

**E4.4: Delete code with active usage**
```
Trigger: Admin tries to hard-delete used code
Response: 400 "Cannot delete code with usage history"
Alternative: Deactivate instead (preserves audit trail)
```

---

### Category 5: Fraud & Abuse Errors

**E5.1: Rapid code application (bot)**
```
Trigger: > 10 code applications per minute from IP
Detection: Rate limiting middleware
Response: 429 "Too many requests, please wait"
Logging: Flag IP for review
```

**E5.2: Multiple accounts, same code**
```
Trigger: Same IP/device uses code on multiple accounts
Detection: Post-hoc analysis (not real-time for MVP)
Response: None (allowed per account)
Monitoring: Alert if > 5 accounts from same IP
```

**E5.3: Code sharing (leaked public)**
```
Trigger: Code goes viral, rapid redemptions
Detection: Redemption spike alert
Response: Admin can deactivate code
Monitoring: Track redemptions/hour per code
```

---

## Fraud Prevention (Complete Specification)

### Detection Mechanisms

**1. Velocity Monitoring**
```
Metrics tracked:
  - Redemptions per hour per code
  - Redemptions per IP per hour
  - Failed validations per IP
  - Account creation rate (for multi-account fraud)

Alerts:
  - > 50 redemptions/hour on single code: WARNING
  - > 100 redemptions/hour: CRITICAL (possible leak)
  - > 10 failed validations from single IP: REVIEW
  - > 5 new accounts from single IP using same code: REVIEW
```

**2. Pattern Detection**
```
Suspicious patterns:
  - Same shipping address, different accounts
  - Same payment method, different accounts
  - Rapid account creation + code usage
  - Consistent over-redemption attempts

Actions:
  - Flag for manual review
  - Temporary code pause (admin notification)
  - Account suspension (repeat offenders)
```

**3. Code Strength Requirements**
```
Minimum code length: 6 characters
Format: Alphanumeric only (uppercase)
Avoid: Sequential codes (SAVE01, SAVE02, SAVE03)
Recommendation: Random or themed codes

Examples:
  Good: HONEYBEE25, SUMMER2026, WELCOME15
  Bad: CODE1, CODE2, AAA, 123
```

---

### Prevention Mechanisms

**1. Rate Limiting**
```
Endpoint: POST /api/apply-promo-code
Limits:
  - 5 requests per minute per customer
  - 20 requests per minute per IP
  - 100 requests per minute global per code

Response on limit: 429 "Too many requests"
```

**2. One-Time-Per-Customer Default**
```
Default behavior: one_time_per_customer = true
Admin can override for special campaigns
Tracked via promo_code_usage collection
```

**3. Max Redemptions with Buffer**
```
Best practice: Set max_redemptions = target + 5%
Accounts for race conditions
Over-redemption alert fires at target + 10%
```

---

## Analytics & Reporting (Complete Specification)

### Real-Time Metrics

**1. Code Performance Dashboard**
```
Per-code metrics:
  - Total redemptions (used_count)
  - Redemption rate (used / max * 100)
  - Revenue with code (sum of discounted orders)
  - Discount given (sum of discount_amount)
  - Average order value with code
  - Conversion rate (code applied → order completed)

Time-series:
  - Redemptions per hour/day
  - Peak usage times
  - Geographic distribution
```

**2. Campaign Analytics**
```
Aggregate metrics:
  - Total codes active
  - Total discounts given (this month)
  - Most popular codes
  - Codes expiring soon (< 7 days)
  - Codes near exhaustion (> 90% used)
```

### Reporting Queries

**1. Code Usage Report**
```
Query: /admin/api/reports/promo-code-usage
Parameters:
  - code: specific code or "all"
  - date_range: start/end dates
  - group_by: day, week, month

Output:
  {
    "code": "LAUNCH10",
    "period": "2026-01",
    "redemptions": 85,
    "total_discount": 42500,  // $425.00
    "avg_order_value": 5000,   // $50.00
    "orders": [...]
  }
```

**2. Customer Discount History**
```
Query: /admin/api/customers/{id}/discounts
Output:
  {
    "customer_id": "cust_123",
    "codes_used": [
      { "code": "WELCOME20", "used_at": "2026-01-10", "discount": 1000 },
      { "code": "LAUNCH10", "used_at": "2026-01-24", "discount": 500 }
    ],
    "total_discounts": 1500
  }
```

**3. Fraud Detection Report**
```
Query: /admin/api/reports/promo-code-fraud
Output:
  {
    "over_redeemed_codes": [...],
    "suspicious_ips": [...],
    "multi_account_patterns": [...],
    "recommendations": [...]
  }
```

---

## Performance Characteristics

### Latency Budget (Per Operation)

**Code Application:**
- Target: P50 < 30ms, P95 < 100ms, P99 < 200ms
- Components:
  - Code lookup: 15-30ms
  - Usage check: 15-30ms
  - Calculation: 1-5ms
- Total: 31-65ms typical

**Payment Intent with Code:**
- Target: P50 < 400ms, P95 < 700ms, P99 < 1000ms
- Components:
  - Code re-validation: 30-60ms
  - Stripe API: 200-400ms
  - Metadata storage: 20-50ms
- Total: 250-510ms typical

**Usage Increment (Order Creation):**
- Target: P50 < 100ms, P95 < 200ms, P99 < 300ms
- Components:
  - Read promo_code: 20-40ms
  - Update used_count: 20-40ms
  - Create usage record: 20-40ms
- Total: 60-120ms typical

---

### Throughput Estimates

**Concurrent Code Applications:**
- Expected: < 50/minute (normal)
- Peak: < 200/minute (flash sale)
- Capacity: > 1000/minute (Firestore can handle)

**Code Redemptions/Day:**
- Expected: 20-50 (year 1)
- Peak: 100-200 (campaign launch)
- Capacity: Unlimited (no bottleneck)

---

## Security Considerations

### Attack Vector 1: Code Enumeration

**Attack:** Brute-force guess valid codes
**Detection:** Failed validation rate per IP
**Mitigation:**
  - Rate limiting (5/min per IP)
  - CAPTCHA after 3 failures
  - Generic error messages (don't reveal existence)

### Attack Vector 2: Code Sharing

**Attack:** Publicly share limited-use codes
**Detection:** Redemption velocity spike
**Mitigation:**
  - Alert on > 50 redemptions/hour
  - Admin can pause/deactivate
  - one_time_per_customer limits impact

### Attack Vector 3: Multi-Account Abuse

**Attack:** Create multiple accounts to reuse codes
**Detection:** Same IP/device patterns
**Mitigation:**
  - Post-hoc analysis and account review
  - Shipping address matching
  - Future: Device fingerprinting

---

## Monitoring & Observability

### Critical Metrics

**1. Code Redemption Health**
```
- validation_success_rate (target: > 95%)
- redemption_conversion_rate (applied → order)
- over_redemption_count (target: < 3 per code)
- grace_period_usage_rate (target: < 10%)

Alerts:
  - Validation success < 80%: WARNING
  - Over-redemption > 10: CRITICAL
  - Grace period > 20%: Review expiration UX
```

**2. Performance Metrics**
```
- code_validation_latency_ms (P50, P95, P99)
- usage_increment_latency_ms (P50, P95, P99)

Alerts:
  - P95 > 200ms: WARNING
  - P95 > 500ms: CRITICAL
```

**3. Fraud Indicators**
```
- failed_validations_per_ip
- redemptions_per_ip_per_hour
- multi_account_same_code

Alerts:
  - > 20 failures from single IP: REVIEW
  - > 10 redemptions from single IP: REVIEW
```

---

### Logging Strategy

**INFO level:**
```
- Code applied (code, customer, discount)
- Code redeemed (code, order_id, discount)
- Code created (code, admin)
- Code deactivated (code, admin, reason)
```

**WARN level:**
```
- Grace period redemption (code, minutes_past_expiration)
- Code nearing exhaustion (code, used/max)
- Discount changed during checkout (code, before/after)
```

**ERROR level:**
```
- Over-redemption (code, used_count, max_redemptions)
- Validation failure spike (code, failure_rate)
```

**CRITICAL level:**
```
- Suspected fraud pattern (code, indicators)
- Mass over-redemption (code, > 10 over)
```

---

## Testing Strategy

### Unit Tests (Per Function)

**validatePromoCode():**
```
- Valid code, all checks pass
- Code not found (404)
- Code inactive
- Code expired (no grace)
- Code expired (within grace)
- Code expired (beyond grace)
- Below minimum order
- Max redemptions reached
- Already used by customer
- Multiple codes blocked

Total: 10 test cases
```

**createPromoCode():**
```
- Valid creation
- Duplicate code (blocked)
- Invalid discount (0%, 101%)
- Expiration in past (blocked)
- Missing required fields

Total: 5 test cases
```

**incrementCodeUsage():**
```
- Happy path increment
- Over-redemption (still increments)
- Concurrent increment (race safety)
- Usage record creation

Total: 4 test cases
```

**Total unit tests: 19 test cases**

---

### Integration Tests (End-to-End)

**Test 1: Complete code lifecycle**
```
1. Admin creates code "TEST10"
2. Customer applies code → validates
3. Customer creates payment intent → discount locked
4. Customer completes payment
5. Order created with discount
6. Verify used_count = 1
7. Verify usage record exists
```

**Test 2: Grace period redemption**
```
1. Create code expiring in 1 minute
2. Customer applies code (0:30 before expiration)
3. Wait until code expires
4. Customer creates payment intent (2 min after expiration)
5. Verify discount honored (within 5-min grace)
6. Verify "within_grace" logged
```

**Test 3: Max redemptions race**
```
1. Create code with max_redemptions = 1
2. Two customers apply code simultaneously
3. Both create payment intents (before either completes)
4. Both complete payment
5. Verify both orders created with discount
6. Verify used_count = 2 (over-redemption)
7. Verify warning logged
```

**Test 4: One-time-per-customer enforcement**
```
1. Customer uses code on Order #1
2. Customer tries to use same code on Order #2
3. Verify validation fails
4. Verify error message shows previous usage
```

**Test 5: Admin deactivation mid-checkout**
```
1. Customer applies code
2. Admin deactivates code
3. Customer tries to create payment intent
4. Verify 400 "Promotion ended"
```

**Test 6: Cart change below minimum**
```
1. Customer applies code (cart meets minimum)
2. Customer removes item (cart below minimum)
3. Customer tries to create payment intent
4. Verify 400 "Cart below minimum"
```

**Total integration tests: 6 scenarios**

---

### Load Tests (Performance Validation)

**Scenario 1: Normal campaign**
```
- 100 code applications over 10 minutes
- 60 payment intents created
- 50 orders completed
- Measure: P95 latency, error rate

Success: P95 < 100ms validation, < 1% errors
```

**Scenario 2: Flash sale (high concurrency)**
```
- 500 code applications in 1 minute
- Single popular code
- 200 concurrent payment intents
- Measure: Race handling, over-redemption count

Success: All orders honored, over-redemption < 5%
```

---

## Dependencies

**External Services:**
- Firestore (code storage, usage tracking)
- Stripe (payment intent metadata)

**Internal Services:**
- Auth service (customer identification)
- Order service (discount application)

**Libraries:**
- Firestore SDK (v9.x)
- Stripe SDK (v10.x)

---

## Configuration

**Environment Variables:**
```
PROMO_CODE_GRACE_PERIOD_MINUTES=5
PROMO_CODE_MAX_DISCOUNT_PERCENT=50
PROMO_CODE_RATE_LIMIT_PER_MINUTE=5
PROMO_CODE_RATE_LIMIT_PER_IP=20
PROMO_CODE_MIN_LENGTH=6
OVER_REDEMPTION_ALERT_THRESHOLD=10
```

---

## Success Criteria (Quantified)

**Reliability:**
- 99.9% of valid codes work on first try
- Zero incorrect discount amounts charged
- < 5% over-redemption per code

**Performance:**
- P95 code validation < 100ms
- P95 payment intent with code < 700ms

**Customer Experience:**
- Clear error messages for all validation failures
- Grace period prevents 90% of "expired during checkout" frustrations
- Discount shown = discount charged (always)

**Business:**
- Support tickets for code issues: < 1 per 100 redemptions
- Fraud loss: < 2% of total discounts given
- Campaign effectiveness measurable (analytics)

**Operations:**
- Admin can create/manage codes without engineering
- Deactivation takes effect immediately for new checkouts
- Audit trail for all code changes

---

## Open Questions Resolved

All 7 L1 questions answered:

**Q1: What if customer applies code, then removes items below minimum?**
✅ Frontend warns, backend rejects at payment intent creation

**Q2: What if code reaches max redemptions during checkout?**
✅ Accept over-redemption, customer already paid (Variant 3)

**Q3: Can customer use multiple codes?**
✅ No, enforced at application time (single code per order)

**Q4: What if admin changes code while customer using it?**
✅ Locked at payment intent, changes affect new checkouts only (Variant 6C)

**Q5: How to prevent duplicate codes?**
✅ Unique constraint + validation at creation

**Q6: What if code used for refunded order?**
✅ Usage NOT decremented, prevents fraud (Variant 7)

**Q7: Can expired codes be reactivated?**
✅ Yes, admin can update expires_at to future date

---

**Last Updated:** 2026-01-24
**Stage:** L3
**Status:** ✅ Complete - Exhaustive scenario coverage achieved
**Confidence Level:** 95%+
