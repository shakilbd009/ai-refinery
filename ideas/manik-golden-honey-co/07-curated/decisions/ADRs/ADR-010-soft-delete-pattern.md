# ADR-010: Soft-Delete Pattern for Products and Data Retention

## Status

Accepted

---

## Context

Admin needs to remove products from store (discontinued, out of season, errors). Hard-deleting products causes cascading data issues:

**Problems with hard delete:**
1. **Breaks order history** - Customer order pages show "Product not found"
2. **Orphans reviews** - 15 reviews exist for deleted product (query breaks)
3. **Breaks analytics** - Revenue reports reference missing products
4. **Breaks reservations** - Active checkouts fail (product disappeared mid-flow)
5. **No recovery** - Accidentally deleted product lost forever

**Key factors:**
- Products have complex relationships (orders, reviews, reservations, analytics)
- Deletion often temporary (seasonal products return next year)
- Admin mistakes happen (accidentally delete wrong product)
- Storage cheap (Firestore pricing negligible for product data)
- Customer expectations (order history must persist)

**Why this decision needed now:**
Data integrity is foundational. Hard deletes cause operational chaos and customer service issues. Must establish deletion pattern before implementation.

---

## Decision

**Implement soft-delete pattern: Set `active = false` instead of removing documents.**

**Core mechanism:**
- Products never hard-deleted from Firestore
- Admin "delete" action sets `active = false`, `deleted_at = timestamp`
- Public queries filter `WHERE active = true`
- Admin queries show recently deleted (90-day window for restore)
- Related data (reviews, orders, reservations) preserved intact

**Soft-delete fields:**
```
products/{productId}
  active: boolean (default: true)
  deleted_at: timestamp | null
  deleted_by: adminUserId | null
  deletion_reason: string | null (optional)
```

**Query patterns:**
- Public: `WHERE active = true` (excludes deleted)
- Admin: `WHERE active = true OR deleted_at > now - 90 days` (includes recent deletes)
- Analytics: No filter (includes all products for historical reports)

---

## Consequences

### Positive

- **Data integrity:** Order history never breaks (product always exists)
- **Graceful degradation:** Active checkouts complete normally (product soft-deleted mid-flow)
- **Accidental delete recovery:** Admin can restore within 90 days (undo button)
- **Analytics continuity:** Historical reports work (product data persists)
- **Audit trail:** Track who deleted what when (compliance, debugging)
- **Review preservation:** Customer reviews visible in admin (quality insights)

### Negative

- **Database bloat:** Deleted products accumulate (storage cost grows slowly)
- **Query complexity:** All queries must filter `active = true` (easy to forget)
- **Confusing semantics:** "Delete" doesn't actually delete (admin education needed)
- **No hard delete UI:** Admin can't truly remove products (edge case for GDPR, abuse)
- **Index overhead:** Compound indexes needed (active + other fields)

### Neutral

- Storage cost negligible (1000 deleted products ≈ $0.01/month)
- Admin UI shows "Deleted" badge (not hidden, just inactive)
- Restore function needed (admin dashboard feature)

---

## Alternatives Considered

### Alternative 1: Hard Delete with Cascade

**Why considered:**
- Clean database (no orphaned data)
- True deletion (semantically correct)
- Simpler queries (no `active` filter)

**Why rejected:**
- Breaks customer order history (unacceptable UX)
- Cascade deletes risky (accidental data loss)
- No recovery from mistakes (permanent)
- Analytics broken (historical products missing)
- Complex to implement correctly (must cascade to reviews, analytics records, etc.)

### Alternative 2: Archive Collection (Move Deleted Products)

**Why considered:**
- Separate active/deleted products (cleaner main collection)
- True deletion from main collection
- Still preserves data (archive available)

**Why rejected:**
- Breaks foreign key references (orders reference products collection, not archive)
- Requires updating all relationships (orders, reviews, analytics)
- Complex to query across both collections (active + archive)
- Not simpler than soft-delete (more infrastructure)

### Alternative 3: Versioning (Keep All Versions)

**Why considered:**
- Complete history (see product changes over time)
- Restore any version (maximum flexibility)
- Audit trail built-in (compliance)

**Why rejected:**
- Over-engineering for simple case (don't need version history)
- Complex queries (get latest active version)
- Increased storage cost (every edit = new version)
- Not solving deletion problem (still need soft-delete within versions)

### Alternative 4: Status Enum (active | deleted | archived | hidden)

**Why considered:**
- More granular states (distinguish deletion reasons)
- Future-proof (easy to add new statuses)
- Clearer semantics (status field obvious)

**Why rejected:**
- Over-engineering for MVP (two states sufficient: active/inactive)
- Query complexity (multiple status checks)
- Admin UI complexity (more buttons, more confusion)
- Can add later if needed (start simple)

---

## Implementation Notes

**Admin delete product:**
```
DELETE /admin/api/products/:productId
Authorization: Admin JWT

Implementation:
  BEGIN transaction:
    READ product (verify exists)
    UPDATE product:
      active = false
      deleted_at = now
      deleted_by = adminUserId
    COMMIT

  Response:
    {
      "success": true,
      "message": "Product marked inactive",
      "restore_available_until": deleted_at + 90 days
    }
```

**Admin restore product:**
```
POST /admin/api/products/:productId/restore
Authorization: Admin JWT

Implementation:
  BEGIN transaction:
    READ product
    IF deleted_at > now - 90 days:
      UPDATE product:
        active = true
        deleted_at = null
        deleted_by = null
      COMMIT
    ELSE:
      RETURN error "Product deleted > 90 days ago, cannot restore"
```

**Public product queries (always filter):**
```
// Product list page
products.where("active", "==", true).orderBy("name")

// Product detail page
products.doc(productId).get()
  IF product.active == false:
    SHOW "Product no longer available"
```

**Admin product queries (show recent deletes):**
```
// Admin product list
products.where("active", "==", true)  // Active tab
products.where("deleted_at", ">", now - 90 days)  // Deleted tab

// Admin product detail (always load, even if deleted)
products.doc(productId).get()  // No active filter
```

**Graceful handling in checkout:**
```
ON order creation (product soft-deleted mid-checkout):
  READ product (even if active = false)
  CREATE order (allow completion)
  Product disappears from store (no new orders)
  Customer completes checkout normally
```

**Hard delete (admin override, rare):**
```
POST /admin/api/products/:productId/hard-delete
Authorization: Admin JWT + Confirmation

Require:
  - Zero active reservations
  - Zero orders in last 7 years (GDPR retention)
  - Admin confirmation dialog ("This is permanent")

Use cases:
  - Test products (created by mistake)
  - GDPR right to deletion (customer data)
  - Abusive content (spam products)
```

---

## Success Criteria

**Data Integrity:**
- Zero broken order references (customer sees product details always)
- Zero broken analytics queries (historical reports include deleted products)
- Zero lost reviews (reviews persist with deleted products)

**Admin Experience:**
- Restore function used > 10% of deletions (mistakes caught)
- Admin understands soft-delete (no confusion tickets)
- Deletion workflow takes < 10 seconds (quick action)

**Customer Experience:**
- Zero "Product not found" errors on order history pages
- Active checkouts complete normally (soft-delete doesn't break flow)
- Product pages show clear "No longer available" message

**Storage:**
- Deleted products < 1% of total storage cost
- Storage growth linear (not exponential from accumulation)
- 1000 deleted products cost < $1/year

---

## Review Date

**6 months post-launch** - Review deleted product count, restore usage rate, storage costs. Decide on permanent deletion policy (e.g., delete after 7 years for GDPR).

**Triggers for early review:**
- Deleted products > 50% of total (unusual deletion rate)
- Storage costs > $10/month from deleted products (unexpected)
- Restore feature unused (admin might not know about it)
- Customer complaints about unavailable products (messaging unclear)

---

## References

- [enhancements-L2.md](../05-design-l2/enhancements-L2.md) - Cascade delete analysis (Q2)
- [Soft Delete Pattern](https://en.wikipedia.org/wiki/Soft_deletion) - Design pattern reference
- [GDPR Data Retention](https://gdpr-info.eu/) - Legal requirements
- Related ADRs: None (foundational data pattern)

---

**Date:** 2026-01-24
**Author(s):** Manik Golden Honey Co Design Team
**Reviewers:** Pending L2 Review
