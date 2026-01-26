# ADR-008: Firestore Transaction Strategy for Race Prevention

## Status

Accepted

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

**Transaction patterns:**

Inventory reservation:
```
BEGIN transaction:
  READ product document
  CALCULATE available = quantity - reserved_quantity
  IF available < requested: ROLLBACK, RETURN error
  CREATE reservation document
  UPDATE product.reserved_quantity += quantity
  COMMIT
ON conflict: Retry (up to 3 attempts)
```

Reservation release:
```
BEGIN transaction:
  READ reservation document
  IF status != "active": ROLLBACK (already released, idempotent)
  READ product document
  UPDATE reservation.status = "expired"
  UPDATE product.reserved_quantity -= reservation.quantity
  COMMIT
```

Admin inventory update:
```
BEGIN transaction:
  READ product document
  VALIDATE newQuantity >= reserved_quantity
  IF invalid: ROLLBACK, RETURN error with details
  UPDATE product.quantity = newQuantity
  COMMIT
```

## Consequences

### Positive

- **Zero overselling:** Conflict detection prevents race conditions
- **Data integrity:** Invariants maintained automatically
- **Simple mental model:** Operations are atomic (no partial states)
- **Automatic retries:** Firestore handles transient conflicts
- **Audit trail:** Transaction failures logged for debugging

### Negative

- **Increased latency:** Transaction overhead 50-100ms vs direct write
- **Retry delays:** Conflicting transactions retry with exponential backoff (100-500ms)
- **Transaction limits:** 500 writes per transaction (cart size limit needed)
- **Cost:** Transactions count as multiple operations
- **Complexity:** Must structure all operations as transactions

### Trade-offs

| Approach | Latency | Complexity | Safety | Infrastructure |
|----------|---------|------------|--------|----------------|
| Firestore Transactions | Medium | Medium | High | None (built-in) |
| Optimistic Locking | Low | High | Medium | None |
| Distributed Locks (Redis) | Medium | High | High | Redis cluster |
| Single-Threaded Queue | High | High | Highest | Job queue |

## Alternatives Rejected

**Optimistic Locking:** Requires manual conflict detection, custom retry logic, partial state possible between operations, doesn't prevent all races.

**Distributed Locks (Redis):** Additional infrastructure, network dependency, deadlock potential if client crashes, over-engineering when Firestore transactions solve the problem.

**Single-Threaded Queue:** Poor scalability (bottleneck), increased latency (queue wait), bad UX (customer waits for queue position).

## References

- ADR-001: Pessimistic Inventory Locking (foundational decision)
- ADR-007: Idempotent Order Creation (uses transactions)
- Firestore Transactions: https://firebase.google.com/docs/firestore/manage-data/transactions
