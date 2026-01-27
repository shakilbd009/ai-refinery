# UX Validation: manik-golden-honey-co

**Validated:** 2026-01-27
**Validator:** general-purpose (UX focus)

## Verdict: NEEDS_ATTENTION

---

## Critical Issues (Must Fix Before Launch)

None

---

## High Priority Issues (Should Fix)

### H1: No Loading State Guidance for 15-Minute Reservation Timer

**Location:** Checkout Flow (checkout-flow.md, inventory-reservation.md)

**Issue:** The 15-minute reservation timeout creates a critical user experience gap. While the backend handles expiration gracefully (400 "Reservation expired" with auto-re-reserve attempt), there is no specification for:
- Visible countdown timer showing remaining reservation time
- Warning notification when reservation is expiring (e.g., at 2-minute mark)
- Clear recovery path when reservation expires mid-checkout

**User Impact:** Customers who take time to fill shipping address or review order may be surprised when their cart items become unavailable. This could cause frustration and cart abandonment.

**Recommendation:**
- Add visible countdown timer component to checkout page
- Show warning toast/banner at 5-minute and 2-minute marks
- Provide clear "Extend Time" button or auto-extend on user activity
- On expiration: Show clear message with one-click re-reserve action

---

### H2: Review Submission Timing Creates Customer Confusion

**Location:** ADR-002-review-timing-immediate.md, review-moderation.md

**Issue:** Customers can submit reviews immediately after order placement, before receiving the product. The ADR acknowledges this creates "customer confusion: unclear if they should review now or wait for delivery."

**User Impact:**
- Customers may submit premature reviews ("Can't wait to try it!") that add no value
- Legitimate product feedback may be delayed because customer assumed they should review immediately
- Expectation mismatch with typical e-commerce review workflows

**Recommendation:**
- Add explicit UI guidance: "You can review your ordering experience now, or wait until you receive your product to review the honey itself"
- Consider adding review type selection: "Order Experience" vs "Product Review"
- Display "Reviewed before delivery" indicator for context on public reviews

---

### H3: Cancellation Request SLA Not Communicated in UI Spec

**Location:** ADR-003-cancellation-request-workflow.md, requirements.md

**Issue:** The cancellation workflow requires admin approval with a planned "24-hour SLA," but there is no specification for how this expectation is communicated to customers in the UI.

**User Impact:** Customers may expect instant cancellation (like Amazon) and become frustrated when their request sits in pending state without clear timeline communication.

**Recommendation:**
- Specify UI copy for cancellation request submission: "Your request will be reviewed within 24 hours"
- Add estimated response time on the "cancellation requested" order status display
- Consider email confirmation with SLA commitment when request is submitted
- Add order detail page copy explaining the review process

---

### H4: Mobile Responsive Behavior Underspecified

**Location:** requirements.md (WCAG 1.4.10 Reflow mentioned), accessibility.md

**Issue:** Requirements mention mobile browser support and WCAG 1.4.10 (no horizontal scroll at 320px), but there is no specification for:
- Touch target sizes (44x44px minimum for accessibility)
- Mobile-specific navigation patterns
- Cart/checkout flow adaptations for small screens
- Mobile keyboard handling for form inputs

**User Impact:** Mobile users represent a significant portion of e-commerce traffic. Underspecified mobile UX may result in poor implementation decisions.

**Recommendation:**
- Add touch target size requirements (minimum 44x44px per WCAG 2.1)
- Specify mobile navigation pattern (hamburger menu, bottom nav, etc.)
- Document any checkout flow differences for mobile
- Add mobile-specific form considerations (numeric keyboard for phone, etc.)

---

## Medium Priority Issues (Consider Fixing)

### M1: Error Message Specificity Varies

**Location:** edge-cases/data-boundaries.md, timing.md

**Issue:** Error messages range from specific ("Cart is empty", "Code too long") to vague ("Payment system slow", "High demand, try again"). The checkout flow shows:
- Payment timeout: "Payment system slow" (no recovery guidance)
- Flash sale contention: "High demand, try again" (no queue or retry timing)

**User Impact:** Vague error messages leave users uncertain about what went wrong and what action to take.

**Recommendation:**
- Payment timeout: "Payment processing is taking longer than usual. Your order is not yet confirmed. [Wait] [Try Again]"
- High demand: "This item is in high demand. We're holding your place. Please try again in a few seconds."
- Add recovery action buttons to all error states

---

### M2: Promo Code Edge Cases Create Confusing User Experience

**Location:** discount-code.md, edge-cases/timing.md

**Issue:** Several promo code scenarios may confuse users:
- 5-minute grace period after expiration: User may not understand why code worked/didn't work
- "Add $X more to keep discount" when below minimum after removing items
- Code deactivated during checkout but still honored (inconsistent messaging)

**User Impact:** Discount code behavior may seem unpredictable or inconsistent to users.

**Recommendation:**
- When within grace period, show: "Code expires soon - complete checkout to lock in discount"
- Add minimum order threshold indicator in cart: "Add $X to qualify for SAVE10 discount"
- Clarify in UI when locked discount is being honored despite code changes

---

### M3: Out-of-Stock User Flow Incomplete

**Location:** requirements.md (FR-1), inventory-reservation.md

**Issue:** Requirements state "out-of-stock products visually indicated" but do not specify:
- Whether out-of-stock products are shown in listings or filtered
- What happens when product goes out of stock while in cart
- Back-in-stock notification option
- Waitlist functionality

**User Impact:** Customers may add items to cart, begin checkout, and only then discover items unavailable.

**Recommendation:**
- Specify cart validation behavior on page load (show unavailable items with removal prompt)
- Consider "Notify when available" button for out-of-stock products
- Add real-time inventory checks before "Proceed to Checkout" action

---

### M4: Review Rejection Feedback Loop Unclear

**Location:** review-moderation.md

**Issue:** When admin rejects a review, customer receives email "with edit link," but:
- No specification for what rejection reasons are communicated
- No guidance on whether specific feedback is given or just "rejected"
- Edit cooldown system (1hr, 24hr, 7 days) may frustrate customers without explanation

**User Impact:** Customers may not understand why review was rejected or how to fix it. Cooldown times may seem arbitrary.

**Recommendation:**
- Specify rejection reason categories (spam, inappropriate, off-topic, needs more detail)
- Require admins to select a reason when rejecting
- Display cooldown timer with explanation: "You can edit again in X hours"
- Add help text explaining why edit limits exist

---

### M5: Order Status Email Notifications Not Specified

**Location:** requirements.md (FR-5), operations/runbooks.md

**Issue:** Requirements mention "email notifications on status changes" but do not specify:
- Exact status transitions that trigger emails
- Email content/design guidelines
- Frequency caps (prevent email fatigue)
- Unsubscribe/preference management

**User Impact:** Over-notification can annoy customers; under-notification leaves them uninformed.

**Recommendation:**
- Document which status changes trigger customer emails
- Consider: Order confirmed, Shipped (with tracking), Delivered, Cancellation approved/denied
- Add email preference center for transactional email types

---

## Low Priority Issues (Nice to Have)

### L1: No Guest Checkout Option

**Location:** requirements.md (FR-3, FR-4)

**Issue:** Checkout requires customer authentication (passwordless email code). While this is simpler than password management, some customers prefer true guest checkout without creating an account.

**User Impact:** May increase cart abandonment for one-time buyers who don't want to provide email code.

**Recommendation:** Consider for post-MVP: guest checkout with optional account creation after order completion.

---

### L2: No Order Modification Path

**Location:** requirements.md (FR-6), ADR-003

**Issue:** Customers can only request cancellation, not order modification (change address, change quantity, add item). ADR-003 mentions "Admin can offer alternatives" but this is informal.

**User Impact:** Customer who wants to change shipping address must request cancellation and re-order.

**Recommendation:** Consider adding "Request Change" option alongside "Request Cancellation" for simpler modifications.

---

### L3: Search and Filter Behavior Underspecified

**Location:** requirements.md (FR-1, FR-9)

**Issue:** Product browsing mentions "product listing displays all active products" but no search, sort, or filter options specified for customers (admin has search/filter per FR-9).

**User Impact:** With limited products (honey category only), not critical, but may frustrate users as catalog grows.

**Recommendation:** Document future search/sort requirements for scalability.

---

### L4: Cart Persistence Edge Cases

**Location:** requirements.md (FR-2)

**Issue:** Cart persists via localStorage, but no specification for:
- What happens if product is deleted while in cart
- Product price changes while in cart
- Product goes out of stock while in cart
- Cart sync across devices (not supported, but should be communicated)

**User Impact:** Price/availability changes may surprise customers at checkout.

**Recommendation:** Add cart validation on page load with clear messaging for any changes.

---

### L5: No Progress Indicator for Multi-Step Checkout

**Location:** checkout-flow.md

**Issue:** Checkout has multiple logical steps (Cart Review -> Shipping -> Payment -> Confirmation) but no specification for progress indicator.

**User Impact:** Customers may not know how many steps remain, potentially causing abandonment.

**Recommendation:** Add step indicator (e.g., "Step 2 of 4: Shipping Address").

---

## Observations

### Strengths

1. **Comprehensive Accessibility Planning**: The WCAG 2.1 AA compliance document is thorough, covering form accessibility, keyboard navigation, color contrast, and testing strategies. This is exemplary for an MVP.

2. **Thoughtful Error Handling at Backend Level**: The edge cases documentation shows careful consideration of failure modes, with specific error codes and messages for data boundaries, state transitions, and timing issues.

3. **Passwordless Auth is User-Friendly**: The 6-digit email code authentication removes password friction while maintaining security. The 10-minute expiration is reasonable.

4. **Graceful Degradation Patterns**: The design handles external service failures (Stripe, email) with appropriate user messaging and retry mechanisms.

5. **Verified Purchaser Reviews**: Requiring order history before review submission prevents spam and fake reviews, building trust.

### Areas Needing Implementation Attention

1. **Frontend State Management**: Many UX flows depend on proper frontend state handling (reservation timers, real-time validation, optimistic updates). Implementation must be careful to match backend specifications.

2. **Email Template Design**: Multiple notification types are specified but email content/design is not documented. Poor email design could undermine the careful backend work.

3. **Admin Dashboard UX**: While customer UX is well-specified, admin dashboard usability is less detailed. Admin efficiency directly impacts customer experience (faster cancellation approvals, review moderation).

4. **Loading and Feedback States**: The design assumes various loading states and feedback messages but doesn't specify their exact presentation. Consider a component library or style guide.

---

## Summary

| Severity | Count |
|----------|-------|
| Critical | 0 |
| High | 4 |
| Medium | 5 |
| Low | 5 |
| **Total** | **14** |

The design demonstrates strong UX foundations, particularly in accessibility compliance and error handling architecture. The high-priority issues primarily concern user communication (timers, SLAs, mobile specifics) rather than fundamental flow problems. Addressing the high and medium issues before launch would significantly improve customer confidence and reduce support burden.
