# ADR-002: Immediate Review Submission After Order Placement

## Status

Accepted (with risk mitigation via admin moderation)

---

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

---

## Decision

Customers can submit reviews **immediately after placing an order**, without waiting for product delivery or experience.

**Rationale:**
- Admin moderation provides quality gate to reject obviously premature reviews
- Simpler implementation (no delivery tracking dependency)
- Higher review participation rate (strike while engagement is hot)
- Admin can distinguish between premature reviews and legitimate service feedback

---

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

---

## Alternatives Considered

### Alternative 1: Reviews Only After Delivery Confirmation

**Why considered:**
- **Authentic reviews**: Customers have received and tried the product
- **Higher quality**: Reviews reflect actual honey taste, packaging quality, freshness
- **Trust**: Future customers confident reviews are legitimate
- **Industry standard**: Amazon, most e-commerce platforms use verified delivery

**Why rejected:**
- **Tracking complexity**: Requires accurate delivery status (admin must update)
- **Reminder email system**: Need automated "Review your order" emails 3-7 days post-delivery
- **Lower review rate**: Customers forget or lose interest after delivery
- **MVP bloat**: Adds significant implementation complexity for uncertain benefit
- **Small sample size risk**: With only ~3 reviews/week, can't afford low participation

### Alternative 2: Time-Delayed Reviews (X Days After Order)

**Why considered:**
- Middle ground: Gives time for delivery without explicit tracking
- Simpler than delivery confirmation
- Automatic unlock after 7 days (assumes delivery)

**Why rejected:**
- **Arbitrary timing**: 7 days may be too short (product not delivered) or too long (customer forgot)
- **Still complex**: Requires background job to unlock reviews
- **Doesn't solve authenticity**: Customer still might not have tried product
- **Worse than both alternatives**: Complexity of post-delivery timing without authenticity benefit

---

## Implementation Notes

**Review form guidance:**
- Prompt text: "Share your experience with this order (product quality, shipping, packaging, taste)"
- Clarify customers can review ordering experience OR product quality
- No explicit "wait for delivery" instruction (would contradict immediate availability)

**Admin moderation guidelines:**
- **Reject**: "5 stars! Can't wait to try it!" (clearly premature, no value)
- **Approve**: "5 stars! Order arrived quickly and honey tastes amazing" (legitimate post-delivery)
- **Approve**: "4 stars! Easy checkout but wish there were more size options" (ordering experience feedback)
- **Gray area**: "5 stars! Love supporting local honey" (not about product, but positive sentiment)

**Database schema:**
- `reviews.created_at` - tracks when review submitted
- `reviews.order_created_at` - reference to order date (can calculate time delta)
- No additional fields needed for MVP

**Future enhancements (if authenticity becomes issue):**
- Add "Verified Delivery" badge (if order status = delivered when review submitted)
- Add "Reviewed X days after order" indicator
- Implement post-delivery reminder emails to encourage reviews

---

## Success Criteria

**How we'll know this decision was correct:**
- Admin moderation rejection rate < 20% (most reviews are legitimate)
- Review quality score > 3.5/5 (future customers find reviews helpful)
- Review participation rate > 25% (higher than industry average ~15%)
- No customer complaints about "fake reviews"
- Reviews provide useful signal to future buyers

**Red flags to watch for:**
- Rejection rate > 30% (too many premature reviews)
- Reviews mostly about shipping, not product quality
- Future customers ignoring reviews (low trust signal)
- Admin overwhelmed by moderation workload

---

## Review Date

**Review after first 100 reviews** (approximately 8-10 months at 3 reviews/week) or if:
- Rejection rate exceeds 30% (authenticity problem)
- Customer feedback indicates confusion about review timing
- Competitor reviews significantly higher quality (trust disadvantage)
- Admin requests delivery-gated reviews due to workload

**Fallback plan:** If authenticity becomes problematic, implement delivery-gated reviews in V2.

---

## References

- [requirements.md](../02-requirements/requirements.md) - Open Question #7 resolution
- Related ADRs: None
- Industry benchmarks: Amazon review rates ~5-10%, specialty food ~15-20%

---

**Date:** 2026-01-24
**Author(s):** Claude (Systematic Refinement)
**Reviewers:** [Pending]
