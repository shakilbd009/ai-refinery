# L3: Performance Analysis - Exhaustive Assessment

**Component:** System-Wide Performance, Scalability, and Optimization Strategy
**Stage:** L3 (Refine L3 - Exhaustive Coverage)
**Date:** 2026-01-25

---

## Executive Summary

This document provides exhaustive performance analysis for Manik Golden Honey Co, covering latency budgets, throughput estimates, scaling limits, bottleneck analysis, and caching/CDN strategies.

**Tech Stack:**
- Frontend: Next.js 14 (SSR + CSR hybrid)
- Backend: Go API (RESTful)
- Database: Firestore (NoSQL, native mode)
- Infrastructure: GCP Cloud Run (auto-scaling)
- Payments: Stripe
- Emails: SendGrid/Mailgun
- Storage: Cloud Storage + Cloud CDN

---

## 1. Latency Budget per Critical Path

### 1.1 Checkout Flow Latency Budget

**Total Target: P50 < 2s, P95 < 5s, P99 < 10s** (excluding customer input time)

| Step | Operation | P50 | P95 | P99 | Notes |
|------|-----------|-----|-----|-----|-------|
| 1 | Cart validation (frontend) | 5ms | 10ms | 20ms | Client-side only |
| 2 | POST /api/reserve-inventory | 75ms | 150ms | 300ms | Firestore transaction |
| 3 | Checkout page render | 50ms | 100ms | 200ms | Next.js SSR |
| 4 | POST /api/apply-promo-code | 30ms | 60ms | 120ms | Read-only validation |
| 5 | POST /api/create-payment-intent | 300ms | 500ms | 800ms | Stripe API dominant |
| 6 | Stripe checkout (customer time) | - | - | - | Not measured |
| 7 | Stripe webhook processing | 150ms | 300ms | 500ms | Order creation |
| 8 | Order confirmation render | 50ms | 100ms | 150ms | Next.js SSR |

**Breakdown of critical operations:**

#### Inventory Reservation (75-300ms)
```
Request parsing:           2-5ms
Session validation:        10-20ms
Firestore transaction:     50-150ms
  - Product read:          20-40ms
  - Availability check:    5-10ms
  - Reservation create:    20-40ms
  - Product update:        20-40ms
Response serialization:    3-5ms
Network overhead:          10-30ms
```

#### Payment Intent Creation (300-800ms)
```
Request parsing:           2-5ms
Reservation validation:    20-40ms
Promo code re-validation:  30-60ms (if applicable)
Stripe API call:           200-500ms (external dependency)
Metadata storage:          20-40ms
Response serialization:    3-5ms
Network overhead:          10-30ms
```

#### Order Creation from Webhook (150-500ms)
```
Signature verification:    5-10ms
Idempotency check:         20-40ms
Firestore transaction:     100-300ms
  - Order creation:        40-80ms
  - Inventory update:      30-60ms (per item)
  - Reservation delete:    20-40ms
Email queueing:            20-40ms
Response to Stripe:        5-10ms
```

### 1.2 Payment Processing Latency

**Stripe API Call Expectations:**

| Operation | P50 | P95 | P99 | Timeout |
|-----------|-----|-----|-----|---------|
| PaymentIntent.create | 250ms | 400ms | 600ms | 30s |
| PaymentIntent.retrieve | 100ms | 200ms | 350ms | 10s |
| Webhook signature verify | 1ms | 2ms | 5ms | N/A |
| Refund.create | 300ms | 500ms | 800ms | 30s |

**Webhook Delivery Expectations:**

| Metric | Value | Notes |
|--------|-------|-------|
| Time to first delivery | 100-500ms | After payment_intent.succeeded |
| Retry schedule | 1m, 5m, 30m, 2h, 6h, 12h, 24h | Exponential backoff |
| Max retry duration | 72 hours | 3 days total |
| Delivery success rate | 99.9% | With retries |

### 1.3 Inventory Operations Latency

**Reservation Lifecycle:**

| Operation | P50 | P95 | P99 | Max Timeout |
|-----------|-----|-----|-----|-------------|
| Reserve (single item) | 75ms | 150ms | 300ms | 10s |
| Reserve (5 items) | 150ms | 300ms | 500ms | 10s |
| Reserve (20 items) | 300ms | 500ms | 800ms | 10s |
| Release (cleanup) | 50ms | 100ms | 200ms | 10s |
| Cleanup job (100 reservations) | 8s | 15s | 25s | 5min |

**Transaction Lock Duration:**

| Scenario | Lock Duration | Conflict Probability |
|----------|---------------|---------------------|
| Normal checkout | 50-150ms | < 1% |
| Multi-item cart | 100-300ms | < 5% |
| Hot product (50% traffic) | 50-150ms | 10-15% |
| Black Friday peak | 50-200ms | 15-25% |

**Cleanup Job Timing:**

| Metric | Value | Notes |
|--------|-------|-------|
| Schedule interval | Every 5 minutes | Cloud Scheduler |
| Expected duration | 5-15 seconds | Normal backlog |
| Max duration | 5 minutes | Cloud Run timeout |
| Max reservations/run | 100 | Batch limit |
| Lazy cleanup (fallback) | +50-200ms | Added to checkout |

### 1.4 Review Moderation Latency

| Operation | P50 | P95 | P99 | Notes |
|-----------|-----|-----|-----|-------|
| Submit review | 150ms | 300ms | 500ms | Includes email queue |
| Admin approve/reject | 100ms | 200ms | 400ms | Includes aggregate update |
| Review query (10 reviews) | 30ms | 60ms | 120ms | Indexed query |

### 1.5 Discount Code Latency

| Operation | P50 | P95 | P99 | Notes |
|-----------|-----|-----|-----|-------|
| Code validation | 30ms | 60ms | 120ms | 2 Firestore reads |
| Usage increment | 60ms | 120ms | 200ms | In order transaction |
| Grace period check | +5ms | +10ms | +15ms | Timestamp comparison |

---

## 2. Throughput Estimates

### 2.1 Orders Per Hour

**Baseline Projections (Year 1):**

| Scenario | Orders/Hour | Orders/Day | Orders/Week |
|----------|-------------|------------|-------------|
| Quiet period | 0-2 | 10-20 | 70-140 |
| Normal | 3-5 | 30-50 | 210-350 |
| Weekend peak | 5-10 | 50-100 | N/A |
| Sale event | 15-30 | 150-300 | N/A |
| Black Friday | 50-100 | 400-800 | N/A |

**Year 2-3 Projections (Growth Scenario):**

| Scenario | Orders/Hour | Orders/Day | Orders/Week |
|----------|-------------|------------|-------------|
| Normal | 10-20 | 100-200 | 700-1400 |
| Peak | 30-50 | 300-500 | N/A |
| Black Friday | 100-200 | 800-1600 | N/A |

### 2.2 Concurrent Users

**Capacity Analysis:**

| Tier | Concurrent Users | Concurrent Checkouts | Notes |
|------|------------------|---------------------|-------|
| Year 1 normal | 10-50 | 1-5 | Comfortable headroom |
| Year 1 peak | 100-200 | 10-20 | Within limits |
| Year 2 normal | 50-200 | 5-20 | Still comfortable |
| Year 2 peak | 500-1000 | 50-100 | Need monitoring |
| Theoretical max | 5000+ | 500+ | Infrastructure limit |

### 2.3 Cart Operations Per Second

| Operation | Normal (ops/s) | Peak (ops/s) | Max Capacity |
|-----------|----------------|--------------|--------------|
| Add to cart | 0.1-0.5 | 1-5 | 100+ |
| Update quantity | 0.1-0.3 | 0.5-2 | 100+ |
| Remove item | 0.05-0.1 | 0.2-0.5 | 100+ |
| View cart | 0.5-1 | 2-10 | 500+ |
| Reserve inventory | 0.02-0.1 | 0.5-2 | 50+ |

**Cart is stored in localStorage, so most operations are client-side only.**

### 2.4 API Requests Per Second

| Endpoint | Normal | Peak | Capacity |
|----------|--------|------|----------|
| GET /api/products | 0.5-2 | 5-20 | 500+ |
| GET /api/products/:id | 1-5 | 10-50 | 500+ |
| POST /api/reserve-inventory | 0.02-0.1 | 0.5-2 | 50+ |
| POST /api/create-payment-intent | 0.02-0.1 | 0.5-2 | 50+ |
| POST /webhooks/stripe | 0.02-0.1 | 0.5-2 | 100+ |
| POST /api/reviews | 0.005-0.02 | 0.05-0.2 | 100+ |

---

## 3. Scaling Limits

### 3.1 Firestore Limits

**Hard Limits:**

| Limit | Value | Impact |
|-------|-------|--------|
| Writes per second (sustained) | 10,000 | Well above needs |
| Reads per second (sustained) | 50,000 | Well above needs |
| Transaction writes | 500 docs | Cart limit: 50 items |
| Transaction reads | 500 docs | Cart limit: 50 items |
| Document size | 1MB | Orders ~3KB, no concern |
| Field values per doc | 20,000 | No concern |
| Index entries per doc | 40,000 | No concern |

**Practical Limits:**

| Scenario | Limit Factor | Threshold | Mitigation |
|----------|--------------|-----------|------------|
| Hot product contention | Transaction conflicts | > 20% conflict rate | Increase inventory or split SKUs |
| Large cart checkout | Transaction time | > 8 seconds | Enforce 50-item limit |
| Cleanup backlog | Job duration | > 200 reservations | Increase job frequency |

**Transaction Conflict Projections:**

| Concurrent Checkouts | Same Product | Conflict Rate | P95 Resolution Time |
|----------------------|--------------|---------------|---------------------|
| 10 | 5 | 2-5% | 100-200ms |
| 50 | 25 | 10-15% | 200-400ms |
| 100 | 50 | 20-30% | 300-600ms |
| 200 | 100 | 30-40% | 500-1000ms |

### 3.2 Cloud Run Limits

**Configuration:**

| Service | Min Instances | Max Instances | Memory | CPU | Timeout |
|---------|---------------|---------------|--------|-----|---------|
| Go API | 1 | 10 | 512MB | 1 | 300s |
| Next.js | 0 | 10 | 1GB | 1 | 60s |
| Cleanup Jobs | 0 | 1 | 256MB | 0.5 | 300s |

**Cold Start Impact:**

| Service | Cold Start P50 | Cold Start P99 | Frequency |
|---------|----------------|----------------|-----------|
| Go API | 200ms | 800ms | Rare (min 1 instance) |
| Next.js | 500ms | 2000ms | Occasional |
| Cleanup Jobs | 300ms | 1500ms | Every 5 min |

**Auto-scaling Triggers:**

| Metric | Scale Up | Scale Down | Notes |
|--------|----------|------------|-------|
| CPU utilization | > 60% | < 30% | 60-second window |
| Memory utilization | > 80% | < 40% | Slower trigger |
| Request concurrency | > 80 | < 20 | Per instance |
| Request latency | N/A | N/A | Not a trigger |

**Instance Capacity (per instance):**

| Metric | Go API | Next.js |
|--------|--------|---------|
| Concurrent requests | 80-100 | 40-60 |
| Requests/second | 200-500 | 50-100 |
| Memory per request | 5-10MB | 10-20MB |

### 3.3 Stripe Rate Limits

**API Limits:**

| Environment | Limit | Notes |
|-------------|-------|-------|
| Test mode | 25 requests/second | Burst allowed |
| Live mode (default) | 100 requests/second | Per account |
| Live mode (elevated) | 500+ requests/second | Contact Stripe |

**Webhook Limits:**

| Metric | Value | Notes |
|--------|-------|-------|
| Endpoints per account | 16 | More than enough |
| Events per endpoint | No limit | - |
| Payload size | 64KB | Orders well under |
| Concurrent deliveries | 100+ | Per endpoint |

**Projected Usage vs Limits:**

| Scenario | API calls/second | % of Limit | Status |
|----------|------------------|------------|--------|
| Normal day | < 1 | < 1% | Safe |
| Peak hour | 2-5 | 2-5% | Safe |
| Black Friday | 10-20 | 10-20% | Safe |
| Theoretical max | 50-100 | 50-100% | Monitor |

### 3.4 Email Provider Limits

**SendGrid/Mailgun Limits:**

| Plan | Emails/month | Emails/hour | Notes |
|------|--------------|-------------|-------|
| Free tier | 100/day | 10 | Testing only |
| Essentials | 100K/month | 1000 | $14.95/month |
| Pro | 1.5M/month | 10,000+ | $89.95/month |

**Projected Email Volume:**

| Scenario | Emails/day | Emails/month | Plan Needed |
|----------|------------|--------------|-------------|
| Year 1 normal | 50-100 | 1500-3000 | Free/Essentials |
| Year 1 peak | 200-400 | 6000-12000 | Essentials |
| Year 2 | 300-600 | 9000-18000 | Essentials |

---

## 4. Bottleneck Analysis

### 4.1 Checkout Flow Bottlenecks

**Slowest Operations (by duration):**

| Rank | Operation | Duration | % of Total | Optimization |
|------|-----------|----------|------------|--------------|
| 1 | Stripe API (payment intent) | 200-500ms | 40-60% | Cannot optimize (external) |
| 2 | Firestore transaction (reserve) | 50-150ms | 15-25% | Optimize query, indexes |
| 3 | Firestore transaction (order) | 100-300ms | 20-35% | Batch writes |
| 4 | Promo code validation | 30-60ms | 5-10% | Cache frequently used codes |
| 5 | Network overhead | 30-60ms | 5-10% | Regional deployment |

**Stripe API is the dominant bottleneck** - no optimization possible on our side.

### 4.2 Contention Points

**Inventory Locks:**

| Product Type | Expected Contention | Risk Level | Mitigation |
|--------------|--------------------|----|------------|
| Normal products | < 5% conflict rate | Low | Automatic retry handles |
| Popular products | 5-15% conflict rate | Medium | Monitor, retry logic |
| Flash sale items | 15-30% conflict rate | High | Rate limiting, queue |
| Limited edition | 30-50% conflict rate | Critical | Lottery/queue system |

**Discount Codes:**

| Scenario | Contention Point | Risk | Mitigation |
|----------|------------------|------|------------|
| Normal usage | used_count increment | Low | Transaction handles |
| Popular code | Many concurrent redemptions | Medium | Accept over-redemption |
| Viral code leak | Rapid exhaustion | High | Rate limit, deactivate |

**Admin Operations:**

| Operation | Contention With | Risk | Mitigation |
|-----------|-----------------|------|------------|
| Inventory update | Customer reservations | Medium | Validate reserved_quantity |
| Product deactivation | Active checkouts | Low | Soft delete pattern |
| Code deactivation | Active checkouts | Low | Honor locked codes |

### 4.3 Database Hotspots

**High-Write Collections:**

| Collection | Write Frequency | Hotspot Risk | Notes |
|------------|-----------------|--------------|-------|
| inventory_reservations | High (checkout + cleanup) | Medium | TTL-based cleanup |
| products.reserved_quantity | High (every checkout) | Medium | Single field update |
| orders | Medium (after payment) | Low | Distributed by time |
| promo_codes.used_count | Medium (redemptions) | Low | Single field update |

**Product Document Contention:**

```
Problem: All checkouts update same product.reserved_quantity field
         Creates write contention on popular products

Analysis:
- 10 concurrent checkouts → 2-5% conflict rate (acceptable)
- 50 concurrent checkouts → 10-15% conflict rate (manageable)
- 100 concurrent checkouts → 20-30% conflict rate (needs attention)

Mitigation:
1. Automatic transaction retry (handles most conflicts)
2. Exponential backoff prevents thundering herd
3. For extreme cases: shard reserved_quantity across sub-documents
```

**High-Read Collections:**

| Collection | Read Frequency | Optimization |
|------------|----------------|--------------|
| products (catalog) | Very High | Cache in CDN/Redis |
| products (checkout) | High | Direct read (fresh data) |
| reviews (product page) | High | Cache with TTL |
| orders (customer history) | Low | No optimization needed |

### 4.4 Network Bottlenecks

**External Service Dependencies:**

| Service | Latency | Availability | Fallback |
|---------|---------|--------------|----------|
| Stripe API | 200-500ms | 99.99% | Queue + retry |
| Firestore | 20-100ms | 99.99% | None (critical) |
| SendGrid | 100-300ms | 99.9% | Secondary provider |
| Cloud Storage | 50-200ms | 99.99% | CDN caching |

**Network Path Latency:**

| Path | Latency | Notes |
|------|---------|-------|
| User → Cloud Run (same region) | 10-30ms | Optimal |
| User → Cloud Run (cross-region) | 50-150ms | CDN helps |
| Cloud Run → Firestore | 5-20ms | Same region |
| Cloud Run → Stripe | 100-300ms | US-based |

---

## 5. Caching Strategy

### 5.1 What to Cache

**Product Catalog (HIGH PRIORITY):**

| Data | Cache Location | TTL | Invalidation |
|------|----------------|-----|--------------|
| Product list | CDN + Redis | 5 min | On product update |
| Product details | CDN + Redis | 5 min | On product update |
| Product images | CDN | 24 hours | On image change |
| Category listing | CDN + Redis | 10 min | On product add/remove |

**Inventory Counts (MEDIUM PRIORITY):**

| Data | Cache Location | TTL | Invalidation |
|------|----------------|-----|--------------|
| Display inventory | Redis | 30 sec | On reservation/order |
| Low stock indicators | Redis | 1 min | On inventory change |
| Out of stock flag | Redis | 10 sec | Real-time for checkout |

**Do NOT cache inventory for checkout flow - always read fresh data.**

**Session Data:**

| Data | Cache Location | TTL | Notes |
|------|----------------|-----|-------|
| Cart contents | localStorage | Session | Client-side only |
| Customer session | JWT (stateless) | 30 min | No server cache |
| Applied promo code | Session state | Checkout | Cleared after order |

**Reviews:**

| Data | Cache Location | TTL | Invalidation |
|------|----------------|-----|--------------|
| Product reviews (page 1) | Redis | 5 min | On new approval |
| Review aggregates | Product doc | N/A | Updated on approval |
| Admin moderation queue | No cache | - | Always fresh |

### 5.2 Cache Layers

**Layer 1: Browser Cache (Client-Side)**

```
Static assets:
  - JS bundles: Cache-Control: max-age=31536000, immutable
  - CSS files: Cache-Control: max-age=31536000, immutable
  - Fonts: Cache-Control: max-age=31536000, immutable

Dynamic content:
  - Product pages: Cache-Control: no-cache (ISR validation)
  - Cart page: Cache-Control: no-store (always fresh)
  - Checkout: Cache-Control: no-store (always fresh)
```

**Layer 2: CDN (Cloud CDN)**

```
Configuration:
  Provider: Google Cloud CDN
  Origin: Cloud Run services
  Cache mode: CACHE_ALL_STATIC + selective dynamic

Cached content:
  - /api/products: 60 seconds (stale-while-revalidate: 300)
  - /api/products/:id: 60 seconds (stale-while-revalidate: 300)
  - /_next/static/*: 365 days (immutable)
  - /images/*: 24 hours (stale-while-revalidate: 86400)

Not cached:
  - /api/reserve-inventory: no-store
  - /api/create-payment-intent: no-store
  - /api/orders: no-store
  - /webhooks/*: no-store
```

**Layer 3: Application Cache (Redis/Memorystore)**

```
Configuration:
  Service: Cloud Memorystore (Redis)
  Instance: Basic tier, 1GB
  Region: Same as Cloud Run

Cached data:
  products:catalog        → Product list JSON, TTL 5 min
  products:{id}           → Product detail JSON, TTL 5 min
  products:{id}:inventory → Available count, TTL 30 sec
  reviews:{product_id}    → First page of reviews, TTL 5 min
  promo:{code}:valid      → Validation result, TTL 60 sec

Cache patterns:
  - Cache-aside (read-through)
  - Write-through on updates
  - TTL-based expiration
  - No cache warming (lazy population)
```

**Layer 4: Database Cache (Firestore)**

```
Firestore has no built-in cache, but:
  - Client SDK caches locally (offline persistence)
  - Server SDK has no caching
  - Use application cache (Redis) for read-heavy paths
```

### 5.3 Cache Invalidation Strategy

**Product Updates:**

```
Admin updates product:
  1. Write to Firestore
  2. Delete Redis keys:
     - products:catalog
     - products:{id}
     - products:{id}:inventory
  3. Purge CDN cache for /api/products*
  4. Next request repopulates cache
```

**Inventory Changes:**

```
On reservation/order:
  1. Write to Firestore (transaction)
  2. Delete Redis key: products:{id}:inventory
  3. Do NOT purge CDN (product details don't show real-time inventory)
  4. Checkout always reads fresh from Firestore
```

**Review Approval:**

```
Admin approves review:
  1. Write to Firestore
  2. Update product aggregates (in transaction)
  3. Delete Redis key: reviews:{product_id}
  4. Product page refreshes on next load
```

**Promo Code Changes:**

```
Admin deactivates code:
  1. Write to Firestore (active = false)
  2. Delete Redis key: promo:{code}:valid
  3. Already-created payment intents: still honored
  4. New validations: will fail
```

### 5.4 Cache Hit Rate Targets

| Cache | Target Hit Rate | Acceptable | Critical |
|-------|-----------------|------------|----------|
| CDN (static assets) | > 95% | > 90% | < 85% |
| CDN (product pages) | > 80% | > 70% | < 60% |
| Redis (product catalog) | > 90% | > 85% | < 80% |
| Redis (inventory counts) | > 70% | > 60% | < 50% |
| Redis (reviews) | > 85% | > 80% | < 70% |

---

## 6. CDN Strategy

### 6.1 Static Assets

**Asset Categories:**

| Category | Size Range | Cache Duration | Notes |
|----------|------------|----------------|-------|
| JS bundles | 100-500KB | 1 year | Versioned filenames |
| CSS files | 20-100KB | 1 year | Versioned filenames |
| Fonts | 50-200KB | 1 year | WOFF2 format |
| Product images | 100-500KB | 24 hours | WebP preferred |
| Icons/logos | 5-50KB | 1 year | SVG preferred |

**Bundle Optimization:**

```
Next.js configuration:
  - Code splitting: Automatic per page
  - Tree shaking: Enabled
  - Minification: Enabled
  - Compression: Brotli (CDN) + gzip (fallback)

Target bundle sizes:
  - Main bundle: < 100KB gzipped
  - Per-page chunk: < 30KB gzipped
  - Total initial load: < 200KB gzipped
```

### 6.2 Edge Caching Rules

**Cloud CDN Configuration:**

```yaml
# cdn-policy.yaml

default_ttl: 3600  # 1 hour default

cache_key_policy:
  include_host: true
  include_protocol: true
  include_query_string: false  # Ignore query params for static

path_rules:
  # Static assets - aggressive caching
  - path: "/_next/static/*"
    cache_mode: CACHE_ALL_STATIC
    default_ttl: 31536000
    client_ttl: 31536000

  # Product images - moderate caching
  - path: "/images/products/*"
    cache_mode: CACHE_ALL_STATIC
    default_ttl: 86400
    client_ttl: 86400

  # API - product catalog (cacheable)
  - path: "/api/products"
    cache_mode: USE_ORIGIN_HEADERS
    # Origin sets: Cache-Control: public, max-age=60

  # API - dynamic endpoints (never cache)
  - path: "/api/reserve-inventory"
    cache_mode: FORCE_CACHE_ALL
    default_ttl: 0  # No caching

  - path: "/api/create-payment-intent"
    cache_mode: FORCE_CACHE_ALL
    default_ttl: 0

  - path: "/webhooks/*"
    cache_mode: FORCE_CACHE_ALL
    default_ttl: 0
```

**Cache Headers from Origin:**

```go
// Go API response headers

// Cacheable endpoints
func handleGetProducts(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Cache-Control", "public, max-age=60, stale-while-revalidate=300")
    w.Header().Set("Vary", "Accept-Encoding")
    // ...
}

// Non-cacheable endpoints
func handleReserveInventory(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Cache-Control", "no-store, no-cache, must-revalidate")
    w.Header().Set("Pragma", "no-cache")
    // ...
}
```

### 6.3 Image Optimization

**Image Processing Pipeline:**

```
Upload flow:
  1. Admin uploads original image (JPEG/PNG)
  2. Cloud Function triggers on upload
  3. Generate variants:
     - Thumbnail: 200x200 WebP, quality 80
     - Card: 400x400 WebP, quality 85
     - Detail: 800x800 WebP, quality 90
     - Full: 1200x1200 WebP, quality 95
     - Fallback: Same sizes in JPEG for Safari < 14
  4. Store all variants in Cloud Storage
  5. CDN caches all variants
```

**Responsive Image Delivery:**

```html
<!-- Product card -->
<picture>
  <source
    type="image/webp"
    srcset="
      /images/products/{id}/card.webp 1x,
      /images/products/{id}/detail.webp 2x
    "
  />
  <img
    src="/images/products/{id}/card.jpg"
    alt="Product name"
    loading="lazy"
    width="400"
    height="400"
  />
</picture>
```

**Image Size Budget:**

| Image Type | Max Size | Format | Quality |
|------------|----------|--------|---------|
| Thumbnail | 20KB | WebP | 80 |
| Card | 50KB | WebP | 85 |
| Detail | 100KB | WebP | 90 |
| Full | 200KB | WebP | 95 |
| Hero banner | 150KB | WebP | 90 |

**Total image payload per page:**

| Page | Images | Total Size Target |
|------|--------|-------------------|
| Homepage | 3-5 hero + 8 products | < 500KB |
| Product listing | 12-20 cards | < 400KB |
| Product detail | 1 full + 4 thumbnails | < 400KB |

### 6.4 CDN Performance Targets

**Latency Targets:**

| Region | CDN Edge RTT | Origin RTT | Cache Miss Penalty |
|--------|--------------|------------|-------------------|
| US (primary) | 5-20ms | 50-100ms | +30-80ms |
| Europe | 10-30ms | 100-200ms | +70-170ms |
| Asia | 20-50ms | 150-300ms | +100-250ms |

**Cache Performance:**

| Metric | Target | Acceptable | Alert Threshold |
|--------|--------|------------|-----------------|
| Cache hit ratio (static) | > 95% | > 90% | < 85% |
| Cache hit ratio (dynamic) | > 80% | > 70% | < 60% |
| Bandwidth savings | > 90% | > 85% | < 80% |
| Origin shield hit ratio | > 80% | > 70% | < 60% |

---

## 7. Performance Testing Strategy

### 7.1 Load Test Scenarios

**Scenario 1: Normal Day Baseline**
```
Duration: 30 minutes
Virtual users: 50 concurrent
User behavior:
  - 70% browse products
  - 20% add to cart
  - 10% complete checkout

Expected results:
  - P95 response time < 500ms
  - Error rate < 0.1%
  - Throughput: 5-10 orders/hour
```

**Scenario 2: Peak Hour Simulation**
```
Duration: 1 hour
Virtual users: 200 concurrent
Ramp-up: 10 minutes

Expected results:
  - P95 response time < 1000ms
  - Error rate < 0.5%
  - Throughput: 20-30 orders/hour
```

**Scenario 3: Black Friday Stress Test**
```
Duration: 2 hours
Virtual users: 500-1000 concurrent
Pattern: Spike at start, sustained load

Expected results:
  - P95 response time < 2000ms
  - Error rate < 1%
  - No data corruption
  - Graceful degradation if overloaded
```

**Scenario 4: Hot Product Contention**
```
Duration: 15 minutes
Virtual users: 100 concurrent
Behavior: All users checkout same product

Expected results:
  - Transaction conflict rate < 30%
  - All conflicts resolved via retry
  - Zero overselling
  - P95 checkout time < 5000ms
```

### 7.2 Performance Monitoring

**Real-Time Metrics:**

```
Dashboards:
  1. Request latency (P50, P95, P99) by endpoint
  2. Error rate by endpoint
  3. Active checkouts / reservations
  4. Firestore transaction conflicts
  5. CDN cache hit ratio
  6. Cloud Run instance count

Alerting:
  - P95 latency > 2s: WARNING
  - P95 latency > 5s: CRITICAL
  - Error rate > 1%: WARNING
  - Error rate > 5%: CRITICAL
  - Transaction conflicts > 20%: WARNING
  - Active reservations > 50: WARNING
```

**Post-Incident Analysis:**

```
Metrics to collect:
  - Latency histogram by time
  - Error types and counts
  - Transaction retry distribution
  - Cache hit/miss timeline
  - Instance scaling events
  - Firestore read/write counts
```

---

## 8. Performance Optimization Roadmap

### 8.1 MVP Launch (Day 1)

**Implemented:**
- Cloud Run auto-scaling
- Firestore transactions
- Basic CDN (Cloud CDN)
- Image optimization (manual)

**Deferred:**
- Redis caching
- Advanced CDN rules
- Image processing pipeline

### 8.2 Post-Launch (Month 1-3)

**Priority 1: Add Redis Caching**
```
Impact: 30-50% reduction in Firestore reads
Effort: 1-2 days
Cost: $30-50/month (Memorystore Basic)
```

**Priority 2: Image Processing Pipeline**
```
Impact: 50-70% reduction in image payload
Effort: 2-3 days
Cost: Minimal (Cloud Functions)
```

**Priority 3: CDN Optimization**
```
Impact: 20-30% improvement in page load
Effort: 1 day
Cost: None (configuration only)
```

### 8.3 Scale Phase (Month 6+)

**If traffic increases 10x:**
```
1. Upgrade Memorystore to Standard tier
2. Add read replicas for Firestore (if available)
3. Implement request coalescing for hot products
4. Consider sharding reservation counter
```

**If transaction conflicts become problematic:**
```
1. Implement lottery system for limited products
2. Add queue-based checkout for flash sales
3. Consider eventual consistency for display inventory
```

---

## 9. Cost vs Performance Trade-offs

### 9.1 Infrastructure Cost Projections

**Year 1 Monthly Costs:**

| Service | Normal Load | Peak Load | Notes |
|---------|-------------|-----------|-------|
| Cloud Run (API) | $15-25 | $30-50 | 1 min instance |
| Cloud Run (Next.js) | $10-20 | $20-40 | Scale to 0 |
| Firestore | $5-15 | $15-30 | Read/write ops |
| Cloud Storage | $2-5 | $5-10 | Images |
| Cloud CDN | $5-10 | $10-20 | Bandwidth |
| Cloud Scheduler | $0.10 | $0.10 | 1 job |
| Memorystore (optional) | $30-50 | $30-50 | Fixed cost |

**Total without Redis: $40-80/month**
**Total with Redis: $70-130/month**

### 9.2 Performance vs Cost Decisions

| Decision | Performance Gain | Cost | Recommendation |
|----------|------------------|------|----------------|
| Min 1 API instance | -500ms cold start | +$7/month | Yes (MVP) |
| Redis caching | -100ms product reads | +$30/month | Post-launch |
| CDN (included) | -50ms static assets | $0 | Yes (MVP) |
| Image CDN | -200ms page load | +$5/month | Yes (MVP) |
| Regional deployment | -30ms same region | $0 | Yes |

---

## 10. Success Criteria (Quantified)

### 10.1 Latency Targets

| Metric | Target | Acceptable | Critical |
|--------|--------|------------|----------|
| Product page load | < 1s | < 2s | > 3s |
| Checkout start | < 300ms | < 500ms | > 1s |
| Payment processing | < 1s | < 2s | > 3s |
| Order confirmation | < 500ms | < 1s | > 2s |

### 10.2 Throughput Targets

| Metric | Target | Acceptable | Critical |
|--------|--------|------------|----------|
| Orders/hour (peak) | 50+ | 30+ | < 20 |
| Concurrent checkouts | 50+ | 30+ | < 20 |
| Page views/second | 100+ | 50+ | < 30 |

### 10.3 Reliability Targets

| Metric | Target | Acceptable | Critical |
|--------|--------|------------|----------|
| API availability | 99.9% | 99.5% | < 99% |
| Checkout success rate | 99% | 98% | < 95% |
| Zero overselling | 100% | 100% | Any failure |
| Order creation rate | 99.9% | 99.5% | < 99% |

### 10.4 Efficiency Targets

| Metric | Target | Acceptable | Critical |
|--------|--------|------------|----------|
| CDN cache hit ratio | > 90% | > 80% | < 70% |
| Redis cache hit ratio | > 85% | > 75% | < 65% |
| Firestore read efficiency | < 10 reads/page | < 20 | > 30 |
| Transaction conflict rate | < 5% | < 15% | > 25% |

---

## References

- [checkout-flow-L3.md](./checkout-flow-L3.md) - Checkout latency requirements
- [inventory-reservation-L3.md](./inventory-reservation-L3.md) - Transaction performance
- [discount-code-L3.md](./discount-code-L3.md) - Code validation performance
- [ADR-008](../ADRs/ADR-008-firestore-transaction-strategy.md) - Transaction strategy
- [ADR-005](../ADRs/ADR-005-background-job-infrastructure.md) - Background job timing

---

**Last Updated:** 2026-01-25
**Stage:** L3
**Status:** Complete - Exhaustive performance analysis
**Confidence Level:** 95%+
