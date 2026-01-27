# Extraction Rules by Category

Per-category rules for extracting actionable checklist items from curated docs.

## Infrastructure

**Source:** `architecture/overview.md`

### What to Extract

| Pattern | Example Source | Checklist Item |
|---------|----------------|----------------|
| Deployment targets | "Go API deployed to Cloud Run" | `Deploy Go API to Cloud Run` |
| Frontend hosting | "Next.js on Vercel" | `Deploy Next.js frontend to Vercel` |
| Databases | "Firestore for persistence" | `Provision Firestore database` |
| Storage | "Cloud Storage for images" | `Configure Cloud Storage bucket` |
| Caching | "Redis for session cache" | `Set up Redis instance` |
| CDN | "Cloudflare for static assets" | `Configure CDN for static assets` |
| DNS | "Custom domain required" | `Configure DNS for production domain` |

### Detection Signals

```
Technology keywords:
  Cloud Run, Kubernetes, ECS, Lambda, Vercel, Netlify,
  Firestore, PostgreSQL, MongoDB, DynamoDB,
  Redis, Memcached,
  S3, Cloud Storage, Blob Storage,
  CloudFront, Cloudflare

Action patterns:
  "deployed to {service}"
  "uses {database}"
  "stored in {storage}"
  "{service} for {purpose}"
```

---

## Security

**Source:** `security/threat-model.md`

### What to Extract

| Pattern | Example Source | Checklist Item |
|---------|----------------|----------------|
| Rate limiting | "100 req/min per IP" | `Implement rate limiting (100 req/min per IP)` |
| CORS | "CORS for production domain only" | `Configure CORS for production domain` |
| Auth tokens | "JWT with 24h expiry" | `Set up JWT token rotation (24h expiry)` |
| Cookies | "HttpOnly, Secure cookies" | `Enable HTTPS-only cookies` |
| Input validation | "Validate all user input" | `Implement input validation on all endpoints` |
| Secrets | "API keys in Secret Manager" | `Store API keys in Secret Manager` |
| TLS | "HTTPS required" | `Enable TLS/HTTPS for all endpoints` |
| Headers | "Security headers required" | `Configure security headers (CSP, HSTS, etc.)` |

### Detection Signals

```
Security keywords:
  rate limit, throttle, CORS, JWT, OAuth, session,
  cookie, token, authentication, authorization,
  encrypt, hash, salt, validate, sanitize,
  HTTPS, TLS, certificate

Requirement patterns:
  "must {action}"
  "required: {requirement}"
  "{number} per {period}"
  "prevent {threat}"
```

---

## Integrations

**Source:** `architecture/components/*.md`

### What to Extract

| Pattern | Example Source | Checklist Item |
|---------|----------------|----------------|
| Payment | "Stripe for payments" | `Connect Stripe payment processing` |
| Email | "SendGrid for transactional" | `Configure SendGrid for transactional email` |
| SMS | "Twilio for notifications" | `Set up Twilio SMS integration` |
| Analytics | "Segment for tracking" | `Configure analytics (Segment)` |
| Search | "Algolia for product search" | `Set up Algolia search index` |
| Maps | "Google Maps API" | `Configure Google Maps API` |
| Storage SDK | "Cloud Storage SDK" | `Set up Cloud Storage SDK` |

### Detection Signals

```
Integration keywords:
  Stripe, PayPal, Square, Braintree,
  SendGrid, Mailgun, SES, Postmark,
  Twilio, Vonage,
  Segment, Mixpanel, Amplitude,
  Algolia, Elasticsearch,
  Google Maps, Mapbox

Patterns:
  "via {service}"
  "{service} for {purpose}"
  "integrates with {service}"
  "calls {service} API"
```

---

## Monitoring

**Sources:** `operations/runbooks.md`, `performance.md`

### What to Extract

| Pattern | Example Source | Checklist Item |
|---------|----------------|----------------|
| Error alerts | "Alert on 5xx > 1%" | `Set up error alerting (5xx > 1% triggers page)` |
| Latency | "P95 < 200ms" | `Configure P95 latency monitoring` |
| Logging | "Structured JSON logs" | `Enable structured logging` |
| Dashboards | "Order success rate dashboard" | `Create order success rate dashboard` |
| Uptime | "99.9% availability" | `Set up uptime monitoring (99.9% target)` |
| APM | "Trace all requests" | `Configure APM/distributed tracing` |
| Log aggregation | "Cloud Logging" | `Set up log aggregation (Cloud Logging)` |

### Detection Signals

```
Monitoring keywords:
  alert, monitor, dashboard, metric, log,
  P50, P95, P99, latency, uptime, SLA,
  trace, span, APM,
  Datadog, New Relic, Cloud Monitoring, Prometheus

Patterns:
  "alert when {condition}"
  "{metric} < {threshold}"
  "monitor {resource}"
  "log {event}"
```

---

## Testing

**Source:** `edge-cases/*.md`

### What to Extract

Each documented edge case becomes a test scenario:

| Edge Case | Checklist Item |
|-----------|----------------|
| "Reservation expires during checkout" | `Test: reservation expires during checkout` |
| "Promo code expires during payment" | `Test: promo code expires during payment` |
| "Payment succeeds but order fails" | `Test: payment succeeds but order creation fails` |
| "Concurrent inventory reservations" | `Test: concurrent inventory reservations` |

### Extraction Rules

```
For each edge case file:
  1. Find edge case headings or bullet points
  2. Extract the scenario description
  3. Prefix with "Test: "
  4. Make it a testable assertion

Transform patterns:
  "When X happens, Y should occur"
  → "Test: X results in Y"

  "If user does X during Y"
  → "Test: X during Y"

  "Race condition between A and B"
  → "Test: concurrent A and B"
```

---

## Compliance

**Source:** `security/compliance/*.md` (if exists)

### What to Extract

| Pattern | Example Source | Checklist Item |
|---------|----------------|----------------|
| GDPR | "User data export required" | `Implement GDPR data export endpoint` |
| GDPR | "Cookie consent" | `Add cookie consent banner` |
| GDPR | "Right to deletion" | `Implement account deletion flow` |
| PCI | "Stripe handles card data" | `Verify PCI SAQ-A compliance` |
| Accessibility | "WCAG 2.1 AA" | `Test WCAG 2.1 AA accessibility` |
| SOC2 | "Audit logging required" | `Implement audit logging for SOC2` |

### Detection Signals

```
Compliance keywords:
  GDPR, CCPA, HIPAA, PCI, SOC2, ISO27001,
  WCAG, ADA, accessibility,
  data export, data deletion, consent,
  audit log, retention, encryption at rest

Patterns:
  "{regulation} requires {action}"
  "compliant with {standard}"
  "must support {capability}"
```

---

## Priority Ordering

Within each category, order by:

1. **Blocking items** - Must be done before others
2. **Critical path** - Core functionality
3. **Security** - Protection requirements
4. **Observability** - Monitoring and logging
5. **Nice-to-have** - Optional enhancements

Example ordering for Infrastructure:
```
1. [ ] Provision Firestore database       (blocking - needed by API)
2. [ ] Deploy Go API to Cloud Run         (critical path)
3. [ ] Deploy Next.js frontend            (critical path)
4. [ ] Configure Cloud Storage bucket     (feature - images)
5. [ ] Set up Redis cache                 (optimization)
```
