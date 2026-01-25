# L3: Checkout Flow - Exhaustive Design

**Component:** Customer Checkout & Payment Processing (Critical Revenue Path)
**Stage:** L3 (Refine L3 - Exhaustive Coverage)
**Date:** 2026-01-24

---

## L3 Pass: Exhaustive Coverage (Stage 6: Refine L3)

### Complete Flow Variants

All possible checkout paths documented with precise handling.

---

## Variant 1: Happy Path (Expected 85% of Checkouts)

**Preconditions:**
- Customer has valid session
- Cart contains 1-50 items (enforced limit)
- All products active and in stock
- No existing reservation for customer

**Flow:**

```
1. Customer clicks "Checkout" button
   → Frontend: POST /api/reserve-inventory

2. Backend reserves inventory (Firestore transaction):
   Duration: 50-150ms (P50-P95)

   FOR EACH item in cart:
     BEGIN transaction
       READ product (get quantity, reserved_quantity)
       VALIDATE available >= item.quantity
       CREATE reservation document
       UPDATE product.reserved_quantity += item.quantity
     COMMIT transaction

   Response: 200 OK
   {
     "reservation_id": "res_abc123",
     "expires_at": "2026-01-24T15:15:00Z",
     "items": [...]
   }

3. Customer sees checkout page (reservation countdown timer starts)
   Frontend polls /api/reservation-status every 30 seconds

4. Customer enters shipping address (1-3 minutes typical)
   No backend calls during this step

5. Customer clicks "Continue to Payment"
   → Frontend: POST /api/create-payment-intent

6. Backend creates Stripe PaymentIntent (200-500ms):

   Validate reservation still active:
     READ reservation
     IF expires_at < now:
       RETURN 400 "Reservation expired"

   Calculate total with discount (if code applied):
     IF promo_code:
       VALIDATE code (with 5-min grace period)
       discount_amount = total * (discount_percent / 100)
     total_amount = cart_total - discount_amount

   CREATE Stripe PaymentIntent:
     amount = total_amount (in cents)
     currency = "usd"
     metadata:
       reservation_id: "res_abc123"
       customer_id: "cust_xyz789"
       promo_code: "SAVE10" (if applied)
       discount_locked: true
       items_json: JSON.stringify(items)

   Response: 200 OK
   {
     "client_secret": "pi_xyz_secret_abc",
     "amount": 4500
   }

7. Customer redirected to Stripe checkout (embedded or redirect)
   Stripe handles card entry, 3D Secure, payment authorization
   Duration: 30 seconds - 5 minutes (customer-dependent)

8. Customer completes payment successfully
   → Stripe charges card
   → Stripe sends payment_intent.succeeded webhook

9. Backend receives webhook (primary path):
   Duration: 100-500ms from payment to webhook received

   POST /webhooks/stripe
   Headers:
     stripe-signature: [webhook signature]

   Backend handles webhook:
     1. Verify signature (security):
        stripe.webhooks.constructEvent(body, signature, secret)
        IF invalid: RETURN 400 "Invalid signature"

     2. Extract payment_intent_id

     3. Check order existence (idempotency):
        QUERY orders WHERE stripe_payment_intent_id = payment_intent_id
        IF found: RETURN 200 "Order already created"

     4. Create order (Firestore transaction):
        BEGIN transaction
          CREATE order document:
            order_id: auto-generated
            stripe_payment_intent_id: payment_intent_id
            customer_id: from metadata
            items: from metadata
            total: from payment_intent.amount
            promo_code: from metadata (if any)
            status: "confirmed"
            created_at: now
            created_by: "webhook"

          FOR EACH item in items:
            UPDATE product.quantity -= item.quantity
            UPDATE product.reserved_quantity -= item.quantity

          DELETE reservation document
        COMMIT transaction

     5. Send confirmation email (async, non-blocking):
        queue_email_job({
          to: customer.email,
          template: "order_confirmation",
          order_id: order.id
        })

     6. RETURN 200 OK to Stripe

10. Frontend calls /api/confirm-order (fallback path):
    Duration: 1-3 seconds after payment complete

    POST /api/confirm-order
    Body: { payment_intent_id: "pi_xyz" }

    Backend handles confirmation:
      1. Verify customer session
      2. Query Stripe: GET /v1/payment_intents/{id}
      3. IF status != "succeeded": RETURN 400 "Payment incomplete"
      4. Check order existence (idempotency):
         QUERY orders WHERE stripe_payment_intent_id = payment_intent_id
         IF found: RETURN 200 { order } (webhook already created)
      5. Create order (same transaction as webhook)
      6. RETURN 200 { order }

11. Customer sees order confirmation page
    Shows: Order number, items, total, shipping address, email confirmation

Total duration: 2-8 minutes (customer-dependent)
Backend processing: < 2 seconds total
```

**Success criteria:**
- Reservation created < 200ms
- Payment intent created < 500ms
- Order created within 5 seconds of payment
- Customer sees confirmation < 10 seconds of payment

---

## Variant 2: Reservation Expires During Checkout (2-5% of Checkouts)

**Trigger:** Customer takes > 15 minutes from add-to-cart to payment

**Flow:**

```
1-4. [Same as happy path - reservation created, checkout page shown]

5. Customer delays (checking phone, answering door, etc.)
   15 minutes pass

6. Background cleanup job runs (every 5 minutes):
   QUERY reservations WHERE expires_at < now AND status = "active"
   FINDS customer's reservation

   releaseReservation(reservation_id):
     BEGIN transaction
       READ reservation
       IF status != "active": ROLLBACK (already released)
       UPDATE reservation.status = "expired"
       UPDATE product.reserved_quantity -= reservation.quantity
     COMMIT

   Reservation released, inventory returned to pool

7. Customer clicks "Continue to Payment"
   → Frontend: POST /api/create-payment-intent

8. Backend validates reservation:
   READ reservation
   IF status == "expired" OR expires_at < now:
     RETURN 400 {
       "error": "reservation_expired",
       "message": "Your cart reservation expired. Please return to cart.",
       "cart_url": "/cart"
     }

9. Frontend receives error:
   Shows modal:
     "Your cart reservation expired

      Products may have sold out. Please review your cart.

      [Return to Cart]"

   Redirects to /cart

10. Customer sees cart (items still present in session):
    Frontend attempts to re-reserve:
      POST /api/reserve-inventory

    Possible outcomes:
      A) Inventory still available → Reservation succeeds, continue checkout
      B) Inventory insufficient → Error shown, customer reduces quantity
      C) Product deleted → Item removed from cart, customer notified
```

**Customer experience:**
- Clear error message (expired reservation)
- Actionable next step (return to cart)
- Automatic re-reservation attempt
- Graceful handling (no data loss)

**Monitoring:**
- Track reservation expiration rate (target < 5%)
- Alert if > 10% (indicates 15-min TTL too short)

---

## Variant 3: Inventory Insufficient at Reservation (1-3% of Checkouts)

**Trigger:** Another customer purchases last units between add-to-cart and checkout

**Flow:**

```
1. Customer clicks "Checkout"
   → POST /api/reserve-inventory

2. Backend attempts reservation:
   BEGIN transaction
     READ product (Wildflower Honey: quantity=10, reserved=8, available=2)
     Customer wants 3 units
     VALIDATE 2 >= 3 → FAIL
   ROLLBACK

   RETURN 400 {
     "error": "insufficient_inventory",
     "message": "Only 2 units of Wildflower Honey 12oz available",
     "product_id": "prod_123",
     "requested": 3,
     "available": 2
   }

3. Frontend receives error:
   Shows modal:
     "Not enough inventory

      Only 2 units of Wildflower Honey 12oz available.
      You requested 3 units.

      [Update Cart to 2] [Remove Item] [Cancel]"

4. Customer chooses action:
   A) Update Cart to 2:
      Frontend updates quantity
      Retries POST /api/reserve-inventory
      → Success, proceeds to checkout

   B) Remove Item:
      Frontend removes item from cart
      Retries with remaining items
      → Success, proceeds to checkout

   C) Cancel:
      Returns to cart page
      Customer manually adjusts
```

**Edge case: Multiple items insufficient**

```
Cart:
  - Wildflower Honey: want 5, available 2
  - Comb Honey: want 3, available 1

Backend returns:
  400 {
    "error": "insufficient_inventory_multiple",
    "message": "Multiple items have insufficient inventory",
    "items": [
      { "product": "Wildflower Honey", "requested": 5, "available": 2 },
      { "product": "Comb Honey", "requested": 3, "available": 1 }
    ]
  }

Frontend shows all issues:
  "Not enough inventory for 2 items:

   - Wildflower Honey: Want 5, only 2 available
   - Comb Honey: Want 3, only 1 available

   [Adjust All] [Review Cart]"
```

---

## Variant 4: Promo Code Expires During Checkout (1-2% with Code)

**Trigger:** Code expires between application and payment intent creation

**Flow:**

```
1. Customer applies code "WEEKEND20" at 11:58 PM (expires midnight)
   → POST /api/apply-promo-code

   Backend validates:
     expires_at = 2026-01-26 00:00:00
     now = 2026-01-25 23:58:00
     expires_at > now ✓

   RETURN 200 {
     "valid": true,
     "discount_percent": 20,
     "warning": "Code expires in 2 minutes"
   }

2. Frontend shows warning:
   "⚠️ Code expires in 2 minutes. Complete checkout soon."
   Countdown timer starts

3. Customer proceeds, enters shipping (3 minutes)

4. Customer clicks "Continue to Payment" at 12:01 AM
   → POST /api/create-payment-intent

5. Backend validates code with grace period:
   expires_at = 2026-01-26 00:00:00
   now = 2026-01-26 00:01:00
   grace_period = 5 minutes

   IF now <= expires_at + grace_period:
     // Within grace, allow
     discount_locked = true
     Log "Grace period redemption: WEEKEND20"

   CREATE PaymentIntent with discount

6. Order created successfully
   Email mentions: "Your code expired during checkout but we honored it as a courtesy."
```

**Beyond grace period (12:06 AM):**

```
Backend validation:
  now = 2026-01-26 00:06:00
  now > expires_at + 5min (00:05:00) → FAIL

  RETURN 400 {
    "error": "promo_code_expired",
    "message": "Code WEEKEND20 expired",
    "code": "WEEKEND20",
    "expired_at": "2026-01-26T00:00:00Z"
  }

Frontend:
  Shows modal:
    "Promo code expired

     Code WEEKEND20 is no longer valid.

     [Remove Code & Continue] [Cancel]"

  If Remove Code:
    Session clears promo_code
    Retries payment intent creation (full price)
```

---

## Variant 5: Payment Succeeds, Order Creation Fails (< 0.1% - Rare but Critical)

**Trigger:** Firestore outage, network partition, backend crash during order creation

**Flow:**

```
1-7. [Same as happy path - payment completes successfully]

8. Stripe sends webhook
   → Backend receives: POST /webhooks/stripe

9. Backend attempts order creation:
   BEGIN transaction
     CREATE order document
     UPDATE products inventory
     DELETE reservation
   COMMIT → FIRESTORE TIMEOUT (30 seconds)

   Transaction fails, order NOT created

10. Backend catches error:
    Log error:
      level: "critical"
      message: "Order creation failed after successful payment"
      payment_intent_id: "pi_xyz"
      customer_email: "customer@example.com"
      amount: 4500
      stack_trace: [...]

    Send urgent alert:
      Slack: #critical-alerts
      "🚨 URGENT: Payment succeeded, order creation failed
       Payment: pi_xyz
       Customer: customer@example.com
       Amount: $45.00
       Action: Manual order creation required"

    RETURN 500 to Stripe (triggers retry)

11. Stripe retries webhook (exponential backoff):
    Retry 1: 1 minute later
    Retry 2: 5 minutes later
    Retry 3: 30 minutes later
    Retry 4: 2 hours later
    ...continues for 3 days

12. Possible resolutions:

    A) Firestore recovers, webhook retry succeeds:
       Order created automatically
       Alert auto-resolves
       Customer receives confirmation email (delayed)

    B) Webhook retries exhaust (3 days), manual intervention:
       Admin sees alert (still open)
       Admin checks Stripe dashboard:
         - Payment successful ✓
         - Customer email visible
         - Items in metadata

       Admin manually creates order:
         POST /admin/api/manual-order-creation
         Body: { payment_intent_id: "pi_xyz" }

         Backend:
           Query Stripe API (get payment details)
           Create order (same logic as webhook)
           Send confirmation email
           Log manual intervention

       Admin marks alert resolved

13. Customer experience:

    Worst case (3-day delay):
      - Customer paid, saw payment success
      - No confirmation email received
      - Customer emails support: "Where's my order?"
      - Support checks system, sees payment, creates order
      - Customer receives email: "Your order #1234 has been confirmed"
      - Apology discount offered (customer service goodwill)
```

**Prevention:**
- Firestore health monitoring (alert before failure)
- Webhook retry handles 99% of transient failures
- Manual order creation for edge cases

**Success metric:**
- < 0.1% of payments require manual intervention
- 100% of successful payments eventually create orders

---

## Variant 6: Customer Session Expires During Checkout (1-2% of Checkouts)

**Trigger:** Customer session timeout (30 minutes) while customer on checkout page

**Flow:**

```
1. Customer adds to cart, clicks "Checkout" (T+0)
   → POST /api/reserve-inventory
   Session created, expires at T+30min

2. Reservation created successfully
   Customer sees checkout page

3. Customer gets distracted, leaves tab open (browsing other sites, taking call)
   28 minutes pass

4. Session expires at T+30min (backend invalidates JWT token)
   Reservation still active (expires T+15min, already expired and cleaned up)

5. Customer returns to checkout page at T+32min
   Clicks "Continue to Payment"
   → Frontend: POST /api/create-payment-intent
     Headers: Authorization: Bearer <expired_jwt_token>

6. Backend validates session:
   jwt.verify(token, secret)
   IF token.exp < now:
     RETURN 401 {
       "error": "session_expired",
       "message": "Your session expired. Please sign in again.",
       "redirect": "/login?return_url=/checkout"
     }

7. Frontend receives 401:
   Clears local session storage
   Shows modal:
     "Your session expired

      Please sign in to continue checkout.

      [Sign In]"

   Redirects to /login with return URL

8. Customer signs in again:
   Email verification code sent
   Customer enters code
   Session recreated

9. Frontend redirects to /checkout (return URL)

10. Possible outcomes:

    A) Reservation still active (customer was quick, < 15 min total):
       Checkout page loads normally
       Customer continues to payment

    B) Reservation expired (> 15 min total):
       Backend validates reservation → expired
       RETURN 400 "Reservation expired"
       Frontend redirects to /cart
       Customer re-reserves inventory
       [Same as Variant 2]

    C) Inventory sold out (another customer bought):
       Customer re-reserves → insufficient inventory
       [Same as Variant 3]
```

**Customer experience:**

Best case (quick re-auth):
- Sign in takes 30-60 seconds
- Reservation still valid
- Continues checkout

Worst case (slow re-auth):
- Sign in takes 2-3 minutes
- Reservation expired
- Must re-reserve, inventory might be gone

**Prevention strategies:**

1. **Session extension on activity:**
   ```
   Frontend polling /api/reservation-status every 30s
   Side effect: Extends session (activity detected)
   New expiration: now + 30 min
   ```

2. **Warning before expiration:**
   ```
   When session has 5 minutes remaining:
     Show banner: "Your session expires in 5 minutes. Complete checkout soon."
   ```

3. **Preserve cart in session storage:**
   ```
   Even if session expires, cart persists in browser
   After re-auth, cart automatically restored
   Customer doesn't lose cart items
   ```

**Implementation notes:**

```
Session management:
  - JWT token exp: 30 minutes
  - Refresh token: Not used (simplicity for MVP)
  - Session extension: On any authenticated request

Frontend session monitoring:
  setInterval(() => {
    const token = getSessionToken()
    const decoded = jwt_decode(token)
    const timeRemaining = decoded.exp - (Date.now() / 1000)

    if (timeRemaining < 300) { // 5 minutes
      showSessionWarning()
    }

    if (timeRemaining < 0) {
      clearSession()
      redirectToLogin()
    }
  }, 60000) // Check every minute
```

**Edge case: Session expires during Stripe payment**

```
Timeline:
1. Customer creates payment intent (T+28min, session valid)
2. Redirected to Stripe checkout page (T+29min)
3. Customer enters card details on Stripe (T+30min)
4. Session expires (T+30min)
5. Customer completes payment on Stripe (T+32min)
6. Stripe redirects back to site (T+32min)
7. Frontend calls /api/confirm-order with expired session

Handling:
  /api/confirm-order validates session → 401
  BUT: Webhook already created order (primary path)
  Frontend retries after re-auth
  Backend returns existing order (idempotent)

Customer sees:
  "Session expired. Signing you in..."
  Auto-redirects to login
  After login, shows order confirmation
  No payment/order lost
```

**Monitoring:**
- Track session expiration rate during checkout (target < 2%)
- Alert if > 5% (indicates timeout too short)
- Track re-auth success rate (target > 90%)

---

## Timeout Handling (Complete Specification)

### Timeout 0: Frontend to Backend (Network Timeouts)

**Timeout Configuration:**

```
Frontend fetch() timeouts:
  - POST /api/reserve-inventory: 10 seconds
  - POST /api/create-payment-intent: 30 seconds
  - POST /api/confirm-order: 10 seconds
  - GET /api/reservation-status: 5 seconds (polling)

Implementation:
  const controller = new AbortController()
  const timeoutId = setTimeout(() => controller.abort(), TIMEOUT_MS)

  try {
    const response = await fetch(url, {
      signal: controller.signal,
      ...options
    })
    clearTimeout(timeoutId)
    return response
  } catch (error) {
    if (error.name === 'AbortError') {
      // Network timeout
      return handleNetworkTimeout(error)
    }
    throw error
  }
```

**Timeout behavior per endpoint:**

```
POST /api/reserve-inventory (10s timeout):
  On timeout:
    - Show error: "Connection slow. Retrying..."
    - Auto-retry (up to 3 attempts)
    - If all fail: "Unable to reserve. Check connection."

POST /api/create-payment-intent (30s timeout):
  On timeout:
    - Show error: "Payment system slow. Please wait..."
    - Manual retry button (don't auto-retry payment operations)
    - Reservation countdown still visible (customer can see time remaining)

POST /api/confirm-order (10s timeout):
  On timeout:
    - Poll order status instead:
      GET /api/orders?payment_intent_id=xyz
    - If order found: Show confirmation (webhook succeeded)
    - If not found: Show "Processing... please wait"
    - Keep polling for 60 seconds
    - If still not found: Show support contact info

GET /api/reservation-status (5s timeout):
  On timeout:
    - Silent failure (don't show error)
    - Retry next interval (30s later)
    - If 3 consecutive timeouts: Show warning banner
```

**User experience:**

Fast connection:
- Endpoints respond in < 1 second
- No timeout messages shown
- Smooth checkout experience

Slow connection (3G, congested wifi):
- Endpoints take 3-5 seconds
- No timeout, but "Loading..." shown
- Checkout completes, just slower

Very slow connection (timeout):
- Clear error messages
- Retry guidance
- Reservation countdown visible (customer knows time limit)

**Monitoring:**
- Track frontend timeout rate per endpoint
- Alert if reservation timeout > 1%
- Alert if payment intent timeout > 2%
- Dashboard shows network latency distribution

### Timeout 1: Reservation Creation

**Timeout:** 10 seconds (Firestore transaction)

```
Frontend: POST /api/reserve-inventory (timeout: 10s)

Backend:
  BEGIN transaction (Firestore timeout: 10s)
    ...reservation logic...
  COMMIT

If timeout:
  Firestore rolls back transaction automatically
  Backend catches timeout error:
    RETURN 504 {
      "error": "reservation_timeout",
      "message": "Reservation request timed out. Please try again.",
      "retryable": true
    }

Frontend:
  Shows error:
    "Checkout is taking longer than usual

     [Try Again] [Cancel]"

  If Try Again:
    Retries POST /api/reserve-inventory (up to 3 attempts)
```

**Monitoring:**
- Track reservation timeout rate (target < 0.1%)
- Alert if > 1% (Firestore performance issue)

---

### Timeout 2: Payment Intent Creation

**Timeout:** 30 seconds (Stripe API call)

```
Frontend: POST /api/create-payment-intent (timeout: 30s)

Backend:
  Stripe API call (timeout: 30s):
    stripe.paymentIntents.create({...})

If timeout:
  Backend catches timeout:
    Log warning: "Stripe API timeout"
    RETURN 504 {
      "error": "payment_intent_timeout",
      "message": "Payment system is slow. Please wait and try again.",
      "retryable": true
    }

Frontend:
  Shows error with retry:
    "Payment system is experiencing delays

     Your reservation is still active (12:30 remaining).

     [Try Again] [Cancel]"

  Auto-retry after 5 seconds (with user confirmation)
```

**Monitoring:**
- Track Stripe API latency (P50, P95, P99)
- Alert if P95 > 5 seconds (Stripe degradation)

---

### Timeout 3: Webhook Processing

**Timeout:** 30 seconds (order creation transaction)

```
Stripe webhook delivery (Stripe timeout: 30s)

Backend: POST /webhooks/stripe
  Order creation transaction (timeout: 30s)

If timeout:
  Transaction rolls back
  Backend returns 500 to Stripe
  Stripe retries webhook (automatic)

No customer-facing impact:
  - Customer doesn't know webhook timed out
  - Webhook retry succeeds (most likely)
  - Order created on retry
```

---

## Retry Logic (Exhaustive)

### Retry Strategy 1: Frontend to Backend (Transient Failures)

```
Retryable errors:
  - 500 Internal Server Error
  - 502 Bad Gateway
  - 503 Service Unavailable
  - 504 Gateway Timeout
  - Network errors (fetch failed)

Non-retryable errors:
  - 400 Bad Request (client error, won't fix on retry)
  - 401 Unauthorized (session issue)
  - 403 Forbidden (permission issue)
  - 404 Not Found (endpoint doesn't exist)

Retry configuration:
  max_retries: 3
  backoff: exponential (1s, 2s, 4s)
  jitter: ±20% (prevent thundering herd)

Example (reservation creation):
  Attempt 1: POST /api/reserve-inventory
    → 500 error
  Wait 1 second

  Attempt 2: POST /api/reserve-inventory
    → 500 error
  Wait 2 seconds

  Attempt 3: POST /api/reserve-inventory
    → 200 success ✓

If all retries fail:
  Show error: "Service unavailable. Please try again later."
  Customer can manually retry
```

---

### Retry Strategy 2: Backend to Stripe (Payment Intent Creation)

```
Stripe SDK has built-in retry:
  max_network_retries: 2
  backoff: exponential

Backend wraps with additional retry:
  try {
    paymentIntent = await stripe.paymentIntents.create({...})
  } catch (error) {
    if (error.type === "StripeConnectionError") {
      // Network issue, retry
      sleep(1000)
      paymentIntent = await stripe.paymentIntents.create({...})
    } else {
      throw error // API error, don't retry
    }
  }
```

---

### Retry Strategy 3: Stripe to Backend (Webhook Delivery)

```
Stripe webhook retry (built-in):
  Retry schedule:
    1 minute
    5 minutes
    30 minutes
    2 hours
    6 hours
    12 hours
    24 hours
    ... continues for 3 days

  Retry stops when:
    - Backend returns 200 (success)
    - 3 days elapsed (give up)

Backend idempotency ensures:
  - Multiple deliveries safe (query before create)
  - Same webhook delivered 10 times → 1 order created
```

---

## Error Scenarios (Exhaustive List)

### Category 1: Customer Input Errors

**E1.1: Invalid shipping address**
```
Trigger: Customer enters fake address
Detection: Address validation API (optional for MVP)
Response: 400 "Invalid shipping address"
Customer action: Correct address
```

**E1.2: Invalid promo code**
```
Trigger: Customer types "SAVE10" (doesn't exist)
Detection: Code lookup fails
Response: 400 "Invalid promo code"
Customer action: Remove code or enter correct code
```

**E1.3: Cart below promo code minimum**
```
Trigger: Code requires $50, cart is $40
Detection: Validation at payment intent creation
Response: 400 "Cart total below minimum $50"
Customer action: Add more items or remove code
```

---

### Category 2: Inventory Errors

**E2.1: Insufficient inventory**
[Covered in Variant 3]

**E2.2: Product deleted during checkout**
```
Trigger: Admin deletes product while customer checking out
Detection: Product lookup fails or active = false
Response: 400 "Product no longer available"
Customer action: Remove item from cart
```

**E2.3: Reservation conflict (race condition)**
```
Trigger: Two customers reserve last unit simultaneously
Detection: Firestore transaction conflict
Response: One succeeds, one gets 400 "Insufficient inventory"
Customer action: Adjust quantity or try different product
```

---

### Category 3: Payment Errors

**E3.1: Payment declined**
```
Trigger: Stripe declines card (insufficient funds, fraud, etc.)
Detection: Stripe returns error to customer
Response: Stripe shows decline reason
Customer action: Use different payment method
Note: Backend never sees this (Stripe handles)
```

**E3.2: Payment timeout**
[Covered in Timeout Handling]

**E3.3: 3D Secure failure**
```
Trigger: Customer fails 3D Secure authentication
Detection: Stripe returns authentication_failed
Response: Stripe shows auth failure message
Customer action: Contact bank or use different card
Note: Backend never sees this (Stripe handles)
```

---

### Category 4: System Errors

**E4.1: Firestore outage**
[Covered in Variant 5]

**E4.2: Stripe outage**
```
Trigger: Stripe API down (rare, < 99.99% uptime)
Detection: All Stripe API calls fail
Response: Show maintenance page
Customer action: Wait and retry
Mitigation: Status page link, email when resolved
```

**E4.3: Backend service crash**
```
Trigger: Cloud Run instance crashes
Detection: Load balancer routes to healthy instance
Response: Request retried automatically
Customer action: None (transparent retry)
Monitoring: Track crash rate, alert if > 1/hour
```

**E4.4: Webhook signature verification failure (Security Critical)**
```
Trigger: Attacker sends fake webhook to create fraudulent orders
Detection: Webhook signature verification fails
Flow:
  POST /webhooks/stripe
  Headers:
    stripe-signature: [invalid or missing signature]

  Backend:
    try {
      event = stripe.webhooks.constructEvent(
        requestBody,
        signature,
        webhookSecret
      )
    } catch (error) {
      // Signature verification failed
      Log critical security event:
        level: "critical"
        event: "webhook_signature_verification_failed"
        ip_address: request.ip
        signature: signature (for forensics)
        body_preview: first 100 chars of body

      Alert security team:
        "🚨 SECURITY: Invalid webhook signature detected
         IP: {ip_address}
         Time: {timestamp}
         Possible attack attempt"

      RETURN 400 "Invalid signature" (don't return 200, don't process)
    }

Response: 400 Bad Request
Customer impact: None (attacker request rejected)
Attacker impact: Attack blocked, logged, alerted

Monitoring:
  - Track signature verification failures
  - Alert on ANY occurrence (should be zero in normal operation)
  - Rate limit webhook endpoint by IP (10 requests/minute)
  - Automatic IP blocking after 3 failed signatures (24-hour block)

Prevention:
  - Webhook secret stored in environment variable (never in code)
  - HTTPS only (prevent man-in-the-middle)
  - Webhook endpoint not publicly documented (security by obscurity as additional layer)
```

**E4.5: Order created but email confirmation failed**
```
Trigger: Mailgun API down, rate limit exceeded, or email address invalid
Detection: Email send API returns error
Flow:
  Order creation succeeds ✓
  Attempt to send confirmation email:
    try {
      await mailgun.messages.create(domain, {
        to: customer.email,
        subject: "Order Confirmation #1234",
        template: "order_confirmation",
        variables: { order }
      })
    } catch (error) {
      // Email send failed
      Log warning:
        level: "warning"
        event: "order_confirmation_email_failed"
        order_id: order.id
        customer_email: customer.email
        error: error.message

      UPDATE order:
        email_sent = false
        email_failed_at = now
        email_error = error.message

      // Don't rollback order creation (order is valid)
      // Don't alert immediately (not critical, will retry)
    }

Response: Order created successfully (200 OK)
Customer impact:
  - Payment succeeded ✓
  - Order created ✓
  - No confirmation email received ✗

Customer experience:
  - Customer sees order confirmation page (frontend shows success)
  - Customer expects email, doesn't receive it
  - Customer might email support: "Where's my confirmation?"

Mitigation:
  1. Retry mechanism (background job):
     Every 5 minutes, query orders WHERE email_sent = false
     Retry email send (up to 3 attempts over 24 hours)

  2. Admin dashboard indicator:
     "Email Failed" badge on order (admin can manually resend)

  3. Manual resend option:
     Admin clicks "Resend Confirmation Email"
     Triggers immediate email send
     Updates email_sent = true on success

  4. Fallback email provider:
     If Mailgun fails 3 times, try SendGrid (secondary provider)
     Requires: SENDGRID_API_KEY configured

  5. Customer self-service:
     Order confirmation page shows:
       "Didn't receive email? [Resend Confirmation]"
     Customer clicks, triggers email resend

Recovery:
  - 90% of failed emails succeed on first retry (transient failures)
  - 95% succeed within 3 retries
  - 99% succeed with admin manual resend
  - < 1% require customer to use alternative email

Monitoring:
  - Track email send failure rate (target < 1%)
  - Alert if > 5% (Mailgun outage or configuration issue)
  - Track retry success rate (target > 90%)
  - Dashboard shows: Orders with failed emails (count)

Admin action on failure spike:
  1. Check Mailgun status page (service outage?)
  2. Check Mailgun quota (rate limit exceeded?)
  3. Verify MAILGUN_API_KEY valid (credentials expired?)
  4. Switch to SendGrid if Mailgun down > 1 hour
  5. Batch resend failed emails once issue resolved
```

**E4.6: Customer session expired during checkout**
[Covered in Variant 6]

---

## Performance Characteristics

### Latency Budget (Per Operation)

**Reservation Creation:**
- Target: P50 < 100ms, P95 < 200ms, P99 < 500ms
- Components:
  - Firestore transaction: 50-100ms
  - Business logic: 10-20ms
  - Network overhead: 20-50ms
- Total: 80-170ms typical

**Payment Intent Creation:**
- Target: P50 < 300ms, P95 < 500ms, P99 < 1000ms
- Components:
  - Reservation validation: 20-50ms
  - Promo code validation: 30-60ms
  - Stripe API call: 200-400ms
  - Business logic: 20-50ms
- Total: 270-560ms typical

**Order Creation (Webhook):**
- Target: P50 < 500ms, P95 < 1000ms, P99 < 2000ms
- Components:
  - Firestore transaction: 100-300ms
  - Inventory updates: 50-100ms per product
  - Reservation deletion: 30-50ms
  - Email queueing: 20-50ms
- Total: 200-500ms for single item, +100ms per additional item

---

### Throughput Estimates

**Concurrent Checkouts:**
- Firestore limit: 10,000 writes/second (global)
- Transaction conflicts: < 5% at 100 concurrent checkouts
- Expected volume: < 10 concurrent checkouts (year 1)
- Headroom: 1000x capacity available

**Orders Per Hour:**
- Expected: 5-10 orders/hour (peak)
- Capacity: 500+ orders/hour (Firestore + Stripe)
- Bottleneck: None identified

---

### Scaling Limits

**Firestore Transaction Conflicts:**
- Hot product (50% of traffic): 10% conflict rate at 50 concurrent
- Mitigation: Automatic retry resolves 95%+
- Escalation: Increase inventory to reduce contention

**Stripe API Rate Limits:**
- Rate limit: 100 requests/second
- Expected usage: < 1 request/second (year 1)
- Headroom: 100x capacity

**Cloud Run Auto-scaling:**
- Min instances: 1
- Max instances: 10
- Scale trigger: 80% CPU or memory
- Cold start: < 1 second (optimized)

---

## Security Considerations

### Attack Vector 1: Inventory Locking DoS

**Attack:** Create many reservations, never pay (lock up inventory)

**Mitigation:**
- 15-minute TTL (reservations expire quickly)
- Rate limiting: 5 reservations per customer per hour
- CAPTCHA on checkout button (prevent bots)
- Monitoring: Alert if > 50 active reservations

**Detection:**
- Track reservation:order ratio (target > 60%)
- Alert if < 30% (high abandonment, possible attack)

---

### Attack Vector 2: Promo Code Farming

**Attack:** Create many accounts, use code multiple times

**Mitigation:**
- one_time_per_customer enforcement
- Email verification required
- Email normalization (Gmail+aliases blocked)
- Rate limiting: 5 code applications per IP per hour

**Detection:**
- Track code usage by IP address
- Alert if same IP uses code 10+ times
- Manual review flagged accounts

---

### Attack Vector 3: Payment Intent Replay

**Attack:** Capture payment_intent_id, attempt to create multiple orders

**Mitigation:**
- Idempotent order creation (query before create)
- stripe_payment_intent_id unique constraint
- Webhook signature verification

**Detection:**
- Track duplicate payment_intent_id attempts
- Alert on any occurrence (shouldn't happen)

---

## Monitoring & Observability

### Critical Metrics

**1. Checkout Funnel (Conversion Tracking)**
```
add_to_cart → click_checkout → reserve_success → payment_intent_created → payment_success → order_created

Metric: Conversion rate at each step
Target:
  click_checkout: 40% (40% of cart additions proceed)
  reserve_success: 95% (most reservations succeed)
  payment_intent_created: 90% (some abandon at shipping)
  payment_success: 85% (card declines, cart abandonment)
  order_created: 99.9% (payment → order should be automatic)

Alert if any step drops > 20% from baseline
```

**2. Reservation Metrics**
```
- Active reservations count (gauge)
- Reservation expiration rate (%)
- Reservation → order conversion rate (%)
- Average time to checkout (minutes)

Targets:
  - Active reservations: < 20 at any time
  - Expiration rate: < 5%
  - Conversion rate: > 60%
  - Time to checkout: < 8 minutes (median)
```

**3. Payment Metrics**
```
- Payment intent creation latency (P50, P95, P99)
- Payment success rate (%)
- Payment decline rate (%)
- Webhook processing time (P50, P95, P99)

Targets:
  - Creation latency P95: < 500ms
  - Success rate: > 80%
  - Decline rate: < 15%
  - Webhook processing P95: < 1000ms
```

**4. Error Metrics**
```
- Insufficient inventory errors (count/hour)
- Reservation timeout errors (count/hour)
- Payment timeout errors (count/hour)
- Order creation failures (count/hour)

Alerts:
  - Insufficient inventory > 10/hour (demand spike)
  - Reservation timeout > 5/hour (Firestore slow)
  - Payment timeout > 5/hour (Stripe slow)
  - Order creation failure > 1/hour (CRITICAL)
```

---

### Logging Strategy

**INFO level:**
- Reservation created (reservation_id, customer_id, items)
- Payment intent created (payment_intent_id, amount, promo_code)
- Order created (order_id, payment_intent_id, total)

**WARN level:**
- Reservation expired (reservation_id, customer_id)
- Promo code grace period used (code, customer_id)
- Stripe API slow (latency > 2 seconds)

**ERROR level:**
- Reservation creation failed (reason, customer_id)
- Payment intent creation failed (reason, cart_total)
- Webhook signature verification failed (security)

**CRITICAL level:**
- Order creation failed after payment success (payment_intent_id, customer_email, amount)
- Firestore transaction timeout (operation, duration)

---

## Testing Strategy

### Unit Tests (Per Function)

**reserveInventory():**
- Happy path (sufficient inventory)
- Insufficient inventory (multiple scenarios)
- Product not found
- Invalid quantity (zero, negative, > 1000)
- Transaction conflict simulation
- Timeout simulation

**createPaymentIntent():**
- Happy path (no promo code)
- With valid promo code
- With expired promo code (within/beyond grace)
- Reservation not found
- Reservation expired
- Stripe API error

**createOrderFromPayment():**
- Happy path (webhook path)
- Happy path (frontend path)
- Idempotency (duplicate payment_intent_id)
- Transaction failure (rollback)
- Email send failure (non-blocking)

**Total unit tests:** 30-40 test cases

---

### Integration Tests (End-to-End Paths)

**Test 1: Complete happy path**
1. POST /api/reserve-inventory → 200
2. POST /api/create-payment-intent → 200
3. Simulate Stripe payment success
4. POST /webhooks/stripe → 200
5. Verify order created
6. Verify inventory decremented
7. Verify reservation deleted

**Test 2: Webhook + frontend race**
1. Complete steps 1-3 above
2. Send webhook AND frontend /confirm-order simultaneously
3. Verify only ONE order created
4. Verify both requests return success

**Test 3: Reservation expiration**
1. Create reservation
2. Wait 15 minutes (or mock time)
3. Trigger cleanup job
4. Verify reservation released
5. Attempt payment intent creation → 400

**Test 4: Payment success, order failure, webhook retry**
1. Complete steps 1-3 above
2. Mock Firestore to fail on first attempt
3. Webhook returns 500
4. Mock Firestore to succeed on second attempt
5. Simulate webhook retry → 200
6. Verify order created on retry

**Total integration tests:** 15-20 scenarios

---

### Load Tests (Performance Validation)

**Scenario 1: Normal load (baseline)**
- 10 concurrent checkouts
- 100 checkouts over 10 minutes
- Measure: P95 latency, error rate
- Success: P95 < 500ms, error rate < 1%

**Scenario 2: Peak load (Black Friday)**
- 50 concurrent checkouts
- 500 checkouts over 10 minutes
- Measure: P95 latency, transaction conflicts
- Success: P95 < 1000ms, conflict rate < 10%

**Scenario 3: Hot product (contention)**
- 20 users checkout same product simultaneously
- Product has 10 units available
- Measure: How many get "insufficient inventory" error
- Success: Exactly 10 succeed, 10 fail, no overselling

---

## Open Questions Resolved

All 5 L1 questions from checkout-flow-L1.md answered:

**Q1: Payment success but order creation fails?**
✅ Answered: Multi-layered recovery (webhook retry, manual intervention, monitoring)

**Q2: Webhook vs frontend race?**
✅ Answered: Idempotent creation with deduplication, both paths safe

**Q3: Partial inventory fulfillment?**
✅ Answered: All-or-nothing for MVP (variant 3 documents behavior)

**Q4: Discount code expiration timing?**
✅ Answered: 5-minute grace period, lock-in at payment intent (variant 4)

**Q5: Multiple tab reservation management?**
✅ Answered: Allow duplicates (minor inefficiency, covered in enhancements-L2.md)

---

## Dependencies

**External Services:**
- Stripe API (payment processing)
- Firestore (data storage, transactions)
- Mailgun (email delivery)
- Cloud Scheduler (background cleanup trigger)

**Internal Services:**
- Auth service (customer session validation)
- Product service (inventory lookups)
- Email service (confirmation emails)

**Libraries:**
- Stripe SDK (v10.x)
- Firestore SDK (v9.x)
- Express (v4.x)

---

## Configuration

**Environment Variables:**
```
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
FIRESTORE_PROJECT_ID=manik-honey-prod
MAILGUN_API_KEY=key-...
MAILGUN_DOMAIN=mg.manikgoldenhoney.com
RESERVATION_TTL_MINUTES=15
PROMO_CODE_GRACE_PERIOD_MINUTES=5
PAYMENT_INTENT_TIMEOUT_SECONDS=30
ORDER_CREATION_TIMEOUT_SECONDS=30
```

---

## Success Criteria (Quantified)

**Reliability:**
- 99.9% of payments result in order creation
- < 0.1% require manual intervention
- Zero duplicate orders

**Performance:**
- P95 checkout duration < 10 seconds (excluding customer input time)
- P95 reservation creation < 200ms
- P95 payment intent creation < 500ms

**Customer Experience:**
- > 90% checkout completion rate (payment intent → payment success)
- < 5% reservation expiration rate
- < 1% "out of stock" errors during checkout

**Business:**
- Support tickets for missing orders: < 1 per 1000 orders
- Revenue recovery rate: 100% (all successful payments → orders)

---

**Last Updated:** 2026-01-24
**Stage:** L3
**Status:** ✅ Complete - Exhaustive scenario coverage achieved
**Confidence Level:** 95%+
