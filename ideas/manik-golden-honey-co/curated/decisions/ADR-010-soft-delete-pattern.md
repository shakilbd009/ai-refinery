# ADR-010: Soft-Delete Pattern for Products and Data Retention

## Status

Accepted

---

## Context

Admin needs to remove products from store (discontinued, out of season, errors). Hard-deleting products causes cascading data issues:

**Problems with hard delete:**
1. Breaks order history - Customer order pages show "Product not found"
2. Orphans reviews - Reviews exist for deleted product (query breaks)
3. Breaks analytics - Revenue reports reference missing products
4. Breaks reservations - Active checkouts fail (product disappeared mid-flow)
5. No recovery - Accidentally deleted product lost forever

**Key factors:**
- Products have complex relationships (orders, reviews, reservations, analytics)
- Deletion often temporary (seasonal products return next year)
- Admin mistakes happen (accidentally delete wrong product)
- Storage cheap (Firestore pricing negligible for product data)
- Customer expectations (order history must persist)

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

**Hard delete (admin override, rare):** Available for test products, GDPR compliance, or abusive content. Requires zero active reservations and explicit confirmation.

---

## Consequences

### Positive

- **Data integrity:** Order history never breaks (product always exists)
- **Graceful degradation:** Active checkouts complete normally (product soft-deleted mid-flow)
- **Accidental delete recovery:** Admin can restore within 90 days
- **Analytics continuity:** Historical reports work (product data persists)
- **Audit trail:** Track who deleted what when (compliance, debugging)
- **Review preservation:** Customer reviews visible in admin (quality insights)

### Negative

- **Database bloat:** Deleted products accumulate (storage cost grows slowly)
- **Query complexity:** All queries must filter `active = true` (easy to forget)
- **Confusing semantics:** "Delete" doesn't actually delete (admin education needed)
- **Index overhead:** Compound indexes needed (active + other fields)

### Trade-offs

- Storage cost negligible (1000 deleted products ~ $0.01/month)
- Admin UI shows "Deleted" badge (not hidden, just inactive)
- Restore function required in admin dashboard

---

## Alternatives Considered

### Hard Delete with Cascade

Rejected because: Breaks customer order history (unacceptable UX), cascade deletes risky (accidental data loss), no recovery from mistakes, analytics broken (historical products missing).

### Archive Collection (Move Deleted Products)

Rejected because: Breaks foreign key references (orders reference products collection), requires updating all relationships, complex to query across both collections.

### Versioning (Keep All Versions)

Rejected because: Over-engineering for simple case (don't need version history), complex queries to get latest active version, increased storage cost (every edit = new version).

### Status Enum (active | deleted | archived | hidden)

Rejected because: Over-engineering for MVP (two states sufficient), query complexity with multiple status checks, admin UI complexity. Can add granular states later if needed.
