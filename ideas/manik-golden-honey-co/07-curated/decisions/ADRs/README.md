# Architecture Decision Records (ADRs)

This directory contains all architecture decisions for the Manik Golden Honey Co e-commerce platform.

---

## Index

### Stage 3-4 ADRs (Foundational)

**ADR-001: [Pessimistic Inventory Locking](./ADR-001-pessimistic-inventory-locking.md)**
- **Decision:** Reserve inventory BEFORE payment (not after)
- **Status:** Accepted
- **Key Tradeoff:** Prevents overselling vs temporarily reduces available inventory

**ADR-002: [Review Timing Immediate](./ADR-002-review-timing-immediate.md)**
- **Decision:** Allow reviews immediately after order (not after delivery)
- **Status:** Accepted
- **Key Tradeoff:** Fast social proof vs premature reviews

**ADR-003: [Cancellation Request Workflow](./ADR-003-cancellation-request-workflow.md)**
- **Decision:** Customer requests, admin approves/denies (not auto-cancel)
- **Status:** Accepted
- **Key Tradeoff:** Quality control vs customer friction

**ADR-004: [Discount Code Scope Order-Wide](./ADR-004-discount-code-scope-order-wide.md)**
- **Decision:** One code per order, applies to all items (not product-specific)
- **Status:** Accepted
- **Key Tradeoff:** Simplicity vs marketing flexibility

**ADR-005: [Background Job Infrastructure](./ADR-005-background-job-infrastructure.md)**
- **Decision:** Cloud Scheduler + Cloud Run (not Cloud Functions, not Cron)
- **Status:** Accepted
- **Key Tradeoff:** Reliability vs complexity

**ADR-006: [Admin Notification Strategy](./ADR-006-admin-notification-strategy.md)**
- **Decision:** Dual notifications (dashboard badges + email)
- **Status:** Accepted
- **Key Tradeoff:** Real-time awareness vs alert fatigue

---

### Stage 5 ADRs (L2 Design Decisions)

**ADR-007: [Idempotent Order Creation](./ADR-007-idempotent-order-creation.md)**
- **Decision:** Webhook primary path + frontend fallback with deduplication
- **Status:** Accepted
- **Key Tradeoff:** Complexity vs reliability (payment success → order created)
- **Solves:** Payment success but order failure, webhook/frontend race condition

**ADR-008: [Firestore Transaction Strategy](./ADR-008-firestore-transaction-strategy.md)**
- **Decision:** Use Firestore transactions for all inventory operations
- **Status:** Accepted
- **Key Tradeoff:** Latency overhead vs data integrity (zero overselling)
- **Solves:** Concurrent checkout races, concurrent cleanup races

**ADR-009: [Multi-Layered Job Failure Mitigation](./ADR-009-multi-layered-job-failure-mitigation.md)**
- **Decision:** 5-layer defense (scheduler + monitoring + manual trigger + lazy cleanup + alerts)
- **Status:** Accepted
- **Key Tradeoff:** Complexity vs availability (< 20 min MTTR)
- **Solves:** Background job failure causing inventory lockup

**ADR-010: [Soft-Delete Pattern](./ADR-010-soft-delete-pattern.md)**
- **Decision:** Set `active = false` instead of removing documents
- **Status:** Accepted
- **Key Tradeoff:** Database bloat vs data integrity (order history never breaks)
- **Solves:** Product deletion breaking orders, reviews, analytics

**ADR-011: [Review Moderation Workflow](./ADR-011-review-moderation-workflow.md)**
- **Decision:** Admin approve/reject only (no editing)
- **Status:** Accepted
- **Key Tradeoff:** Customer friction vs authenticity (reviews are customer's words)
- **Solves:** Review quality vs trust in review content

**ADR-012: [Discount Code Lock-In](./ADR-012-discount-code-lock-in.md)**
- **Decision:** Lock discount at payment intent creation with 5-min grace period
- **Status:** Accepted
- **Key Tradeoff:** Over-redemption risk vs customer trust (price shown = price charged)
- **Solves:** Code expiration during checkout, admin changes mid-checkout

---

## ADR Lifecycle

**Statuses:**
- **Proposed:** Under discussion, not yet decided
- **Accepted:** Decision made, implementation planned/in-progress
- **Deprecated:** No longer applies (superseded or obsoleted)
- **Superseded by ADR-XXX:** Replaced by newer decision

**Review schedule:**
- ADRs reviewed post-launch based on "Review Date" in each document
- Early review triggered by "Triggers for early review" criteria
- Updates documented as new ADRs (original marked "Superseded")

---

## Cross-References

**Inventory Management:**
- ADR-001 (Pessimistic Locking) → ADR-008 (Transaction Strategy) → ADR-009 (Failure Mitigation)

**Order Creation:**
- ADR-001 (Inventory Locking) → ADR-007 (Idempotent Creation) → ADR-008 (Transactions)

**Review System:**
- ADR-002 (Immediate Timing) → ADR-011 (Moderation Workflow)

**Discount Codes:**
- ADR-004 (Order-Wide Scope) → ADR-012 (Lock-In Strategy)

**Data Integrity:**
- ADR-010 (Soft-Delete) applies to products, reviews, analytics

---

## Templates

New ADRs should follow the template: [`docs/templates/adr-template.md`](../../docs/templates/adr-template.md)

Required sections:
- Status
- Context (why decision needed)
- Decision (what we're doing)
- Consequences (positive, negative, neutral)
- Alternatives Considered (with rejection rationale)
- Implementation Notes
- Success Criteria
- Review Date
- References

---

## Naming Convention

`ADR-XXX-short-descriptive-title.md`

- **XXX:** Sequential number (001, 002, ...)
- **Title:** Kebab-case, describes decision clearly
- **Examples:**
  - `ADR-013-payment-provider-selection.md`
  - `ADR-014-email-service-strategy.md`

---

**Total ADRs:** 12
**Last Updated:** 2026-01-24
**Stage:** L2 Design Complete
