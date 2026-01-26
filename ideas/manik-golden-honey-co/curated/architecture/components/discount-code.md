# Component: Discount Code

## Overview

Percentage-based discount codes with configurable restrictions. Order-wide only (ADR-004), locked at PaymentIntent creation (ADR-012) with 5-minute grace period for expiration.

**Key capabilities:**
- Admin code creation and management
- Real-time validation at checkout
- Usage tracking and one-time-per-customer enforcement
- Grace period for codes expiring during checkout

## Design

### Triple Validation
1. **Application time (read-only):** Check exists, active, not expired, minimum order
2. **PaymentIntent creation:** Re-validate, lock discount in metadata
3. **Order creation:** Trust locked value, increment usage atomically

### Data Model
```typescript
promo_codes: {
  code: string,              // Unique, uppercase
  discount_percentage: number, // 1-100
  min_order_value: number | null,
  max_redemptions: number | null,
  one_time_per_customer: boolean,
  used_count: number,        // Denormalized
  active: boolean,
  expires_at: timestamp | null
}

promo_code_usage: {
  code: string,
  customer_id: string,
  order_id: string,
  discount_amount: number,
  redeemed_at: timestamp
}
```

### Lock-In Strategy
```
1. Customer applies code → validate, show discount preview
2. Customer clicks pay → create PaymentIntent with metadata:
   { promo_code, discount_percentage, discount_amount }
3. Order creation → use locked values, increment used_count
```

**Why lock at PaymentIntent:** Prevents price mismatch between what customer sees and what they're charged.

## Implementation Details

### Grace Period Logic
```javascript
if (code.expires_at < now) {
  const graceDeadline = code.expires_at + 5 * 60 * 1000; // 5 min
  if (now <= graceDeadline) {
    return { valid: true, within_grace: true };
  }
  return { valid: false, error: "Code expired" };
}
```

### Over-Redemption Handling
```javascript
// At order creation, if max_redemptions exceeded due to race:
if (used_count >= max_redemptions) {
  console.warn(`Over-redemption: ${code}`);
  // Continue anyway - customer already paid with discount
}
transaction.update(codeRef, { used_count: increment(1) });
```

**Rationale:** Better to honor discount than refund customer.

## Edge Cases

**Cart changes after code applied:**
- Customer removes item, now below minimum
- Frontend shows warning: "Add $X more to keep discount"
- Backend enforces at PaymentIntent creation

**Admin deactivates during checkout:**
- In-flight PaymentIntents with locked code: honored
- New code applications: rejected

**Multiple tabs applying same code:**
- First to complete payment succeeds
- Second fails: "Code already used"

## Failure Modes

**High redemption velocity (viral code):**
- Alert on >50 redemptions/hour
- Admin can deactivate immediately
- In-flight checkouts still honored

**Over-redemption rate high:**
- Monitor: alert if >10% over max_redemptions
- Acceptable cost: ~$50-150 per incident
- Alternative: reject (worse UX)

## Performance Targets

| Metric | Target |
|--------|--------|
| Code validation P95 | <100ms |
| PaymentIntent with code P95 | <700ms |
| Usage increment P95 | <200ms |
