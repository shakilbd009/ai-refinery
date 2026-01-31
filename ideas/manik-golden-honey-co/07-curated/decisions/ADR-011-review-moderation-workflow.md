# ADR-011: Review Moderation Workflow (Approve/Reject Only)

## Status

Accepted

---

## Context

Customer reviews critical for e-commerce conversion. Small producer needs authentic reviews to compete with established brands. However, immediate review submission means customers might submit premature reviews ("Can't wait to try it!").

**Admin needs moderation to:**
- Filter premature reviews (before customer tries product)
- Remove spam/abuse/competitor sabotage
- Maintain review quality (helpful to future customers)
- Build trust (only genuine reviews published)

**Key factors:**
- Trust is paramount (customers must believe reviews are real)
- Admin editing creates authenticity questions ("Did customer really write this?")
- Small volume (< 50 reviews/month initially) - manual moderation feasible
- Review timing immediate - moderation catches premature reviews

---

## Decision

**Implement approve/reject-only workflow with rejection reasons and customer revision.**

**Core mechanism:**
1. Customer submits review -> status = "pending"
2. Admin sees review in moderation queue
3. Admin chooses:
   - **Approve:** Review published immediately
   - **Reject:** Review returns to customer with reason
4. Customer receives rejection notification with edit link
5. Customer edits and resubmits -> status = "pending" (back to queue)
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

**Escalation:** After 3+ rejections, review flagged for special admin attention with options to contact customer directly or permanently reject.

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

### Trade-offs

- Rejection rate baseline unknown (will learn from production data)
- Customer resubmission rate unknown (measure engagement)
- Version history tracked for audit purposes

---

## Alternatives Considered

### Admin Can Edit Review Text

Rejected because: Trust concern (customer sees edited text, wonders "Did I write this?"), authenticity questions for future customers, accountability issue (admin owns modified content), scope creep (minor edits become major rewrites).

### Auto-Approve with Post-Moderation

Rejected because: Quality risk (premature reviews published), spam vulnerability (competitor sabotage visible before removal), reputation damage (bad review public before admin sees it), reactive not proactive approach.

### Customer Self-Service with Guidelines

Rejected because: Relies on customer compliance (many won't read guidelines), spam not prevented (automated submissions bypass self-check), no protection from competitor sabotage.

### Tiered Moderation (Trusted Customer Auto-Approve)

Rejected because: Complex trust scoring algorithm needed, edge cases for trusted customer gone rogue, small volume doesn't justify complexity. Can implement later if needed.
