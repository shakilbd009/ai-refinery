# Stage 3: Trade-Off Analysis & ADRs - Status

**Project:** Manik Golden Honey Co
**Stage:** 3 - Explore → Refine L1
**Date Started:** 2026-01-24
**Date Completed:** 2026-01-24
**Status:** ✅ Complete - Ready for Stage 4

---

## Stage 3 Completion Checklist

### ADR Creation
- [x] ADR-001: Pessimistic Inventory Locking Strategy
- [x] ADR-002: Immediate Review Timing (with admin moderation)
- [x] ADR-003: Order Cancellation Request Workflow
- [x] ADR-004: Order-Wide Discount Codes
- [x] ADR-005: Cloud Scheduler for Background Jobs
- [x] ADR-006: Dashboard Badges + Email for Admin Notifications

### Trade-Off Analysis
- [x] 2-4 alternatives considered for each major decision
- [x] Honest pros/cons documented (no rubber-stamping)
- [x] Clear decision rationale with context
- [x] Trade-offs explicitly accepted
- [x] Implementation notes provided
- [x] Success criteria defined

### Red Flags Checklist
- [x] No analysis paralysis (decisions made with 80%+ confidence)
- [x] No false precision (assumptions documented with validation)
- [x] No solution-first bias (requirements before architecture)
- [x] No ignoring trade-offs (negative consequences documented)
- [x] No hand-waving complexity (concrete implementation details)
- [x] No rubber-stamping (substantive alternatives)
- [x] No god objects (clear separation of concerns)
- [x] No "figure it out later" on critical decisions
- [x] All decisions have documented rationale
- [x] Requirements are specific and measurable
- [x] Major edge cases identified (comprehensive analysis in Stage 5)
- [x] Assumptions explicitly documented

### Documentation Quality
- [x] All ADRs follow template structure
- [x] Context sections explain why decision needed
- [x] Alternatives section complete (not empty)
- [x] Consequences sections honest (positive/negative/neutral)
- [x] Implementation notes concrete (code samples, schemas)
- [x] Success criteria measurable
- [x] Review dates set (3-6 months)

---

## Architectural Decisions Made

### 1. Pessimistic Inventory Locking (ADR-001)
**Decision:** Reserve inventory during checkout (15-min window), background job releases expired reservations

**Key Trade-Offs:**
- ✅ Prevents overselling (reputation protection)
- ❌ Reduces conversion during abandonment
- ❌ Background job complexity

**Alternative Rejected:** Accept overselling (too risky for small producer)

---

### 2. Immediate Review Timing (ADR-002)
**Decision:** Customers can review immediately after order placement

**Key Trade-Offs:**
- ✅ Higher review rate (engagement while hot)
- ✅ Simpler implementation (no delivery tracking)
- ❌ Authenticity risk (reviews before trying product)
- ✅ Mitigated by admin moderation

**Alternative Rejected:** Post-delivery reviews (adds complexity, lowers participation)

---

### 3. Cancellation Request Workflow (ADR-003)
**Decision:** Customer requests cancellation, admin approves/denies

**Key Trade-Offs:**
- ✅ Business protection (can fix issues before refunding)
- ✅ Operational insights (learn why customers cancel)
- ❌ Not instant (24-hour SLA)
- ❌ Admin workload (manual review)

**Alternative Rejected:** Instant self-service (loses Stripe fees, no fix opportunity)

---

### 4. Order-Wide Discount Codes (ADR-004)
**Decision:** Discount codes apply to entire cart, not product-specific

**Key Trade-Offs:**
- ✅ Simplest implementation (single percentage calculation)
- ✅ Clear customer UX
- ❌ Limited marketing flexibility (can't target specific products)

**Alternative Rejected:** Product-specific codes (adds significant complexity for MVP)

---

### 5. Cloud Scheduler for Background Jobs (ADR-005)
**Decision:** Cloud Scheduler triggers dedicated Cloud Run service for reservation cleanup

**Key Trade-Offs:**
- ✅ Serverless (aligns with architecture)
- ✅ Separation of concerns (isolated cleanup logic)
- ❌ Cold starts (acceptable for background job)
- ❌ Additional service to manage

**Alternative Rejected:** Cron in main API (requires min instance, couples concerns)

---

### 6. Dashboard Badges + Email Notifications (ADR-006)
**Decision:** Hybrid notification strategy (visual badges + email alerts)

**Key Trade-Offs:**
- ✅ Dual awareness (missed events unlikely)
- ✅ Actionable emails (direct links to dashboard)
- ❌ Email fatigue (multiple events = multiple emails)

**Alternative Rejected:** SMS alerts (overkill for 24-hour SLA, costly)

---

## Key Decisions Deferred

### Implementation Details (Not Critical for Architecture):
1. **Email Service Provider**: SendGrid vs Mailgun (lean toward Mailgun for deliverability)
2. **Review Edit Limits**: Unlimited vs 3 edits (recommend 3, document as business rule)
3. **Session Management**: JWT session_id for reservations (implementation detail)
4. **Logging Format**: Cloud Logging JSON standard (follow GCP best practices)

**Rationale:** These don't affect core architecture and can be decided during implementation.

---

## Open Questions Resolution

From Stage 2, resolved:
- ✅ Q2: Inventory race condition → **ADR-001 (pessimistic locking)**
- ✅ Q3: Order cancellation → **ADR-003 (request with approval)**
- ✅ Q7: Review timing → **ADR-002 (immediate, admin moderation)**
- ✅ Q9: Discount scope → **ADR-004 (order-wide only)**

Remaining (defer to Stage 4-5):
- Q1: Shipping address editing after order? (minor feature, defer)
- Q4: Multiple admin users? (future enhancement, single admin for MVP)
- Q5: Email templates needed? (implementation detail, Stage 4)
- Q6: Review notification mechanism? (**ADR-006 resolved**)
- Q8: Discount stacking? (N/A for MVP, single code only)
- Q10: Review edit limits? (business rule, not architecture)

---

## Architecture Summary

**Services:**
1. **Next.js App** (Cloud Run) - Customer storefront + admin dashboard
2. **Go API** (Cloud Run) - Business logic, data operations, payments
3. **Cleanup Service** (Cloud Run) - Background job for reservation expiry
4. **Firestore** - Database (products, orders, reviews, reservations, etc.)
5. **Cloud Scheduler** - Triggers cleanup service every 5 minutes
6. **Cloud Storage** - Product images (CDN-backed)

**Key Patterns:**
- Serverless architecture (Cloud Run auto-scaling)
- Repository pattern (database abstraction in Go API)
- Pessimistic locking (inventory reservations)
- Admin approval workflows (reviews, cancellations)
- Dual notifications (dashboard badges + email)

**Security:**
- Passwordless customer auth (6-digit email codes)
- Admin email/password auth
- JWT tokens (8-hour expiration)
- Stripe handles payment data (PCI compliance)
- Service account tokens for internal services

---

## Stage 4 Preview

**Next Stage:** Refine L1 → Refine L2 (Detailed Design)

**Objective:** First complete pass at high level

**Key Activities:**
1. Apply Progressive Deepening Template (L1 level) to major components
2. Create detailed architecture diagrams (Mermaid)
3. Map primary data flows (checkout, order fulfillment, moderation)
4. Specify component interfaces (API contracts)
5. Identify basic error scenarios
6. Document database schema in detail

**Frameworks to apply:**
- Progressive Deepening Template (L1)
- Architecture Decision Records (expand if needed)
- Trade-Off Analysis (component boundaries)

**Estimated time:** 2-3 hours for L1 level documentation

---

## Files Created in Stage 3

```
ideas/manik-golden-honey-co/
├── 03-trade-offs/
│   ├── remaining-decisions.md     (architectural decisions analysis)
│   ├── red-flags-checklist.md    (validation checklist - PASSED)
│   └── status.md                  (this file)
└── ADRs/
    ├── ADR-001-pessimistic-inventory-locking.md
    ├── ADR-002-review-timing-immediate.md
    ├── ADR-003-cancellation-request-workflow.md
    ├── ADR-004-discount-code-scope-order-wide.md
    ├── ADR-005-background-job-infrastructure.md
    └── ADR-006-admin-notification-strategy.md
```

---

## Success Metrics

**Stage 3 Goals Achieved:**
- ✅ 6 critical architectural decisions documented with ADRs
- ✅ Trade-off analysis complete for all major decisions
- ✅ Red flags checklist passed (no critical issues)
- ✅ All decisions have concrete implementation details
- ✅ Review dates set for all ADRs (3-6 months)
- ✅ No "figure it out later" on critical paths

**Quality Indicators:**
- All ADRs have substantive "Alternatives Considered" sections
- All ADRs have honest "Negative Consequences" (no rubber-stamping)
- Concrete code samples, schemas, and deployment notes included
- Measurable success criteria defined

---

**Completed By:** Claude (Systematic Refinement)
**Date:** 2026-01-24
**Ready for Stage 4:** ✅ YES
