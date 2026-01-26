# Component: Review Moderation

## Overview

Verified purchaser reviews with admin approval workflow (ADR-011). Immediate submission (ADR-002) with approve/reject-only moderation (no admin editing of customer content).

**Key capabilities:**
- Review submission (verified purchaser check)
- Admin moderation queue (approve/reject)
- Customer editing with escalating cooldowns
- Spam detection and flagging

## Design

### Status Flow
```
Customer submits → [pending] → Admin reviews → [approved] or [rejected]
                                     ↑
                              Customer edits (returns to pending)
```

### Triple-Gate Security
1. **Verified purchaser:** Must have confirmed order for product
2. **Admin moderation:** Manual approval before public display
3. **Edit re-moderation:** All edits return to pending

### Data Model
```typescript
reviews: {
  product_id: string,
  customer_id: string,
  order_id: string,          // Proof of purchase
  rating: number,            // 1-5
  text: string,              // 10-1000 chars
  status: string,            // pending | approved | rejected
  edit_count: number,
  next_edit_allowed_at: timestamp | null,
  rejection_reason: string | null,
  created_at: timestamp,
  moderated_at: timestamp | null,
  moderated_by: string | null
}
```

### Constraint
One review per (customer_id, product_id).

## Implementation Details

### Submission Flow
```
1. Verify customer has confirmed order for product
2. Check no existing review for this product
3. Create review with status="pending"
4. Queue admin notification email
5. Return success to customer
```

### Edit Cooldown Schedule
| Edit # | Cooldown |
|--------|----------|
| 1 | Immediate |
| 2 | 1 hour |
| 3 | 24 hours |
| 4+ | 7 days |

**Rationale:** Prevents spam while allowing legitimate revisions.

### Spam Detection
**High severity (auto-flag):**
- Contains URL + phone number
- Duplicate of 3+ other reviews

**Medium severity (flag for admin):**
- Contains URL OR phone number
- 5+ reviews from customer in 24 hours
- Same IP submitted 3+ reviews in 1 hour

### Product Aggregates
On approval:
```javascript
transaction.update(productRef, {
  total_reviews: increment(1),
  total_rating: increment(rating),
  average_rating: (total_rating + rating) / (total_reviews + 1)
});
```

On edit of approved review:
- Remove from public display (pending)
- Decrement aggregates until re-approved

## Edge Cases

**Bait-and-switch (edit after approval):**
- Customer posts positive → approved → edits to negative
- Edit returns to pending
- Admin sees "Original: ⭐⭐⭐⭐⭐ → Edited: ⭐⭐"
- Can reject obvious abuse

**Product deleted while review pending:**
- Review remains in DB (audit trail)
- Query for public reviews includes product.active check
- Customer sees "Product no longer available" in My Reviews

**Two admins approve simultaneously:**
- Transaction checks status before update
- Second gets error: "Already processed by {admin}"

## Failure Modes

**Email notification fails:**
- Review still created (email non-blocking)
- Retry queue for failed emails
- Admin dashboard is source of truth

**High spam volume:**
- Spam detection flags for priority review
- Rate limiting prevents flood
- Admin can block IP/customer

## Performance Targets

| Metric | Target |
|--------|--------|
| Submission P95 | <300ms |
| Approval P95 | <200ms |
| Moderation queue response | <24 hours |
| Spam detection accuracy | >95% |
