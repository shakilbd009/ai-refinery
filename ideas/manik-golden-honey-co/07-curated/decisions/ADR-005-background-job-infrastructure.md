# ADR-005: Cloud Scheduler for Background Job Infrastructure

## Status

Accepted

## Context

ADR-001 (Pessimistic Inventory Locking) requires a background job to clean up expired inventory reservations every 5-15 minutes. The system needs to query `inventory_reservations` where `expires_at < NOW()`, return reserved quantities to available inventory, and delete expired records.

**Key factors:**
- Job runs frequently (every 5-10 minutes)
- Critical for inventory accuracy (stale reservations block sales)
- Low compute requirements (expected < 10 expired reservations per run)
- Serverless architecture preference (GCP Cloud Run for other services)
- MVP budget constraints (minimize infrastructure costs)

## Decision

Use **GCP Cloud Scheduler** to trigger a dedicated **Cloud Run job** for reservation cleanup.

**Architecture:**
1. Cloud Scheduler fires HTTP POST request every 5 minutes
2. POST triggers `/jobs/cleanup-reservations` endpoint on dedicated Cloud Run service
3. Cloud Run service runs cleanup logic (query, update, delete)
4. Returns HTTP 200 on success, 500 on failure
5. Cloud Scheduler monitors job execution and alerts on failures

**Deployment configuration:**
- Cloud Run: `--min-instances 0 --max-instances 1 --no-allow-unauthenticated`
- Cloud Scheduler: `*/5 * * * *` with OIDC authentication
- Retry config: 3 attempts with 1-hour max retry duration

## Consequences

### Positive

- **Serverless**: No persistent VMs to manage or pay for when idle
- **Native GCP integration**: Cloud Scheduler to Cloud Run is standard pattern
- **Scales to zero**: Cleanup service only runs when triggered (cost-efficient)
- **Monitoring built-in**: Cloud Logging captures all job executions
- **Retries**: Cloud Scheduler automatically retries failed jobs
- **HTTP-based**: Easy to test manually via curl
- **Separation of concerns**: Cleanup logic isolated from main API

### Negative

- **Cold starts**: First invocation may take 2-3 seconds (acceptable for background job)
- **Additional service**: Must deploy and manage separate Cloud Run service
- **Network latency**: HTTP call adds ~100ms overhead vs in-process
- **Cost**: Cloud Scheduler ($0.10/job/month) plus Cloud Run invocations

### Trade-offs

| Factor | Cloud Scheduler + Cloud Run | Cron in Main API | Firestore TTL |
|--------|------------------------------|------------------|---------------|
| Cost | ~$2/month | ~$7-10/month (min instance) | Free but incomplete |
| Complexity | Medium | Low | Low code, high orchestration |
| Fault tolerance | High (auto-retry) | Low (API crash stops job) | Medium |
| Testability | High (curl endpoint) | Low | Low |
| Custom logic | Full control | Full control | Requires Cloud Function |

## Alternatives Rejected

**Cron Job in Main API:** Requires minimum 1 instance running always ($7-10/month), couples cleanup with API logic, violates serverless scale-to-zero principle.

**Firestore TTL:** Only deletes documents, cannot execute return-to-inventory logic. Would require TTL + Cloud Function trigger, adding more components than chosen approach.

**Cloud Tasks Queue:** Overkill for fixed-interval periodic job. Cloud Scheduler sufficient; can migrate later if dynamic scheduling needed.

## References

- ADR-001: Pessimistic Inventory Locking (requires this background job)
- GCP Cloud Scheduler: https://cloud.google.com/scheduler/docs
- GCP Cloud Run: https://cloud.google.com/run/docs
