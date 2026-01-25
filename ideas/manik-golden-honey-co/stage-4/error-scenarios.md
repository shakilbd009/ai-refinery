# Basic Error Scenarios - Stage 4

**Project:** Manik Golden Honey Co
**Stage:** 4 - Refine L1 (Basic Error Identification)
**Date:** 2026-01-24

---

## Overview

This document identifies basic error scenarios for critical flows. Comprehensive edge case analysis and failure mode mapping will be completed in **Stage 5 (Refine L2)** and **Stage 6 (Refine L3)**.

**L1 focus:** Identify obvious error paths that require explicit handling.

---

## Checkout Flow Errors

### 1. Insufficient Inventory

**Scenario:** Customer attempts to checkout but product is out of stock

**Trigger:** `/checkout/reserve-inventory` called, but `available_qty < requested_qty`

**Handling:**
- Return `400 Bad Request` with specific product, requested amount, available amount
- Frontend shows: "Sorry, only X units of [Product] available"
- Customer can adjust quantity or remove item

**Impact:** Prevents bad UX (customer thinks they can buy, then fails at payment)

---

### 2. Reservation Expired During Checkout

**Scenario:** Customer takes > 15 minutes to complete checkout, reservation expires

**Trigger:** `/checkout/create-payment-intent` called with expired `reservation_id`

**Handling:**
- Check `reservation.expires_at < NOW()` before creating PaymentIntent
- Return `400 Bad Request`: "Your checkout session expired. Please start over."
- Frontend redirects to cart, shows message
- Inventory already released by background job

**Impact:** Prevents charging customer for unavailable inventory

---

### 3. Payment Succeeds But Order Creation Fails

**Scenario:** Stripe payment confirms, but `/checkout/confirm-order` fails (database error, network issue)

**Trigger:** Payment successful, but order not created in Firestore

**Handling (Critical):**
- **Stripe webhook as backup**: Webhook creates order if frontend call failed
- Log error with `payment_intent_id` for manual reconciliation
- Admin dashboard shows "unmatched payments" for investigation
- Customer receives email: "Payment processed, confirming order shortly"

**Impact:** Customer charged but no order record → Revenue loss + support burden

**Mitigation:** Idempotency key on order creation (prevent duplicate orders from retry)

---

### 4. Promo Code Expires Mid-Checkout

**Scenario:** Customer applies code, then code expires before payment

**Trigger:** Code valid at application time, expired at payment time

**Handling:**
- Re-validate code in `/create-payment-intent`
- If expired: Remove discount, recalculate total
- Return error: "Code LAUNCH10 expired. New total: $X.XX"
- Customer must confirm new price before payment

**Impact:** Prevents customer dispute ("I was charged more than shown")

---

### 5. Concurrent Checkout Race Condition

**Scenario:** Two customers checkout simultaneously for last unit

**Trigger:** Both call `/reserve-inventory` at exact same time, 1 unit available

**Handling:**
- Firestore transaction with pessimistic lock
- First request succeeds, second gets `400 Insufficient Inventory`
- Second customer sees "Out of stock" immediately

**Impact:** Prevents overselling (ADR-001 objective)

**Note:** L2 will detail transaction implementation

---

## Payment Processing Errors

### 6. Stripe Payment Declined

**Scenario:** Customer's card is declined by Stripe

**Trigger:** Stripe.confirmPayment() fails

**Handling:**
- Stripe.js shows error to customer
- Frontend doesn't call `/confirm-order`
- Reservation remains active (expires after 15 min)
- Customer can retry with different card

**Impact:** Expected failure, no special handling needed

---

### 7. Stripe API Timeout

**Scenario:** Stripe API unreachable or slow

**Trigger:** `/create-payment-intent` → Stripe API timeout (> 10s)

**Handling:**
- Return `500 Internal Server Error`: "Payment system temporarily unavailable"
- Frontend shows: "Please try again in a few minutes"
- Log error for monitoring/alerting
- Reservation remains (customer can retry)

**Impact:** Checkout unavailable during Stripe outage

**Mitigation:** Retry logic with exponential backoff (3 attempts)

---

### 8. Webhook Signature Validation Fails

**Scenario:** Malicious webhook POST to `/webhooks/stripe`

**Trigger:** Invalid signature on webhook request

**Handling:**
- Verify webhook signature using Stripe secret
- If invalid: Return `400 Bad Request`, log security event
- Do not process webhook payload

**Impact:** Prevents fake payment confirmations

---

## Review Moderation Errors

### 9. Customer Reviews Product They Didn't Purchase

**Scenario:** Malicious customer tries to review product they didn't order

**Trigger:** POST `/reviews` with product_id customer never ordered

**Handling:**
- Query orders: `customer_id = X AND line_items contains product_id = Y`
- If no match: Return `403 Forbidden`: "Must purchase before reviewing"
- Frontend hides review button for unpurchased products

**Impact:** Prevents fake reviews

---

### 10. Review Edit Spam

**Scenario:** Customer edits review 50 times (spams admin moderation queue)

**Trigger:** PUT `/reviews/:id` called repeatedly

**Handling:**
- Check `review.edit_count >= 3`
- If exceeded: Return `400 Bad Request`: "Maximum edits reached"
- Frontend disables edit button after 3 edits

**Impact:** Prevents admin queue spam

**Note:** Edit limit is business rule, may adjust based on feedback

---

## Email Delivery Errors

### 11. Email Service (Mailgun) Down

**Scenario:** Mailgun API unreachable

**Trigger:** Order confirmation email fails to send

**Handling:**
- Order creation succeeds regardless (email is non-critical)
- Log error with order_id and customer email
- Retry email via background job (attempt 3 times over 1 hour)
- If all retries fail: Admin dashboard shows "email failed" for manual follow-up

**Impact:** Customer doesn't receive confirmation (support issue, not order issue)

---

### 12. Customer Email Bounce

**Scenario:** Customer's email address invalid (typo or fake)

**Trigger:** Mailgun webhook: bounce notification

**Handling:**
- Log bounce event with customer_id
- Admin dashboard flags customer with bounced email
- For passwordless auth: Customer can't log in (no verification code delivered)
- Support process: Contact customer via phone/alternate method

**Impact:** Customer can't receive order updates

---

## Inventory Management Errors

### 13. Background Job Failure (Cloud Scheduler Down)

**Scenario:** Cleanup job doesn't run (Cloud Scheduler outage)

**Trigger:** No job executions for > 15 minutes

**Handling:**
- Cloud Monitoring alert: "Cleanup job not executed in 15 min"
- Reservations not released → inventory stays locked
- Manual intervention: Run cleanup endpoint via curl
- Workaround: Admin can manually adjust inventory if critical

**Impact:** Inventory appears unavailable (sales blocked)

**Mitigation:** Redundant monitoring, backup manual trigger

---

### 14. Admin Sets Inventory Below Reserved Amount

**Scenario:** Admin updates product quantity to 5, but 10 units are reserved

**Trigger:** PUT `/admin/products/:id` with `quantity < reserved_quantity`

**Handling:**
- Validate: `new_quantity >= reserved_quantity`
- If violated: Return `400 Bad Request`: "Cannot set quantity below reserved (10 units currently reserved)"
- Frontend shows current reserved amount as warning

**Impact:** Prevents negative available inventory

---

### 15. Reservation Cleanup Double-Delete

**Scenario:** Two cleanup jobs run simultaneously, both try to delete same reservation

**Trigger:** Cloud Scheduler misconfiguration (two jobs at same time)

**Handling:**
- Firestore transaction: Check reservation exists before deleting
- First job deletes, second job gets "not found" (idempotent)
- No error thrown (idempotent cleanup is safe)

**Impact:** Minor log noise, no actual issue

**Note:** L2 will document transaction structure

---

## Cancellation Flow Errors

### 16. Stripe Refund Fails

**Scenario:** Admin approves cancellation, but Stripe refund API fails

**Trigger:** PUT `/admin/cancellations/:id/approve` → Stripe refund error

**Handling:**
- Do NOT mark order as cancelled (refund failed)
- Return `500 Internal Server Error` with Stripe error details
- Admin sees error message: "Refund failed: [Stripe error]"
- Admin must resolve (manual refund in Stripe dashboard) then retry

**Impact:** Cancellation blocked until refund succeeds

**Mitigation:** Retry logic (3 attempts), then escalate to admin

---

### 17. Customer Requests Cancellation After Shipment

**Scenario:** Order already shipped, customer clicks "Request Cancellation"

**Trigger:** POST `/cancellations` with `order.status = 'shipped'`

**Handling:**
- Check order status before creating request
- Return `400 Bad Request`: "Cannot cancel shipped orders. Contact support for returns."
- Frontend hides cancellation button if status = shipped/delivered

**Impact:** Prevents invalid cancellation requests

---

## Admin Authentication Errors

### 18. Brute Force Login Attempts

**Scenario:** Attacker tries many passwords for admin account

**Trigger:** Multiple failed POST `/admin/login` attempts

**Handling:**
- Rate limit: Max 5 failed attempts per email per 15 minutes
- After 5 failures: Return `429 Too Many Requests`: "Too many failed attempts. Try again in 15 minutes."
- Log security event (potential attack)

**Impact:** Prevents credential stuffing attacks

---

### 19. JWT Token Expired Mid-Session

**Scenario:** Admin logged in, token expires after 8 hours

**Trigger:** Any `/admin/*` endpoint call with expired JWT

**Handling:**
- Middleware checks token expiration
- Return `401 Unauthorized`
- Frontend detects 401, redirects to `/admin/login`
- Admin must re-authenticate

**Impact:** Session timeout (expected behavior)

---

## Next Steps: Comprehensive Edge Case Analysis (Stage 5)

**L1 identified 19 basic error scenarios.**

**Stage 5 (Refine L2) will:**
- Apply Edge Case Discovery Framework systematically
- Document error handling for all edge cases
- Create failure mode analysis table
- Map recovery strategies
- Define monitoring/alerting thresholds

**Stage 6 (Refine L3) will:**
- Achieve 100% edge case coverage
- Document every failure mode with recovery
- Security threat model
- Performance implications
- Complete scenario coverage

---

**Last Updated:** 2026-01-24
**Stage:** L1 (Basic Errors Identified)
