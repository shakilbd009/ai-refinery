# Stage 2: Requirements Analysis - Status

**Project:** Manik Golden Honey Co
**Stage:** 2 - Brainstorm → Explore (Requirements Analysis)
**Date Started:** 2026-01-24
**Date Completed:** 2026-01-24
**Status:** ✅ Complete - Ready for Stage 3

---

## Stage 2 Completion Checklist

### Requirements Documentation
- [x] Functional requirements documented with acceptance criteria
- [x] Non-functional requirements specified (performance, security, reliability, usability)
- [x] Constraints documented (budget, timeline, technology, regulatory)
- [x] Success metrics defined (user, technical, business)
- [x] Dependencies identified (external and internal)
- [x] Assumptions documented with validation plans
- [x] Open questions captured

### Requirements Validation
- [x] Target users and pain points validated (Customer: small producer access, Admin: order chaos)
- [x] Success metrics are measurable and realistic (validated for specialty honey business)
- [x] Out of scope items explicitly defined (loyalty programs, multi-category, etc.)
- [x] No vague requirements (all specific and measurable)
- [x] Acceptance criteria defined for all functional requirements
- [x] Priority levels assigned (Must Have / Should Have / Nice to Have)

### Stakeholder Review
- [x] Requirements reviewed with business stakeholder (interactive Q&A completed)
- [x] Open questions answered or assigned (4 critical questions resolved, 6 deferred to later stages)
- [x] Assumptions validated or flagged for testing (12 assumptions documented with validation plans)
- [x] Scope agreement (in-scope vs out-of-scope) (reviews + discount codes added to scope)

---

## Key Decisions Made

1. **Product Reviews & Ratings**: Added to MVP scope
   - Star ratings (1-5) + text reviews
   - Verified purchasers only
   - Admin moderation required before publishing
   - Customers can edit/delete their reviews
   - ⚠️ **Risk Flagged**: Reviews allowed immediately after order (before product received)

2. **Discount Code System**: Added to MVP scope
   - Percentage-based discounts only (no fixed-amount for MVP)
   - Order-wide application only (not product-specific)
   - Full restriction support (min order, expiration, max redemptions, one-time per customer)
   - Complete admin management (create, edit, deactivate, view stats)

3. **Inventory Race Condition Strategy**: Pessimistic Locking
   - Reserve inventory when checkout starts (15-minute window)
   - Background job releases abandoned reservations
   - Prevents overselling at cost of temporary inventory reduction
   - **Rationale**: Reputation protection for small producer > conversion optimization

4. **Order Cancellation**: Request with Admin Approval
   - Customer can request cancellation (pending/processing orders only)
   - Admin reviews and approves/denies
   - Approved cancellations trigger Stripe refund + inventory return
   - Middle-ground complexity between no-cancellation and full self-service

5. **Pain Points Confirmed**:
   - Customer: Hard to buy honey online from small/local producers
   - Admin: Managing orders manually (email/phone/text chaos)

---

## Open Questions

**Resolved (4):**
- ~~Inventory race condition handling strategy~~ → **Pessimistic locking (15-min reservation)**
- ~~Customer order cancellation support~~ → **Request with admin approval**
- ~~Review timing~~ → **Immediately after order placement** (⚠️ risk flagged)
- ~~Discount code product-specific or order-wide~~ → **Order-wide only**

**Remaining (6):**
1. Customer shipping address editing after order placement?
2. Review notification mechanism for admin? (email immediately? daily digest? dashboard badge?)
3. Review edit limits? (unlimited edits? limit 3 edits? always re-moderate?)
4. Multiple admin users support? (single admin for MVP or multi-user?)
5. Discount code stacking with other promotions? (N/A if only one promo type for MVP)
6. Email templates needed? (order confirmation, status update, password reset, review moderation, cancellation request, cancellation approval/denial)

---

## Next Stage: Stage 3 - Explore → Refine L1

**Objective:** Evaluate approaches and make architectural decisions

**Frameworks to apply:**
- Trade-Off Analysis Framework
- Architecture Decision Records (ADRs)
- Design Red Flags Checklist

**Key activities:**
- Identify 2-3 viable architectural approaches
- Create trade-off analysis for major decisions
- Document first ADRs
- Answer open questions from Stage 2
- Make recommendations with clear rationale

---

## Notes

**Scope Change Impact:**
- Added 3 new functional requirements (reviews, review moderation, discount codes)
- Database schema additions: `reviews`, `promo_codes`, `promo_code_usage` collections
- Estimated timeline impact: +2-3 weeks to MVP
- Complexity: Moderate increase (review moderation workflow, discount validation logic)

**Timeline Estimate:**
- Original MVP: 6-8 weeks
- Updated MVP: 8-11 weeks (with reviews + discount codes)
