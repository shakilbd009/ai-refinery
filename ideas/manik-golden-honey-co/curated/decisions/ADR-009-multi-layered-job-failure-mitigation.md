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
