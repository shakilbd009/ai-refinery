# ADR-009: Multi-Layered Background Job Failure Mitigation

## Status

Accepted

---

## Context

Background cleanup job releases expired inventory reservations (15-min TTL). Job runs every 5 minutes via Cloud Scheduler.

**Failure scenarios:**
1. **Cloud Scheduler outage** (GCP service down)
2. **Cloud Run service crash** (deployment, OOM, bug)
3. **Firestore timeout** (slow queries, quota)
4. **Job logic error** (uncaught exception)

**Impact of prolonged failure:**
- Expired reservations never released
- Inventory permanently locked (customers see "Out of stock")
- Revenue loss (can't sell available inventory)
- Customer frustration (products appear unavailable)

**Key factors:**
- Cloud Scheduler SLA: 99.95% (26 min/month expected downtime)
- Single point of failure (one job for all cleanup)
- Silent failures possible (job fails, no one notices for hours)
- Manual intervention needed (admin must fix)

**Why this decision needed now:**
Background job reliability directly impacts revenue. Prolonged failure locks inventory, causing sales loss. Must design robust failure mitigation before implementation.

---

## Decision

**Implement multi-layered failure mitigation with redundant cleanup mechanisms.**

**Five defensive layers:**

1. **Layer 1: Cloud Scheduler (Primary)**
   - Runs every 5 minutes (288 runs/day)
   - 3 automatic retries on failure
   - 99.95% uptime SLA

2. **Layer 2: Job Health Monitoring**
   - Alert fires if job hasn't run in 15 minutes
   - Slack + email notification
   - Admin sees "Cleanup job failing" banner

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
- Scheduler runs (Layer 1) → Alert fires at 15 min (Layer 2) → Admin triggers manual cleanup (Layer 3) → Lazy cleanup prevents complete lockup (Layer 4)

---

## Consequences

### Positive

- **High availability:** Multiple fallback layers prevent total failure
- **Fast recovery:** 15-minute detection + manual trigger = < 20 min downtime
- **Self-healing:** Lazy cleanup reduces impact of scheduler failure
- **Operational visibility:** Clear alerts guide admin response
- **No infrastructure dependency:** Works without external services (Redis, etc.)

### Negative

- **Increased complexity:** Five layers to test and maintain
- **Alert fatigue risk:** False positives possible (transient failures)
- **Lazy cleanup overhead:** Adds 1-2 sec to checkout (only when backlog exists)
- **Not exhaustive:** Lazy cleanup limited to accessed products (doesn't clean all)
- **Manual intervention:** Admin must respond to alerts (not fully automated)

### Neutral

- Monitoring infrastructure needed (alerting, dashboard)
- Admin runbook required (escalation procedures)
- Cleanup latency increased (worst case 15-20 min vs 5 min)

---

## Alternatives Considered

### Alternative 1: Single Layer (Cloud Scheduler Only)

**Why considered:**
- Simple (one mechanism)
- Lowest complexity
- Cloud Scheduler highly reliable (99.95% SLA)

**Why rejected:**
- No fallback on failure (inventory locks indefinitely)
- Silent failures (admin doesn't know job failing)
- Manual recovery requires deep technical knowledge
- 26 min/month expected downtime (unacceptable)
- Single point of failure (no redundancy)

### Alternative 2: Firestore TTL (Auto-Expire Documents)

**Why considered:**
- No background job needed (Firestore handles expiration)
- Zero maintenance (fully automated)
- Perfect reliability (built-in feature)

**Why rejected:**
- Firestore TTL not available (future feature, not current)
- Still need to decrement `reserved_quantity` (requires trigger/function)
- Cloud Function trigger adds complexity (another service)
- Not simpler than current approach (just shifts complexity)

### Alternative 3: Dual Schedulers (Active-Passive)

**Why considered:**
- Redundant schedulers (higher availability)
- Automatic failover (passive takes over)
- Industry standard pattern (proven)

**Why rejected:**
- Over-engineering for small scale (100 orders/day)
- Requires distributed coordination (leader election)
- Increased cost (two Cloud Run services)
- Complexity not justified (current approach sufficient)

### Alternative 4: Customer-Triggered Cleanup (No Background Job)

**Why considered:**
- Zero scheduler dependency (completely self-healing)
- Cleanup happens on every checkout (always fresh)
- Simpler infrastructure (no cron needed)

**Why rejected:**
- Products never accessed stay locked (inventory waste)
- Cleanup cost paid by customers (slower checkout)
- Unfair distribution (popular products cleaned frequently, others never)
- Doesn't solve problem (some inventory still locked)

---

## Implementation Notes

**Health monitoring:**
```
Collection: job_runs
  job_run_id: "cleanup-2026-01-24-10-05"
  started_at: timestamp
  completed_at: timestamp
  reservations_cleaned: 12
  status: "success" | "failed"

Monitor query:
  last_run = job_runs.orderBy("started_at", "desc").limit(1)
  IF now - last_run.started_at > 15 minutes:
    ALERT "Cleanup job not running"
```

**Manual trigger endpoint:**
```
POST /admin/api/cleanup-reservations
Headers:
  Authorization: Bearer <admin_jwt>

Response:
  {
    "job_run_id": "manual-2026-01-24-10-30",
    "reservations_cleaned": 15,
    "duration_ms": 342
  }

Implementation:
  Same logic as scheduled job
  Tagged as "manual" in job_runs (distinguish from scheduled)
  Admin action logged (audit trail)
```

**Lazy cleanup (self-healing):**
```
checkInventoryAvailability(productId):
  BEGIN transaction:
    1. READ product document
    2. QUERY expired reservations (WHERE expires_at < now, LIMIT 10)
    3. FOR EACH expired: releaseReservation(id)
    4. READ product again (recalculate available)
    5. RETURN available_quantity

  Limit to 10 prevents timeout (balance cleanup vs latency)
```

**Alert configuration:**
```
Trigger: job_runs last run > 15 minutes ago
Destinations:
  - Slack: #critical-alerts
  - Email: admin@manikgoldenhoney.com
  - Dashboard: Red banner "Cleanup job failing"

Message:
  "🚨 Inventory cleanup job hasn't run in 15+ minutes.
   Reservations may be accumulating.
   Action: Click 'Run Cleanup Now' in dashboard."
```

---

## Success Criteria

**Reliability:**
- Job success rate > 99% (scheduled + manual combined)
- Mean time to recovery (MTTR) < 30 minutes (alert → manual cleanup)
- Zero incidents of inventory locked > 4 hours

**Monitoring:**
- Alert fires within 1 minute of 15-min threshold
- Admin acknowledges alert within 15 minutes (SLA)
- Manual cleanup completes in < 60 seconds

**Self-Healing:**
- Lazy cleanup releases > 80% of expired reservations (popular products)
- Backlog never exceeds 100 (Layer 4 prevents runaway growth)
- Revenue impact < $100/incident (inventory locked briefly)

**Operational:**
- Admin runbook exists (step-by-step recovery)
- Manual trigger used < 5 times/month (scheduler mostly reliable)
- No customer complaints about false "Out of stock" (lockup prevented)

---

## Review Date

**2 weeks post-launch** - Review actual failure rate, MTTR, and lazy cleanup effectiveness. Adjust alert threshold (15 min) based on real recovery times.

**Triggers for early review:**
- Manual cleanups > 10/month (scheduler unreliable)
- MTTR > 1 hour (admin response too slow)
- Revenue loss > $500/incident (unacceptable business impact)
- Lazy cleanup insufficient (backlog growth despite Layer 4)

---

## References

- [inventory-operations-L2.md](../05-design-l2/inventory-operations-L2.md) - Detailed failure analysis
- [Cloud Scheduler Documentation](https://cloud.google.com/scheduler/docs) - GCP service details
- [Cloud Run Best Practices](https://cloud.google.com/run/docs/tips/general) - Reliability patterns
- Related ADRs:
  - ADR-005: Background Job Infrastructure (foundational decision)
  - ADR-008: Firestore Transaction Strategy (cleanup uses transactions)

---

**Date:** 2026-01-24
**Author(s):** Manik Golden Honey Co Design Team
**Reviewers:** Pending L2 Review
