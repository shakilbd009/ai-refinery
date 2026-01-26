# Timing Edge Cases

Timeouts, expiration, clock skew, DST handling, and concurrent operations.

---

## Timeouts

### Timeout Configuration

| Operation | Timeout | On Timeout |
|-----------|---------|------------|
| Firestore read | 10s | Retry with backoff |
| Firestore transaction | 30s | Transaction aborts, retry |
| Stripe API call | 30s | Return 504, client retries |
| Webhook processing | 30s | Return 500, Stripe retries |
| Email send | 10s | Queue for retry |
| Background job total | 5 min | Cloud Run terminates |

### Timeout Handling Matrix

| Component | Timeout Scenario | User Impact | Resolution |
|-----------|------------------|-------------|------------|
| Checkout reservation | Firestore slow | "Please wait..." spinner | Auto-retry 3x |
| Payment intent | Stripe timeout | "Payment system slow" | Manual retry button |
| Order creation | Transaction timeout | No order (yet) | Webhook retry |
| Promo validation | Query timeout | "Try again" | Auto-retry |
| Review submit | Write timeout | "Submitting..." | Auto-retry |

---

## Expiration Scenarios

### Expiration Types

| What Expires | TTL | Detection | Consequence |
|--------------|-----|-----------|-------------|
| Reservation | 15 min | expires_at < now | Inventory released |
| Promo code | Set by admin | expires_at < now | 5-min grace, then reject |
| JWT session | 30 min | token.exp < now | Re-auth required |
| Password reset token | 1 hour | expires_at < now | Request new token |
| Stripe PaymentIntent | 24 hours | Stripe expires it | Customer must restart |

### Edge Cases at Expiration Boundary

| Scenario | Timing | Handling |
|----------|--------|----------|
| Reservation expires during payment | Payment at T+14:59, order at T+15:01 | "completing" status prevents cleanup |
| Promo expires at midnight | Apply 23:58, pay 00:03 | 5-min grace period allows |
| Session expires during Stripe checkout | Customer on Stripe page at expiry | Webhook creates order anyway |
| Multiple expirations simultaneously | Reservation + promo both expire | Validate both, fail-fast |

---

## Clock Skew

### Server Time Authority

| Scenario | Issue | Solution |
|----------|-------|----------|
| Client time ahead | Sees "expired" when still valid | Server validates, client displays |
| Client time behind | Thinks valid when expired | Server is authority |
| Server cluster skew | Different servers disagree | Use Firestore server timestamp |
| Timezone confusion | "Expires midnight" ambiguous | Store as UTC, display in user TZ |

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

## Daylight Saving Time Transitions

### DST Edge Cases

| Scenario | Issue | Example |
|----------|-------|---------|
| Spring forward (lose hour) | 2 AM doesn't exist | Promo expires "March 10, 2 AM" - skipped |
| Fall back (repeat hour) | 2 AM happens twice | Which 2 AM? |
| User in different DST zone | Admin sets expiry in EST, user in PST | Use UTC storage |

### Resolution

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

## Concurrent Operations

### User + User Concurrency

| Scenario | Conflict | Resolution |
|----------|----------|------------|
| Two users checkout last item | Inventory race | Transaction, first wins |
| Two users use last code redemption | Usage race | Over-redemption accepted |
| Two users edit same review | Shouldn't happen | One user per review |

### User + Background Job Concurrency

| Scenario | Conflict | Resolution |
|----------|----------|------------|
| User pays while cleanup runs | Reservation might be released | "completing" status blocks cleanup |
| User applies code while admin deactivates | Code might become invalid | Validate at payment intent |
| User submits review while moderation runs | New review enters queue | FIFO processing |

### Background Job + Background Job Concurrency

| Scenario | Conflict | Resolution |
|----------|----------|------------|
| Two cleanup instances run | Same reservation processed twice | Idempotent: check status first |
| Cleanup + reconciliation | Both modify reserved_quantity | Reconciliation runs less frequently |
| Email retry + new email | Duplicate emails possible | Idempotent: check email_sent flag |
