# ADR-011: Review Moderation Workflow (Approve/Reject Only)

## Status

Accepted

---

## Context

Customer reviews critical for e-commerce conversion. Small producer needs authentic reviews to compete with established brands. However, immediate review submission (ADR-002) means customers might submit premature reviews ("Can't wait to try it!").

**Admin needs moderation to:**
- Filter premature reviews (before customer tries product)
- Remove spam/abuse/competitor sabotage
- Maintain review quality (helpful to future customers)
- Build trust (only genuine reviews published)

**Moderation approaches:**

1. **No moderation** - Publish all reviews immediately (risky)
2. **Admin edits review text** - Fix issues, keep review (trust concern)
3. **Admin approve/reject only** - Binary decision (authentic but strict)
4. **Customer self-moderates** - System auto-approves after criteria met (complex)

**Key factors:**
- Trust is paramount (customers must believe reviews are real)
- Admin editing creates authenticity questions (did customer really write this?)
- Small volume (< 50 reviews/month initially) - Manual moderation feasible
- Review timing immediate (ADR-002) - Moderation catches premature reviews

**Why this decision needed now:**
Review authenticity is core value proposition. Wrong moderation approach damages trust. Must resolve before implementation.

---

## Decision

**Implement approve/reject-only workflow with rejection reasons and customer revision.**

**Core mechanism:**
1. Customer submits review → status = "pending"
2. Admin sees review in moderation queue
3. Admin chooses:
   - **Approve:** Review published immediately
   - **Reject:** Review returns to customer with reason
4. Customer receives rejection notification with edit link
5. Customer edits and resubmits → status = "pending" (back to queue)
6. Admin re-reviews edited version

**No admin editing allowed:**
- Admin cannot modify review text
- Customer owns review content (verbatim)
- Rejection reasons guide customer fixes

**Rejection reasons (predefined):**
- Contains personal information (email, phone, address)
- Spam or promotional content
- Inappropriate language
- Product not tried yet (premature review)
- Other: [admin free-text explanation]

---

## Consequences

### Positive

- **Authentic reviews:** Customer's own words (no admin tampering)
- **Clear ownership:** Customer accountable for content
- **Trust preserved:** No questions about edited reviews
- **Simple workflow:** Binary decision (approve vs reject)
- **Customer education:** Rejection reasons teach guidelines
- **Audit trail:** Track who approved/rejected when (compliance)

### Negative

- **More back-and-forth:** Customer must edit and resubmit (slower)
- **Can't fix typos:** Admin sees obvious typo, must reject whole review
- **Customer friction:** Rejection feels harsh (even with explanation)
- **Admin workload:** Review-reject-resubmit cycle takes more time than quick edit
- **Abandonment risk:** Customer might not resubmit after rejection

### Neutral

- Rejection rate baseline unknown (will learn from production data)
- Customer resubmission rate unknown (measure engagement)
- Version history tracked (see edit progression)

---

## Alternatives Considered

### Alternative 1: Admin Can Edit Review Text

**Why considered:**
- Faster moderation (fix typo, approve immediately)
- Better customer experience (no rejection)
- Simpler workflow (one step: edit + approve)
- Industry standard (many platforms allow admin editing)

**Why rejected:**
- **Trust concern:** Customer sees edited text, wonders "Did I write this?"
- **Authenticity question:** Future customers doubt review legitimacy
- **Accountability issue:** Admin owns modified content (liability)
- **Scope creep:** Minor edits become major rewrites
- **Not scalable:** As volume grows, editing burden increases

### Alternative 2: Auto-Approve with Post-Moderation

**Why considered:**
- Instant publication (best customer experience)
- Scalable (no moderation bottleneck)
- Most reviews legitimate (low abuse rate expected)

**Why rejected:**
- **Quality risk:** Premature reviews published ("Shipping was fast, haven't tried yet")
- **Spam vulnerability:** Competitor sabotage visible before removal
- **Reputation damage:** Bad review public before admin sees it
- **Reactive not proactive:** Damage done before moderation
- **Doesn't align with ADR-002:** Immediate review timing requires moderation

### Alternative 3: Customer Self-Service with Guidelines

**Why considered:**
- No admin moderation needed (customer checks criteria themselves)
- Scalable (zero admin workload)
- Educational (customers learn guidelines upfront)

**Why rejected:**
- **Trust on customer compliance:** Many won't read guidelines
- **Spam not prevented:** Automated submissions bypass self-check
- **Quality inconsistent:** Customers interpret guidelines differently
- **No protection:** Competitor sabotage published automatically

### Alternative 4: Tiered Moderation (Trusted Customer Auto-Approve)

**Why considered:**
- Reduced moderation load (trusted customers bypass queue)
- Rewards good behavior (previous approved reviews = trust)
- Scalable (as base grows, auto-approve % increases)

**Why rejected:**
- **Complex to implement:** Trust scoring algorithm needed
- **Edge cases:** How to handle trusted customer gone rogue?
- **Small volume:** < 50 reviews/month doesn't justify complexity
- **Premature optimization:** Build simple first, optimize later if needed

---

## Implementation Notes

**Admin moderation UI:**
```
Moderation Queue Page:
  Pending Reviews: 3

  Review #1:
    Product: Wildflower Honey 12oz
    Customer: john@example.com (2 previous orders)
    Rating: ⭐⭐⭐⭐⭐
    Submitted: 2026-01-24 10:30 AM

    Review text (read-only):
    "This honey is amazing! Buy from Manik's shop on Main St."

    [Approve] [Reject]

    If Reject clicked:
      Reason: [ ] Personal information
              [ ] Spam/promotional
              [ ] Inappropriate language
              [ ] Product not tried yet
              [x] Other: "Please remove store address reference"

      [Submit Decision]

Action handling:
  ON approve:
    UPDATE review:
      status = "approved"
      approved_by = adminUserId
      approved_at = now
    SEND email: "Your review is now live!"

  ON reject:
    UPDATE review:
      status = "rejected"
      rejected_by = adminUserId
      rejected_at = now
      rejection_reason = selectedReason
    SEND email with rejection reason + edit link
```

**Customer rejection notification:**
```
Email subject: Your review needs revision

Hi John,

Your review for Wildflower Honey 12oz could not be approved:

Reason: Please remove store address reference

Original review:
"This honey is amazing! Buy from Manik's shop on Main St."

Reviews should focus on the product itself, not include
store locations or external references.

Please edit your review:
[Edit Review Button] → links to review edit page

Thank you for taking the time to review our products!

Manik Golden Honey Co
```

**Customer edit flow:**
```
Review edit page (customer sees rejected review):
  Status: Needs Revision

  Rejection reason:
  "Please remove store address reference"

  Edit your review:
  [Text area with original review text]
  ⭐⭐⭐⭐⭐ (rating editable)

  [Cancel] [Submit Revised Review]

ON submit:
  UPDATE review:
    text = new_text
    rating = new_rating
    status = "pending"
    edited_at = now
    edit_count++
  SEND notification to admin (new review in queue)
```

**Version history tracking:**
```
Collection: review_history
  review_id: "abc123"
  version: 1
  text: "Original text"
  status: "rejected"
  rejection_reason: "Personal information"
  timestamp: 2026-01-24 10:30

  version: 2
  text: "Edited text"
  status: "pending"
  timestamp: 2026-01-24 11:00

Admin can view history:
  "Customer edited 2 times, rejected 1 time"
```

**Escalation (multiple rejections):**
```
IF review.edit_count >= 3:
  Flag review for manual admin attention
  Admin dashboard shows: "Struggling Customer" badge
  Admin can:
    - Contact customer directly (clarify expectations)
    - Approve with warning (borderline acceptable)
    - Permanently reject (customer not complying)
```

---

## Success Criteria

**Review Quality:**
- Approval rate > 80% (most reviews acceptable on first submission)
- Resubmission rate > 60% (rejected customers edit and resubmit)
- Average edits per review < 1.5 (few back-and-forth cycles)

**Customer Experience:**
- Time to approval < 24 hours (fast moderation)
- Rejection notification clear (customers understand why)
- Resubmission successful rate > 90% (edits fix issues)

**Admin Efficiency:**
- Moderation time < 2 min per review (quick decision)
- Rejection reasons used > 95% (predefined options sufficient)
- "Other" reason < 20% (predefined reasons cover most cases)

**Trust:**
- Zero customer complaints about edited reviews (none exist)
- Customer survey: 90%+ believe reviews are authentic
- Competitor review sabotage detected and rejected (moderation works)

---

## Review Date

**3 months post-launch** - Review approval rate, resubmission rate, rejection reasons distribution. Assess whether admin editing would significantly improve efficiency without harming trust.

**Triggers for early review:**
- Approval rate < 60% (too strict, need clearer guidelines)
- Resubmission rate < 30% (customers abandoning after rejection)
- Admin editing requested > 10 times (workflow pain point)
- Customer complaints about rejection process (UX issue)

---

## References

- [business-rules-L2.md](../stage-5/business-rules-L2.md) - Detailed moderation analysis (Q2)
- [Review Quality Best Practices](https://www.shopify.com/blog/product-reviews) - Industry patterns
- Related ADRs:
  - ADR-002: Review Timing Immediate (drives moderation need)

---

**Date:** 2026-01-24
**Author(s):** Manik Golden Honey Co Design Team
**Reviewers:** Pending L2 Review
