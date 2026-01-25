# Edge Case Discovery: Comprehensive Analysis

**Stage:** 6 - Edge Case Discovery (Phase 2)
**Date:** 2026-01-24
**Coverage Target:** 100% of framework categories

---

## Category 1: Data Boundary Cases

### 1.1 Empty Inputs (null, empty string, empty arrays)

#### Cart & Checkout

| Input | Location | Handling | Test Case |
|-------|----------|----------|-----------|
| Empty cart | POST /api/reserve-inventory | 400 "Cart is empty" | `items: []` |
| Null cart_id | POST /api/reserve-inventory | 400 "cart_id required" | `cart_id: null` |
| Empty product_id | Cart item | 400 "Invalid product_id" | `product_id: ""` |
| Null quantity | Cart item | 400 "Quantity required" | `quantity: null` |
| Empty shipping address | Order creation | 400 "Shipping address required" | `address: {}` |
| Null customer_id | Session | 401 "Authentication required" | Missing session |

#### Discount Codes

| Input | Location | Handling | Test Case |
|-------|----------|----------|-----------|
| Empty code | POST /api/apply-promo-code | 400 "Code required" | `code: ""` |
| Null code | POST /api/apply-promo-code | 400 "Code required" | `code: null` |
| Whitespace only | POST /api/apply-promo-code | 400 "Invalid code" | `code: "   "` |

#### Reviews

| Input | Location | Handling | Test Case |
|-------|----------|----------|-----------|
| Empty review text | POST /api/reviews | 400 "Review text required" | `text: ""` |
| Null rating | POST /api/reviews | 400 "Rating required" | `rating: null` |
| Empty display name | POST /api/reviews | Use "Anonymous" default | `display_name: ""` |

**Implementation Pattern:**
```javascript
// Validation middleware
function validateRequired(field, value) {
  if (value === null || value === undefined) {
    throw new ValidationError(`${field} is required`);
  }
  if (typeof value === 'string' && value.trim() === '') {
    throw new ValidationError(`${field} cannot be empty`);
  }
  if (Array.isArray(value) && value.length === 0) {
    throw new ValidationError(`${field} cannot be empty`);
  }
}
```

---

### 1.2 Maximum Values (integer overflow, string length limits, array size limits)

#### Quantity Limits

| Field | Max Value | Handling | Rationale |
|-------|-----------|----------|-----------|
| Cart item quantity | 100 | 400 "Max 100 per item" | Practical limit for honey orders |
| Cart items count | 50 | 400 "Max 50 items per cart" | Firestore transaction limit (500 writes) |
| Reservation quantity total | 500 | 400 "Order too large" | Prevents DoS via large reservations |

#### String Length Limits

| Field | Max Length | Handling | Rationale |
|-------|------------|----------|-----------|
| Promo code | 20 chars | 400 "Code too long" | Reasonable code length |
| Review text | 2000 chars | 400 "Review too long" | Prevents spam walls |
| Customer name | 100 chars | 400 "Name too long" | Standard limit |
| Address line | 200 chars | 400 "Address too long" | Standard limit |
| Email | 254 chars | 400 "Email too long" | RFC 5321 limit |

#### Numeric Limits

| Field | Max Value | Handling | Rationale |
|-------|-----------|----------|-----------|
| Price (cents) | 99999999 (999,999.99) | 400 "Price exceeds limit" | Practical max |
| Discount percent | 100 | 400 "Discount must be 1-100" | Business rule |
| Rating | 5 | 400 "Rating must be 1-5" | Star system |
| Max redemptions | 1000000 | 400 "Max redemptions too high" | Prevent accidental unlimited |

**Implementation Pattern:**
```javascript
const LIMITS = {
  CART_ITEM_QUANTITY: 100,
  CART_ITEMS_COUNT: 50,
  PROMO_CODE_LENGTH: 20,
  REVIEW_TEXT_LENGTH: 2000,
  MAX_PRICE_CENTS: 99999999,
};

function validateMaxValue(field, value, max) {
  if (value > max) {
    throw new ValidationError(`${field} exceeds maximum (${max})`);
  }
}
```

---

### 1.3 Minimum Values (zero, negative numbers, boundary conditions)

#### Zero Values

| Field | Zero Allowed? | Handling |
|-------|---------------|----------|
| Cart quantity | No | 400 "Quantity must be at least 1" |
| Product price | No | 400 "Price must be positive" |
| Discount percent | No | 400 "Discount must be at least 1%" |
| Min order value | Yes | 0 means no minimum |
| Max redemptions | No | null means unlimited, 0 invalid |
| Rating | No | 400 "Rating must be 1-5" |

#### Negative Numbers

| Field | Handling | Test Case |
|-------|----------|-----------|
| Quantity: -1 | 400 "Quantity must be positive" | `quantity: -1` |
| Price: -100 | 400 "Price must be positive" | `price: -100` |
| Discount: -10 | 400 "Discount must be 1-100" | `discount_percent: -10` |
| Rating: -1 | 400 "Rating must be 1-5" | `rating: -1` |

#### Boundary Conditions

| Scenario | Value | Expected |
|----------|-------|----------|
| Rating exactly 1 | `rating: 1` | Valid (minimum) |
| Rating exactly 5 | `rating: 5` | Valid (maximum) |
| Discount exactly 1% | `discount_percent: 1` | Valid (minimum) |
| Discount exactly 100% | `discount_percent: 100` | Valid (free order) |
| Cart total exactly at minimum | `total = min_order_value` | Code valid |
| Cart total $0.01 below minimum | `total = min - 1` | Code invalid |

**Implementation Pattern:**
```javascript
function validatePositive(field, value) {
  if (typeof value !== 'number' || value <= 0) {
    throw new ValidationError(`${field} must be a positive number`);
  }
}

function validateRange(field, value, min, max) {
  if (value < min || value > max) {
    throw new ValidationError(`${field} must be between ${min} and ${max}`);
  }
}
```

---

### 1.4 Special Characters (Unicode, emoji, SQL injection, XSS)

#### Unicode & Emoji Handling

| Field | Allowed? | Handling | Example |
|-------|----------|----------|---------|
| Customer name | Yes (Unicode) | Store as-is | "José García" ✓ |
| Review text | Yes (Unicode + emoji) | Store as-is | "Great honey! 🍯" ✓ |
| Promo code | No (alphanumeric only) | 400 "Invalid characters" | "SAVE🎉10" ✗ |
| Address | Yes (Unicode) | Store as-is | "北京市朝阳区" ✓ |
| Email | Limited charset | Standard email validation | RFC 5322 compliant |

#### SQL Injection Prevention

| Attack Vector | Input | Handling |
|---------------|-------|----------|
| Code field | `'; DROP TABLE promo_codes; --` | Firestore parameterized queries (safe) |
| Name field | `Robert'); DROP TABLE users; --` | Firestore doesn't use SQL (safe) |
| Search | `" OR 1=1 --` | Firestore doesn't use SQL (safe) |

**Firestore Safety:** NoSQL database doesn't use SQL queries. All operations use parameterized document references. SQL injection not applicable but input still sanitized for other reasons.

#### XSS Prevention

| Field | Risk | Mitigation |
|-------|------|------------|
| Review text (display) | High | HTML escape on render |
| Customer name (display) | Medium | HTML escape on render |
| Promo code (display) | Low | Alphanumeric only |
| Admin notes | Medium | HTML escape on render |

**Implementation Pattern:**
```javascript
// Promo code validation (alphanumeric only)
function validatePromoCodeFormat(code) {
  if (!/^[A-Z0-9]+$/i.test(code)) {
    throw new ValidationError('Code must be alphanumeric only');
  }
}

// XSS prevention on output (React auto-escapes, but be explicit)
function sanitizeForDisplay(text) {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
```

---

### 1.5 Type Mismatches (string as number, null as object)

#### Common Type Mismatches

| Field | Expected | Invalid Input | Handling |
|-------|----------|---------------|----------|
| quantity | number | `"5"` (string) | Coerce to number or 400 |
| quantity | number | `"five"` | 400 "Quantity must be a number" |
| price | number | `"19.99"` | Coerce to number (cents) |
| active | boolean | `"true"` | Coerce to boolean |
| active | boolean | `1` | Coerce to boolean |
| expires_at | timestamp | `"tomorrow"` | 400 "Invalid date format" |
| items | array | `{}` | 400 "Items must be an array" |
| items | array | `null` | 400 "Items required" |

**Implementation Pattern:**
```javascript
function coerceNumber(value, field) {
  if (typeof value === 'number') return value;
  if (typeof value === 'string') {
    const parsed = Number(value);
    if (isNaN(parsed)) {
      throw new ValidationError(`${field} must be a valid number`);
    }
    return parsed;
  }
  throw new ValidationError(`${field} must be a number`);
}

function validateType(value, expectedType, field) {
  const actualType = Array.isArray(value) ? 'array' : typeof value;
  if (actualType !== expectedType) {
    throw new ValidationError(`${field} must be ${expectedType}, got ${actualType}`);
  }
}
```

---

## Category 2: State Transition Cases

### 2.1 Invalid State Transitions

#### Order Status Transitions

```
Valid transitions:
  pending → confirmed → shipped → delivered
  pending → canceled
  confirmed → canceled
  confirmed → refunded (after payment)
  shipped → delivered
  delivered → (terminal state)
  canceled → (terminal state)
  refunded → (terminal state)

Invalid transitions (must reject):
  canceled → confirmed  (can't resurrect canceled order)
  canceled → shipped    (can't ship canceled order)
  refunded → confirmed  (can't un-refund)
  delivered → shipped   (can't go backwards)
  shipped → pending     (can't go backwards)
```

| Current State | Attempted State | Handling |
|---------------|-----------------|----------|
| canceled | confirmed | 400 "Cannot modify canceled order" |
| refunded | shipped | 400 "Cannot ship refunded order" |
| delivered | any | 400 "Order already delivered" |
| pending | delivered | 400 "Order must be shipped first" |

**Implementation Pattern:**
```javascript
const VALID_TRANSITIONS = {
  pending: ['confirmed', 'canceled'],
  confirmed: ['shipped', 'canceled', 'refunded'],
  shipped: ['delivered'],
  delivered: [],
  canceled: [],
  refunded: [],
};

function validateStateTransition(currentState, newState) {
  const allowed = VALID_TRANSITIONS[currentState] || [];
  if (!allowed.includes(newState)) {
    throw new ValidationError(
      `Cannot transition from ${currentState} to ${newState}`
    );
  }
}
```

#### Reservation Status Transitions

```
Valid:
  active → completing → completed
  active → expired (by cleanup job)
  active → admin_cancelled (by admin)
  completing → completed (payment succeeded)
  completing → active (payment failed, restore)

Invalid:
  expired → active (can't resurrect)
  completed → active (can't undo order)
  admin_cancelled → active (can't restore without new reservation)
```

#### Review Status Transitions

```
Valid:
  pending_moderation → approved
  pending_moderation → rejected
  approved → hidden (admin action)
  approved → edited (customer edit, re-moderation)

Invalid:
  rejected → approved (must re-submit as new review)
  hidden → approved (admin must explicitly unhide)
```

---

### 2.2 Race Conditions on State Changes

#### Concurrent Order Status Updates

| Scenario | Race Condition | Resolution |
|----------|----------------|------------|
| Admin cancels while shipping | Both try to update status | Transaction: first wins, second sees conflict |
| Two admins ship same order | Duplicate shipping label risk | Status check in transaction, second fails |
| Refund while customer requests cancel | Both valid but conflicting | First to commit wins |

**Implementation Pattern:**
```javascript
async function updateOrderStatus(orderId, newStatus, userId) {
  return firestore.runTransaction(async (transaction) => {
    const orderRef = firestore.doc(`orders/${orderId}`);
    const order = await transaction.get(orderRef);

    if (!order.exists) throw new Error('Order not found');

    const currentStatus = order.data().status;
    validateStateTransition(currentStatus, newStatus);

    transaction.update(orderRef, {
      status: newStatus,
      status_updated_at: FieldValue.serverTimestamp(),
      status_updated_by: userId,
    });

    return { previousStatus: currentStatus, newStatus };
  });
}
```

#### Concurrent Inventory Updates

| Scenario | Race Condition | Resolution |
|----------|----------------|------------|
| Two customers reserve last unit | Both see available = 1 | Transaction conflict, retry, loser sees 0 |
| Admin updates while customer reserves | Quantity changes mid-reservation | Transaction ensures consistency |
| Cleanup job + payment complete | Both try to release reservation | Idempotent: status check first |

---

### 2.3 State Persistence Failures (DB write fails mid-transition)

#### Partial Write Scenarios

| Operation | Failure Point | State After Failure | Recovery |
|-----------|---------------|---------------------|----------|
| Create order | After payment, before order write | Payment exists, no order | Webhook retry creates order |
| Reserve inventory | After reservation, before quantity update | Reservation orphaned | Cleanup job releases |
| Apply discount | After usage record, before order | Usage exists, no order | Order creation checks existing usage |
| Ship order | After status update, before shipping label | Status = shipped, no label | Admin manually creates label |

**Transaction Guarantees:**
```javascript
// All-or-nothing order creation
async function createOrder(paymentIntentId) {
  return firestore.runTransaction(async (transaction) => {
    // All reads first
    const reservation = await transaction.get(reservationRef);
    const products = await Promise.all(productRefs.map(r => transaction.get(r)));

    // All writes together (atomic)
    transaction.create(orderRef, orderData);
    transaction.delete(reservationRef);
    products.forEach((prod, i) => {
      transaction.update(productRefs[i], {
        quantity: FieldValue.increment(-items[i].quantity),
        reserved_quantity: FieldValue.increment(-items[i].quantity),
      });
    });

    // If any write fails, all roll back
  });
}
```

---

### 2.4 Orphaned States

#### Orphan Scenarios

| Orphan Type | How Created | Detection | Cleanup |
|-------------|-------------|-----------|---------|
| Reservation without order | Customer abandons checkout | expires_at < now | Background job every 5 min |
| Payment intent without order | Webhook never delivered | Stripe dashboard check | Manual order creation |
| Usage record without order | Transaction failed mid-way | order_id = null | Cleanup job deletes orphans |
| Order without payment | Should never happen | payment_intent_id = null | Alert + investigation |
| Review without order | Order deleted after review | order_id foreign key missing | Keep review, mark order_deleted |

**Orphan Detection Queries:**
```javascript
// Find reservations that should be cleaned up
const orphanedReservations = await firestore
  .collection('reservations')
  .where('status', '==', 'active')
  .where('expires_at', '<', now)
  .get();

// Find usage records without orders (orphaned)
const orphanedUsage = await firestore
  .collection('promo_code_usage')
  .where('order_id', '==', null)
  .where('created_at', '<', oneHourAgo)
  .get();
```

---

### 2.5 Recovery from Partial State

#### Rollback Scenarios

| Scenario | Partial State | Rollback Action |
|----------|---------------|-----------------|
| Payment failed after reservation | Reservation exists, no order | Reservation expires naturally (15 min) |
| Inventory update failed | reserved_quantity inconsistent | Recalculate from reservations collection |
| Promo code update failed | used_count wrong | Recalculate from usage records |
| Email send failed | Order exists, no email | Retry queue, admin can resend |

**Reconciliation Pattern:**
```javascript
// Reconcile reserved_quantity from actual reservations
async function reconcileReservedQuantity(productId) {
  const activeReservations = await firestore
    .collection('reservations')
    .where('status', '==', 'active')
    .get();

  let calculatedReserved = 0;
  activeReservations.forEach(res => {
    const item = res.data().items.find(i => i.product_id === productId);
    if (item) calculatedReserved += item.quantity;
  });

  const product = await firestore.doc(`products/${productId}`).get();
  const storedReserved = product.data().reserved_quantity;

  if (calculatedReserved !== storedReserved) {
    console.warn(`Mismatch: stored=${storedReserved}, calculated=${calculatedReserved}`);
    await firestore.doc(`products/${productId}`).update({
      reserved_quantity: calculatedReserved,
      reconciled_at: FieldValue.serverTimestamp(),
    });
  }
}
```

---

## Category 3: Timing Cases

### 3.1 Timeouts (network, database, external API)

#### Timeout Configuration

| Operation | Timeout | On Timeout |
|-----------|---------|------------|
| Firestore read | 10s | Retry with backoff |
| Firestore transaction | 30s | Transaction aborts, retry |
| Stripe API call | 30s | Return 504, client retries |
| Webhook processing | 30s | Return 500, Stripe retries |
| Email send | 10s | Queue for retry |
| Background job total | 5 min | Cloud Run terminates |

#### Timeout Handling Matrix

| Component | Timeout Scenario | User Impact | Resolution |
|-----------|------------------|-------------|------------|
| Checkout reservation | Firestore slow | "Please wait..." spinner | Auto-retry 3x |
| Payment intent | Stripe timeout | "Payment system slow" | Manual retry button |
| Order creation | Transaction timeout | No order (yet) | Webhook retry |
| Promo validation | Query timeout | "Try again" | Auto-retry |
| Review submit | Write timeout | "Submitting..." | Auto-retry |

---

### 3.2 Expiration Scenarios

#### Expiration Types

| What Expires | TTL | Detection | Consequence |
|--------------|-----|-----------|-------------|
| Reservation | 15 min | expires_at < now | Inventory released |
| Promo code | Set by admin | expires_at < now | 5-min grace, then reject |
| JWT session | 30 min | token.exp < now | Re-auth required |
| Password reset token | 1 hour | expires_at < now | Request new token |
| Stripe PaymentIntent | 24 hours | Stripe expires it | Customer must restart |

#### Edge Cases at Expiration Boundary

| Scenario | Timing | Handling |
|----------|--------|----------|
| Reservation expires during payment | Payment at T+14:59, order at T+15:01 | "completing" status prevents cleanup |
| Promo expires at midnight | Apply 23:58, pay 00:03 | 5-min grace period allows |
| Session expires during Stripe checkout | Customer on Stripe page at expiry | Webhook creates order anyway |
| Multiple expirations simultaneously | Reservation + promo both expire | Validate both, fail-fast |

---

### 3.3 Clock Skew (server time vs client time, timezones)

#### Server Time Authority

| Scenario | Issue | Solution |
|----------|-------|----------|
| Client time ahead | Sees "expired" when still valid | Server validates, client displays |
| Client time behind | Thinks valid when expired | Server is authority |
| Server cluster skew | Different servers disagree | Use Firestore server timestamp |
| Timezone confusion | "Expires midnight" ambiguous | Store as UTC, display in user TZ |

**Implementation:**
```javascript
// Always use server timestamp for expiration checks
const expires_at = FieldValue.serverTimestamp();

// Display in user's timezone (frontend)
function formatExpiration(utcTimestamp, userTimezone) {
  return new Intl.DateTimeFormat('en-US', {
    timeZone: userTimezone,
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(utcTimestamp);
}
```

---

### 3.4 Daylight Saving Time Transitions

#### DST Edge Cases

| Scenario | Issue | Example |
|----------|-------|---------|
| Spring forward (lose hour) | 2 AM doesn't exist | Promo expires "March 10, 2 AM" → skipped |
| Fall back (repeat hour) | 2 AM happens twice | Which 2 AM? |
| User in different DST zone | Admin sets expiry in EST, user in PST | Use UTC storage |

**Resolution:**
- Store all timestamps in UTC
- Display in local timezone
- DST transitions are 1 hour max discrepancy
- 5-min grace period covers DST confusion

```javascript
// Store expiration as end-of-day UTC
function setExpirationEndOfDay(date, adminTimezone) {
  const localEndOfDay = new Date(date);
  localEndOfDay.setHours(23, 59, 59, 999);

  // Convert to UTC
  return localEndOfDay.toISOString();
}
```

---

### 3.5 Concurrent Operations

#### User + User Concurrency

| Scenario | Conflict | Resolution |
|----------|----------|------------|
| Two users checkout last item | Inventory race | Transaction, first wins |
| Two users use last code redemption | Usage race | Over-redemption accepted |
| Two users edit same review | Shouldn't happen | One user per review |

#### User + Background Job Concurrency

| Scenario | Conflict | Resolution |
|----------|----------|------------|
| User pays while cleanup runs | Reservation might be released | "completing" status blocks cleanup |
| User applies code while admin deactivates | Code might become invalid | Validate at payment intent |
| User submits review while moderation runs | New review enters queue | FIFO processing |

#### Background Job + Background Job Concurrency

| Scenario | Conflict | Resolution |
|----------|----------|------------|
| Two cleanup instances run | Same reservation processed twice | Idempotent: check status first |
| Cleanup + reconciliation | Both modify reserved_quantity | Reconciliation runs less frequently |
| Email retry + new email | Duplicate emails possible | Idempotent: check email_sent flag |

---

## Category 4: Integration Cases

### 4.1 External Service Down

#### Stripe Down

| Scenario | Detection | Fallback | Customer Message |
|----------|-----------|----------|------------------|
| API unreachable | Connection timeout | None (critical path) | "Payment system unavailable" |
| Webhook endpoint down | Our side down | Stripe retries for 3 days | N/A (async) |
| Dashboard inaccessible | Admin can't refund | Wait or use API | N/A (admin) |

**Stripe Outage Handling:**
```javascript
async function createPaymentIntent(data) {
  try {
    return await stripe.paymentIntents.create(data);
  } catch (error) {
    if (error.type === 'StripeConnectionError') {
      // Log and alert
      logger.critical('Stripe connection failed', { error });
      alertOps('Stripe appears to be down');
      throw new ServiceUnavailableError('Payment system temporarily unavailable');
    }
    throw error;
  }
}
```

#### Mailgun Down

| Scenario | Detection | Fallback | Impact |
|----------|-----------|----------|--------|
| API unreachable | Connection timeout | Queue for retry | Delayed emails |
| Rate limited | 429 response | Exponential backoff | Delayed emails |
| Quota exceeded | 402 response | Alert admin | No emails until resolved |

**Email Fallback:**
```javascript
async function sendEmail(email) {
  try {
    await mailgun.send(email);
    return { sent: true };
  } catch (error) {
    // Queue for retry
    await firestore.collection('email_queue').add({
      email,
      attempts: 0,
      next_retry: new Date(Date.now() + 5 * 60 * 1000),
      error: error.message,
    });
    return { sent: false, queued: true };
  }
}
```

#### Firestore Down

| Scenario | Detection | Fallback | Impact |
|----------|-----------|----------|--------|
| Complete outage | All operations fail | None (critical) | Site down |
| Partial outage | Some regions affected | Multi-region config | Degraded |
| Quota exceeded | 429 errors | Alert + wait | Site slow/down |

**Note:** Firestore outage = site outage. No reasonable fallback for MVP. Monitor Firestore health.

---

### 4.2 External Service Slow

#### Slow Response Handling

| Service | Normal Latency | Slow Threshold | Action at Threshold |
|---------|----------------|----------------|---------------------|
| Stripe | 200-400ms | > 2s | Log warning, continue |
| Stripe | 200-400ms | > 10s | Timeout, show retry |
| Mailgun | 100-300ms | > 5s | Queue for async |
| Firestore | 20-100ms | > 1s | Log warning |
| Firestore | 20-100ms | > 5s | Alert, possible outage |

**Slow Service Detection:**
```javascript
async function timedFetch(operation, warningThreshold, errorThreshold) {
  const start = Date.now();
  try {
    const result = await operation();
    const duration = Date.now() - start;

    if (duration > errorThreshold) {
      logger.error(`Operation exceeded error threshold: ${duration}ms`);
    } else if (duration > warningThreshold) {
      logger.warn(`Operation slow: ${duration}ms`);
    }

    return result;
  } catch (error) {
    const duration = Date.now() - start;
    logger.error(`Operation failed after ${duration}ms`, { error });
    throw error;
  }
}
```

---

### 4.3 External Service Rate Limiting

#### Rate Limit Responses

| Service | Rate Limit | Detection | Handling |
|---------|------------|-----------|----------|
| Stripe | 100 req/sec | 429 response | Exponential backoff |
| Mailgun | 300 req/min | 429 response | Queue and throttle |
| Firestore | 10k writes/sec | 429 response | Unlikely to hit for MVP |

**Backoff Strategy:**
```javascript
async function withBackoff(operation, maxRetries = 5) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      if (error.status === 429 && attempt < maxRetries) {
        const delay = Math.pow(2, attempt) * 1000 + Math.random() * 1000;
        logger.warn(`Rate limited, retrying in ${delay}ms`);
        await sleep(delay);
        continue;
      }
      throw error;
    }
  }
}
```

---

### 4.4 Webhook Delivery Failures

#### Stripe Webhook Retry Schedule

| Attempt | Delay After Previous | Total Time |
|---------|---------------------|------------|
| 1 | Immediate | 0 |
| 2 | 1 minute | 1 min |
| 3 | 5 minutes | 6 min |
| 4 | 30 minutes | 36 min |
| 5 | 2 hours | 2.6 hours |
| ... | Continues | Up to 3 days |

#### Webhook Failure Scenarios

| Failure | Stripe Behavior | Our Response |
|---------|-----------------|--------------|
| 500 error | Retry | Fix bug, wait for retry |
| 502/503 | Retry | Infra issue, auto-recover |
| Timeout (30s) | Retry | Optimize processing |
| 404 | Stop retrying | Misconfigured endpoint |
| Invalid signature | Stop retrying | Security issue, investigate |

**Idempotent Webhook Processing:**
```javascript
async function handleStripeWebhook(event) {
  // Check if already processed
  const existing = await firestore
    .collection('processed_webhooks')
    .doc(event.id)
    .get();

  if (existing.exists) {
    logger.info(`Webhook ${event.id} already processed`);
    return { status: 200, message: 'Already processed' };
  }

  // Process webhook
  await processPaymentSuccess(event);

  // Mark as processed
  await firestore.collection('processed_webhooks').doc(event.id).set({
    processed_at: FieldValue.serverTimestamp(),
    event_type: event.type,
  });

  return { status: 200, message: 'Processed' };
}
```

---

### 4.5 API Version Mismatches

#### Stripe API Versioning

| Risk | Scenario | Prevention |
|------|----------|------------|
| Breaking change | New Stripe version changes response format | Pin API version in SDK |
| Deprecated field | Field we use becomes deprecated | Monitor Stripe changelog |
| New required field | Stripe requires field we don't send | Test before upgrading |

**Version Pinning:**
```javascript
const stripe = require('stripe')('sk_...', {
  apiVersion: '2023-10-16', // Pin to specific version
});

// Monitor for version updates
// Set calendar reminder to review quarterly
```

#### Firestore SDK Versioning

| Risk | Scenario | Prevention |
|------|----------|------------|
| Breaking change | SDK upgrade changes API | Test in staging first |
| Deprecated method | Method we use becomes deprecated | Monitor release notes |

**Best Practice:**
- Pin dependencies in package.json
- Review changelogs before upgrading
- Test in staging environment
- Keep upgrade window quarterly

---

## Summary: Edge Case Coverage

### Data Boundary Cases ✅
- [x] Empty inputs: All fields validated for null/empty
- [x] Maximum values: Limits defined for all numeric/string fields
- [x] Minimum values: Zero/negative handling specified
- [x] Special characters: Unicode allowed, SQL/XSS prevented
- [x] Type mismatches: Coercion and validation defined

### State Transition Cases ✅
- [x] Invalid transitions: State machine defined for orders/reservations/reviews
- [x] Race conditions: Transaction-based resolution
- [x] Persistence failures: All-or-nothing transactions
- [x] Orphaned states: Detection queries and cleanup jobs
- [x] Partial state recovery: Reconciliation patterns

### Timing Cases ✅
- [x] Timeouts: All operations have timeout + handling
- [x] Expiration: All expirable entities covered
- [x] Clock skew: Server timestamp authority
- [x] DST transitions: UTC storage + grace period
- [x] Concurrent operations: All conflict scenarios mapped

### Integration Cases ✅
- [x] Service down: Fallbacks for each external service
- [x] Service slow: Thresholds and degraded operation
- [x] Rate limiting: Backoff strategies
- [x] Webhook failures: Idempotent processing + retry handling
- [x] Version mismatches: Version pinning + upgrade process

---

**Last Updated:** 2026-01-24
**Stage:** L3 - Phase 2
**Status:** ✅ Complete - 100% framework coverage
