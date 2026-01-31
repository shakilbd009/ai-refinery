# Architecture Decision Records

Index of all architectural decisions for Manik Golden Honey Co.

## Summary

| ADR | Title | Status | Category |
|-----|-------|--------|----------|
| [001](./ADR-001-pessimistic-inventory-locking.md) | Pessimistic Inventory Locking | Accepted | Inventory |
| [002](./ADR-002-review-timing-immediate.md) | Immediate Review Submission | Accepted | Reviews |
| [003](./ADR-003-cancellation-request-workflow.md) | Admin-Approved Cancellations | Accepted | Orders |
| [004](./ADR-004-discount-code-scope-order-wide.md) | Order-Wide Discount Codes | Accepted | Checkout |
| [005](./ADR-005-background-job-infrastructure.md) | Cloud Scheduler + Cloud Run Jobs | Accepted | Infrastructure |
| [006](./ADR-006-admin-notification-strategy.md) | Dashboard Badges + Email Hybrid | Accepted | Admin UX |
| [007](./ADR-007-idempotent-order-creation.md) | Dual-Path Order Creation | Accepted | Checkout |
| [008](./ADR-008-firestore-transaction-strategy.md) | Firestore Transaction Strategy | Accepted | Data |
| [009](./ADR-009-multi-layered-job-failure-mitigation.md) | Multi-Layer Job Reliability | Accepted | Operations |
| [010](./ADR-010-soft-delete-pattern.md) | Soft Delete for Products | Accepted | Data |
| [011](./ADR-011-review-moderation-workflow.md) | Approve/Reject-Only Moderation | Accepted | Reviews |
| [012](./ADR-012-discount-code-lock-in.md) | Discount Lock-In at Payment | Accepted | Checkout |

## By Category

### Inventory & Checkout
- **ADR-001:** Reserve inventory for 15 minutes during checkout (pessimistic locking)
- **ADR-004:** Order-wide percentage discounts only (no product-specific codes)
- **ADR-007:** Support both webhook and frontend order creation (idempotent)
- **ADR-012:** Lock discount value when PaymentIntent is created (5-min grace period)

### Orders & Cancellations
- **ADR-003:** Customer requests cancellation, admin approves/denies

### Reviews
- **ADR-002:** Allow immediate review submission (no delivery verification)
- **ADR-011:** Admin approves/rejects reviews (no editing customer content)

### Infrastructure & Operations
- **ADR-005:** Cloud Scheduler triggers Cloud Run for background jobs
- **ADR-006:** Admin notifications via dashboard badges + email for urgent items
- **ADR-009:** Five-layer mitigation for background job failures

### Data Management
- **ADR-008:** Firestore transactions with 3-retry limit for inventory operations
- **ADR-010:** Soft-delete products (set `active=false`) for data integrity

## Key Trade-offs

| Decision | Trade-off Accepted |
|----------|-------------------|
| Pessimistic locking | Temporary inventory reduction vs zero overselling |
| Immediate reviews | Premature reviews possible vs better submission UX |
| Admin-only cancellations | Slower process vs fraud prevention |
| Order-wide discounts | Less flexibility vs implementation simplicity |
| Multi-layer job mitigation | Complexity vs high availability |
| Soft delete | Storage growth vs data integrity |
