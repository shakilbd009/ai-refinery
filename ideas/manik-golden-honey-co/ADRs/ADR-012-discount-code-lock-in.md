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
1. **Trust issue:** Customer saw 10% discount, expects to pay discounted price
2. **Stripe payment intent:** Amount locked when created (can't change retroactively)
3. **UX confusion:** What if code invalid at payment but was valid at application?

**Key factors:**
- Customer expects price shown = price charged (trust)
- Stripe payment intent amount immutable (technical constraint)
- Admin might correct mistakes (change discount percentage)
- Code expiration likely near midnight (time zone confusion)

**Why this decision needed now:**
Discount code handling affects customer trust and payment accuracy. Wrong approach causes support tickets, refunds, and lost customers. Must resolve before implementation.

---

## Decision

**Lock discount at payment intent creation. Once PaymentIntent created, honor locked discount at order creation.**

**Core mechanism:**
1. **Application time:** Validate code, show discount (informational)
2. **Payment intent creation:** Re-validate code, lock discount in metadata
3. **Order creation:** Use locked discount from metadata (no re-validation for expiration/percentage)
4. **Exception:** Still check max_redemptions (accept over-redemption if race occurs)

**Grace period for expiration:**
- 5-minute grace period after expiration (balance customer trust vs business rules)
- Within grace: Code accepted (customer already in checkout)
- Beyond grace: Code rejected at payment intent creation (before customer pays)

**Locked metadata fields:**
```
PaymentIntent.metadata:
  promo_code: "SAVE10"
  discount_percent: 10  // Locked value at intent creation
  discount_amount: 500  // In cents
  discount_locked: true  // Flag indicating lock-in
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
- **Grace period:** Reduces friction for near-expiration codes (5-min buffer)

### Negative

- **Over-redemption possible:** Max redemptions not enforced strictly (race condition)
- **Admin confusion:** Code change doesn't affect active checkouts (delayed impact)
- **Slight staleness:** Customer might get expired code within grace period
- **Testing complexity:** Must simulate time-based scenarios (expiration, grace period)

### Neutral

- Payment intent creation becomes source of truth (not application time)
- Re-validation at order creation only for max_redemptions (selective check)
- Grace period arbitrary (5 min chosen, could be 2 or 10)

---

## Alternatives Considered

### Alternative 1: Re-Validate at Order Creation (Strict Enforcement)

**Why considered:**
- No over-redemption (strict max_redemptions)
- Admin changes take effect immediately (no grace period)
- Always current (no stale discounts)

**Why rejected:**
- **Customer charged wrong amount:** Payment intent created with discount, order created without
- **Stripe limitation:** Can't change payment intent amount after customer authorized
- **Trust violation:** Customer approved $45 charge, sees $50 order confirmation
- **Refund complexity:** Must refund difference, explain to customer (bad UX)

### Alternative 2: Reserve Discount Slot at Application Time

**Why considered:**
- Prevents over-redemption (reserve slot like inventory)
- Customer guaranteed discount (no race on max_redemptions)
- Clear state machine (reserved → redeemed)

**Why rejected:**
- **Increased complexity:** Another reservation system (beyond inventory)
- **Abandoned carts:** Reserved slots never released (customer doesn't checkout)
- **Background cleanup needed:** Expire discount reservations (more jobs)
- **Over-engineering:** Problem already solved by lock-in + accept-over-redemption

### Alternative 3: No Grace Period (Strict Expiration)

**Why considered:**
- Simpler logic (expired = rejected, no special cases)
- Clear business rules (midnight means midnight)
- No ambiguity (code either valid or not)

**Why rejected:**
- **Poor UX:** Customer enters checkout at 11:58 PM, pays at 12:02 AM → rejected
- **Lost sales:** Customer abandons (code didn't work as expected)
- **Support burden:** "Code didn't work" tickets near midnight
- **Time zone confusion:** Customer's local time vs server time (admin set expiration)
- **Not customer-centric:** Penalizes slow customers (entering card details carefully)

### Alternative 4: Lock at Application Time (Not Payment Intent)

**Why considered:**
- Earlier lock-in (less time for changes)
- Consistent discount throughout checkout
- Simpler to explain (code application = commitment)

**Why rejected:**
- **No payment commitment:** Customer hasn't initiated payment yet
- **Abandoned carts:** Discount locked but customer never pays
- **Admin can't fix mistakes:** Typo in discount % affects all applied codes until checkout
- **Payment intent still source of truth:** Stripe amount must match something (pick payment intent)

---

## Implementation Notes

**Payment intent creation with lock-in:**
```
POST /api/create-payment-intent

Request:
  {
    "reservation_id": "res_123",
    "promo_code": "SAVE10"
  }

Implementation:
  1. READ promo_code document
  2. VALIDATE code (with grace period):
       active == true
       expires_at >= now - 5 minutes (grace period)
       min_order_value <= cart_total

     IF validation fails:
       RETURN error (customer must remove code or fix cart)

  3. CALCULATE discount_amount = cart_total * (discount_percent / 100)

  4. CREATE Stripe PaymentIntent:
       amount = cart_total - discount_amount
       metadata:
         promo_code: code
         discount_percent: locked value
         discount_amount: locked value
         discount_locked: true
         validation_time: now

  5. RETURN payment_intent (customer proceeds to Stripe checkout)
```

**Grace period validation:**
```
FUNCTION validatePromoCode(code, validationTime):
  READ promo_code

  IF code.expires_at < validationTime:
    grace_period = 5 minutes
    IF validationTime <= code.expires_at + grace_period:
      // Within grace period, allow with metadata
      RETURN {
        valid: true,
        within_grace: true
      }
    ELSE:
      // Beyond grace, reject
      RETURN {
        valid: false,
        error: "Code expired"
      }

  RETURN { valid: true }
```

**Order creation (honor locked discount):**
```
createOrderFromPayment(payment_intent_id):
  1. Extract metadata from Stripe PaymentIntent
  2. IF metadata.discount_locked:
       // Honor locked discount (no re-validation for expiration)
       code = metadata.promo_code
       discount = metadata.discount_amount

       // ONLY check max_redemptions (not expiration/percentage)
       READ promo_code
       IF used_count >= max_redemptions:
         Log "Over-redemption (race condition)"
         // Still honor discount (customer already paid)

       INCREMENT promo_code.used_count
       CREATE promo_code_usage record

  3. CREATE order:
       promo_code: code
       discount_amount: locked discount
       total: payment_intent.amount (already discounted)
```

**Monitoring (grace period usage):**
```
Track metric:
  grace_period_redemptions = orders WHERE
    payment_intent.metadata.within_grace == true

Dashboard:
  Grace period redemptions: 15 (3% of total)

Alert if > 20%:
  "High grace period usage - consider extending code expiration"
```

---

## Success Criteria

**Customer Trust:**
- Zero "charged wrong amount" support tickets
- Zero refunds due to discount discrepancies
- Customer survey: 95%+ trust checkout pricing

**Business:**
- Over-redemption < 3% per code (max_redemptions race rare)
- Grace period usage < 10% (most customers checkout before expiration)
- Admin understands lock-in (no confusion about delayed code changes)

**Technical:**
- Payment intent metadata always includes discount (if code applied)
- Order creation never recalculates discount (uses locked value)
- Monitoring tracks grace period usage (data-driven grace period tuning)

**Edge Cases:**
- Code expires during payment → Honored within grace period (5 min)
- Admin changes discount → In-flight checkouts use locked value
- Max redemptions hit → Accept over-redemption (customer already paid)

---

## Review Date

**1 month post-launch** - Review grace period usage rate, over-redemption frequency, customer complaints. Adjust grace period (5 min) based on checkout duration distribution.

**Triggers for early review:**
- Grace period usage > 20% (extend expiration window)
- Over-redemption > 10% per code (tighten max_redemptions enforcement)
- Customer confusion about code lock-in (communication issue)
- Admin complaints about delayed code changes (workflow mismatch)

---

## References

- [discount-code-validation-L2.md](../stage-5/discount-code-validation-L2.md) - Detailed validation analysis (Q2)
- [Stripe PaymentIntent Metadata](https://stripe.com/docs/api/payment_intents/object#payment_intent_object-metadata) - Technical documentation
- Related ADRs:
  - ADR-004: Discount Code Scope Order-Wide (business rule)

---

**Date:** 2026-01-24
**Author(s):** Manik Golden Honey Co Design Team
**Reviewers:** Pending L2 Review
