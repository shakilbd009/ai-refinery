# L2: Business Rules & Policy Decisions

**Component:** Review Moderation, Discount Codes, Checkout Flow
**Stage:** L2 (Refine L2 - Detailed Design)
**Date:** 2026-01-24

---

## Important Questions from L1 (8 Total)

**Review Moderation (4):**
1. Multiple purchases → multiple reviews?
2. Can admin edit review text?
3. Review bombing prevention?
4. Review edit limits?

**Discount Codes (3):**
5. Cart changes after code applied?
6. Duplicate code prevention?
7. Refunded order usage decrement?

**Checkout Flow (1):**
8. Partial inventory fulfillment?

---

## Review Moderation Business Rules

### Q1: Multiple Purchases → Multiple Reviews?

**Scenario:**
```
Customer buys "Wildflower Honey" on three occasions:
- Order #1: Jan 1, 2026
- Order #2: Feb 15, 2026 (restock)
- Order #3: Mar 20, 2026 (gift)

Can customer submit three reviews for the same product?
```

**Options:**

**Option A: One review per product (regardless of order count)**
- Customer can only review product once
- If they reorder, can edit existing review
- Simplest implementation

**Option B: One review per order (allows multiple)**
- Customer can review each purchase separately
- Captures experience at different times
- More complex to manage

**Option C: One review per product per year**
- Annual review refresh allowed
- Captures product changes over time
- Medium complexity

---

**Decision: Option A - One review per product per customer**

**Rationale:**

**Pros:**
- Simple to understand (customer and admin)
- Prevents review spam
- Single source of truth for customer opinion
- Easier moderation (one review to manage)

**Cons:**
- Customer can't share evolving opinions
- Reorders don't get fresh reviews
- Lost insights from repeat customers

**Accepted tradeoff:** Simplicity over richness. MVP focuses on verified purchaser reviews, not experience tracking over time.

---

**Implementation:**

```
Database constraint:
  reviews collection
  Composite unique index: (product_id, customer_id)

Review submission validation:
  QUERY reviews WHERE product_id = X AND customer_id = Y
  IF found:
    RETURN error "You already reviewed this product. Edit your existing review instead."
  ELSE:
    CREATE review (status = pending)

Admin dashboard:
  Show existing review link when customer already reviewed
  Allow customer to edit existing review (returns to moderation queue)
```

**Edge case: Customer deletes review, then repurchases**

```
Timeline:
T+0:  Customer reviews product (Jan 1)
T+30: Customer deletes review (changed mind)
T+60: Customer repurchases product (Feb 1)
T+61: Customer wants to review again

Behavior:
- Check if review exists (deleted reviews stay in DB with status = "deleted")
- IF status = "deleted", allow new review
- Create fresh review (new review_id, status = pending)

Alternative: Undelete + edit existing review
- Show "You previously reviewed this product (deleted)"
- Offer to restore + edit
- Simpler data model (one review per product persists)
```

**MVP Decision:** Allow new review after deletion (simpler UX).

---

### Q2: Can Admin Edit Review Text?

**Scenario:**
```
Customer submits review:
  "This honey is amazing! Buy it from Manik's shop on Main Street."

Admin sees this and wants to:
  Option A: Approve as-is (includes store address)
  Option B: Edit to remove address
  Option C: Reject with reason "No external references"
```

**Options:**

**Option A: Admin can edit review text**
- Admin fixes typos, removes personal info, edits inappropriate content
- Review still attributed to customer
- Transparency issue (customer didn't write final version)

**Option B: Admin approve/reject only (no editing)**
- Admin approves or rejects with reason
- Customer edits and resubmits if rejected
- Preserves authenticity

**Option C: Admin can suggest edits (workflow)**
- Admin marks issues in review
- Customer sees suggestions, edits themselves
- Most complex workflow

---

**Decision: Option B - Approve/Reject Only (No Admin Editing)**

**Rationale:**

**Pros:**
- Authentic reviews (customer's own words)
- No trust issues (customer owns content)
- Clear responsibility (customer accountable for content)
- Simple workflow (binary decision)

**Cons:**
- More customer back-and-forth (reject → edit → resubmit)
- Can't fix minor typos quickly
- Admin workload for common issues

**Accepted tradeoff:** Authenticity over efficiency. Customer reviews must be customer-written.

---

**Implementation:**

```
Admin moderation UI:
  Review text: [Read-only display]

  Actions:
  [ Approve ]  [ Reject ]

  If Reject selected:
    Rejection reason (required):
    [ ] Contains personal information
    [ ] Spam or promotional content
    [ ] Inappropriate language
    [ ] Product not tried yet
    [ ] Other: [text field]

  Submit button: [Submit Decision]

Backend:
  ON admin approval:
    UPDATE review SET status = "approved", approved_by = adminId, approved_at = now

  ON admin rejection:
    UPDATE review SET status = "rejected", rejected_by = adminId, rejected_at = now, rejection_reason = reason
    SEND email to customer with rejection_reason
    Email includes: "Edit your review and resubmit"

Customer notification email:
  Subject: Your review needs revision

  Hi {customer_name},

  Your review for {product_name} could not be approved:

  Reason: {rejection_reason}

  Please edit your review to address this issue:
  [Edit Review Button]

  Original review:
  "{review_text}"

  Thanks,
  Manik Golden Honey Co
```

**Customer edit flow:**

```
ON customer edits rejected review:
  UPDATE review SET text = new_text, status = "pending", edited_at = now
  NOTIFY admin (new review in moderation queue)
  Admin re-reviews updated content
```

**Edge case: Admin rejects multiple times**

```
Workflow:
1. Customer submits review → pending
2. Admin rejects (reason: "No external links")
3. Customer edits, removes link → pending
4. Admin rejects (reason: "Too short")
5. Customer edits, expands → pending
6. Admin approves ✓

History tracking:
  review_history table:
    - version_number
    - text
    - status
    - moderation_note
    - timestamp

Admin can see edit history (audit trail).
```

**Spam prevention:** If admin rejects 3+ times, flag customer for review (possible bad actor).

---

### Q3: Review Bombing Prevention?

**Scenario:**
```
Competitor wants to sabotage Manik's honey:
- Creates 10 fake email accounts
- Orders product 10 times (minimum purchase)
- Submits 10 one-star reviews
- All reviews say "Terrible quality, don't buy"

How to prevent this?
```

**Attack vectors:**

1. **Multiple email accounts** (Gmail+aliases: user+1@gmail.com, user+2@gmail.com)
2. **Burner credit cards** (Privacy.com virtual cards)
3. **VPN/proxy** (hide IP address)
4. **Timing** (submit all reviews within minutes)

---

**Defense layers:**

**Layer 1: Verified Purchaser Requirement (Already Implemented)**

```
Cannot review without order.

Attack cost:
- $50/review (average product price)
- $500 for 10 reviews
- Expensive but possible for motivated attacker
```

**Layer 2: Email Verification (Already Implemented)**

```
Passwordless auth requires email verification.

Mitigation:
- Gmail+aliases blocked (detect and normalize)
- Disposable email domains blocked (list of known providers)

Algorithm:
  ON customer registration:
    email_normalized = normalizeEmail(email)
    // user+1@gmail.com → user@gmail.com

  IF email_normalized already exists:
    RETURN error "Email already registered"

  IF email domain in DISPOSABLE_EMAIL_DOMAINS:
    RETURN error "Disposable emails not allowed"
```

**Layer 3: Admin Moderation (Already Implemented)**

```
All reviews require approval.

Admin red flags:
- Multiple similar reviews submitted simultaneously
- One-star reviews with generic negative text
- Reviews from new customers (first purchase)

Admin action:
- Investigate customer order history
- Check IP address patterns (if tracked)
- Reject suspicious reviews
```

**Layer 4: Rate Limiting (New)**

```
Limit review submissions per customer:
- 1 review per product per customer (already enforced)
- Max 5 reviews per day across all products
- Max 10 reviews per week

Algorithm:
  ON review submission:
    COUNT reviews WHERE customer_id = X AND created_at > now - 24h
    IF count >= 5:
      RETURN error "Daily review limit reached"

Prevents attacker from submitting 10 reviews instantly.
```

**Layer 5: Review Pattern Detection (New)**

```
Detect suspicious patterns:
- Multiple reviews with identical text
- Multiple reviews submitted within 5 minutes
- Multiple reviews from same IP address (if tracked)

Algorithm:
  ON review submission:
    QUERY recent_reviews:
      WHERE created_at > now - 1h
      WHERE text = new_review.text OR customer_ip = new_review.ip

    IF count > 3:
      Flag review for admin (auto-reject or manual review)
      Log incident: "Potential review bombing detected"
```

**Layer 6: Minimum Order Value (New - Optional)**

```
Require order value > $X to review:
- Prevents cheap spam orders ($5 product repeated)
- Increases attack cost

Algorithm:
  ON review submission:
    READ order (order_id from verified purchaser check)
    IF order.total < MINIMUM_REVIEW_ORDER_VALUE:
      RETURN error "Order total must exceed ${X} to review"

MVP Decision: Skip this (too restrictive, all products reviewable).
```

---

**Decision: Implement Layers 1-5**

**MVP Implementation:**
- Layer 1: ✅ Already implemented (verified purchaser)
- Layer 2: ✅ Already implemented (email verification) + Add email normalization
- Layer 3: ✅ Already implemented (admin moderation)
- Layer 4: ✅ Add rate limiting (5/day, 10/week)
- Layer 5: ✅ Add pattern detection (flag for admin)
- Layer 6: ❌ Skip (too restrictive)

**Accepted risk:** Determined attacker can still spam (expensive but possible). Rely on admin moderation + pattern detection to catch.

**Escalation:** If review bombing occurs, admin can:
1. Reject all suspicious reviews
2. Refund attacker orders (ban customer)
3. Report to payment processor (fraud)
4. Contact platform support (if marketplace)

---

**Implementation:**

```
Email normalization:
  FUNCTION normalizeEmail(email):
    email_lower = email.toLowerCase()

    // Remove Gmail +aliases
    IF email_lower ends with "@gmail.com":
      username = email_lower.split("@")[0]
      username_clean = username.split("+")[0]
      RETURN username_clean + "@gmail.com"

    // Add more providers as needed (Outlook, Yahoo)

    RETURN email_lower

Rate limiting:
  Collection: review_submissions_log
    - customer_id
    - review_id
    - submitted_at

  ON review submission:
    COUNT WHERE customer_id = X AND submitted_at > now - 24h
    IF count >= 5: REJECT

Pattern detection:
  ON review submission:
    QUERY WHERE text = new_review.text AND created_at > now - 1h
    IF count > 1:
      UPDATE review SET flagged = true, flag_reason = "Duplicate text"
      NOTIFY admin

Admin dashboard:
  "Flagged Reviews" section
  Shows reviews with suspicious patterns
  Admin can bulk-reject or investigate
```

---

### Q4: Review Edit Limits?

**Scenario:**
```
Customer submits review, admin rejects (reason: "Too short").
Customer edits 10 times:
- Edit 1: Adds one sentence → rejected (still too short)
- Edit 2: Adds paragraph → rejected (contains external link)
- Edit 3: Removes link → rejected (mentions competitor)
- ...
- Edit 10: Finally acceptable → approved

Admin spent 10 review cycles on one customer.
```

**Question:** Limit how many times customer can edit/resubmit?

---

**Options:**

**Option A: No limit (current)**
- Customer can edit infinitely
- Admin reviews every edit
- Risk: Spam admin queue

**Option B: Hard limit (3 edits max)**
- After 3 rejections, review permanently rejected
- Customer cannot resubmit
- Risk: Legitimate customers locked out

**Option C: Escalating cooldown**
- Edit 1: Immediate resubmit
- Edit 2: 1-hour cooldown
- Edit 3: 24-hour cooldown
- Edit 4+: 7-day cooldown

---

**Decision: Option C - Escalating Cooldown**

**Rationale:**

**Pros:**
- Prevents admin spam (delays between edits)
- Legitimate customers can still succeed (no hard limit)
- Encourages careful editing (cooldown penalty)

**Cons:**
- Complex to implement (track cooldown state)
- Frustrated customers (must wait)

**Accepted tradeoff:** Moderate complexity for spam prevention.

---

**Implementation:**

```
Database:
  reviews table:
    - edit_count: integer (incremented on each edit)
    - last_edited_at: timestamp
    - next_edit_allowed_at: timestamp (calculated)

ON customer edits review:
  READ review (get edit_count, last_edited_at)

  IF now < next_edit_allowed_at:
    RETURN error "You can edit again on {next_edit_allowed_at}"

  INCREMENT edit_count
  UPDATE review:
    text = new_text
    status = "pending"
    last_edited_at = now
    next_edit_allowed_at = calculateCooldown(edit_count)

FUNCTION calculateCooldown(edit_count):
  SWITCH edit_count:
    CASE 0-1: RETURN now (immediate)
    CASE 2:   RETURN now + 1 hour
    CASE 3:   RETURN now + 24 hours
    CASE 4+:  RETURN now + 7 days

Customer UI:
  IF next_edit_allowed_at > now:
    Show message: "You can edit this review again in {time_remaining}"
    Disable "Edit Review" button
```

**Edge case: Admin approves before cooldown expires**

```
Timeline:
T+0:  Customer edits (edit #3) → 24-hour cooldown
T+1h: Admin approves review

Behavior:
- Cooldown irrelevant (review approved)
- Customer sees review live
- If customer wants to edit again later, cooldown resets (edit_count = 0)

ON admin approval:
  UPDATE review:
    status = "approved"
    edit_count = 0 (reset counter)
    next_edit_allowed_at = null
```

**Edge case: Customer hits 7-day cooldown multiple times**

```
Spam indicator:
  IF edit_count > 10:
    Flag customer for admin review
    Email admin: "Customer {email} has edited review {product} 10+ times"
    Possible actions:
      - Admin manually approves/rejects
      - Admin contacts customer (clarify guidelines)
      - Admin bans customer (malicious)
```

---

## Discount Code Business Rules

### Q5: Cart Changes After Code Applied?

**Scenario:**
```
Customer adds to cart:
- Wildflower Honey 12oz: $15 × 3 = $45
- Comb Honey: $20 × 1 = $20
- Total: $65

Customer applies code "SAVE10" (10% off, minimum $50):
- Validates ✓ (total $65 > $50)
- Discount: $6.50
- New total: $58.50

Customer removes Comb Honey ($20):
- New cart total: $45
- Still below minimum $50

Should discount be removed automatically?
```

---

**Options:**

**Option A: Remove discount automatically on cart change**
- Re-validate whenever cart changes
- Remove code if validation fails
- Customer sees discount disappear

**Option B: Keep discount, validate only at payment**
- Code stays applied (optimistic)
- Validation at payment intent creation
- Payment rejected if invalid

**Option C: Warning message, customer decides**
- Show warning: "Cart below minimum, discount will not apply"
- Keep code applied (customer can fix cart)
- Clear UX feedback

---

**Decision: Option C - Warning Message, Validate at Payment**

**Rationale:**

**Pros:**
- Best UX (customer controls cart)
- Clear feedback (warning shown immediately)
- Simple implementation (validate at payment, not on every cart change)

**Cons:**
- Customer might not notice warning
- Could attempt checkout with invalid code

**Accepted tradeoff:** Clear warnings > automatic removal (less surprising).

---

**Implementation:**

```
Frontend (cart page):
  ON cart change:
    IF promo_code_applied:
      calculateCartTotal()
      IF total < promo_code.min_order_value:
        Show warning banner:
          ⚠️ Cart total below minimum ${min_order_value}.
          Add ${difference} more to keep discount.

      ELSE:
        Hide warning (cart valid)

  Code stays applied (not removed automatically)

Backend (payment intent creation):
  ON /create-payment-intent:
    IF promo_code:
      VALIDATE min_order_value <= cart_total
      IF invalid:
        RETURN error:
          {
            "error": "promo_code_invalid",
            "message": "Cart total below minimum ${min_order_value}",
            "required_total": min_order_value,
            "current_total": cart_total
          }

  Customer must:
    - Add more items, OR
    - Remove promo code, OR
    - Proceed without discount
```

**Edge case: Customer adds items, then removes**

```
Timeline:
1. Cart: $45, code invalid
2. Customer adds $10 item → $55, code valid ✓
3. Warning disappears
4. Customer removes $10 item → $45, code invalid
5. Warning reappears

Behavior: Dynamic warning based on current cart state.
```

**Edge case: Code minimum changes during checkout**

```
Admin edits code:
- Old minimum: $50
- New minimum: $100

Customer cart: $65

Timeline:
T+0:  Customer applies code (minimum $50) ✓
T+5:  Admin changes minimum to $100
T+10: Customer proceeds to payment
T+11: Validation fails (cart $65 < minimum $100)

Behavior:
- Payment intent creation validates with CURRENT code settings
- Customer sees error: "Code minimum increased to $100"
- Customer can remove code or add more items

Note: Covered in discount-code-validation-L2.md (lock-in at payment intent).
```

**MVP Decision:** Lock minimum at payment intent creation (prevent mid-checkout changes).

---

### Q6: Duplicate Code Prevention?

**Scenario:**
```
Admin creates code "LAUNCH10" (10% off, expires Jan 31).

Later, admin creates another code "LAUNCH10" (20% off, expires Feb 28).

System allows duplicate? Or enforces unique codes?
```

---

**Options:**

**Option A: Allow duplicates (different IDs)**
- Same code text, different promo_code documents
- System picks first match (undefined behavior)
- Confusing for customers and admin

**Option B: Enforce uniqueness (recommended)**
- Code field must be unique
- Admin sees error if duplicate
- Clear 1:1 mapping (code → discount)

**Option C: Allow duplicates with date ranges**
- Same code can exist in non-overlapping periods
- "LAUNCH10" Jan 1-31, then "LAUNCH10" Feb 1-28
- Complex to implement

---

**Decision: Option B - Enforce Unique Codes**

**Rationale:**

**Pros:**
- Simple mental model (one code = one discount)
- No ambiguity (customer always gets same discount)
- Easy admin management (clear code list)

**Cons:**
- Admin must create new code names (can't reuse)
- Slight inconvenience (want to reuse "SAVE10" monthly)

**Accepted tradeoff:** Clarity over convenience. Use "SAVE10-JAN", "SAVE10-FEB" if monthly.

---

**Implementation:**

```
Database:
  promo_codes collection
  Firestore doesn't support unique constraints (except doc ID)

  Workaround: Use code as document ID

  Collection structure:
    promo_codes/{code}
      code: "LAUNCH10" (same as doc ID, redundant but clear)
      discount_percent: 10
      expires_at: timestamp
      ...

ON admin creates code:
  TRY:
    CREATE document with ID = code
  CATCH AlreadyExistsError:
    RETURN error "Code already exists. Choose a different code."

Admin UI:
  Code creation form:
    Code: [________]
    [Check Availability]

  ON "Check Availability" click:
    READ promo_codes/{code}
    IF exists:
      Show error: "Code already in use. Try LAUNCH10-V2"
    ELSE:
      Show success: "Code available ✓"

  Submit button: [Create Code]
```

**Edge case: Admin deactivates code, wants to reuse**

```
Scenario:
- Admin creates "SAVE20" (Jan campaign)
- Admin deactivates "SAVE20" (Jan 31)
- Admin wants to create "SAVE20" again (Feb campaign)

Current behavior:
- Code exists (active = false)
- Cannot create duplicate

Options:
A) Hard-delete old code (lose audit trail)
B) Force new code name ("SAVE20-FEB")
C) Allow reactivation with new settings

MVP Decision: Option B (force new name).

Future enhancement: Reactivation flow (change expiration, reactivate).
```

---

### Q7: Refunded Order Usage Decrement?

**Scenario:**
```
Code "LAUNCH10": max_redemptions = 100, used_count = 50

Customer orders product, applies code:
- Order created
- used_count incremented to 51

Customer requests cancellation (changed mind):
- Admin approves cancellation
- Stripe refund issued
- Order status = "canceled"

Should used_count decrement to 50?
```

---

**Options:**

**Option A: Decrement on refund**
- Track actual successful orders
- Accurate marketing analytics
- Allows code to be reused by same customer

**Option B: Don't decrement (simpler)**
- used_count = total redemption attempts
- Includes refunded orders
- Simpler implementation, no edge cases

**Option C: Separate counters**
- used_count = total attempts
- successful_count = completed orders
- Marketing uses successful_count

---

**Decision: Option B - Don't Decrement**

**Rationale:**

**Pros:**
- Simple implementation (no refund tracking)
- Prevents gaming (customer can't reuse code by canceling)
- Clear semantics (used_count = times code entered system)

**Cons:**
- Less accurate marketing analytics (includes refunds)
- Code might "run out" faster (refunds count)

**Accepted tradeoff:** Simplicity over precision. Marketing can query successful orders separately.

---

**Implementation:**

```
ON order cancellation:
  UPDATE order SET status = "canceled", canceled_at = now
  ISSUE Stripe refund
  // Do NOT decrement promo_code.used_count

Promo code stats (admin dashboard):
  Total redemptions: promo_code.used_count
  Successful orders: COUNT(orders WHERE promo_code = X AND status != "canceled")
  Refund rate: (used_count - successful) / used_count

Admin can see full picture without complex decrement logic.
```

**Edge case: Customer cancels, then reorders with same code**

```
Scenario:
- Customer orders with "SAVE10" (first use)
- used_count++, usage record created
- Customer cancels
- used_count NOT decremented
- Customer reorders, tries "SAVE10" again

Behavior:
  ON code application:
    QUERY promo_code_usage WHERE customer_id = X AND code = "SAVE10"
    IF found AND promo_code.one_time_per_customer:
      RETURN error "Code already used"

Customer cannot reuse code even after refund.

Alternative: Allow reuse if previous order canceled
  IF found:
    READ order (usage.order_id)
    IF order.status == "canceled":
      Allow reuse (previous attempt doesn't count)

MVP Decision: Don't allow reuse (simpler, prevents gaming).
```

---

## Checkout Flow Business Rules

### Q8: Partial Inventory Fulfillment?

**Scenario:**
```
Customer wants to order:
- Wildflower Honey 12oz: 5 units

Available inventory: 3 units

Options:
A) Reject entirely ("Add 3 or fewer")
B) Offer partial ("Only 3 available, add them?")
C) Allow customer to choose quantity
```

---

**Options:**

**Option A: All-or-nothing (reject partial)**
- Customer must reduce quantity to available
- Clear error message
- Simplest implementation

**Option B: Automatic partial fulfillment**
- System adds 3 units (maximum available)
- Customer doesn't get 5 but gets some
- Confusing (customer wanted 5)

**Option C: Offer partial with choice**
- Show: "Only 3 available. Add 3 to cart?"
- Customer clicks Yes/No
- Better UX, more complex

---

**Decision: Option A - All-or-Nothing (MVP), Option C (Future Enhancement)**

**Rationale:**

**Pros (All-or-nothing):**
- Simple implementation
- Clear customer expectation (get what you order)
- No partial fulfillment complexity

**Cons:**
- Lost sales (customer wanted 5, can't get 3)
- Friction (must manually adjust quantity)

**Accepted tradeoff:** Simplicity for MVP. Add partial offers in future based on data (how often does this happen?).

---

**Implementation (MVP):**

```
ON customer adds to cart (quantity = 5):
  READ product (get available inventory)

  IF available < quantity:
    RETURN error:
      {
        "error": "insufficient_inventory",
        "message": "Only {available} units available",
        "requested": quantity,
        "available": available,
        "suggestion": "Reduce quantity to {available} or fewer"
      }

Frontend shows:
  ❌ Only 3 units available
  [Adjust quantity to 3] [Remove from cart]

  If customer clicks "Adjust", quantity input changes to 3 automatically.
```

**Implementation (Future - Option C):**

```
ON customer adds to cart (quantity = 5):
  IF available < quantity:
    SHOW modal:
      "Only 3 units available. Would you like to add 3 to your cart?"

      [Add 3 Units] [Cancel]

    IF "Add 3 Units":
      Add 3 units to cart (partial fulfillment)
      Show success: "Added 3 units (maximum available)"

    IF "Cancel":
      Don't add to cart
```

**Edge case: Inventory changes during checkout**

```
Timeline:
T+0:  Customer adds 5 units, sees error (only 3 available)
T+1:  Customer reduces to 3, adds to cart ✓
T+5:  Another customer buys 2 units
T+6:  Inventory now: 1 available
T+10: First customer proceeds to checkout
T+11: Reservation fails (only 1 available now)

Behavior:
  ON /reserve-inventory:
    BEGIN transaction
    READ product (available = 1)
    CHECK 1 >= 3 → FAIL
    ROLLBACK
    RETURN error "Inventory changed, only 1 unit available now"

Customer must return to cart, adjust quantity again.

UX improvement: Show real-time inventory on cart page (poll every 30s).
```

---

## Summary of Decisions

| Question | Decision | Implementation Complexity |
|----------|----------|--------------------------|
| Multiple purchases → reviews? | One review per product | Low (unique index) |
| Admin edit review text? | No editing, approve/reject only | Low (workflow) |
| Review bombing prevention? | 5 layers (email normalization, rate limiting, pattern detection) | Medium |
| Review edit limits? | Escalating cooldown (1h, 24h, 7d) | Medium |
| Cart changes after code? | Warning message, validate at payment | Low |
| Duplicate code prevention? | Enforce unique codes | Low (doc ID) |
| Refunded order usage decrement? | Don't decrement | Low (no change) |
| Partial inventory fulfillment? | All-or-nothing (MVP), offer choice (future) | Low (MVP) |

---

## Edge Cases Catalog

**Review Moderation:**
1. Customer deletes review, repurchases → Allow new review
2. Admin rejects 10+ times → Flag customer for review
3. Multiple reviews with identical text → Pattern detection flags

**Discount Codes:**
4. Admin changes code minimum mid-checkout → Lock-in at payment intent
5. Admin deactivates code, wants to reuse → Force new code name
6. Customer cancels, tries to reuse code → Blocked (one-time-per-customer)

**Checkout Flow:**
7. Inventory changes during cart → checkout → Reservation fails, clear error

---

## Monitoring & Alerts

**Review Moderation:**
- Review edit count > 10 → Flag customer
- Pattern detection hits > 5/hour → Possible review bombing

**Discount Codes:**
- Duplicate code creation attempts → Admin education issue
- Refund rate > 30% for code → Marketing review

**Checkout Flow:**
- Reservation failures due to inventory changes > 10/day → UX issue (real-time inventory needed)

---

## Testing Scenarios

**Review Moderation:**
1. Customer submits second review for same product → Rejected
2. Customer edits review 4 times → Cooldown enforced
3. 5 reviews submitted in 1 minute → Rate limiting triggered

**Discount Codes:**
4. Customer reduces cart below minimum → Warning shown, payment rejected
5. Admin creates duplicate code → Error returned
6. Customer cancels order, tries code again → Rejected

**Checkout Flow:**
7. Customer adds 5 units (3 available) → Error shown, suggested reduction to 3

---

**Last Updated:** 2026-01-24
**Stage:** L2
**Status:** ✅ All important questions resolved with clear business rules
