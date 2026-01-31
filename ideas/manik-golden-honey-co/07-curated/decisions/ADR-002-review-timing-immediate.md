# ADR-002: Immediate Review Submission After Order Placement

## Status

Accepted (with risk mitigation via admin moderation)

## Context

Product reviews are critical for e-commerce trust and conversion. However, the timing of when customers can submit reviews significantly impacts review authenticity and value. The challenge: balance customer convenience with review quality.

**Key factors:**
- Small producer business relies on authentic reviews for trust
- Admin moderation is required for all reviews (quality gate exists)
- MVP timeline constraints (simpler implementation preferred)
- Low order volume (~10 orders/week = ~3 reviews/week at 30% rate)
- Customers may forget to review if delayed too long
- Shipping times vary (2-7 days typical)

**The trade-off:**
- **Immediate reviews**: Easier for customers, but may be inauthentic (haven't tried product)
- **Post-delivery reviews**: More authentic, but requires delivery tracking + reminder emails

## Decision

Customers can submit reviews **immediately after placing an order**, without waiting for product delivery or experience.

**Rationale:**
- Admin moderation provides quality gate to reject obviously premature reviews
- Simpler implementation (no delivery tracking dependency)
- Higher review participation rate (strike while engagement is hot)
- Admin can distinguish between premature reviews and legitimate service feedback

## Rationale

### Why not require delivery confirmation first?

While this approach produces more authentic reviews, it was rejected because:
- **Tracking complexity**: Requires accurate delivery status (admin must update)
- **Reminder email system**: Need automated "Review your order" emails 3-7 days post-delivery
- **Lower review rate**: Customers forget or lose interest after delivery
- **MVP bloat**: Adds significant implementation complexity for uncertain benefit
- **Small sample size risk**: With only ~3 reviews/week, can't afford low participation

### Why not use time-delayed reviews (X days after order)?

This middle-ground approach was rejected because:
- **Arbitrary timing**: 7 days may be too short (product not delivered) or too long (customer forgot)
- **Still complex**: Requires background job to unlock reviews
- **Doesn't solve authenticity**: Customer still might not have tried product
- **Worst of both worlds**: Complexity of post-delivery without authenticity benefit

## Consequences

### Positive

- **Simpler implementation**: No dependency on order status tracking for review unlocking
- **Higher review rate**: Customers review while engaged (right after purchase excitement)
- **Earlier reviews**: Products get reviews faster (helps early-stage business)
- **Flexibility**: Customers can review ordering experience, customer service, packaging (not just product)
- **MVP timeline**: Removes complexity of delivery confirmation + reminder emails

### Negative

- **Authenticity risk**: Reviews may not reflect actual product experience
- **Low signal reviews**: "Can't wait to try it!" adds no value to future customers
- **Admin burden**: Must evaluate each review for authenticity vs prematurity
- **Customer confusion**: Unclear if they should review now or wait for delivery
- **Quality perception**: Future customers may doubt review authenticity

### Neutral

- Admin moderation becomes more critical (quality gatekeeper)
- Review prompt could guide customers: "Share your ordering experience or product feedback"
- May need to add "Verified Purchase" + "Reviewed after delivery" badges later
