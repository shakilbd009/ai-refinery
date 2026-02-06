# Dependency Risk Assessment: Manik Golden Honey Co

## Critical Dependencies (System won't function without)

### 1. Stripe

| Attribute | Value |
|-----------|-------|
| **Type** | API / Payment Service |
| **Provider** | Stripe, Inc. |
| **Version/Lock** | Latest API (versioned per-account) |
| **Cost** | 2.9% + $0.30 per transaction |
| **SLA** | 99.99% uptime (historical) |
| **Data Location** | US (PCI-compliant) |

**Usage:**
- Payment intent creation, confirmation, and refunds
- Webhook-driven order creation (primary path per ADR-007)
- Discount code lock-in at PaymentIntent level (ADR-012)
- Deeply integrated: checkout flow, order creation, cancellation refunds

**Risk Analysis:**
- **Likelihood of failure:** Low (market leader, excellent track record)
- **Impact of failure:** Critical (no payments = no revenue)
- **Risk Score:** MEDIUM

**Mitigation:**
- [x] Graceful degradation defined (show "payments temporarily unavailable" message)
- [x] Webhook retry mechanism (Stripe retries for 3 days)
- [x] Idempotent order creation handles duplicate webhooks (ADR-007)
- [ ] Circuit breaker pattern (post-launch, 30-day priority)
- [ ] Offline payment queue (future consideration)
- **Alternative:** No direct alternative for MVP. PayPal could serve as secondary processor post-launch.

**Monitoring:**
- Health: Stripe status page API
- Alert threshold: 3 payment failures in 5 minutes
- Owner: Admin (email alert)

**Contract/Compliance:**
- Data processing agreement: Yes (Stripe DPA)
- PCI DSS compliant: Yes (SAQ-A, Stripe handles card data)
- GDPR compliant: Yes (Stripe DPA covers EU)
- Pricing lock: None (standard published rates)

---

### 2. Firestore (Google Cloud)

| Attribute | Value |
|-----------|-------|
| **Type** | Managed Database Service |
| **Provider** | Google Cloud Platform |
| **Version/Lock** | Firestore Native mode |
| **Cost** | ~$0/month at MVP scale (free tier: 50K reads, 20K writes/day) |
| **SLA** | 99.999% (multi-region), 99.99% (regional) |
| **Data Location** | US multi-region (nam5) |

**Usage:**
- All application data: 10 collections (products, customers, orders, reviews, reservations, promo codes, etc.)
- Transaction-based inventory management (ADR-008)
- Estimated ~7.3MB total data Year 1
- Deeply integrated: repository pattern abstracts access but all data lives here

**Risk Analysis:**
- **Likelihood of failure:** Low (Google infrastructure, industry-leading SLA)
- **Impact of failure:** Critical (no database = no application)
- **Risk Score:** MEDIUM

**Mitigation:**
- [x] Multi-region configuration for high availability
- [x] Read-only fallback mode during write outages (disaster recovery plan)
- [x] Daily automatic backups (7-day retention)
- [x] Repository pattern enables future migration to PostgreSQL
- [x] Distributed counter sharding for hot-spot prevention (ADR-001)
- **Alternative:** PostgreSQL via Cloud SQL (migration path documented in architecture)

**Monitoring:**
- Health: GCP Console / Cloud Monitoring
- Alert threshold: >500ms P95 latency or error rate >1%
- Owner: Admin

**Contract/Compliance:**
- Data processing agreement: Yes (GCP DPA)
- SOC2 compliant: Yes
- GDPR compliant: Yes (data residency controls)
- Pricing lock: None (pay-as-you-go, free tier covers MVP)

---

### 3. GCP Cloud Run

| Attribute | Value |
|-----------|-------|
| **Type** | Serverless Container Platform |
| **Provider** | Google Cloud Platform |
| **Version/Lock** | Managed (fully managed) |
| **Cost** | $30-50/month estimated for MVP |
| **SLA** | 99.95% |
| **Data Location** | us-central1 |

**Usage:**
- Hosts Go backend API (min 1 instance, max 10)
- Hosts Next.js frontend (scales to 0, max 10)
- Hosts cleanup service for expired reservations
- All three services depend on Cloud Run availability

**Risk Analysis:**
- **Likelihood of failure:** Low (Google infrastructure)
- **Impact of failure:** Critical (no compute = no application)
- **Risk Score:** MEDIUM

**Mitigation:**
- [x] Auto-scaling handles traffic spikes
- [x] Minimum 1 instance for Go API (avoids cold start on critical path)
- [x] Zero-downtime deployment procedure documented in runbooks
- [x] Emergency rollback procedure documented
- **Alternative:** GKE or any Docker-compatible platform (standard containers)

**Monitoring:**
- Health: Cloud Run health checks + Cloud Monitoring
- Alert threshold: >5% error rate or >2s P95 latency
- Owner: Admin

**Contract/Compliance:**
- Data processing agreement: Yes (GCP DPA)
- SOC2 compliant: Yes
- GDPR compliant: Yes
- Pricing lock: None (pay-per-use)

---

## Important Dependencies (Major impact if failed)

### 4. Mailgun

| Attribute | Value |
|-----------|-------|
| **Type** | Email API Service |
| **Provider** | Sinch (Mailgun) |
| **Version/Lock** | Latest API |
| **Cost** | Free tier (5,000 emails/month) covers MVP |
| **SLA** | 99.99% |
| **Data Location** | US |

**Usage:**
- Passwordless authentication codes (6-digit verification)
- Order confirmation emails
- Cancellation status notifications
- Admin notification emails

**Risk Analysis:**
- **Likelihood of failure:** Medium (email delivery is inherently unreliable)
- **Impact of failure:** High (no auth codes = customers can't log in; no order confirmations)
- **Risk Score:** MEDIUM

**Mitigation:**
- [x] Retry logic for failed sends (3 attempts with backoff)
- [x] Auth codes stored in Firestore (can be resent)
- [x] Admin dashboard shows orders regardless of email status
- **Alternative:** SendGrid (swap via API adapter, minimal code change)

**Monitoring:**
- Health: Mailgun dashboard / webhook events
- Alert threshold: >10% bounce rate or delivery delay >5 minutes
- Owner: Admin

**Contract/Compliance:**
- Data processing agreement: Yes
- CAN-SPAM compliant: Yes
- GDPR compliant: Yes (DPA available)
- Pricing lock: None

---

### 5. GCP Cloud Storage

| Attribute | Value |
|-----------|-------|
| **Type** | Object Storage |
| **Provider** | Google Cloud Platform |
| **Version/Lock** | Standard storage class |
| **Cost** | ~$0/month at MVP scale |
| **SLA** | 99.95% |
| **Data Location** | us-central1 |

**Usage:**
- Product image storage and serving
- ~20 products, estimated <100MB total
- Shallow integration (image URLs stored in Firestore)

**Risk Analysis:**
- **Likelihood of failure:** Low (Google infrastructure)
- **Impact of failure:** Medium (images won't load, but checkout still works)
- **Risk Score:** LOW

**Mitigation:**
- [x] CDN caching for served images
- [x] Placeholder images if load fails
- **Alternative:** Any S3-compatible storage, or serve from filesystem

---

### 6. GCP Cloud Scheduler

| Attribute | Value |
|-----------|-------|
| **Type** | Managed Cron Service |
| **Provider** | Google Cloud Platform |
| **Version/Lock** | Managed |
| **Cost** | Free tier (3 jobs) covers MVP |
| **SLA** | Part of GCP SLA |
| **Data Location** | us-central1 |

**Usage:**
- Triggers reservation cleanup every 5 minutes
- Single job, critical for releasing expired inventory locks

**Risk Analysis:**
- **Likelihood of failure:** Low
- **Impact of failure:** High (expired reservations won't release, blocking inventory)
- **Risk Score:** MEDIUM

**Mitigation:**
- [x] Multi-layered job failure mitigation (ADR-009): 5 defensive layers
- [x] Manual admin cleanup endpoint as fallback
- [x] Self-healing: next successful run cleans up missed items
- **Alternative:** Any cron service, or internal Go ticker

---

## Nice-to-Have Dependencies (Can live without)

### 7. Next.js Framework

| Attribute | Value |
|-----------|-------|
| **Type** | Web Framework / Library |
| **Provider** | Vercel (open source) |
| **Version/Lock** | 14.x (pinned) |
| **Cost** | Free (open source, MIT license) |

**Usage:**
- Frontend framework for customer storefront and admin dashboard
- SSR for SEO on product pages
- Deep integration (entire frontend built on it)

**Risk Analysis:**
- **Likelihood of failure:** Low (massive community, Vercel-backed, MIT licensed)
- **Impact of failure:** Low (framework is vendored at build time, runtime doesn't depend on Vercel)
- **Risk Score:** LOW

**Mitigation:**
- [x] Version pinned in package.json
- [x] Builds produce static output (no runtime dependency on Vercel)
- **Alternative:** Any React framework (Remix, Vite + React Router)

---

### 8. Go Standard Library + Chi Router

| Attribute | Value |
|-----------|-------|
| **Type** | Language Runtime + Library |
| **Provider** | Google (Go), go-chi (open source) |
| **Version/Lock** | Go 1.21+, Chi v5 (pinned) |
| **Cost** | Free (open source) |

**Usage:**
- Backend API runtime and routing
- Deeply integrated but standard patterns

**Risk Analysis:**
- **Likelihood of failure:** Low (Go is Google-backed, Chi is lightweight with minimal dependencies)
- **Impact of failure:** Low (compiled binary, no runtime dependency on external services)
- **Risk Score:** LOW

**Mitigation:**
- [x] Version pinned in go.mod
- [x] Chi has minimal dependency tree
- **Alternative:** Standard library net/http (Chi is a thin wrapper)

---

## Combined Risk Summary

| Metric | Value |
|--------|-------|
| Total dependencies | 8 |
| Critical | 3 (Stripe, Firestore, Cloud Run) |
| Important | 3 (Mailgun, Cloud Storage, Cloud Scheduler) |
| Nice-to-have | 2 (Next.js, Go/Chi) |
| Single points of failure | 1 (Stripe for payments) |
| Dependencies without alternatives | 0 (all have documented alternatives) |

## Architecture Risk

**Combined availability (critical path):**
- Stripe (99.99%) x Firestore (99.999%) x Cloud Run (99.95%) = ~99.94% uptime
- Target availability: 99.9%
- **Result:** Meets target. Cloud Run is the weakest link.

**Key insight:** Stripe is the only true single point of failure for revenue. All other critical dependencies have fallback modes or alternatives. The repository pattern for Firestore and containerized deployment for Cloud Run provide migration paths if needed.

## Mitigation Priority

| Priority | Dependency | Action | Due |
|----------|------------|--------|-----|
| P0 | Stripe | Implement circuit breaker pattern | Post-launch (30 days) |
| P0 | Mailgun | Verify SendGrid as hot-swap alternative | Post-launch (30 days) |
| P1 | Firestore | Test disaster recovery failover procedure | Post-launch (60 days) |
| P1 | Cloud Scheduler | Verify multi-layer cleanup mitigation | During implementation |
| P2 | Cloud Run | Document multi-region failover | Post-launch (90 days) |
