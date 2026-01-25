# Progressive Deepening: Inventory Reservation System

**Component:** Pessimistic Inventory Locking with Background Cleanup
**Stage:** L1 (Refine L1 - High-Level Design)
**Date:** 2026-01-24

---

## L1 Pass: Surface Level (Stage 4: Refine L1)

### What

The inventory reservation system temporarily locks product quantities during checkout to prevent overselling. When a customer clicks "Checkout", inventory is reserved for 15 minutes. If payment succeeds, inventory is decremented and reservation deleted. If checkout is abandoned or times out, a background job releases the reservation.

**Key components:**
- Reservation creation (atomic check + lock)
- Expiration tracking (15-minute TTL)
- Background cleanup job (Cloud Scheduler every 5 min)
- Available quantity calculation: `quantity - reserved_quantity`

---

### Why

**Prevent overselling:** Small honey producer cannot afford "sorry, we're out of stock" after payment.

**High-level motivation:**
- Reputation protection (fulfill all accepted orders)
- Customer experience (no payment success → order failure scenarios)
- Operational clarity (admin knows true available inventory)
- Stripe fee avoidance (no refunds due to overselling)

**Why pessimistic locking (ADR-001):**
- Race condition prevented at reservation time
- Customer always gets what they reserve
- Trade-off: Temporarily reduces conversion (reserved inventory unavailable)

---

### Key Insight

**Inventory has three states: physical, available, and reserved.**

- **Physical quantity**: Total units in warehouse (admin manages)
- **Reserved quantity**: Sum of active reservations (system manages)
- **Available quantity**: `physical - reserved` (what customers see)

**Critical invariant:**
```
available_quantity = quantity - reserved_quantity >= 0
```

If this invariant is violated, we've oversold or have a bug.

**State transitions:**
1. **Reservation created**: `reserved_quantity += N`
2. **Payment succeeds**: `quantity -= N`, `reserved_quantity -= N`
3. **Reservation expires**: `reserved_quantity -= N`
4. **Admin updates inventory**: `quantity = X` (must check `X >= reserved_quantity`)

---

### Initial Questions Raised

1. **What if background job fails to run (Cloud Scheduler down)?**
   - Reservations never expire → inventory permanently locked → L2 mitigation

2. **What if two background jobs run simultaneously?**
   - Same reservation cleaned up twice → double-decrement bug → L2 prevention

3. **What if admin updates inventory below reserved amount?**
   - `quantity = 5`, `reserved_quantity = 10` → Negative available → L2 validation

4. **What if customer's session expires mid-checkout?**
   - Reservation persists but customer can't complete → Acceptable or needs manual release? → L2

5. **Can customer see how much time left on reservation?**
   - UX improvement (countdown timer) → L2 enhancement

6. **What if product is deleted while reservations exist?**
   - Orphaned reservations? Cascade cleanup? → L2

7. **Race condition: Two customers checkout simultaneously for last unit?**
   - Firestore transaction atomicity critical → L2 transaction design

---

## L2 Pass: Detailed Level (Stage 5: Refine L2)

*To be completed in Stage 5*

---

**Last Updated:** 2026-01-24
**Stage:** L1
