# Operational Runbooks

**Project:** Manik Golden Honey Co
**Purpose:** Incident response, recovery procedures, and on-call operations

---

## Incident Response Quick Reference

### Critical Alerts (Page Immediately)

| Alert | Condition | Immediate Action |
|-------|-----------|------------------|
| API Down | Health check fails 2x | Rollback to previous revision |
| Error Rate > 10% | 5xx for 3 min | Rollback to previous revision |
| Payment Failures | > 5 in 5 min | Check Stripe status, investigate logs |
| Database Connection Failed | 1 minute | Check Firestore status, verify IAM |

### Warning Alerts (Slack Notification)

| Alert | Condition | Response Window |
|-------|-----------|-----------------|
| Error Rate 5-10% | 5xx for 5 min | 15 minutes |
| P95 Latency > 2s | 10 min sustained | 30 minutes |
| Order Volume < 50% baseline | 1 hour | 1 hour |
| Webhook Retry Rate > 10% | 30 min | 1 hour |

---

## Emergency Rollback Procedure

**Execute in < 5 minutes when triggered by critical alert.**

### Option A: Traffic Shift (Fastest - 30 seconds)

```bash
# 1. List recent revisions
gcloud run revisions list --service=go-api --region=us-central1 --limit=5

# 2. Route all traffic to previous revision
gcloud run services update-traffic go-api \
  --to-revisions=go-api-PREVIOUS_SHA=100 \
  --region=us-central1

# 3. Verify
curl -sf https://api.manikgoldenhoney.com/api/health
```

### Option B: Redeploy Known Good Image (2-3 minutes)

```bash
# Find last known good image
gcloud container images list-tags gcr.io/$PROJECT_ID/go-api --limit=10

# Deploy that image
gcloud run deploy go-api \
  --image=gcr.io/$PROJECT_ID/go-api:KNOWN_GOOD_SHA \
  --region=us-central1 \
  --platform=managed
```

### Full Stack Rollback Script

```bash
#!/bin/bash
export PROJECT_ID="manik-honey-prod"
export REGION="us-central1"
export API_GOOD_SHA="abc123"
export WEB_GOOD_SHA="def456"

gcloud run deploy go-api --image=gcr.io/$PROJECT_ID/go-api:$API_GOOD_SHA --region=$REGION
gcloud run deploy nextjs-app --image=gcr.io/$PROJECT_ID/nextjs-app:$WEB_GOOD_SHA --region=$REGION

curl -sf https://api.manikgoldenhoney.com/api/health || echo "API FAILED"
curl -sf https://manikgoldenhoney.com/api/health || echo "WEB FAILED"
```

---

## Common Incident Playbooks

### Stripe Webhook Failures

**Symptoms:** Orders not created after payment, customer complaints

**Diagnosis:**
```bash
# Check webhook logs
gcloud logging read 'resource.labels.service_name="go-api" AND jsonPayload.endpoint="/webhooks/stripe"' --limit=50

# Verify endpoint reachable (expect 400, not 500/timeout)
curl -X POST https://api.manikgoldenhoney.com/webhooks/stripe -H "Content-Type: application/json" -d '{"test": true}'
```

**Resolution by Cause:**
| Cause | Fix |
|-------|-----|
| Secret mismatch | Update in Secret Manager, redeploy |
| Endpoint timeout | Check logs, scale up Cloud Run |
| Order creation error | Check Firestore connectivity |

**Manual Order Recovery:**
```bash
curl -X POST https://api.manikgoldenhoney.com/admin/orders/recover \
  -H "Authorization: Bearer $ADMIN_JWT" \
  -d '{"payment_intent_id": "pi_xxx", "force_create": true}'
```

### High Error Rate

**Diagnosis:**
```bash
# Identify error types
gcloud logging read 'resource.labels.service_name="go-api" AND severity>=ERROR' --limit=100

# Check recent deployments
gcloud run revisions list --service=go-api --region=us-central1 --limit=5
```

**Resolution by Pattern:**
| Error Pattern | Cause | Fix |
|---------------|-------|-----|
| "connection refused" | Firestore down | Check GCP status |
| "context deadline exceeded" | Timeout | Increase timeout |
| "permission denied" | IAM issue | Check service account |
| New errors after deploy | Code bug | Rollback immediately |

### Database Contention

**Symptoms:** Transaction conflicts, elevated latency on inventory ops

**Diagnosis:**
```bash
gcloud logging read 'jsonPayload.message=~"transaction|conflict"' --limit=50
```

**Resolution:**
| Cause | Fix |
|-------|-----|
| Popular product demand | Increase retry count with backoff |
| Cleanup job overlap | Adjust job schedule |
| Flash sale burst | Pre-warm inventory, increase timeout |

### Payment Failures Spike

**Diagnosis:**
```bash
# Check Stripe API status
curl https://status.stripe.com/api/v1/status | jq .

# Check payment logs
gcloud logging read 'jsonPayload.message=~"payment|stripe" AND severity>=ERROR' --limit=50
```

**Resolution by Decline:**
| Decline | Action |
|---------|--------|
| card_declined, insufficient_funds | Normal, no action |
| processing_error | Check Stripe status |
| api_error | Fix integration bug |
| rate_limit | Implement backoff |

---

## Escalation Matrix

| Level | Role | When | Response Time |
|-------|------|------|---------------|
| L1 | On-Call Engineer | Any alert | 5 min |
| L2 | Tech Lead | L1 cannot resolve in 15 min | 10 min |
| L3 | Engineering Manager | L2 cannot resolve in 30 min | 15 min |
| Exec | CEO/CTO | Outage > 1 hour | 30 min |

**Contact Methods:**
- L1: PagerDuty (primary), Slack #on-call (backup)
- L2/L3: Phone call (primary), Slack DM (backup)
- Exec: Phone call (primary), Email (backup)

---

## On-Call Expectations

**Rotation:** Weekly (Monday 9 AM to Monday 9 AM), Primary + Secondary

**Response SLAs:**
| Severity | Acknowledge | Respond | Resolve Target |
|----------|-------------|---------|----------------|
| Critical | 5 min | 15 min | 1 hour |
| Warning | 15 min | 1 hour | 4 hours |
| Info | Next business day | - | - |

**On-Call Toolkit (bookmark these):**
- Cloud Console: `https://console.cloud.google.com/run?project=manik-honey-prod`
- Monitoring: `https://console.cloud.google.com/monitoring`
- Stripe: `https://dashboard.stripe.com/webhooks`
- PagerDuty: `https://manik.pagerduty.com`

**Shell Aliases:**
```bash
alias mglogs='gcloud logging read --project=manik-honey-prod --limit=100'
alias mgdeploy='gcloud run revisions list --service=go-api --region=us-central1'
alias mgrollback='gcloud run services update-traffic go-api --to-revisions'
```

---

## Disaster Recovery

### Backup Schedule

| Type | Frequency | Retention |
|------|-----------|-----------|
| Point-in-time recovery | Continuous | 7 days |
| Daily Firestore export | 2 AM UTC | 30 days |
| Weekly Firestore export | Sundays 3 AM | 90 days |

### Recovery Objectives

- **RTO (Recovery Time):** 1 hour
- **RPO (Recovery Point):** 1 hour for most data, 0 for orders

### Restore Procedures

**Point-in-Time (within 7 days):**
```bash
gcloud firestore databases restore \
  --source-database=(default) \
  --destination-database=restored-$(date +%Y%m%d) \
  --snapshot-time="2026-01-24T15:00:00Z"
```

**From Export (older):**
```bash
# List backups
gsutil ls -l gs://manik-backups/firestore/

# Import to staging first
gcloud firestore import gs://manik-backups/firestore/20260120 --database=staging

# After verification, import to production
gcloud firestore import gs://manik-backups/firestore/20260120 --database=(default)
```

---

## Communication Templates

**During Incident (Slack #incidents):**
```
[INCIDENT] Rollback in progress for go-api
Trigger: <error rate/latency/etc>
Action: Rolling back to revision <SHA>
ETA: 5 minutes
On-call: @username
```

**Post-Resolution:**
```
[RESOLVED] Rollback complete for go-api
Duration: <X minutes>
Impact: <estimated orders affected>
Root cause: Under investigation
Postmortem: Will be scheduled
```
