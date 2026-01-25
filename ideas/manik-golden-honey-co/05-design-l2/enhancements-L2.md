# L2: Enhancement Questions (Nice-to-Have)

**Component:** Review Moderation, Inventory, Discount Codes, Checkout
**Stage:** L2 (Refine L2 - Detailed Design)
**Date:** 2026-01-24

---

## Overview

These 8 questions address enhancements that improve UX and edge case handling but aren't blockers for MVP. Decisions are lightweight - implement if time permits, defer to post-launch otherwise.

---

## Review Moderation Enhancements

### Q1: Show Rejected Reviews to Customer?

**Scenario:**
Customer submits review, admin rejects (reason: "Contains external links"). Should customer see the rejected review in their account?

**Options:**
- **A) Show rejected reviews with reason** (transparency)
- **B) Hide rejected reviews** (avoid hurt feelings)
- **C) Show as "Pending revision" with reason** (middle ground)

**Decision: Option C - Show as "Pending Revision"**

**Rationale:** Balance between transparency and UX. Customer sees review status without feeling rejected.

**Implementation:**
```
Customer "My Reviews" page:
  Approved reviews: ✓ Live (visible to public)
  Pending reviews: ⏳ Under review
  Rejected reviews: ⚠️ Needs revision
    - Show rejection reason
    - [Edit Review] button
    - Guide: "Address the issue and resubmit"

Database:
  Don't delete rejected reviews (status = "rejected")
  Customer query: WHERE customer_id = X (all statuses)
  Public query: WHERE status = "approved" (only approved)
```

**UX Benefit:** Customer understands why review not live, can fix and resubmit.

**Future Enhancement:** Auto-expire rejected reviews after 30 days (cleanup stale data).

---

### Q2: Cascade Delete Reviews When Product Deleted?

**Scenario:**
Admin deletes product "Lavender Honey 8oz" (discontinued). Product has 15 approved reviews. What happens to reviews?

**Options:**
- **A) Cascade delete reviews** (clean database)
- **B) Keep reviews, hide from public** (audit trail)
- **C) Soft-delete product, keep reviews** (product inactive but data persists)

**Decision: Option C - Soft-Delete Product**

**Rationale:** Never hard-delete products (breaks order history). Soft-delete preserves reviews and order references.

**Implementation:**
```
Product deletion (admin action):
  UPDATE product SET active = false, deleted_at = now
  // Reviews remain untouched

Public product queries:
  WHERE active = true (excludes deleted)

Admin product queries:
  WHERE active = true OR deleted_at > now - 90 days
  // Show recently deleted (for restore)

Reviews for deleted products:
  Public: Not shown (product inactive, no product page)
  Admin: Still visible (audit, analytics)
  Customer: Still shown in "My Reviews" (history)
```

**Edge Case: Customer reviews deleted product, then product restored**

```
Timeline:
1. Product deleted (active = false)
2. Reviews hidden from public (product page doesn't exist)
3. Product restored (active = true)
4. Reviews automatically visible again (product page restored)

No special handling needed (reviews never deleted).
```

**Data Retention:** Keep deleted products + reviews indefinitely (storage cheap, data valuable).

---

## Inventory Reservation Enhancements

### Q3: Expired Session Handling?

**Scenario:**
Customer adds to cart, reservation created (expires in 15 min). Customer's browser session expires (30 min timeout). Reservation still active but customer can't access checkout.

**Impact:** Reservation persists, inventory locked, but customer gone. Not critical (reservation expires anyway).

**Decision: No Special Handling (MVP)**

**Rationale:** Reservation TTL (15 min) shorter than session timeout (30 min). Reservation expires before session in normal flow. If customer's browser crashes, reservation auto-expires.

**Current Behavior:**
```
1. Customer adds to cart, reservation created (expires T+15min)
2. Customer session expires at T+30min (inactive)
3. Reservation already expired at T+15min (background job cleaned up)
4. Customer returns, session recreated, cart empty (expected)

No issue: Reservation expired before session.
```

**Edge Case: Session expires before reservation**

```
If session timeout < reservation TTL:
1. Customer session expires at T+10min
2. Reservation still active (expires T+15min)
3. Customer locked out of checkout (can't complete payment)
4. Reservation expires at T+15min (background cleanup)

Result: 5-minute window where inventory locked but customer can't buy.
Acceptable: Rare (most users complete checkout within 10 min).
```

**Future Enhancement:** Track session ID with reservation, invalidate reservation on session expiry.

**For MVP:** Accept minor inefficiency (5-min inventory lock on edge case).

---

### Q4: Reservation Countdown Timer UX?

**Scenario:**
Customer in checkout sees reservation expiring in 3 minutes. No indication on screen. Customer completes payment at 14:59 (reservation expires 15:00). Stressful UX.

**Enhancement:** Show countdown timer "Your cart is reserved for 12:34".

**Decision: Implement if Time Permits**

**Rationale:** Nice UX improvement, reduces anxiety, likely increases conversion. Medium complexity.

**Implementation:**
```
Frontend (cart/checkout page):
  ON page load:
    reservation_expires_at = (from reservation object)
    Start countdown timer:
      time_remaining = reservation_expires_at - now

  Display:
    ⏱️ Cart reserved for 14:32
    (Updates every second)

  When < 5 minutes remaining:
    Change color to red (urgency)
    Show message: "Complete checkout soon to secure your items"

  When expired:
    Redirect to cart
    Show error: "Reservation expired. Items returned to inventory."
```

**Technical Considerations:**
- Reservation created server-side (server timestamp authoritative)
- Client countdown approximate (client clock skew possible)
- Re-sync with server every 60 seconds (poll reservation status)

**Future Enhancement:** Push notification when < 2 minutes remaining (if customer idle).

**Priority:** Medium (good ROI, improves conversion likely).

---

### Q5: Product Deletion with Active Reservations?

**Scenario:**
Admin wants to delete product "Comb Honey 16oz". Product has 3 active reservations (customers checking out). Admin clicks Delete.

**Options:**
- **A) Block deletion until reservations expire** (safe)
- **B) Allow deletion, cancel reservations** (forceful)
- **C) Soft-delete, reservations complete normally** (graceful)

**Decision: Option C - Soft-Delete**

**Rationale:** Never break customer checkout flow. Soft-delete allows in-flight orders to complete.

**Implementation:**
```
Admin deletes product:
  IF active_reservations_count > 0:
    Show warning:
      "3 customers currently checking out this product.
       Product will be hidden from store but checkout allowed to complete."
    [Confirm Delete] [Cancel]

  ON confirm:
    UPDATE product SET active = false, deleted_at = now
    // Reservations remain valid

Reservation → Order flow:
  ON order creation:
    READ product (even if active = false)
    // Allow order for deleted products (reservation already created)

  AFTER order created:
    Product stays soft-deleted (no new customers can order)

Public product queries:
  WHERE active = true (excludes soft-deleted)
  // Deleted product disappears from store immediately
```

**Customer Experience:**
- Customers with active reservations complete checkout normally
- New customers cannot find product (store page removed)
- No broken checkout flows

**Edge Case: Customer abandons reservation for deleted product**

```
1. Admin soft-deletes product (T+0)
2. Customer abandons checkout (T+5)
3. Reservation expires (T+15)
4. Background cleanup releases reservation (decrements reserved_quantity)

Product document persists (soft-deleted, reserved_quantity = 0).
No issues.
```

**Hard Delete:** Never for products with order history. Breaks analytics, customer order pages.

---

## Discount Code Enhancements

### Q6: Multiple Code Enforcement?

**Scenario:**
Customer tries to apply two codes: "SAVE10" (10% off) and "LAUNCH20" (20% off). Should system allow both?

**Business Rule (from ADR-004):** One code per order (MVP).

**Question:** How to enforce technically?

**Decision: UI Prevention + Backend Validation**

**Implementation:**
```
Frontend (cart page):
  Promo code input: [________] [Apply]

  IF code already applied:
    Hide input field
    Show: "SAVE10 applied (-$5.00) [Remove Code]"

  Customer must remove existing code before applying new one.

Backend validation:
  ON /apply-promo-code:
    IF session already has promo_code:
      RETURN error:
        {
          "error": "code_already_applied",
          "message": "Remove existing code to apply a new one",
          "current_code": session.promo_code
        }

  ON /create-payment-intent:
    IF metadata contains multiple promo_codes (hacking attempt):
      REJECT payment intent
      Log security incident
```

**Edge Case: Customer uses multiple browser tabs**

```
Tab A: Applies "SAVE10"
Tab B: Applies "LAUNCH20" (different session? same session?)

If same session (cookies shared):
  - Tab B application overwrites Tab A code
  - Session stores latest code only
  - No issue (one code enforced)

If different sessions (incognito + normal):
  - Two separate carts, two separate sessions
  - Can apply different codes to different carts
  - No issue (two separate orders eventually)
```

**Security:** Backend validates one code per payment_intent (metadata check). Can't bypass via UI hacking.

---

### Q7: Mid-Checkout Admin Code Modification?

**Scenario:**
Customer applies "SAVE10" (10% off), proceeds to payment. While customer entering card details, admin changes "SAVE10" to 5% off (mistake correction). What happens?

**Covered in:** `discount-code-validation-L2.md` (lock-in at payment intent).

**Decision: Lock Discount at Payment Intent Creation**

**Brief Summary:**
```
Timeline:
T+0:  Customer applies code (10% off shown)
T+5:  Admin changes to 5% off
T+10: Customer creates payment intent
      - Backend reads code (now 5% off)
      - Creates PaymentIntent with 5% discount
      - Customer charged with 5% discount

Customer confusion: Saw 10%, charged for 5%.
```

**Resolution: Lock discount at application time**

```
Frontend stores discount_percent when code applied:
  session.promo_code = {
    code: "SAVE10",
    discount_percent: 10,  // Locked value
    applied_at: timestamp
  }

Payment intent creation uses session.discount_percent (not DB value).

Metadata includes both:
  - code: "SAVE10"
  - discount_percent_applied: 10
  - discount_percent_current: 5 (from DB at order creation)

If mismatch detected at order creation:
  Log warning: "Code changed during checkout"
  Honor locked value (customer trust)
```

**Tradeoff:** Slight staleness (customer gets old discount) vs trust (honor shown price).

**MVP Decision:** Lock at payment intent, honor locked value at order creation.

---

## Checkout Flow Enhancements

### Q8: Multiple Tab Reservation Management?

**Scenario:**
Customer opens two browser tabs, both showing cart with "Wildflower Honey 12oz × 3". Customer clicks checkout in both tabs.

**Question:** Create two reservations for same customer + cart?

**Options:**
- **A) Allow duplicate reservations** (simple, wasteful)
- **B) Detect and prevent duplicates** (complex)
- **C) Merge/update existing reservation** (graceful)

**Decision: Option A - Allow Duplicates (MVP), Option C (Future)**

**Rationale:** Rare edge case (< 1% of checkouts). Reservations expire quickly (15 min). Accept temporary inefficiency.

**Current Behavior:**
```
Tab A clicks checkout:
  - Creates reservation R1 (3 units)
  - reserved_quantity += 3

Tab B clicks checkout:
  - Creates reservation R2 (3 units)
  - reserved_quantity += 3 (now +6 total)

Result: 6 units reserved for same customer (wasteful).

Resolution:
1. Customer completes payment in Tab A
   - Order created, R1 deleted, inventory decremented by 3
   - reserved_quantity -= 3

2. Tab B reservation R2 expires (15 min later)
   - Background cleanup deletes R2
   - reserved_quantity -= 3

Final state: Correct (customer got 3 units, reserved 0).

Impact: 15-minute window with 3 extra units locked.
```

**Acceptable for MVP:** Low volume (< 100 orders/day), rare occurrence (< 1%), 15-min duration.

**Future Enhancement (Option C):**

```
ON /reserve-inventory:
  QUERY existing reservations:
    WHERE customer_id = X
    WHERE product_id = Y
    WHERE status = "active"

  IF found:
    UPDATE existing reservation:
      - quantity = new_quantity
      - expires_at = now + 15 min (refresh expiration)
    // Don't increment reserved_quantity again

  ELSE:
    CREATE new reservation
    INCREMENT reserved_quantity
```

**Implementation Complexity:** Medium (query + conditional logic).

**Priority:** Low (rare edge case, minimal impact).

---

## Summary of Decisions

| Question | Decision | Implementation | Priority |
|----------|----------|----------------|----------|
| Show rejected reviews to customer? | Show as "Pending revision" | Medium | Medium |
| Cascade delete reviews when product deleted? | Soft-delete product | Low | High |
| Expired session handling? | No special handling | None | Low |
| Reservation countdown timer UX? | Implement if time permits | Medium | Medium |
| Product deletion with active reservations? | Soft-delete, allow completion | Low | High |
| Multiple code enforcement? | UI prevention + backend validation | Low | High |
| Mid-checkout admin code modification? | Lock discount at payment intent | Low | High |
| Multiple tab reservation management? | Allow duplicates (MVP) | None | Low |

---

## Implementation Recommendations

**Implement for MVP (4):**
1. ✅ Soft-delete products (preserves reviews, reservations, orders)
2. ✅ Multiple code enforcement (UI + backend validation)
3. ✅ Lock discount at payment intent (customer trust)
4. ✅ Show rejected reviews as "Pending revision" (transparency)

**Defer to Post-Launch (4):**
5. ⏳ Reservation countdown timer (nice UX, not critical)
6. ⏳ Expired session handling (edge case, minimal impact)
7. ⏳ Multiple tab reservation deduplication (rare, low impact)
8. ⏳ Auto-expire rejected reviews after 30 days (data hygiene)

---

## Edge Cases Discovered

1. **Product restored after deletion** - Reviews automatically visible again (soft-delete behavior)
2. **Session expires before reservation** - 5-min window of locked inventory (acceptable)
3. **Multiple tabs with different sessions** - Two separate carts, no conflict
4. **Admin changes code during checkout** - Locked discount prevents customer confusion
5. **Duplicate reservations expire** - Both cleaned up eventually, no data corruption

---

## Monitoring Additions

**Review Moderation:**
- Track rejected reviews pending revision > 7 days (stale)
- Alert if rejection rate > 40% (admin too strict or customers not understanding guidelines)

**Inventory:**
- Track soft-deleted products with inventory > 0 (potential revenue if restored)
- Alert if multiple tab reservations > 10/day (UX issue worth fixing)

**Discount Codes:**
- Track code change during checkout events (admin education issue)
- Alert if multiple code application attempts > 50/day (UI unclear)

---

**Last Updated:** 2026-01-24
**Stage:** L2
**Status:** ✅ All enhancement questions resolved with lightweight decisions
