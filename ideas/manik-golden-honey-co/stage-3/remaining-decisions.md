# Remaining Architectural Decisions - Stage 3

**Project:** Manik Golden Honey Co
**Stage:** 3 - Explore → Refine L1 (Trade-Off Analysis)
**Date:** 2026-01-24

---

## Critical Decisions Made (ADRs Created)

1. ✅ **ADR-001**: Pessimistic inventory locking with 15-min reservations
2. ✅ **ADR-002**: Immediate review submission (admin moderation mitigates risk)
3. ✅ **ADR-003**: Cancellation request with admin approval
4. ✅ **ADR-004**: Order-wide discount codes only (no product-specific)

---

## Additional Decisions Needed

### High Priority (Need ADRs)

#### 1. Background Job Infrastructure for Reservation Cleanup

**Decision needed:** How to implement the background job that releases expired inventory reservations?

**Options:**
- **A) GCP Cloud Scheduler + Cloud Run job**
  - Pros: Serverless, auto-scaling, integrated with GCP stack
  - Cons: Cold starts, additional Cloud Run service
- **B) Cron job in main Go API**
  - Pros: Simpler, no additional service
  - Cons: Requires min 1 instance always running, couples job to API
- **C) Firestore TTL (Time-To-Live) policy**
  - Pros: Zero code, Firestore handles cleanup automatically
  - Cons: No audit trail, less control over cleanup logic

**Recommendation:** Option A (Cloud Scheduler) - aligns with serverless architecture, clean separation of concerns

**ADR needed:** ADR-005

---

#### 2. Admin Notification Strategy

**Decision needed:** How should admin be notified of time-sensitive events (reviews, cancellation requests)?

**Options:**
- **A) Email only**
  - Pros: Simplest, works everywhere, no additional UI
  - Cons: Easy to miss, no urgency indicator, inbox clutter
- **B) Dashboard badges + email**
  - Pros: Visual indicator in admin UI, email backup
  - Cons: Admin must check dashboard regularly
- **C) SMS alerts for critical events**
  - Pros: Immediate notification, hard to miss
  - Cons: Costs per SMS, requires phone number, overkill for MVP?

**Recommendation:** Option B (Dashboard badges + email) - balanced approach for MVP

**ADR needed:** ADR-006

---

### Medium Priority (May Need ADRs)

#### 3. Email Service Provider Choice

**Decision needed:** SendGrid vs Mailgun vs other?

**Options:**
- **A) SendGrid**
  - Free tier: 100 emails/day
  - Pros: Popular, good docs, generous free tier
  - Cons: Delivery reputation takes time to build
- **B) Mailgun**
  - Free tier: 5,000 emails/month (first 3 months)
  - Pros: Better deliverability reputation, simpler API
  - Cons: Less generous free tier long-term
- **C) AWS SES**
  - Pay-as-you-go: $0.10 per 1,000 emails
  - Pros: Cheapest, scales infinitely
  - Cons: Requires AWS account (multi-cloud complexity)

**Recommendation:** Option B (Mailgun) - better deliverability for small sender

**ADR needed:** Possibly ADR-007 (or implementation detail)

---

#### 4. Review Edit Limitations

**Decision needed:** How many times can customer edit their review?

**Options:**
- **A) Unlimited edits (always re-moderated)**
  - Pros: Most flexible, customer-friendly
  - Cons: Admin workload if customer edits repeatedly
- **B) Limit to 3 edits**
  - Pros: Prevents abuse, reasonable allowance
  - Cons: Arbitrary limit, customer frustration if legitimate need
- **C) One edit only**
  - Pros: Simplest, minimal admin burden
  - Cons: May not be enough for legitimate corrections

**Recommendation:** Option B (limit 3 edits) - balanced approach

**ADR needed:** Possibly (or document in requirements as business rule)

---

#### 5. Checkout Session Management

**Decision needed:** How to track customer checkout sessions for inventory reservation?

**Options:**
- **A) JWT token with session_id claim**
  - Pros: Stateless, secure, expires automatically
  - Cons: Can't invalidate before expiration
- **B) Server-side session storage (Firestore)**
  - Pros: Can invalidate anytime, full control
  - Cons: Database reads on every request
- **C) Browser fingerprinting**
  - Pros: No auth required
  - Cons: Not reliable, privacy concerns

**Recommendation:** Option A (JWT with session_id) - aligns with auth pattern

**ADR needed:** Implementation detail (not critical enough for full ADR)

---

### Low Priority (Implementation Details)

#### 6. Image Storage Organization

**Decision:** Cloud Storage bucket structure for product images?

**Likely solution:** `/products/{product_id}/{image_name}` - standard pattern

**ADR needed:** No

---

#### 7. Logging Structure

**Decision:** Structured logging format (JSON with request IDs, etc.)

**Likely solution:** Standard Cloud Logging JSON format

**ADR needed:** No

---

#### 8. API Rate Limiting

**Decision:** Rate limiting strategy for public endpoints?

**Likely solution:** Cloud Run built-in rate limiting + application-level for auth endpoints

**ADR needed:** No (follow GCP best practices)

---

## Next Steps

1. **Create ADR-005**: Background Job Infrastructure (high priority)
2. **Create ADR-006**: Admin Notification Strategy (high priority)
3. **Evaluate ADR-007**: Email Service Provider (document or defer to implementation)
4. **Document business rules**: Review edit limits (not full ADR needed)
5. **Run Red Flags Checklist**: Validate all decisions made so far

---

## Stage 3 Completion Criteria

- [x] 4 critical ADRs created (inventory, reviews, cancellation, discounts)
- [ ] 2 high-priority ADRs created (background jobs, notifications)
- [ ] Trade-off analysis complete for all major decisions
- [ ] Red flags checklist passed
- [ ] Architecture diagrams updated (if needed)
- [ ] Open questions resolved or deferred with rationale
