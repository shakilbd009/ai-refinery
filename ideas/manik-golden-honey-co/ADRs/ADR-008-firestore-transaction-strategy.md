# ADR-008: Firestore Transaction Strategy for Race Prevention

## Status

Accepted

---

## Context

Inventory reservation system faces critical race conditions:

1. **Concurrent checkout:** Two customers checkout last unit simultaneously
2. **Concurrent cleanup:** Two background jobs release same reservation
3. **Concurrent updates:** Admin updates inventory while customer reserves

**Without atomicity:**
- Overselling (two customers get last unit)
- Inventory corruption (reserved_quantity double-decremented)
- Negative inventory (admin sets quantity below reserved amount)

**Key factors:**
- Small producer cannot afford overselling (reputation damage)
- Data corruption causes operational chaos (admin can't trust inventory counts)
- Race conditions are inevitable (concurrent users, background jobs)
- Must guarantee invariant: `available = quantity - reserved_quantity >= 0`

**Why this decision needed now:**
Inventory management is core business logic. Race conditions cause revenue loss, customer dissatisfaction, and data integrity issues. Must resolve before implementation.

---

## Decision

**Use Firestore transactions with pessimistic locking for all inventory operations.**

**Core principles:**
1. **Read-check-write within transaction:** All inventory operations atomic
2. **Automatic retry on conflict:** Firestore handles contention (up to 3 attempts)
3. **Serializable isolation:** Transactions execute as if sequential
4. **Conflict detection:** Second transaction sees conflict, retries with fresh data

**Operations requiring transactions:**
- Inventory reservation (customer checkout)
- Reservation release (order creation, background cleanup)
- Admin inventory updates (validate against reserved_quantity)
- Order creation (decrement inventory, delete reservation)

**Transaction guarantees leveraged:**
- **Atomicity:** All-or-nothing (reservation created + inventory incremented together)
- **Isolation:** Concurrent transactions don't see intermediate states
- **Durability:** Committed changes persist (no partial state)

---

## Consequences

### Positive

- **Zero overselling:** Conflict detection prevents race conditions
- **Data integrity:** Invariants maintained automatically
- **Simple mental model:** Operations are atomic (no partial states)
- **Automatic retries:** Firestore handles transient conflicts (no custom retry logic)
- **Audit trail:** Transaction failures logged (debugging race conditions)

### Negative

- **Increased latency:** Transaction overhead 50-100ms (vs direct write)
- **Retry delays:** Conflicting transactions retry (exponential backoff adds 100-500ms)
- **Transaction limits:** 500 writes per transaction (cart limit needed)
- **Cost:** Transactions count as multiple operations (slightly higher Firestore costs)
- **Complexity:** Must structure all operations as transactions (can't use direct writes)

### Neutral

- Firestore quota limits apply (10,000 writes/second per database)
- Contention monitoring needed (high conflict rate indicates hot products)
- Testing requires concurrency simulation (harder than serial tests)

---

## Alternatives Considered

### Alternative 1: Optimistic Locking (Version Numbers)

**Why considered:**
- Lower latency (no transaction overhead)
- Simpler code (read, increment version, write)
- Better performance under low contention

**Why rejected:**
- Manual conflict detection (must check version on write)
- Custom retry logic needed (Firestore doesn't handle)
- Partial state possible (reservation created, inventory not updated)
- Complex debugging (harder to trace conflict sources)
- Doesn't prevent all races (version check has window)

### Alternative 2: Distributed Locks (Redis/Memcached)

**Why considered:**
- Explicit lock visibility (admin can see locks)
- Configurable timeout (finer control)
- Works across multiple databases (if needed)

**Why rejected:**
- Additional infrastructure (Redis cluster, monitoring)
- Network dependency (lock service outage breaks checkouts)
- Deadlock potential (lock held indefinitely if client crashes)
- Over-engineering (Firestore transactions solve problem)
- Increased operational complexity (another service to manage)

### Alternative 3: Single-Threaded Queue (Job Processor)

**Why considered:**
- Zero race conditions (sequential processing)
- Simple reasoning (no concurrency)
- Guaranteed ordering (FIFO)

**Why rejected:**
- Poor scalability (bottleneck on single thread)
- Increased latency (queue wait time)
- Complex infrastructure (job queue, workers)
- Customer waits for queue position (bad UX)
- Doesn't solve admin update conflicts (async operation)

---

## Implementation Notes

**Inventory reservation transaction:**
```
reserveInventory(productId, customerId, quantity):
  BEGIN Firestore transaction:
    1. READ product document
    2. CALCULATE available = quantity - reserved_quantity
    3. IF available < quantity: ROLLBACK, RETURN error
    4. CREATE reservation document
    5. UPDATE product.reserved_quantity += quantity
    6. COMMIT transaction

  ON conflict (another transaction modified product):
    Retry transaction (up to 3 attempts)
    IF still failing: RETURN error "High demand, try again"
```

**Reservation release transaction:**
```
releaseReservation(reservationId):
  BEGIN Firestore transaction:
    1. READ reservation document
    2. IF status != "active": ROLLBACK (already released, idempotent)
    3. READ product document
    4. UPDATE reservation.status = "expired"
    5. UPDATE product.reserved_quantity -= reservation.quantity
    6. COMMIT transaction

  Idempotency: Second release sees status = "expired", exits early
```

**Admin inventory update transaction:**
```
updateProductInventory(productId, newQuantity):
  BEGIN Firestore transaction:
    1. READ product document
    2. VALIDATE newQuantity >= reserved_quantity
    3. IF invalid: ROLLBACK, RETURN error with details
    4. UPDATE product.quantity = newQuantity
    5. COMMIT transaction

  Validation prevents negative available inventory
```

**Critical patterns:**
- Always read before write (within transaction)
- Check conditions after read (before write)
- Handle ROLLBACK explicitly (clear error messages)
- Log conflicts (track contention by product)

---

## Success Criteria

**Data Integrity:**
- Zero negative inventory incidents (available < 0)
- Zero overselling incidents (two orders for last unit)
- Zero inventory corruption (reserved_quantity != SUM(active reservations))

**Performance:**
- Transaction conflict rate < 5% (under normal load)
- Transaction retry success rate > 95% (conflicts resolve on retry)
- P95 transaction latency < 200ms (including retries)
- P99 transaction latency < 500ms (worst case)

**Scalability:**
- Handles 100 concurrent checkouts without degradation
- Hot product (50% of traffic) maintains < 10% conflict rate
- Background cleanup completes in < 30 seconds for 500 reservations

**Monitoring:**
- Track transaction conflicts per product (identify hot products)
- Alert if conflict rate > 20% (indicates contention issue)
- Dashboard shows retry distribution (P50, P95, P99)

---

## Review Date

**1 month post-launch** - Review actual conflict rates, retry distribution, and performance under real load. Adjust retry limits and error thresholds based on data.

**Triggers for early review:**
- Conflict rate > 15% sustained (consider sharding hot products)
- Customer complaints about "High demand, try again" errors
- Transaction latency P99 > 1 second (performance issue)

---

## References

- [inventory-race-conditions-L2.md](../stage-5/inventory-race-conditions-L2.md) - Detailed race condition analysis
- [Firestore Transactions](https://firebase.google.com/docs/firestore/manage-data/transactions) - Official documentation
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices) - Performance guidance
- Related ADRs:
  - ADR-001: Pessimistic Inventory Locking (foundational decision)
  - ADR-007: Idempotent Order Creation (uses transactions)

---

**Date:** 2026-01-24
**Author(s):** Manik Golden Honey Co Design Team
**Reviewers:** Pending L2 Review
