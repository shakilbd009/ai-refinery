# ADR-003: Order Cancellation Request with Admin Approval

## Status

Accepted

## Context

Customers occasionally need to cancel orders after payment (wrong address, changed mind, duplicate order, etc.). E-commerce platforms must balance customer convenience with business operational needs. For a small honey producer, every cancellation has real costs: Stripe refund fees, admin time, and potential inventory waste.

**Key factors:**
- Small business with manual fulfillment (no automated warehouse)
- Stripe refund fees: 2.9% + $0.30 not recoverable
- Low cancellation rate expected (< 5% of orders, ~0.5 per week)
- Admin needs visibility into cancellation reasons (operational insights)
- Some cancellations may be preventable (wrong address = address update, not cancellation)
- Instant self-service cancellation could be abused

## Decision

Implement **cancellation request workflow with admin approval**:

1. Customer clicks "Request Cancellation" on order detail page (if status = pending/processing)
2. Customer provides optional cancellation reason
3. System notifies admin via email immediately
4. Admin reviews request + reason in admin dashboard
5. Admin approves (triggers Stripe refund + inventory return) OR denies (with optional explanation)
6. Customer notified via email of decision

**Middle-ground approach:** More customer-friendly than "email us to cancel", but protects business from instant cancellation abuse.

## Rationale

### Why not email-only cancellation (no self-service)?

While simplest to implement, this approach was rejected because:
- **Poor UX**: Customer must find contact email, write message, wait for response
- **Unclear process**: Customer doesn't know if cancellation was received/processed
- **Higher support burden**: Emails harder to track than structured requests
- **No self-service feel**: Feels too manual for modern e-commerce expectations
- **Lost opportunity**: No structured data on cancellation reasons

### Why not instant self-service cancellation?

While providing the best customer experience, this approach was rejected because:
- **No opportunity to fix**: Customer cancels for wrong address when address update would solve it
- **Stripe fee loss**: 2.9% + $0.30 lost on every cancellation (not recoverable)
- **Abuse potential**: Customer could order, cancel, re-order repeatedly (churning fees)
- **Inventory thrashing**: Automatic inventory return may not reflect reality (product already packed)
- **No insights**: Miss opportunity to understand why customers cancel
- **Small business disadvantage**: Can't absorb cancellation costs like large businesses

### Why not time-based cancellation rules?

A hybrid approach (instant if < 1 hour, admin approval if > 1 hour) was rejected because:
- **Complexity**: Two different workflows to implement and maintain
- **Arbitrary cutoff**: 1 hour may be too short or too long depending on fulfillment speed
- **Edge cases**: What if admin already started packing at 59 minutes?
- **Not worth complexity**: For ~0.5 cancellations/week, single approval workflow is simpler

## Consequences

### Positive

- **Business protection**: Admin can address fixable issues (wrong address) before refunding
- **Operational insights**: Cancellation reasons inform product/process improvements
- **Fraud prevention**: Admin can deny suspicious cancellation patterns
- **Inventory control**: Admin decides when to return inventory (vs holding for potential re-fulfillment)
- **Customer options**: Admin can offer alternatives (change address, change product, etc.)
- **Stripe fee minimization**: Some requests may be resolvable without refund

### Negative

- **Not instant**: Customer waits for admin approval (24-hour SLA needed)
- **Admin workload**: Every cancellation requires manual review (but expected low volume)
- **Customer frustration**: May expect instant self-service like large e-commerce
- **Complexity**: More UI states (pending, approved, denied) and email templates
- **Edge cases**: What if admin is unavailable for extended period?

### Neutral

- Requires admin notification system (email alerts for new requests)
- Adds `cancellation_requests` collection to database
- Need clear SLA communication to customers ("reviewed within 24 hours")
- Admin dashboard needs cancellation queue management
