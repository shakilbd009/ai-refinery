# API Contracts - Key Endpoints

**Project:** Manik Golden Honey Co
**Stage:** 4 - Refine L1 (Detailed Design)
**Date:** 2026-01-24

---

## Overview

RESTful API using JSON for requests/responses. All endpoints return consistent error format.

**Base URL:** `https://api.manikgoldenhoney.com` (example)

**Common headers:**
- `Content-Type: application/json`
- `Authorization: Bearer {jwt_token}` (protected endpoints)

---

## Authentication Endpoints

### POST /api/auth/send-code

**Purpose:** Send 6-digit verification code to customer email

**Request:**
```json
{
  "email": "customer@example.com"
}
```

**Response (200 OK):**
```json
{
  "message": "Verification code sent to customer@example.com",
  "expires_in_seconds": 600
}
```

**Errors:**
- `400 Bad Request`: Invalid email format
- `429 Too Many Requests`: Rate limit exceeded (max 3 codes per email per hour)

---

### POST /api/auth/verify-code

**Purpose:** Verify code and return JWT token

**Request:**
```json
{
  "email": "customer@example.com",
  "code": "123456"
}
```

**Response (200 OK):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "customer": {
    "id": "cust_abc123",
    "email": "customer@example.com"
  }
}
```

**Errors:**
- `400 Bad Request`: Missing email or code
- `401 Unauthorized`: Invalid or expired code
- `429 Too Many Requests`: Too many failed attempts (max 3)

---

### POST /api/admin/login

**Purpose:** Admin login with email/password

**Request:**
```json
{
  "email": "admin@manikgoldenhoney.com",
  "password": "securepassword"
}
```

**Response (200 OK):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "admin": {
    "id": "admin_xyz789",
    "email": "admin@manikgoldenhoney.com"
  }
}
```

**Errors:**
- `401 Unauthorized`: Invalid credentials
- `429 Too Many Requests`: Too many failed attempts

---

## Checkout Endpoints

### POST /api/checkout/reserve-inventory

**Purpose:** Reserve inventory for checkout session

**Auth:** Optional (unauthenticated checkout supported)

**Request:**
```json
{
  "items": [
    {
      "product_id": "prod_abc123",
      "quantity": 2
    },
    {
      "product_id": "prod_def456",
      "quantity": 1
    }
  ],
  "session_id": "sess_xyz789"
}
```

**Response (200 OK):**
```json
{
  "reservation_id": "res_123",
  "expires_at": "2026-01-24T15:30:00Z",
  "reserved_items": [
    {
      "product_id": "prod_abc123",
      "quantity": 2
    },
    {
      "product_id": "prod_def456",
      "quantity": 1
    }
  ]
}
```

**Errors:**
- `400 Bad Request`: Insufficient inventory
  ```json
  {
    "error": "insufficient_inventory",
    "message": "Product 'Wildflower Honey 12oz' has only 1 unit available",
    "product_id": "prod_abc123",
    "requested": 2,
    "available": 1
  }
  ```
- `404 Not Found`: Product not found or inactive

---

### POST /api/checkout/validate-promo-code

**Purpose:** Validate discount code and return discount amount

**Request:**
```json
{
  "code": "LAUNCH10",
  "cart_total": 4500  // cents
}
```

**Response (200 OK):**
```json
{
  "valid": true,
  "code": "LAUNCH10",
  "discount_percentage": 10,
  "discount_amount": 450,
  "final_total": 4050,
  "message": "10% discount applied"
}
```

**Errors:**
- `400 Bad Request`: Code invalid/expired/inactive
  ```json
  {
    "valid": false,
    "error": "code_expired",
    "message": "This code expired on 2026-01-15"
  }
  ```
- `400 Bad Request`: Minimum order not met
  ```json
  {
    "valid": false,
    "error": "minimum_not_met",
    "message": "Add $5.50 more to use this code",
    "min_order_value": 5000,
    "current_total": 4500,
    "amount_needed": 550
  }
  ```

---

### POST /api/checkout/create-payment-intent

**Purpose:** Create Stripe PaymentIntent for checkout

**Request:**
```json
{
  "reservation_id": "res_123",
  "promo_code": "LAUNCH10",
  "shipping_address": {
    "name": "John Doe",
    "street": "123 Main St",
    "city": "Portland",
    "state": "OR",
    "zip": "97201",
    "country": "US"
  }
}
```

**Response (200 OK):**
```json
{
  "client_secret": "pi_abc123_secret_xyz",
  "payment_intent_id": "pi_abc123",
  "amount": 4050,
  "currency": "usd"
}
```

**Errors:**
- `400 Bad Request`: Reservation expired
- `400 Bad Request`: Promo code invalid at payment time
- `500 Internal Server Error`: Stripe API failure

---

### POST /api/checkout/confirm-order

**Purpose:** Create order after successful payment

**Request:**
```json
{
  "payment_intent_id": "pi_abc123",
  "reservation_id": "res_123"
}
```

**Response (201 Created):**
```json
{
  "order_id": "ord_abc123",
  "order_number": "MGH-1001",
  "total": 4050,
  "status": "pending",
  "confirmation_email_sent": true
}
```

**Errors:**
- `400 Bad Request`: Payment not confirmed
- `400 Bad Request`: Reservation expired
- `409 Conflict`: Order already created for this PaymentIntent

---

## Review Endpoints

### POST /api/reviews

**Purpose:** Submit product review (verified purchaser only)

**Auth:** Required (customer JWT)

**Request:**
```json
{
  "product_id": "prod_abc123",
  "order_id": "ord_xyz789",
  "rating": 5,
  "review_text": "Amazing honey! Fresh and delicious, will order again."
}
```

**Response (201 Created):**
```json
{
  "review_id": "rev_abc123",
  "status": "pending",
  "message": "Your review has been submitted for moderation"
}
```

**Errors:**
- `403 Forbidden`: Customer did not purchase this product
  ```json
  {
    "error": "not_verified_purchaser",
    "message": "You must purchase this product before reviewing"
  }
  ```
- `409 Conflict`: Review already exists
  ```json
  {
    "error": "duplicate_review",
    "message": "You have already reviewed this product",
    "existing_review_id": "rev_def456"
  }
  ```
- `400 Bad Request`: Invalid rating (not 1-5) or text too short/long

---

### GET /api/admin/reviews/pending

**Purpose:** List reviews awaiting moderation

**Auth:** Required (admin JWT)

**Response (200 OK):**
```json
{
  "reviews": [
    {
      "id": "rev_abc123",
      "product_id": "prod_xyz",
      "product_name": "Wildflower Honey 12oz",
      "customer_email": "john@example.com",
      "rating": 5,
      "review_text": "Great honey!",
      "created_at": "2026-01-24T10:30:00Z"
    }
  ],
  "total_count": 1
}
```

---

### PUT /api/admin/reviews/:id/approve

**Purpose:** Approve pending review

**Auth:** Required (admin JWT)

**Response (200 OK):**
```json
{
  "review_id": "rev_abc123",
  "status": "approved",
  "message": "Review approved and now visible to customers"
}
```

**Errors:**
- `404 Not Found`: Review not found
- `400 Bad Request`: Review not in pending status

---

## Cancellation Endpoints

### POST /api/cancellations

**Purpose:** Request order cancellation

**Auth:** Required (customer JWT)

**Request:**
```json
{
  "order_id": "ord_abc123",
  "reason": "Ordered wrong size by mistake"
}
```

**Response (201 Created):**
```json
{
  "cancellation_request_id": "canc_xyz789",
  "status": "pending",
  "message": "Your cancellation request has been submitted. We'll review within 24 hours."
}
```

**Errors:**
- `400 Bad Request`: Order already shipped/delivered
  ```json
  {
    "error": "order_not_eligible",
    "message": "Cannot cancel orders that have already shipped",
    "order_status": "shipped"
  }
  ```
- `409 Conflict`: Cancellation request already pending
- `403 Forbidden`: Not your order

---

### PUT /api/admin/cancellations/:id/approve

**Purpose:** Approve cancellation and issue refund

**Auth:** Required (admin JWT)

**Response (200 OK):**
```json
{
  "cancellation_request_id": "canc_xyz789",
  "status": "approved",
  "order_id": "ord_abc123",
  "refund_amount": 4050,
  "stripe_refund_id": "re_abc123",
  "inventory_returned": true,
  "customer_notified": true
}
```

**Errors:**
- `500 Internal Server Error`: Stripe refund failed
  ```json
  {
    "error": "refund_failed",
    "message": "Failed to process refund with Stripe",
    "stripe_error": "charge_already_refunded"
  }
  ```

---

## Admin Promo Code Endpoints

### POST /api/admin/promo-codes

**Purpose:** Create new discount code

**Auth:** Required (admin JWT)

**Request:**
```json
{
  "code": "SPRING20",
  "discount_percentage": 20,
  "min_order_value": 3000,
  "expiration_date": "2026-04-01T00:00:00Z",
  "max_redemptions": 100,
  "one_time_per_customer": true
}
```

**Response (201 Created):**
```json
{
  "promo_code_id": "promo_abc123",
  "code": "SPRING20",
  "active": true,
  "created_at": "2026-01-24T12:00:00Z"
}
```

**Errors:**
- `409 Conflict`: Code already exists
- `400 Bad Request`: Invalid discount percentage (not 0-100)

---

## Common Error Format

**All errors follow this structure:**

```json
{
  "error": "error_code",
  "message": "Human-readable error message",
  "details": {
    // Optional context-specific details
  }
}
```

**Common HTTP Status Codes:**
- `200 OK` - Success
- `201 Created` - Resource created
- `400 Bad Request` - Invalid input
- `401 Unauthorized` - Missing or invalid auth token
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource doesn't exist
- `409 Conflict` - Duplicate or conflicting state
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server-side failure

---

**Last Updated:** 2026-01-24
**Stage:** L1 (Refine L1)
