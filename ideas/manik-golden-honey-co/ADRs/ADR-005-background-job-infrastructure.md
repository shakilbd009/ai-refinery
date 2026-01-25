# ADR-005: Cloud Scheduler for Background Job Infrastructure

## Status

Accepted

---

## Context

ADR-001 (Pessimistic Inventory Locking) requires a background job to clean up expired inventory reservations every 5-15 minutes. The system needs to query `inventory_reservations` where `expires_at < NOW()`, return reserved quantities to available inventory, and delete expired records.

**Key factors:**
- Job runs frequently (every 5-10 minutes)
- Critical for inventory accuracy (stale reservations block sales)
- Low compute requirements (expected < 10 expired reservations per run)
- Serverless architecture preference (GCP Cloud Run for other services)
- MVP budget constraints (minimize infrastructure costs)
- No existing job scheduler infrastructure

---

## Decision

Use **GCP Cloud Scheduler** to trigger a dedicated **Cloud Run job** for reservation cleanup.

**Architecture:**
1. Cloud Scheduler fires HTTP POST request every 5 minutes
2. POST → `/jobs/cleanup-reservations` endpoint on dedicated Cloud Run service
3. Cloud Run service runs cleanup logic (query, update, delete)
4. Returns HTTP 200 on success, 500 on failure
5. Cloud Scheduler monitors job execution and alerts on failures

---

## Consequences

### Positive

- **Serverless**: No persistent VMs to manage or pay for when idle
- **Native GCP integration**: Cloud Scheduler → Cloud Run is standard pattern
- **Scales to zero**: Cleanup service only runs when triggered (cost-efficient)
- **Monitoring built-in**: Cloud Logging captures all job executions
- **Retries**: Cloud Scheduler automatically retries failed jobs
- **HTTP-based**: Easy to test manually (curl the endpoint)
- **Separation of concerns**: Cleanup logic isolated from main API

### Negative

- **Cold starts**: First invocation may take 2-3 seconds (acceptable for background job)
- **Additional service**: Must deploy/manage separate Cloud Run service
- **Network latency**: HTTP call adds ~100ms overhead vs in-process
- **Cost**: Cloud Scheduler charges ($0.10 per job per month) + Cloud Run invocations
- **Complexity**: More moving parts than cron in main API

### Neutral

- Cloud Scheduler free tier: 3 jobs included
- Cleanup endpoint should require authentication (service account token)
- Job frequency can be tuned (5 min vs 10 min vs 15 min)

---

## Alternatives Considered

### Alternative 1: Cron Job in Main Go API

**Why considered:**
- **Simplest**: No additional service, just a goroutine with ticker
- **No HTTP overhead**: In-process execution
- **Fewer moving parts**: Single service to deploy
- **Common pattern**: Many apps run background jobs this way

**Why rejected:**
- **Requires min instance**: Must keep min 1 API instance running always (costs ~$7-10/month)
- **Couples concerns**: Cleanup logic mixed with API code
- **Less fault-tolerant**: If API crashes, cleanup stops
- **Scaling conflict**: API scales based on HTTP traffic, not job schedule
- **Testing harder**: Can't easily trigger cleanup manually
- **Violates serverless principle**: Defeats Cloud Run's scale-to-zero benefit

### Alternative 2: Firestore TTL (Time-To-Live) Policy

**Why considered:**
- **Zero code**: Firestore automatically deletes docs after TTL
- **Simplest**: Set `ttl: 15 minutes` on reservation docs
- **No infrastructure**: No scheduler, no service, no code

**Why rejected:**
- **No inventory return logic**: Firestore TTL just deletes docs, doesn't update `reserved_quantity`
- **Workaround complexity**: Would need Firestore trigger → Cloud Function → update products
- **No audit trail**: Can't log which reservations expired (debugging harder)
- **Less control**: Can't customize cleanup logic (batch updates, alerts, etc.)
- **Not truly simpler**: TTL + Cloud Function = more components than Cloud Scheduler + Cloud Run

### Alternative 3: Cloud Tasks Queue

**Why considered:**
- More sophisticated than Cloud Scheduler
- Can schedule individual tasks dynamically
- Better for variable-timing jobs

**Why rejected:**
- **Overkill**: Don't need dynamic task scheduling (fixed 5-min interval)
- **More complex**: Harder to configure than Cloud Scheduler
- **Not needed for MVP**: Cloud Scheduler sufficient for periodic job
- **Can migrate later**: Not architecturally limiting to start with Scheduler

---

## Implementation Notes

**Cloud Scheduler configuration:**
```yaml
name: cleanup-expired-reservations
schedule: "*/5 * * * *"  # Every 5 minutes
timezone: America/New_York
http_target:
  uri: https://cleanup-jobs-<hash>.run.app/jobs/cleanup-reservations
  http_method: POST
  headers:
    Authorization: Bearer ${SERVICE_ACCOUNT_TOKEN}
retry_config:
  retry_count: 3
  max_retry_duration: 3600s
```

**Cloud Run cleanup service:**
```go
// main.go
func main() {
    http.HandleFunc("/jobs/cleanup-reservations", handleCleanupReservations)
    http.ListenAndServe(":8080", nil)
}

func handleCleanupReservations(w http.ResponseWriter, r *http.Request) {
    // Auth check: verify service account token
    if !verifyServiceAccount(r) {
        http.Error(w, "Unauthorized", 401)
        return
    }

    // Cleanup logic
    ctx := context.Background()
    expired := queryExpiredReservations(ctx)

    for _, res := range expired {
        // Return reserved quantity to product
        returnReservedQuantity(ctx, res.ProductID, res.Quantity)
        // Delete reservation record
        deleteReservation(ctx, res.ID)
        // Log for audit
        log.Printf("Released reservation: %s (product: %s, qty: %d)",
            res.ID, res.ProductID, res.Quantity)
    }

    w.WriteHeader(200)
    json.NewEncoder(w).Encode(map[string]interface{}{
        "expired_count": len(expired),
        "status": "success",
    })
}
```

**Deployment:**
```bash
# Build cleanup service
gcloud builds submit --tag gcr.io/PROJECT_ID/cleanup-jobs

# Deploy to Cloud Run
gcloud run deploy cleanup-jobs \
  --image gcr.io/PROJECT_ID/cleanup-jobs \
  --platform managed \
  --region us-central1 \
  --no-allow-unauthenticated \
  --min-instances 0 \
  --max-instances 1

# Create Cloud Scheduler job
gcloud scheduler jobs create http cleanup-expired-reservations \
  --schedule="*/5 * * * *" \
  --uri="https://cleanup-jobs-<hash>.run.app/jobs/cleanup-reservations" \
  --http-method=POST \
  --oidc-service-account-email=scheduler@PROJECT_ID.iam.gserviceaccount.com
```

**Monitoring:**
- Cloud Logging: All job executions logged with expired count
- Alerting: Alert if job fails 3+ times in a row
- Dashboard: Track expired reservations per run (expect 0-5 typically)

**Testing:**
```bash
# Manual trigger for testing
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://cleanup-jobs-<hash>.run.app/jobs/cleanup-reservations
```

---

## Success Criteria

**How we'll know this decision was correct:**
- Job executes successfully > 99.9% of the time (< 1 failure per 1000 runs)
- Cold start latency < 3 seconds (acceptable for background job)
- Cleanup latency < 5 seconds per run (fast enough for 5-min interval)
- Zero inventory accuracy issues due to stale reservations
- Infrastructure cost < $2/month (Cloud Scheduler + Cloud Run invocations)

**Monitoring metrics:**
- Job execution success rate
- Average expired reservations per run
- Job execution duration (p50, p95, p99)
- Cold start frequency and duration
- Cost per month

---

## Review Date

**Review after 3 months of production use** or if:
- Job failures > 1% (reliability issue)
- Cold starts causing problems (min instance needed)
- Cost exceeds $5/month (alternative may be cheaper)
- Need for more complex scheduling (Cloud Tasks migration)

**Future enhancements:**
- Add more background jobs (email digests, analytics) to same service
- Implement job dashboard (view recent executions, manual trigger)
- Add alerting for unusual patterns (spike in expired reservations)

---

## References

- ADR-001: Pessimistic Inventory Locking (requires this background job)
- GCP Cloud Scheduler: https://cloud.google.com/scheduler/docs
- GCP Cloud Run jobs: https://cloud.google.com/run/docs/execute/jobs

---

**Date:** 2026-01-24
**Author(s):** Claude (Systematic Refinement)
**Reviewers:** [Pending]
