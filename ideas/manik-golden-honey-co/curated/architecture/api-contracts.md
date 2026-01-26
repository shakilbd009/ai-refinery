# API Contracts

RESTful API using JSON. All endpoints return consistent error format.

**Base URL:** `https://api.manikgoldenhoney.com`

## Authentication

### POST /api/auth/send-code
Send verification code to customer email.

**Request:** `{ "email": "customer@example.com" }`
**Response:** `{ "message": "Code sent", "expires_in_seconds": 600 }`
**Errors:** 400 (invalid email), 429 (rate limit)

### POST /api/auth/verify-code
Verify code, return JWT.

**Request:** `{ "email": "...", "code": "123456" }`
**Response:** `{ "token": "...", "customer": { "id", "email" } }`
**Errors:** 401 (invalid/expired), 429 (too many attempts)

### POST /api/admin/login
Admin login with password.

**Request:** `{ "email": "...", "password": "..." }`
**Response:** `{ "token": "...", "admin": { "id", "email" } }`
**Errors:** 401 (invalid credentials)

## Checkout

### POST /api/checkout/reserve-inventory
Reserve inventory for 15 minutes.

**Request:**
```json
{
  "items": [{ "product_id": "...", "quantity": 2 }],
  "session_id": "sess_xyz"
}
```
**Response:** `{ "reservation_id": "...", "expires_at": "..." }`
**Errors:** 400 (insufficient inventory), 404 (product not found)

### POST /api/checkout/validate-promo-code
Validate discount code.

**Request:** `{ "code": "LAUNCH10", "cart_total": 4500 }`
**Response:** `{ "valid": true, "discount_percentage": 10, "discount_amount": 450 }`
**Errors:** 400 (invalid/expired/minimum not met)

### POST /api/checkout/create-payment-intent
Create Stripe PaymentIntent.

**Request:** `{ "reservation_id": "...", "promo_code": "...", "shipping_address": {...} }`
**Response:** `{ "client_secret": "...", "amount": 4050 }`
**Errors:** 400 (reservation expired)

### POST /api/checkout/confirm-order
Create order after payment (idempotent).

**Request:** `{ "payment_intent_id": "...", "reservation_id": "..." }`
**Response:** `{ "order_id": "...", "order_number": "MGH-1001" }`
**Errors:** 400 (payment incomplete), 409 (order exists)

## Reviews

### POST /api/reviews
Submit review (verified purchaser only).

**Auth:** Customer JWT required
**Request:** `{ "product_id": "...", "order_id": "...", "rating": 5, "text": "..." }`
**Response:** `{ "review_id": "...", "status": "pending" }`
**Errors:** 403 (not purchaser), 409 (already reviewed)

### PUT /api/reviews/:id
Edit review (returns to pending).

**Auth:** Customer JWT (owner only)
**Request:** `{ "text": "...", "rating": 5 }`
**Errors:** 429 (cooldown active)

## Cancellations

### POST /api/cancellations
Request order cancellation.

**Auth:** Customer JWT required
**Request:** `{ "order_id": "...", "reason": "..." }`
**Response:** `{ "cancellation_request_id": "...", "status": "pending" }`
**Errors:** 400 (order shipped), 409 (already requested)

## Admin Endpoints

### GET /api/admin/reviews/pending
List reviews awaiting moderation.

**Auth:** Admin JWT required
**Response:** `{ "reviews": [...], "total_count": 5 }`

### PUT /api/admin/reviews/:id/approve
Approve review.

**Response:** `{ "status": "approved" }`

### PUT /api/admin/reviews/:id/reject
Reject review with reason.

**Request:** `{ "reason": "..." }`
**Response:** `{ "status": "rejected" }`

### PUT /api/admin/cancellations/:id/approve
Approve cancellation (triggers refund).

**Response:** `{ "status": "approved", "refund_amount": 4050 }`

### POST /api/admin/promo-codes
Create discount code.

**Request:**
```json
{
  "code": "SPRING20",
  "discount_percentage": 20,
  "min_order_value": 3000,
  "max_redemptions": 100,
  "one_time_per_customer": true,
  "expires_at": "2026-04-01T00:00:00Z"
}
```

## Webhooks

### POST /webhooks/stripe
Stripe webhook handler (primary order creation path).

**Security:** Signature verification required
**Events handled:** `payment_intent.succeeded`
**Response:** 200 OK (or 500 for retry)

## Error Format

```json
{
  "error": "error_code",
  "message": "Human-readable message",
  "details": {}
}
```

**Status Codes:**
- 200/201: Success
- 400: Invalid input
- 401: Authentication required
- 403: Permission denied
- 404: Not found
- 409: Conflict
- 429: Rate limited
- 500: Server error
