# L3: Review Moderation System - Exhaustive Design

**Component:** Customer Reviews & Admin Moderation Workflow
**Stage:** L3 (Refine L3 - Exhaustive Coverage)
**Date:** 2026-01-24

---

## L3 Pass: Exhaustive Coverage (Stage 6: Refine L3)

### Complete Flow Variants

All possible review submission and moderation paths documented with precise handling.

---

## Variant 1: Happy Path - First Review Submission (Expected 70% of Reviews)

**Preconditions:**
- Customer has completed at least one order
- Customer has not previously reviewed this product
- Customer session is valid
- Product is active (not deleted)

**Flow:**

```
1. Customer navigates to "My Orders" page
   Shows list of completed orders with "Write Review" button

2. Customer clicks "Write Review" for Wildflower Honey 12oz
   → Frontend: GET /api/products/{productId}/review-eligibility

3. Backend validates eligibility (50-100ms):

   BEGIN transaction
     READ orders WHERE customer_id = X AND product_id = Y AND status = "confirmed"
     IF no orders found:
       RETURN 403 "You must purchase this product to review it"

     READ reviews WHERE customer_id = X AND product_id = Y
     IF review found:
       RETURN 409 "You already reviewed this product"

   RETURN 200 { eligible: true, order_id: "ord_123" }

4. Frontend shows review form:
   - Star rating (1-5 stars, required)
   - Review text (textarea, 10-1000 characters, required)
   - [Cancel] [Submit Review]

5. Customer writes review, clicks "Submit Review"
   Frontend validation:
     - Rating selected (1-5)
     - Text length 10-1000 characters
     - No URLs detected (basic regex check)
     - No email addresses detected

   → POST /api/reviews

6. Backend creates review (100-200ms):

   Request:
   {
     "product_id": "prod_abc123",
     "order_id": "ord_xyz789",
     "rating": 5,
     "text": "This honey is amazing! Perfect for my morning tea."
   }

   BEGIN transaction
     Verify eligibility again (prevent race condition):
       READ orders WHERE order_id = X AND customer_id = session.customer_id
       IF not found: RETURN 403 "Order not found"

       READ reviews WHERE customer_id = session.customer_id AND product_id = Y
       IF found: RETURN 409 "Already reviewed"

     CREATE review document:
       review_id: auto-generated
       product_id: from request
       customer_id: from session
       order_id: from request
       rating: from request
       text: from request
       status: "pending"
       submitted_at: now
       edit_count: 0
       next_edit_allowed_at: null

     CREATE review_history entry:
       review_id: review_id
       version: 1
       text: original text
       rating: original rating
       action: "submitted"
       timestamp: now

   COMMIT transaction

   Send notification to admin:
     queue_email_job({
       to: admin@manikgoldenhoney.com,
       template: "new_review_pending",
       review_id: review.id,
       product_name: product.name,
       customer_email: customer.email
     })

   Update admin dashboard badge:
     INCREMENT pending_reviews_count

   RETURN 201 {
     "review_id": "rev_abc123",
     "status": "pending",
     "message": "Review submitted for approval"
   }

7. Frontend shows success:
   "✓ Review submitted!

    Your review will appear after admin approval (usually within 24 hours).

    [View My Reviews]"

8. Admin receives email notification (within 2 minutes):
   Subject: New review pending approval

   Product: Wildflower Honey 12oz
   Customer: john@example.com
   Rating: ⭐⭐⭐⭐⭐

   Review:
   "This honey is amazing! Perfect for my morning tea."

   [Approve] [Reject]

9. Admin clicks "Approve" in email or dashboard
   → POST /admin/api/reviews/{reviewId}/approve

10. Backend processes approval (100-200ms):

    Verify admin session:
      IF not admin: RETURN 403 "Unauthorized"

    BEGIN transaction
      READ review
      IF status != "pending":
        RETURN 400 "Review already processed"

      UPDATE review:
        status = "approved"
        approved_by = admin_id
        approved_at = now

      UPDATE product (aggregate review stats):
        total_reviews += 1
        total_rating += review.rating
        average_rating = total_rating / total_reviews

    COMMIT transaction

    Send confirmation to customer:
      queue_email_job({
        to: customer.email,
        template: "review_approved",
        review_id: review.id,
        product_name: product.name,
        product_url: site_url + "/products/" + product.id
      })

    Decrement admin badge:
      DECREMENT pending_reviews_count

    RETURN 200 "Review approved"

11. Customer receives approval email (within 2 minutes):
    Subject: Your review is now live!

    Hi John,

    Your review for Wildflower Honey 12oz has been approved and is now visible to other customers.

    [View Your Review]

12. Review appears on product page:
    Public query: WHERE product_id = X AND status = "approved"
    Shows: Customer name, rating, text, date

Total duration: 24 hours typical (mostly waiting for admin review)
Backend processing: < 1 second total
```

**Success criteria:**
- Review submission < 300ms
- Admin approval < 200ms
- Customer notification < 5 minutes
- Review visible within 1 minute of approval

---

## Variant 2: Review Rejected - Customer Edits and Resubmits (15% of Reviews)

**Trigger:** Admin rejects review due to policy violation

**Flow:**

```
1-8. [Same as happy path - review submitted, admin receives notification]

9. Admin reviews submission:
   Sees issue: Review mentions external website ("Buy from honey.com!")

10. Admin clicks "Reject" in dashboard
    Rejection modal shows:
      Reason (required):
      [ ] Contains personal information
      [ ] Spam or promotional content
      [x] Inappropriate language / External references
      [ ] Product not tried yet
      [ ] Other: [text field]

    Admin selects "Inappropriate language / External references"
    Adds note: "Please remove the external website reference"

    [Cancel] [Submit Rejection]

11. Backend processes rejection (100-200ms):

    BEGIN transaction
      READ review
      IF status != "pending":
        RETURN 400 "Review already processed"

      UPDATE review:
        status = "rejected"
        rejected_by = admin_id
        rejected_at = now
        rejection_reason = "Inappropriate language / External references"
        rejection_note = "Please remove the external website reference"
        next_edit_allowed_at = now (immediate edit allowed after first rejection)

      CREATE review_history entry:
        review_id: review.id
        version: 1
        action: "rejected"
        reason: rejection_reason
        note: rejection_note
        timestamp: now

    COMMIT transaction

    Send notification to customer:
      queue_email_job({
        to: customer.email,
        template: "review_rejected",
        review_id: review.id,
        product_name: product.name,
        rejection_reason: reason,
        rejection_note: note,
        edit_url: site_url + "/reviews/" + review.id + "/edit"
      })

    Decrement admin badge:
      DECREMENT pending_reviews_count

    RETURN 200 "Review rejected"

12. Customer receives rejection email (within 2 minutes):
    Subject: Your review needs revision

    Hi John,

    Your review for Wildflower Honey 12oz could not be approved:

    Reason: Inappropriate language / External references
    Note: Please remove the external website reference

    Original review:
    "This honey is amazing! Buy from honey.com!"

    [Edit Review]

13. Customer clicks "Edit Review"
    → GET /reviews/{reviewId}/edit

    Backend validates:
      IF review.customer_id != session.customer_id:
        RETURN 403 "Not your review"

      IF review.next_edit_allowed_at > now:
        RETURN 429 {
          "error": "edit_cooldown_active",
          "message": "You can edit again at {next_edit_allowed_at}",
          "retry_after_seconds": seconds_remaining
        }

      RETURN 200 {
        review: review data,
        rejection_reason: reason,
        rejection_note: note
      }

    Frontend shows edit form:
      Status: ⚠️ Needs Revision

      Rejection reason: Inappropriate language / External references
      Admin note: Please remove the external website reference

      Your review:
      [Text area with current review text]
      ⭐⭐⭐⭐⭐ (rating editable)

      [Cancel] [Submit Revised Review]

14. Customer edits text, clicks "Submit Revised Review"
    Removed external reference, new text: "This honey is amazing! Perfect quality."

    → PUT /api/reviews/{reviewId}

15. Backend processes edit (150-250ms):

    Validate cooldown:
      IF review.next_edit_allowed_at > now:
        RETURN 429 "Edit cooldown active"

    BEGIN transaction
      READ review
      IF status not in ["rejected", "approved"]:
        RETURN 400 "Cannot edit review in current state"

      CREATE review_history entry:
        review_id: review.id
        version: review.edit_count + 1
        text: new_text
        rating: new_rating
        action: "edited"
        previous_status: review.status
        timestamp: now

      UPDATE review:
        text = new_text
        rating = new_rating (if changed)
        status = "pending"
        edited_at = now
        edit_count += 1
        next_edit_allowed_at = calculateCooldown(edit_count)

      Calculate cooldown:
        SWITCH edit_count:
          CASE 1: return now (immediate)
          CASE 2: return now + 1 hour
          CASE 3: return now + 24 hours
          CASE 4+: return now + 7 days

    COMMIT transaction

    Notify admin (new review in queue):
      queue_email_job({
        template: "review_edited",
        note: "Customer edited after rejection (attempt #{edit_count})"
      })

    INCREMENT pending_reviews_count

    RETURN 200 "Review resubmitted"

16. Admin reviews edited version:
    Dashboard shows:
      "Edited review (2nd attempt)"
      Previous version: "This honey is amazing! Buy from honey.com!"
      Current version: "This honey is amazing! Perfect quality."

    Admin approves ✓

17. Review goes live (same as happy path approval)
```

**Customer experience:**
- Clear rejection reason
- Actionable feedback (admin note)
- Easy edit flow (one click from email)
- Immediate resubmission (first edit)

**Monitoring:**
- Track rejection rate (target < 30%)
- Track resubmission rate after rejection (target > 60%)
- Track approval rate on 2nd attempt (target > 80%)

---

## Variant 3: Multiple Rejections - Escalating Cooldown (3% of Reviews)

**Trigger:** Customer submits poor quality review multiple times

**Flow:**

```
1. First rejection: Immediate edit allowed (covered in Variant 2)
   edit_count = 1, next_edit_allowed_at = now

2. Customer edits and resubmits within 5 minutes

3. Second rejection: Still has issues (e.g., too short)

   Backend calculates cooldown:
     edit_count = 2
     next_edit_allowed_at = now + 1 hour

   Email to customer:
     "Your review needs revision

      You can edit again in 1 hour.

      This helps prevent spam and gives you time to write a thoughtful review."

4. Customer tries to edit immediately:
   → GET /reviews/{reviewId}/edit

   Backend:
     IF now < next_edit_allowed_at:
       RETURN 429 {
         "error": "edit_cooldown_active",
         "message": "You can edit again at {time}",
         "retry_after_seconds": 3400,
         "reason": "Multiple edits require cooldown to prevent spam"
       }

   Frontend shows:
     "⏱️ Edit cooldown active

      You can edit this review again in 56 minutes.

      Multiple edits require a waiting period to ensure quality reviews.

      [View My Reviews]"

5. Customer waits 1 hour, edits again

6. Third rejection: Still problematic

   Backend calculates cooldown:
     edit_count = 3
     next_edit_allowed_at = now + 24 hours

   Email to customer:
     "Your review needs revision

      You can edit again in 24 hours.

      Please review our guidelines: [Review Guidelines Link]"

7. Customer waits 24 hours, edits again

8. Fourth rejection: Persistent issues

   Backend calculates cooldown:
     edit_count = 4
     next_edit_allowed_at = now + 7 days

   Flag for admin attention:
     CREATE admin_alert:
       type: "struggling_reviewer"
       review_id: review.id
       customer_id: customer.id
       edit_count: 4
       message: "Customer has edited review 4 times, all rejected"

   Admin dashboard shows alert

9. Admin options:

   A) Contact customer directly:
      Email customer explaining review guidelines
      Offer to help write acceptable review

   B) Approve with warning:
      "Review is borderline but acceptable"
      Approve to avoid customer frustration

   C) Permanently reject:
      Final rejection with detailed explanation
      Customer cannot edit further

10. Monitoring alert:
    IF edit_count > 5:
      ALERT "Customer {email} has edited review {review_id} 5+ times"
      Possible bad actor or confused customer
```

**Cooldown schedule:**
- Edit 1: Immediate (0 min)
- Edit 2: 1 hour cooldown
- Edit 3: 24 hour cooldown
- Edit 4+: 7 day cooldown

**Escalation criteria:**
- 3+ rejections → Show review guidelines link
- 4+ rejections → Flag for admin attention
- 5+ rejections → Alert (possible abuse or confusion)

**Monitoring:**
- Track reviews with 3+ edits (target < 5%)
- Track reviews with 5+ edits (target < 1%)
- Alert if same customer has multiple reviews with 3+ edits

---

## Variant 4: Spam Detection Triggers - Auto-Flag for Review (5% of Reviews)

**Trigger:** Review submission matches spam patterns

**Flow:**

```
1. Customer submits review with suspicious characteristics:
   - Identical text to another review (copy-paste spam)
   - Contains external URL
   - Multiple reviews from same IP within 5 minutes
   - Contains phone number or email address

2. Frontend validation (basic):
   - Detects URLs: regex /https?:\/\//
   - Detects emails: regex /\S+@\S+\.\S+/
   - Shows warning: "Reviews cannot contain URLs or email addresses"
   - Customer can still submit (maybe false positive)

3. Backend spam detection (comprehensive):

   POST /api/reviews
   Request: { rating: 5, text: "Great! Call 555-1234" }

   Spam checks:
     1. Pattern Detection:
        CHECK FOR:
          - Phone numbers: /\d{3}[-.]?\d{3}[-.]?\d{4}/
          - Emails: /\S+@\S+\.\S+/
          - URLs: /https?:\/\/|www\./
          - Common spam phrases: ["buy now", "click here", "limited time"]

     2. Duplicate Text Detection:
        QUERY reviews WHERE text = submitted_text
        IF count > 0:
          Flag as potential spam

     3. Rate Limiting:
        QUERY reviews WHERE customer_id = X AND created_at > now - 1 day
        IF count >= 5:
          Flag as potential spam (review bombing)

     4. IP Pattern Detection:
        QUERY reviews WHERE ip_address = X AND created_at > now - 1 hour
        IF count > 3:
          Flag as potential spam

   IF any spam indicators detected:
     CREATE review with additional flags:
       status = "pending"
       flagged = true
       flag_reasons = ["phone_number_detected", "rate_limit_high"]
       flagged_at = now

     SEND alert to admin:
       "⚠️ Spam-flagged review

        Product: {product_name}
        Customer: {email}
        Flags: Phone number detected, High rate limit
        IP: {ip_address}

        Review text:
        {text}

        [Review Now]"

     RETURN 201 "Review submitted" (don't tell customer it's flagged)

4. Admin sees flagged review in dashboard:
   Moderation queue shows:
     🚩 FLAGGED REVIEW (priority)

     Product: Wildflower Honey
     Customer: john@example.com
     IP: 192.168.1.1

     Flags:
     - Phone number detected: "555-1234"
     - Similar to 0 other reviews

     Review:
     "Great! Call 555-1234"

     [Approve] [Reject as Spam] [View History]

5. Admin actions:

   A) Approve (false positive):
      Review appears normally
      Clears flagged status

   B) Reject as Spam:
      Review rejected with reason "Spam or promotional content"
      Customer can edit and resubmit
      IP address noted (3 spam rejections → 24h IP block)

   C) Block Customer (severe spam):
      Customer account blocked from reviewing
      All reviews from customer rejected
      Email sent: "Account suspended for spam activity"

6. Automatic spam actions (if confidence high):

   IF multiple severe indicators:
     - Contains URL AND phone number
     - Duplicate of 3+ other reviews
     - Customer has 5+ spam-flagged reviews

   THEN auto-reject:
     status = "rejected"
     rejection_reason = "Spam or promotional content"
     flagged = true
     auto_rejected = true

   SEND email to customer:
     "Review rejected (spam detected)

      Your review was automatically rejected due to spam indicators.

      If this was a mistake, please contact support."
```

**Spam detection patterns:**

**Severity: HIGH (auto-reject)**
- Contains URL + phone number
- Exact duplicate of 3+ reviews
- Customer has 5+ rejected spam reviews

**Severity: MEDIUM (flag for admin)**
- Contains URL OR phone number
- Contains spam keywords
- Duplicate of 1-2 reviews
- 5+ reviews from customer in 24 hours

**Severity: LOW (log but allow)**
- Single suspicious word
- Borderline rate limit (3-4 reviews/day)
- IP shared with 2-3 other customers

**Monitoring:**
- Track spam detection rate (target < 5%)
- Track false positive rate (admin approves flagged review - target < 20%)
- Track auto-reject accuracy (target > 95%)

---

## Variant 5: Customer Edits Approved Review - Returns to Moderation (5% of Reviews)

**Trigger:** Customer wants to update their review after it's already live

**Flow:**

```
1. Customer has approved review visible on product page

2. Customer navigates to "My Reviews"
   Sees: "✓ Approved" badge on review
   Clicks "Edit Review"

3. Frontend shows edit form:
   Current review:
   ⭐⭐⭐⭐⭐
   "This honey is great!"

   Note: "Editing will remove your review from the product page until re-approved by admin."

   [Cancel] [Save Changes]

4. Customer edits: Changes rating from 5 stars to 4 stars
   New text: "This honey is great, but a bit pricey."

   Clicks "Save Changes"

5. Frontend shows confirmation:
   "⚠️ Are you sure?

    Your review will be removed from the product page and require admin re-approval.

    This prevents abuse of the edit feature.

    [Cancel] [Yes, Update Review]"

6. Customer confirms

7. Backend processes edit (same as rejected review edit):

   BEGIN transaction
     READ review
     IF status != "approved":
       RETURN 400 "Can only edit approved reviews"

     CREATE review_history entry:
       version: edit_count + 1
       previous_text: old_text
       previous_rating: old_rating
       action: "edited_after_approval"

     UPDATE review:
       text = new_text
       rating = new_rating
       status = "pending"
       edited_at = now
       edit_count += 1
       previously_approved_at = approved_at
       approved_at = null
       approved_by = null

     UPDATE product (revert aggregates):
       total_reviews -= 1
       total_rating -= old_rating
       average_rating = total_rating / total_reviews

   COMMIT transaction

   Notify admin:
     "Review edited after approval (requires re-review)"

   INCREMENT pending_reviews_count

8. Review removed from product page:
   Public query excludes status = "pending"
   Customers no longer see this review

9. Admin re-reviews:
   Dashboard shows:
     "🔄 RE-REVIEW NEEDED

      Customer edited approved review

      Original (approved):
      ⭐⭐⭐⭐⭐ "This honey is great!"

      Edited version (pending):
      ⭐⭐⭐⭐ "This honey is great, but a bit pricey."

      [Approve] [Reject]"

10. Admin approves edited version:

    UPDATE review:
      status = "approved"
      approved_at = now
      approved_by = admin_id

    UPDATE product (re-add to aggregates):
      total_reviews += 1
      total_rating += new_rating
      average_rating = total_rating / total_reviews

11. Review reappears on product page with updated content
```

**Bait-and-switch prevention:**

Why edit returns to moderation:
- Customer could post positive review (get approved)
- Then edit to negative/spam content (bypass moderation)
- Requiring re-approval prevents this abuse

**Customer education:**
- Clear warning before editing approved review
- Explanation of why re-approval needed
- Alternative: "Delete and create new review" (same outcome)

**Monitoring:**
- Track edit-after-approval rate (target < 10%)
- Track time between approval and edit (detect bait-and-switch patterns)
- Alert if customer edits multiple approved reviews within short time

---

## Timeout Handling

### Timeout 1: Review Submission

**Timeout:** 10 seconds (Firestore transaction)

```
Frontend: POST /api/reviews (timeout: 10s)

Backend:
  BEGIN transaction (Firestore timeout: 10s)
    ...create review...
  COMMIT

If timeout:
  Transaction rolls back
  RETURN 504 "Submission timeout, please try again"

Frontend:
  Shows error with retry:
    "Submission taking longer than usual

     [Try Again] [Cancel]"

  Retry logic:
    - Auto-retry once after 2 seconds
    - If second attempt times out, show manual retry button
    - Preserve form data (don't lose customer's review text)
```

**Edge case: Duplicate submission on retry**

```
Customer submits, times out, retries
First attempt actually succeeded (slow commit)
Second attempt checks for existing review:
  READ reviews WHERE customer_id = X AND product_id = Y
  IF found: RETURN 409 "You already reviewed this product"

Customer sees: "You already submitted a review for this product"
```

---

### Timeout 2: Admin Moderation Action

**Timeout:** 5 seconds (simple update)

```
Admin: POST /admin/api/reviews/{id}/approve (timeout: 5s)

Backend:
  BEGIN transaction
    UPDATE review status
    UPDATE product aggregates
  COMMIT

If timeout:
  RETURN 504 "Action timeout"

Admin dashboard:
  Shows error: "Action failed, please try again"
  Review stays in queue (not removed)
  Admin can retry immediately
```

---

## Error Scenarios (Exhaustive List)

### Category 1: Eligibility Errors

**E1.1: Customer hasn't purchased product**
```
Trigger: Customer tries to review product they never ordered
Detection: Query orders, no results found
Response: 403 {
  "error": "not_purchased",
  "message": "You must purchase this product to review it"
}
Frontend: "Purchase this product to leave a review"
```

**E1.2: Customer already reviewed product**
```
Trigger: Customer tries to submit second review for same product
Detection: Query reviews, existing review found
Response: 409 {
  "error": "already_reviewed",
  "message": "You already reviewed this product",
  "existing_review_id": "rev_123"
}
Frontend: "You already reviewed this product. [View Review] [Edit Review]"
```

**E1.3: Product deleted while writing review**
```
Trigger: Admin deletes product, customer submits review
Detection: Product query returns active = false
Response: 400 {
  "error": "product_unavailable",
  "message": "This product is no longer available"
}
Frontend: "Product no longer available for review"
```

---

### Category 2: Validation Errors

**E2.1: Review text too short**
```
Trigger: Customer submits < 10 characters
Detection: Frontend AND backend validation
Response: 400 "Review must be at least 10 characters"
Frontend: Shows character count: "8/10 minimum"
```

**E2.2: Review text too long**
```
Trigger: Customer submits > 1000 characters
Detection: Frontend prevents typing beyond limit
Backend: 400 "Review exceeds 1000 character limit"
```

**E2.3: No rating selected**
```
Trigger: Customer submits without selecting stars
Detection: Frontend prevents submission
Backend: 400 "Rating required"
```

**E2.4: Review contains profanity (optional filter)**
```
Trigger: Review contains blacklisted words
Detection: Backend profanity filter
Action: Flag review, don't auto-reject
Admin sees warning: "Possible profanity detected"
```

---

### Category 3: Rate Limiting Errors

**E3.1: Too many reviews in short time**
```
Trigger: Customer submits 6 reviews in 1 hour
Detection: Query review count by customer + time
Response: 429 {
  "error": "rate_limit_exceeded",
  "message": "Maximum 5 reviews per hour. Try again later.",
  "retry_after_seconds": 1800
}
Frontend: "Please wait 30 minutes before submitting another review"
Monitoring: Alert if hit frequently (possible review bombing)
```

**E3.2: Edit cooldown active**
[Covered in Variant 3]

---

### Category 4: Admin Action Errors

**E4.1: Review already processed**
```
Trigger: Two admins try to approve same review simultaneously
Detection: Review status check before update
Response: 400 {
  "error": "already_processed",
  "message": "Review already approved by {admin_name}",
  "approved_at": timestamp
}
Admin UI: Removes review from queue, shows toast notification
```

**E4.2: Admin tries to reject without reason**
```
Trigger: Admin clicks reject, doesn't select reason
Detection: Frontend prevents submission
Backend: 400 "Rejection reason required"
Admin UI: "Please select a rejection reason"
```

---

### Category 5: Email Notification Errors

**E5.1: Customer email notification fails**
```
Trigger: Mailgun down, invalid email, etc.
Detection: Email send API error
Action:
  - Log warning (non-blocking)
  - Mark review with email_sent = false
  - Retry every 5 minutes (up to 3 attempts)
  - Admin dashboard shows "Email failed" badge
  - Manual resend option available

Customer impact: Minimal (review still processed, just no email)
```

**E5.2: Admin email notification fails**
```
Trigger: Admin email down
Detection: Email send error
Action:
  - Log warning
  - Admin dashboard still shows pending review badge
  - Admin sees review on next dashboard visit

Admin impact: Delayed notification, not critical
```

---

## Performance Characteristics

### Latency Budget

**Review Submission:**
- Target: P50 < 150ms, P95 < 300ms, P99 < 500ms
- Components:
  - Eligibility check: 30-50ms
  - Review creation: 50-100ms
  - Email queueing: 20-40ms
- Total: 100-190ms typical

**Admin Approval:**
- Target: P50 < 100ms, P95 < 200ms, P99 < 400ms
- Components:
  - Review update: 40-60ms
  - Product aggregates update: 30-50ms
  - Email queueing: 20-40ms
- Total: 90-150ms typical

**Review Query (Public Product Page):**
- Target: P50 < 50ms, P95 < 100ms, P99 < 200ms
- Query: WHERE product_id = X AND status = "approved"
- Index: (product_id, status, approved_at)
- Pagination: 10 reviews per page

---

### Throughput Estimates

**Review Submissions:**
- Expected: 10-20 reviews/day (year 1)
- Capacity: 1000+ reviews/hour (Firestore limit)
- No bottleneck identified

**Admin Moderation:**
- Expected: 10-20 approvals/day
- Capacity: Limited by admin availability, not system
- Queue processing time: < 2 min per review

---

### Scaling Limits

**Review Count per Product:**
- Small products: 10-50 reviews
- Popular products: 100-500 reviews
- Query pagination: 10 per page (scalable)
- Aggregates cached in product document (O(1) reads)

**Concurrent Review Submissions:**
- Firestore handles 10,000 writes/second
- Expected: < 5 concurrent submissions
- No contention expected

---

## Security Considerations

### Attack Vector 1: Review Bombing

**Attack:** Create many fake accounts, submit negative reviews

**Mitigation (5 layers from business-rules-L2):**
1. **Email normalization:** Gmail+aliases blocked
2. **Rate limiting:** 5 reviews/day per customer
3. **Pattern detection:** Duplicate text flagged
4. **Admin moderation:** All reviews reviewed before publish
5. **IP tracking:** Multiple accounts from same IP flagged

**Detection:**
- Multiple reviews with identical/similar text
- Multiple new accounts from same IP
- All reviews 1-star for same product
- High submission rate from single customer

**Response:**
- Flag reviews for admin attention
- Block IP after 3 spam detections (24 hours)
- Ban customer account after 5 spam reviews
- Alert security team on bombing patterns

---

### Attack Vector 2: Bait-and-Switch Reviews

**Attack:** Post positive review, get approved, edit to negative/spam

**Mitigation:**
- Edits return to moderation queue (Variant 5)
- Admin sees original vs edited version
- Version history tracked (audit trail)

**Detection:**
- Reviews edited within 24 hours of approval (suspicious)
- Rating change > 2 stars (5→3 or worse)
- Text completely replaced (not minor edits)

**Response:**
- Admin reviews edited version carefully
- Reject if bait-and-switch detected
- Ban customer if pattern of abuse

---

### Attack Vector 3: Competitor Sabotage

**Attack:** Competitor posts negative reviews to damage reputation

**Mitigation:**
- Verified purchaser requirement (must buy product)
- Cost per review: $15-50 (product price)
- Admin moderation catches suspicious patterns

**Detection:**
- New customer, first order, immediate negative review
- Multiple negative reviews from similar accounts
- Review text mentions competitor products

**Response:**
- Extra scrutiny on first-time negative reviews
- Contact customer to verify authenticity
- Report fraudulent accounts to payment processor

---

## Monitoring & Observability

### Critical Metrics

**1. Review Funnel**
```
order_completed → review_eligible → review_submitted → review_approved → review_live

Conversion rates:
  eligible → submitted: 30% (30% of customers review)
  submitted → approved: 80% (20% rejected)
  approved → live: 100% (all approved go live)

Targets:
  - Submission rate: > 25%
  - Approval rate: > 70%
  - Rejection rate: < 30%
```

**2. Moderation Queue Metrics**
```
- Pending review count (gauge)
- Average time to approval (hours)
- Admin approval throughput (reviews/hour)
- Rejection rate by reason (%)

Targets:
  - Pending count: < 20 at any time
  - Time to approval: < 24 hours (P95)
  - Throughput: > 10 reviews/hour (when admin active)
```

**3. Review Quality Metrics**
```
- Average review length (characters)
- Average rating (stars)
- Edit rate (% of reviews edited)
- Multi-rejection rate (% with 3+ edits)

Targets:
  - Average length: > 50 characters
  - Average rating: 4.0-4.5 stars
  - Edit rate: < 20%
  - Multi-rejection: < 5%
```

**4. Spam Detection Metrics**
```
- Spam flag rate (% of submissions flagged)
- False positive rate (% of flagged reviews approved)
- Auto-reject rate (% auto-rejected by spam filter)
- IP block rate (IPs blocked per day)

Targets:
  - Flag rate: < 10%
  - False positive: < 20%
  - Auto-reject: < 2%
```

---

### Logging Strategy

**INFO level:**
- Review submitted (review_id, customer_id, product_id, rating)
- Review approved (review_id, admin_id, time_to_approval)
- Review edited (review_id, edit_count, previous_status)

**WARN level:**
- Review flagged for spam (review_id, flag_reasons)
- Review rejected (review_id, rejection_reason)
- Edit cooldown hit (customer_id, cooldown_remaining)

**ERROR level:**
- Review submission failed (customer_id, error_message)
- Email notification failed (review_id, email_type)
- Admin action failed (review_id, action, error)

**CRITICAL level:**
- Review bombing detected (product_id, ip_address, review_count)
- Customer banned for spam (customer_id, spam_count)

---

## Testing Strategy

### Unit Tests (30-40 tests)

**reviewSubmission():**
- Happy path (eligible customer)
- Not purchased (403 error)
- Already reviewed (409 error)
- Text too short/long
- Spam detection triggers
- Rate limit exceeded

**adminApproval():**
- Happy path (pending → approved)
- Already processed error
- Aggregate updates correct
- Email notification queued

**reviewEdit():**
- Edit rejected review (immediate)
- Edit after cooldown
- Edit approved review (returns to pending)
- Cooldown calculation (1h, 24h, 7d)

---

### Integration Tests (15-20 tests)

**Test 1: End-to-end happy path**
1. Customer purchases product
2. Customer submits review → pending
3. Admin approves → live
4. Review appears on product page
5. Product aggregates updated

**Test 2: Rejection and resubmission**
1. Customer submits review with URL
2. Admin rejects with reason
3. Customer receives email
4. Customer edits, removes URL
5. Resubmits → pending
6. Admin approves → live

**Test 3: Spam detection and flagging**
1. Customer submits review with phone number
2. Spam detection flags review
3. Admin sees flagged badge
4. Admin rejects as spam
5. IP address logged
6. Second spam from IP → blocked

**Test 4: Edit cooldown enforcement**
1. Customer submits review
2. Rejected → edit count = 1
3. Edits and resubmits
4. Rejected → edit count = 2, cooldown = 1h
5. Tries to edit immediately → 429 error
6. Waits 1 hour → edit allowed

---

### Load Tests

**Scenario 1: Review submission spike**
- 100 customers submit reviews simultaneously
- Measure: P95 latency, error rate
- Success: P95 < 500ms, error rate < 1%

**Scenario 2: Admin moderation throughput**
- 50 pending reviews in queue
- Admin approves as fast as possible
- Measure: Approvals per minute, UI responsiveness
- Success: > 20 approvals/minute, UI < 200ms response

---

## Success Criteria (Quantified)

**Customer Experience:**
- > 90% of reviews approved on first submission
- < 24 hours time to approval (P95)
- < 5% of customers hit edit cooldown
- > 60% resubmission rate after rejection

**Admin Efficiency:**
- < 2 minutes per review moderation
- > 80% approval rate (well-written reviews)
- < 10% spam flag rate (manageable volume)

**System Performance:**
- P95 review submission < 300ms
- P95 approval action < 200ms
- 100% of reviews eventually processed

**Trust & Quality:**
- Average review length > 50 characters
- < 2% spam reviews reach approval
- Zero bait-and-switch incidents
- > 4.0 average rating across products

---

**Last Updated:** 2026-01-24
**Stage:** L3
**Status:** ✅ Complete - Exhaustive scenario coverage achieved
**Confidence Level:** 95%+
