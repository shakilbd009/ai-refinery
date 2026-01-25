# Progressive Deepening: Review Moderation System

**Component:** Customer Reviews & Admin Moderation Workflow
**Stage:** L1 (Refine L1 - High-Level Design)
**Date:** 2026-01-24

---

## L1 Pass: Surface Level (Stage 4: Refine L1)

### What

The review moderation system allows verified purchasers to submit product reviews (star rating + text), which enter a moderation queue for admin approval before appearing publicly. Admins can approve, reject, or delete reviews. Customers can edit/delete their own reviews.

**Key components:**
- Review submission (verified purchaser check)
- Moderation queue (pending reviews)
- Admin approval/rejection workflow
- Email notifications to admin on new reviews
- Public display of approved reviews

---

### Why

**Trust building:** Reviews are critical for e-commerce conversion. Small producer needs authentic reviews to compete with established brands.

**High-level motivation:**
- Build customer trust (real reviews from real purchasers)
- Quality control (admin filters premature or inappropriate reviews)
- Social proof (star ratings increase conversion)
- Customer feedback loop (learn what customers love/hate)

**Why moderation required:**
- ADR-002: Immediate review timing means customers might review before trying product
- Admin can reject "Can't wait to try it!" non-reviews
- Prevents spam, abuse, competitor sabotage

---

### Key Insight

**Reviews are triple-gated: verified purchaser + admin moderation + edit re-moderation.**

This ensures review authenticity despite immediate submission timing:
1. **Gate 1**: Only customers who ordered the product can review it
2. **Gate 2**: Admin approves before public display
3. **Gate 3**: Edits return to moderation queue (prevents bait-and-switch)

**Critical design choice:**
- Status-driven workflow: `pending` → `approved` or `rejected`
- One review per customer per product (can edit, not duplicate)
- Reviews tied to specific order (audit trail)

---

### Initial Questions Raised

1. **What if customer orders same product twice, can they review twice?**
   - One review per product per customer, or per order? → L2 decision

2. **Can admin edit review text, or only approve/reject?**
   - Editing changes meaning (trust issue) → Likely reject-only in L2

3. **What happens to reviews if product is deleted?**
   - Cascade delete or keep for audit? → L2

4. **How do we prevent review bombing (customer creates multiple accounts)?**
   - Email verification helps, but determined attackers? → L2 risk analysis

5. **What if customer edits review 50 times (spam admin queue)?**
   - Edit limit needed (3 edits max?) → L2 business rule

6. **Should rejected reviews be visible to customer?**
   - Transparency vs hurt feelings trade-off → L2

---

## L2 Pass: Detailed Level (Stage 5: Refine L2)

*To be completed in Stage 5*

---

**Last Updated:** 2026-01-24
**Stage:** L1
