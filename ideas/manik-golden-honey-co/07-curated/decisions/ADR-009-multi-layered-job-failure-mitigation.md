# ADR-009: Multi-Layered Background Job Failure Mitigation

## Status

Accepted

---

## Context

Background cleanup job releases expired inventory reservations (15-min TTL). Job runs every 5 minutes via Cloud Scheduler.

**Failure scenarios:**
1. Cloud Scheduler outage (GCP service down)
2. Cloud Run service crash (deployment, OOM, bug)
3. Firestore timeout (slow queries, quota)
4. Job logic error (uncaught exception)

**Impact of prolonged failure:**
- Expired reservations never released
- Inventory permanently locked (customers see "Out of stock")
- Revenue loss (can't sell available inventory)

**Key factors:**
- Cloud Scheduler SLA: 99.95% (26 min/month expected downtime)
- Single point of failure (one job for all cleanup)
- Silent failures possible (job fails, no one notices for hours)

---

## Decision

**Implement multi-layered failure mitigation with redundant cleanup mechanisms.**

**Five defensive layers:**

1. **Layer 1: Cloud Scheduler (Primary)**
   - Runs every 5 minutes (288 runs/day)
   - 3 automatic retries on failure
   - 99.95% uptime SLA
   - **CRITICAL: Uses bounded batch processing (see implementation below)**

2. **Layer 2: Job Health Monitoring**
   - Alert fires if job hasn't run in 15 minutes
   - Slack + email notification
   - Admin dashboard shows warning banner

3. **Layer 3: Manual Trigger API**
   - Admin endpoint: `POST /admin/api/cleanup-reservations`
   - One-click recovery from dashboard
   - Logs admin actions (audit trail)

4. **Layer 4: Lazy Cleanup on Checkout**
   - Checkout flow cleans expired reservations inline
   - Self-healing system (cleanup during normal operations)
   - Limits to 10 reservations (prevent timeout)

5. **Layer 5: Monitoring & Alerting**
   - Track expired reservations backlog
   - Alert if backlog > 50 (job likely failing)
   - Dashboard shows job run history (24 hours)

**Fail-over sequence:**
Scheduler runs (Layer 1) -> Alert fires at 15 min (Layer 2) -> Admin triggers manual cleanup (Layer 3) -> Lazy cleanup prevents complete lockup (Layer 4)

---

## Consequences

### Positive

- **High availability:** Multiple fallback layers prevent total failure
- **Fast recovery:** 15-minute detection + manual trigger = < 20 min downtime
- **Self-healing:** Lazy cleanup reduces impact of scheduler failure
- **Operational visibility:** Clear alerts guide admin response
- **No infrastructure dependency:** Works without external services

### Negative

- **Increased complexity:** Five layers to test and maintain
- **Alert fatigue risk:** False positives possible (transient failures)
- **Lazy cleanup overhead:** Adds 1-2 sec to checkout (only when backlog exists)
- **Not exhaustive:** Lazy cleanup limited to accessed products
- **Manual intervention:** Admin must respond to alerts (not fully automated)

### Trade-offs

- Monitoring infrastructure required (alerting, dashboard)
- Admin runbook needed for escalation procedures
- Cleanup latency increased (worst case 15-20 min vs 5 min)

---

## Alternatives Considered

### Single Layer (Cloud Scheduler Only)

Rejected because: No fallback on failure (inventory locks indefinitely), silent failures (admin unaware), 26 min/month expected downtime unacceptable, single point of failure.

### Firestore TTL (Auto-Expire Documents)

Rejected because: Feature not currently available in Firestore, still requires Cloud Function trigger to decrement `reserved_quantity`, not simpler than current approach.

### Dual Schedulers (Active-Passive)

Rejected because: Over-engineering for small scale (100 orders/day), requires distributed coordination (leader election), increased cost (two Cloud Run services).

### Customer-Triggered Cleanup Only

Rejected because: Products never accessed stay locked indefinitely, cleanup cost paid by customers (slower checkout), unfair distribution (popular products cleaned, others never).

---

## Implementation: Bounded Batch Processing (REQUIRED)

**Problem:** Unbounded cleanup queries risk memory exhaustion and timeouts if backlog grows during extended failures.

**Scenario Analysis:**
- 3-hour failure: ~600 expired reservations (~600KB memory, acceptable)
- 24-hour failure: ~4,800 reservations (~4.8MB, concerning)
- 1-week failure: ~33,600 reservations (33MB + query overhead, timeout risk)

**Solution:** Paginated batch processing with safety limits

```typescript
const BATCH_SIZE = 100;
const MAX_BATCHES_PER_RUN = 5; // Safety limit: 500 reservations max per run
const RESERVATION_TTL_MS = 10 * 60 * 1000; // 10 minutes (reduced from 15)

async function cleanupExpiredReservations(): Promise<CleanupResult> {
  let totalProcessed = 0;
  let totalReleased = 0;
  let batchCount = 0;
  let hasMore = true;

  while (hasMore && batchCount < MAX_BATCHES_PER_RUN) {
    const batch = await firestore
      .collection('reservations')
      .where('status', '==', 'active')
      .where('expires_at', '<', Date.now())
      .orderBy('expires_at', 'asc') // Oldest first
      .limit(BATCH_SIZE)
      .get();

    if (batch.empty) {
      hasMore = false;
      break;
    }

    // Process batch with parallel releases
    const releasePromises = batch.docs.map(async (doc) => {
      try {
        await releaseReservation(doc.id);
        return { id: doc.id, success: true };
      } catch (error) {
        console.error(`Failed to release ${doc.id}:`, error);
        return { id: doc.id, success: false, error };
      }
    });

    const results = await Promise.all(releasePromises);
    const released = results.filter(r => r.success).length;

    totalProcessed += batch.size;
    totalReleased += released;
    batchCount++;

    // Check if there might be more
    hasMore = batch.size === BATCH_SIZE;
  }

  const result: CleanupResult = {
    processed: totalProcessed,
    released: totalReleased,
    batches: batchCount,
    hasMorePending: hasMore,
    timestamp: new Date().toISOString(),
  };

  // Alert if backlog remains after max batches
  if (hasMore) {
    console.warn('Cleanup hit safety limit, backlog remains', result);
    await alertOps('CLEANUP_BACKLOG_REMAINING', result);
  }

  return result;
}
```

**Lazy Cleanup (Layer 4) - Enhanced:**
```typescript
const LAZY_CLEANUP_LIMIT = 25; // Increased from 10 to handle higher backlog

async function lazyCleanupForProduct(productId: string): Promise<number> {
  const expired = await firestore
    .collection('reservations')
    .where('product_id', '==', productId)
    .where('status', '==', 'active')
    .where('expires_at', '<', Date.now())
    .limit(LAZY_CLEANUP_LIMIT)
    .get();

  if (expired.empty) return 0;

  // Release in parallel (accepts 2-4s latency during recovery)
  await Promise.all(expired.docs.map(doc => releaseReservation(doc.id)));

  return expired.size;
}
```

**Circuit Breaker (Layer 5 Enhancement):**
```typescript
const BACKLOG_CRITICAL_THRESHOLD = 100;

async function checkBacklogHealth(): Promise<void> {
  const backlogCount = await firestore
    .collection('reservations')
    .where('status', '==', 'active')
    .where('expires_at', '<', Date.now())
    .count()
    .get();

  if (backlogCount.data().count > BACKLOG_CRITICAL_THRESHOLD) {
    // Block new checkouts to prevent spiral
    await setMaintenanceMode(true, 'Inventory cleanup in progress');
    await alertOps('CHECKOUT_BLOCKED_BACKLOG_CRITICAL', {
      backlog: backlogCount.data().count,
      threshold: BACKLOG_CRITICAL_THRESHOLD,
    });
  }
}
```

**Performance Guarantees:**
- Memory: Max 500 reservations × 1KB = ~500KB per run
- Execution time: <30 seconds for 500 reservations
- Bounded failure: Backlog cannot cause timeout or OOM
