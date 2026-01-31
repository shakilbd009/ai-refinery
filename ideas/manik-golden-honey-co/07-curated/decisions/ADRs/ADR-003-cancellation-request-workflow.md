# ADR-003: Order Cancellation Request with Admin Approval

## Status

Accepted

---

## Context

Customers occasionally need to cancel orders after payment (wrong address, changed mind, duplicate order, etc.). E-commerce platforms must balance customer convenience with business operational needs. For a small honey producer, every cancellation has real costs: Stripe refund fees, admin time, and potential inventory waste.

**Key factors:**
- Small business with manual fulfillment (no automated warehouse)
- Stripe refund fees: 2.9% + $0.30 not recoverable
- Low cancellation rate expected (< 5% of orders, ~0.5 per week)
- Admin needs visibility into cancellation reasons (operational insights)
- Some cancellations may be preventable (wrong address = address update, not cancellation)
- Instant self-service cancellation could be abused

---

## Decision

Implement **cancellation request workflow with admin approval**:

1. Customer clicks "Request Cancellation" on order detail page (if status = pending/processing)
2. Customer provides optional cancellation reason
3. System notifies admin via email immediately
4. Admin reviews request + reason in admin dashboard
5. Admin approves (triggers Stripe refund + inventory return) OR denies (with optional explanation)
6. Customer notified via email of decision

**Middle-ground approach:** More customer-friendly than "email us to cancel", but protects business from instant cancellation abuse.

---

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
- **Edge cases**: What if admin is unavailable for days?

### Neutral

- Requires admin notification system (email alerts for new requests)
- Adds `cancellation_requests` collection to database
- Need clear SLA communication to customers ("reviewed within 24 hours")
- Admin dashboard needs cancellation queue management

---

## Alternatives Considered

### Alternative 1: No Self-Service Cancellation (Email Only)

**Why considered:**
- **Simplest**: No new UI, no workflow state management
- **Full control**: Admin handles all cancellations manually via email
- **Common for small businesses**: Many small e-commerce sites use this approach

**Why rejected:**
- **Poor UX**: Customer must find contact email, write message, wait for response
- **Unclear process**: Customer doesn't know if cancellation was received/processed
- **Higher support burden**: Emails harder to track than structured requests
- **No self-service feel**: Feels too manual for modern e-commerce expectations
- **Lost opportunity**: No structured data on cancellation reasons

### Alternative 2: Instant Self-Service Cancellation

**Why considered:**
- **Best UX**: Customer clicks button, order cancelled instantly, refund initiated
- **Zero admin burden**: Fully automated workflow
- **Industry standard**: Amazon, Shopify, most platforms support this
- **Fast resolution**: Customer issue resolved in seconds

**Why rejected:**
- **No opportunity to fix**: Customer cancels for wrong address when address update would solve it
- **Stripe fee loss**: 2.9% + $0.30 lost on every cancellation (not recoverable)
- **Abuse potential**: Customer could order, cancel, re-order repeatedly (churning fees)
- **Inventory thrashing**: Automatic inventory return may not reflect reality (product already packed)
- **No insights**: Miss opportunity to understand why customers cancel
- **Small business disadvantage**: Can't absorb cancellation costs like large businesses

### Alternative 3: Time-Based Cancellation Rules

**Why considered:**
- Instant cancellation if < 1 hour after order
- Admin approval if > 1 hour (product may be packed)
- Balances speed with business protection

**Why rejected:**
- **Complexity**: Two different workflows to implement and maintain
- **Arbitrary cutoff**: 1 hour may be too short (admin could pack immediately) or too long
- **Edge cases**: What if admin already started packing at 59 minutes?
- **Not worth complexity**: For ~0.5 cancellations/week, single approval workflow is simpler

---

## Implementation Notes

**UI/UX flow:**
- "Request Cancellation" button visible only if `order.status IN ('pending', 'processing')`
- Modal: "Why are you cancelling?" + textarea (optional)
- Confirmation: "Your request has been sent. We'll review within 24 hours."
- Order detail shows: "Cancellation requested - awaiting review"

**Admin dashboard:**
- Cancellation queue tab (badge count)
- Shows: Order ID, customer email, order date, cancellation reason, request date
- Actions: "Approve" (confirm dialog), "Deny" (require explanation), "Contact Customer" (opens email)
- Approve action:
  - Calls Stripe refund API
  - Returns `reserved_quantity` or `quantity` (depending on order status)
  - Updates `order.status = 'cancelled'`
  - Sends customer email: "Your cancellation was approved. Refund will appear in 5-7 days."

**Database schema:**
```
cancellation_requests {
  id: string,
  order_id: string,
  customer_id: string,
  reason: string (optional),
  status: enum('pending', 'approved', 'denied'),
  requested_at: timestamp,
  reviewed_at: timestamp (nullable),
  reviewed_by: string (admin_id),
  admin_notes: string (optional),
  denial_reason: string (optional if denied)
}
```

**Email templates needed:**
1. Customer: "Cancellation request received" (confirmation)
2. Admin: "New cancellation request" (alert with order link)
3. Customer: "Cancellation approved" (refund details)
4. Customer: "Cancellation denied" (reason + next steps)

**Admin SLA:**
- Target: Review within 24 hours
- Email alert ensures visibility
- Dashboard badge reminds admin of pending requests

**Edge case handling:**
- Order already shipped: "Request Cancellation" button hidden
- Multiple cancellation requests: Only one active request per order
- Admin unavailable: Implement "auto-approve after 48 hours" escalation (future enhancement)

---

## Success Criteria

**How we'll know this decision was correct:**
- Average admin review time < 4 hours (fast response)
- Cancellation approval rate > 70% (most are legitimate)
- Customer satisfaction with cancellation process > 4/5
- < 5% of cancellations result in customer complaints
- Admin identifies fixable issues in 20%+ of requests (address changes, etc.)
- Zero abuse/fraud cases

**Monitoring metrics:**
- Cancellation request volume per week
- Average time to admin review
- Approval vs denial rate
- Top cancellation reasons (operational insights)
- Customer feedback on cancellation experience

---

## Review Date

**Review after 6 months** or if:
- Cancellation volume exceeds 5/week (admin burden too high → consider automation)
- Denial rate < 10% (most approvals → consider instant self-service)
- Average review time > 24 hours consistently (admin capacity issue)
- Customer complaints about slow cancellation process

**Potential future enhancements:**
- Auto-approve if < 30 min after order (time-based hybrid)
- Self-service address editing (reduce cancellation need)
- Partial cancellations (remove line items, not entire order)

---

## References

- [requirements.md](../02-requirements/requirements.md) - Open Question #3 resolution
- Related ADRs: ADR-001 (inventory locking affects cancellation inventory return)
- Stripe refunds: https://stripe.com/docs/refunds

---

**Date:** 2026-01-24
**Author(s):** Claude (Systematic Refinement)
**Reviewers:** [Pending]
