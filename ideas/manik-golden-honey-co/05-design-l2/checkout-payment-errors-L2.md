# L2: Checkout Payment Error Handling

**Component:** Payment Processing & Order Creation
**Stage:** L2 (Refine L2 - Detailed Design)
**Date:** 2026-01-24

---

## Critical Questions from L1

1. **What happens if payment succeeds but order creation fails?**
2. **What if Stripe webhook arrives before /confirm-order call?**

---

## Problem 1: Payment Success + Order Creation Failure

### Scenario

```
Customer checkout flow:
1. Reserve inventory ✓
2. Create Stripe PaymentIntent ✓
3. Customer enters card details ✓
4. Stripe charges card ✓
5. Backend receives payment_intent.succeeded webhook ✓
6. Backend attempts to create order document → ❌ FIRESTORE FAILURE
```

**Result:** Customer charged, no order record, inventory still reserved.

### Root Causes

- Firestore write timeout/failure
- Network partition during order creation
- Backend service crash mid-transaction
- Firestore quota exceeded (unlikely but possible)
- Invalid order data (validation passed on client, failed server-side)

---

## Solution: Idempotent Order Creation with Webhook Recovery

### High-Level Algorithm

**Stripe webhook handler (primary path):**

```
ON payment_intent.succeeded webhook:
  1. Verify webhook signature (prevent spoofing)
  2. Extract payment_intent_id
  3. Check if order already exists (query orders where stripe_payment_intent_id = payment_intent_id)

  IF order exists:
    4a. Log "Order already created" (idempotency)
    4b. Return 200 OK (tell Stripe webhook received)

  ELSE:
    4c. Create order document in Firestore transaction:
        - Set stripe_payment_intent_id (unique constraint)
        - Set status = "confirmed"
        - Capture payment details, customer info, items
        - Decrement product inventory
        - Delete reservation document

    IF transaction succeeds:
      5a. Send confirmation email
      5b. Return 200 OK

    IF transaction fails:
      5c. Log error with payment_intent_id
      5d. Return 500 (Stripe will retry webhook)
      5e. Alert admin (urgent: customer charged, no order)
```

**Frontend /confirm-order endpoint (secondary path):**

```
ON /confirm-order API call:
  1. Verify customer session
  2. Extract payment_intent_id from request
  3. Query Stripe API: GET /v1/payment_intents/{id}

  IF payment_intent.status != "succeeded":
    4a. Return error "Payment not completed"

  ELSE:
    4b. Check if order already exists (same query as webhook)

    IF order exists:
      4c. Return order (idempotency, webhook already created it)

    ELSE:
      4d. Create order (same transaction as webhook handler)
      4e. Return created order
```

---

## Key Design Decisions

### Decision 1: Webhook is Primary, Frontend is Fallback

**Rationale:**
- Webhooks are more reliable (Stripe retries failed webhooks)
- Frontend might timeout/crash but webhook persists
- Customer might close browser before /confirm-order completes

**Implementation:**
- Both paths use same order creation function (DRY)
- Both paths are idempotent (check existence first)
- Both paths use `stripe_payment_intent_id` as deduplication key

### Decision 2: Unique Constraint on payment_intent_id

**Firestore schema:**
```
orders/{orderId}
  stripe_payment_intent_id: string (indexed, unique via validation)
  ...
```

**Validation:**
- Before creating order, query: `orders where stripe_payment_intent_id == X`
- If exists, return existing order (idempotency)
- If not exists, create with transaction to prevent race

**Why not Firestore uniqueness constraint?**
- Firestore doesn't support unique constraints (except document ID)
- Use query + transaction for atomicity

---

## Problem 2: Webhook vs Frontend Race Condition

### Scenario

```
Timeline:
T+0ms:  Customer completes payment on Stripe checkout
T+50ms: Stripe sends payment_intent.succeeded webhook → Backend receives
T+50ms: Backend starts order creation transaction
T+100ms: Frontend calls /confirm-order → Backend receives
T+100ms: Frontend checks payment status with Stripe API
T+150ms: Backend completes webhook order creation ✓
T+150ms: Frontend starts order creation → DUPLICATE?
```

**Question:** Do we create two orders for one payment?

---

## Solution: Idempotent Order Creation (Shared Logic)

### High-Level Algorithm

Both webhook and frontend use the **same order creation service**:

```
FUNCTION createOrderFromPayment(payment_intent_id, source):
  1. BEGIN Firestore transaction

  2. Query: orders where stripe_payment_intent_id == payment_intent_id
     IF order found:
       ROLLBACK transaction
       RETURN existing order (idempotent)

  3. Fetch payment details from Stripe API (get customer, amount, metadata)

  4. Create order document:
     - orderId: auto-generated
     - stripe_payment_intent_id: payment_intent_id
     - status: "confirmed"
     - items: from payment metadata
     - customer: from payment metadata
     - total: from payment.amount
     - created_at: now
     - created_by: source (webhook or frontend)

  5. Decrement product inventory (items.forEach → product.quantity -= item.quantity)

  6. Delete reservation document (reservation_id from payment metadata)

  7. COMMIT transaction
     IF commit fails:
       ROLLBACK
       THROW error (caller handles retry)

  8. AFTER transaction commits:
     - Send confirmation email (async, best-effort)
     - Log order creation event

  9. RETURN created order
```

**Key invariant:** Only one order can exist per `payment_intent_id`.

---

## Race Condition Handling

### Case 1: Webhook Arrives First (Expected Flow)

```
T+0:   Webhook starts transaction
T+10:  Webhook queries orders → not found
T+20:  Webhook creates order, commits ✓
T+30:  Frontend calls /confirm-order
T+40:  Frontend queries orders → FOUND (created by webhook)
T+50:  Frontend returns existing order (no duplicate)
```

### Case 2: Frontend Arrives First (Rare)

```
T+0:   Frontend calls /confirm-order
T+10:  Frontend queries orders → not found
T+20:  Frontend creates order, commits ✓
T+25:  Webhook arrives
T+35:  Webhook queries orders → FOUND (created by frontend)
T+45:  Webhook returns 200 OK, logs idempotency hit
```

### Case 3: Simultaneous Arrival (Extreme Edge Case)

```
T+0:   Webhook and frontend both start transactions
T+10:  Both query orders → not found (before either commits)
T+20:  Webhook commits order → SUCCESS
T+21:  Frontend commits order → CONFLICT (payment_intent_id validation)
T+25:  Frontend retries → queries orders → FOUND
T+30:  Frontend returns existing order
```

**How validation prevents duplicate:**
- Firestore transaction includes query + create atomically
- If both try to create, one commits first, second sees conflict
- Loser retries and finds winner's order

**Firestore transaction guarantees:**
- Serializable isolation (prevents read-write conflicts)
- Atomic commit (all-or-nothing)

---

## Error Recovery Strategies

### Scenario 1: Order Creation Fails, Webhook Retries

**Stripe webhook retry policy:**
- Retry on 5xx errors (server failure)
- Exponential backoff: 1min, 5min, 30min, 2hr, 24hr
- Max 3 days of retries

**Our handling:**
```
IF order creation fails (Firestore timeout, etc):
  1. Log error with payment_intent_id and customer email
  2. Return 500 to Stripe (triggers retry)
  3. Alert admin immediately (email/Slack)
  4. Admin can manually create order from Stripe dashboard data
```

**Manual recovery process:**
1. Admin sees alert: "Payment succeeded, order creation failed"
2. Admin checks Stripe dashboard for payment_intent_id
3. Admin sees customer email, items, amount
4. Admin manually creates order in system OR waits for webhook retry
5. Webhook retry succeeds (order created automatically)

### Scenario 2: Inventory Decrement Fails, Order Partially Created

**Problem:**
- Order document created
- Inventory decrement fails (network issue)
- Transaction rolls back
- But Stripe webhook might retry and succeed

**Solution: All-or-nothing transaction**
```
BEGIN transaction:
  1. Create order document
  2. Decrement inventory (all products)
  3. Delete reservation
  COMMIT

IF any step fails:
  ROLLBACK entire transaction
  Order not created, inventory unchanged
```

**Firestore transaction guarantees this atomicity.**

### Scenario 3: Email Send Fails After Order Created

**Problem:**
- Order successfully created
- Confirmation email fails to send
- Customer doesn't know order succeeded

**Solution: Email send is async, best-effort**
```
AFTER transaction commits:
  TRY:
    sendConfirmationEmail(customer, order)
  CATCH error:
    Log email failure
    Store email_sent: false on order document
    Admin dashboard shows "Email failed" badge
```

**Admin remediation:**
- Daily cron job retries failed emails
- Admin can manually trigger email resend
- Customer can check "My Orders" page

---

## Edge Cases Discovered

### Edge Case 1: Duplicate Webhook Delivery

**Stripe behavior:**
- Same webhook may be delivered multiple times
- Identical payload, different delivery attempts

**Handling:**
- Idempotent order creation (query before create)
- Return 200 OK even if order already exists
- Log duplicate webhook delivery (monitoring)

### Edge Case 2: Payment Intent Succeeded Twice (Rare Stripe Bug)

**Scenario:**
- Stripe bug sends two `payment_intent.succeeded` webhooks
- Different webhook IDs, same payment_intent_id

**Handling:**
- Both webhooks use same payment_intent_id
- First creates order
- Second finds existing order (idempotent)
- No duplicate charge (Stripe guarantees one charge per intent)

### Edge Case 3: Customer Refreshes /confirm-order Page

**Scenario:**
- Customer completes payment
- Frontend calls /confirm-order
- Customer refreshes page before response
- Second /confirm-order call fires

**Handling:**
- Both calls query with same payment_intent_id
- First creates order
- Second finds existing order
- Customer sees same order confirmation

### Edge Case 4: Stripe Refund Issued Before Order Created

**Scenario:**
- Payment succeeds
- Order creation fails (webhook retry pending)
- Admin refunds customer manually in Stripe dashboard
- Webhook finally succeeds, creates order

**Handling:**
- Order creation checks payment status with Stripe API
- If payment status = "refunded", don't create order
- Log anomaly, alert admin

**Algorithm update:**
```
FUNCTION createOrderFromPayment(payment_intent_id):
  1. Query orders (check idempotency)
  2. Fetch payment from Stripe API
  3. IF payment.status == "canceled" OR "refunded":
       Log "Payment refunded before order creation"
       RETURN null (don't create order)
  4. Proceed with order creation...
```

---

## Risks & Mitigations

### Risk 1: Firestore Extended Outage

**Scenario:**
- Firestore down for hours
- Webhooks keep retrying, all fail
- Customer charged, no order after 3 days of retries

**Mitigation:**
- Monitor Firestore status page
- Alert admin on webhook failures (Slack/email)
- Admin manual order creation process documented
- Stripe payment data available for 90 days

**Escalation:**
- After 24 hours of failures, admin reviews all pending payments
- Manually creates orders from Stripe dashboard
- Sends apology email to customers with order confirmation

### Risk 2: Webhook Signature Verification Bypass

**Scenario:**
- Attacker crafts fake webhook
- Creates fraudulent orders without payment

**Mitigation:**
- Always verify Stripe webhook signature
- Reject webhooks with invalid signatures (return 400)
- Double-check payment status with Stripe API before order creation

**Algorithm enforcement:**
```
ON webhook received:
  1. Verify signature using Stripe library
     IF invalid: return 400 (no retry)
  2. Fetch payment from Stripe API (don't trust webhook payload alone)
  3. IF payment.status != "succeeded": return 200 (invalid state)
  4. Proceed with order creation
```

### Risk 3: Race Between Webhook and Refund

**Scenario:**
- Payment succeeds
- Admin refunds immediately (customer service)
- Webhook delayed, arrives after refund
- Order created for refunded payment

**Mitigation:**
- Check payment status when creating order (covered in Edge Case 4)
- Order creation queries Stripe API, sees refund, aborts
- Admin UI prevents refund until order created (enforced in UI)

---

## Monitoring & Alerts

### Critical Metrics

1. **Webhook Processing Time**
   - Alert if > 5 seconds (Firestore slow)
   - Dashboard: P50, P95, P99

2. **Order Creation Failures**
   - Alert on ANY failure (customer charged, no order)
   - Slack notification with payment_intent_id, customer email

3. **Webhook Retry Count**
   - Alert if Stripe retrying > 3 times (persistent issue)
   - Dashboard: Retry rate by hour

4. **Idempotency Hit Rate**
   - Track how often duplicate detection prevents duplicates
   - Dashboard: % of orders created by webhook vs frontend

### Admin Dashboard Indicators

- **"Payment Pending Order"** badge: Payment succeeded, order creation failed
- **"Email Failed"** badge: Order created, email send failed
- **"Webhook Retrying"** status: Stripe retrying webhook delivery

---

## Testing Scenarios

### Unit Tests

1. **Idempotent order creation**
   - Call createOrderFromPayment twice with same payment_intent_id
   - Assert: Only one order created

2. **Refunded payment handling**
   - Mock Stripe API to return refunded payment
   - Call createOrderFromPayment
   - Assert: No order created, null returned

3. **Transaction rollback**
   - Mock Firestore inventory decrement to fail
   - Call createOrderFromPayment
   - Assert: No order created (transaction rolled back)

### Integration Tests

1. **Webhook + Frontend race**
   - Trigger webhook and frontend call simultaneously
   - Assert: Only one order created
   - Assert: Both paths return same order

2. **Webhook retry on failure**
   - Mock Firestore to fail first attempt, succeed on retry
   - Trigger webhook twice
   - Assert: Order created on second attempt

3. **Email failure recovery**
   - Mock Mailgun to fail
   - Create order successfully
   - Assert: Order marked email_sent: false
   - Assert: Admin dashboard shows failed email

---

## L1 Questions Answered

### Q1: What happens if payment succeeds but order creation fails?

**Answer:**

1. **Webhook retry** (automatic): Stripe retries webhook up to 3 days with exponential backoff
2. **Admin alert** (immediate): Slack/email notification with payment_intent_id and customer email
3. **Manual recovery** (if retry fails): Admin creates order from Stripe dashboard data
4. **Customer support** (proactive): Admin emails customer confirming order being processed

**Key guarantee:** Every successful payment eventually creates an order (via retry or manual intervention).

### Q2: What if Stripe webhook arrives before /confirm-order call?

**Answer:**

**Idempotent order creation prevents duplicates:**

1. Webhook arrives first → creates order with payment_intent_id
2. Frontend calls /confirm-order → queries by payment_intent_id → finds existing order
3. Returns existing order to frontend (no duplicate)

**Both paths use same creation function, both check existence first.**

**Race condition handled by Firestore transaction atomicity:** If both start simultaneously, one commits first, second detects conflict and returns existing order.

---

**Last Updated:** 2026-01-24
**Stage:** L2
**Status:** ✅ Critical questions resolved
