# ADR-012: Discount Code Lock-In at Payment Intent

## Status

Accepted

---

## Context

Discount codes have time-sensitive properties that can change during checkout:

1. **Expiration timing:** Code expires while customer entering card details
2. **Admin modification:** Admin changes discount percentage mid-checkout
3. **Max redemptions reached:** Code hits limit between validation and payment

**Customer checkout timeline:**
```
T+0:  Customer applies "SAVE10" (10% off, expires 11:59 PM)
T+1:  Validation succeeds, shows $5 discount
T+2:  Customer enters shipping address (2 min)
T+4:  Customer enters card details (3 min)
T+5:  Customer clicks "Pay Now"
      Code might have: expired, changed to 5%, or hit max redemptions
```

**Key problems:**
1. Trust issue: Customer saw 10% discount, expects to pay discounted price
2. Stripe payment intent: Amount locked when created (can't change retroactively)
3. UX confusion: Code invalid at payment but was valid at application

---

## Decision

**Lock discount at payment intent creation. Once PaymentIntent created, honor locked discount at order creation.**

**Core mechanism:**
1. **Application time:** Validate code, show discount (informational)
2. **Payment intent creation:** Re-validate code, lock discount in metadata
3. **Order creation:** Use locked discount from metadata (no re-validation for expiration/percentage)
4. **Exception:** Still check max_redemptions (accept over-redemption if race occurs)

**Grace period for expiration:**
- 5-minute grace period after expiration
- Within grace: Code accepted (customer already in checkout)
- Beyond grace: Code rejected at payment intent creation

**Locked metadata fields:**
```
PaymentIntent.metadata:
  promo_code: "SAVE10"
  discount_percent: 10       // Locked value at intent creation
  discount_amount: 500       // In cents
  discount_locked: true      // Flag indicating lock-in
  validation_time: timestamp
```

---

## Consequences

### Positive

- **Customer trust:** Price shown = price charged (no surprises)
- **Clear semantics:** Validation at payment intent = commitment
- **No retroactive changes:** Customer can't be charged more after seeing price
- **Admin safety:** Code changes don't affect in-flight checkouts
- **Simple implementation:** Payment intent metadata holds truth
- **Grace period:** Reduces friction for near-expiration codes

### Negative

- **Over-redemption possible:** Max redemptions not enforced strictly (race condition)
- **Admin confusion:** Code change doesn't affect active checkouts (delayed impact)
- **Slight staleness:** Customer might get expired code within grace period
- **Testing complexity:** Must simulate time-based scenarios

### Trade-offs

- Payment intent creation becomes source of truth (not application time)
- Re-validation at order creation only for max_redemptions (selective check)
- Grace period arbitrary (5 min chosen, adjustable based on checkout duration data)

---

## Alternatives Considered

### Re-Validate at Order Creation (Strict Enforcement)

Rejected because: Customer charged wrong amount (payment intent created with discount, order without), Stripe limitation (can't change payment intent amount after authorization), trust violation (customer approved $45 charge, sees $50 order), requires complex refund handling.

### Reserve Discount Slot at Application Time

Rejected because: Increased complexity (another reservation system beyond inventory), abandoned carts leave reserved slots, requires background cleanup job, over-engineering when lock-in + accept-over-redemption solves the problem.

### No Grace Period (Strict Expiration)

Rejected because: Poor UX (customer enters checkout at 11:58 PM, pays at 12:02 AM - rejected), lost sales from abandoned carts, support burden near midnight, time zone confusion between customer and server.

### Lock at Application Time (Not Payment Intent)

Rejected because: No payment commitment yet (customer hasn't initiated payment), abandoned carts have locked discounts, admin can't fix mistakes mid-checkout, payment intent still source of truth for Stripe amount.
