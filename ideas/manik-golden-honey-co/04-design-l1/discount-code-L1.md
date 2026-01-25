# Progressive Deepening: Discount Code System

**Component:** Promotional Discount Codes (Order-Wide, Percentage-Based)
**Stage:** L1 (Refine L1 - High-Level Design)
**Date:** 2026-01-24

---

## L1 Pass: Surface Level (Stage 4: Refine L1)

### What

The discount code system allows admin to create percentage-based promotional codes (e.g., "LAUNCH10" for 10% off) that customers apply at checkout. Codes can have restrictions: minimum order value, expiration date, maximum redemptions, and one-time-per-customer limits. Admin can view usage statistics and deactivate codes mid-campaign.

**Key components:**
- Admin code creation/management
- Customer code validation at checkout
- Usage tracking (redemption count)
- One-time-per-customer enforcement
- Order-wide discount application (ADR-004)

---

### Why

**Marketing tool:** Drive customer acquisition and retention through promotional campaigns.

**High-level motivation:**
- Launch promotions ("LAUNCH10" for early customers)
- Customer incentives (reward loyal customers)
- Traffic drivers (social media campaigns)
- Inventory management (move slow products with discounts)

**Why order-wide only (ADR-004):**
- Simplest implementation for MVP
- Clear customer UX (discount applies to everything)
- Faster development (no product tagging/filtering logic)

---

### Key Insight

**Discount codes are validated at three points: application, payment intent, and order creation.**

This triple validation prevents discount abuse:
1. **Application time**: Is code valid? Does cart meet minimum order value?
2. **Payment intent time**: Re-validate (code might have expired during checkout)
3. **Order creation time**: Final validation before recording discount in order

**Critical design choice:**
- `promo_code_usage` collection tracks redemptions per customer
- `used_count` on `promo_codes` for quick stats
- Codes are soft-deleted (set `active: false`, never hard delete for audit trail)

---

### Initial Questions Raised

1. **What if customer applies code, then removes items below minimum order value?**
   - Re-validate when cart changes? Or just at payment? → L2 UX decision

2. **What if code reaches max redemptions during customer's checkout?**
   - First-come-first-served acceptable? Or reserve redemption? → L2 trade-off

3. **Can customer use multiple codes on same order?**
   - ADR-004 says no for MVP, but how to enforce? → L2 validation

4. **What if admin changes code while customer is using it?**
   - Mid-checkout code modification race condition → L2 edge case

5. **How do we prevent admin from creating duplicate codes?**
   - Unique constraint on code field → L2 schema/validation

6. **What if code is used for refunded order, does usage decrement?**
   - Cancellation affects code stats? → L2 business logic

7. **Can expired codes be reactivated with new expiration?**
   - Admin workflow consideration → L2 UX

---

## L2 Pass: Detailed Level (Stage 5: Refine L2)

*To be completed in Stage 5*

---

**Last Updated:** 2026-01-24
**Stage:** L1
