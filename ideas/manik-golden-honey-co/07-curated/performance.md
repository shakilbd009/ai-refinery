# Performance Requirements

Performance budgets, scaling limits, bottleneck analysis, and optimization strategies for Manik Golden Honey Co.

---

## Latency Budgets

### Checkout Flow (Total: P50 < 2s, P95 < 5s)

| Step | Operation | P50 | P95 | P99 |
|------|-----------|-----|-----|-----|
| 1 | Cart validation (client) | 5ms | 10ms | 20ms |
| 2 | Inventory reservation | 75ms | 150ms | 300ms |
| 3 | Checkout page render | 50ms | 100ms | 200ms |
| 4 | Promo code validation | 30ms | 60ms | 120ms |
| 5 | Payment intent creation | 300ms | 500ms | 800ms |
| 6 | Webhook processing | 150ms | 300ms | 500ms |
| 7 | Order confirmation | 50ms | 100ms | 150ms |

**Stripe API is the dominant bottleneck** (40-60% of checkout time) - cannot be optimized on our side.

### Stripe API Expectations

| Operation | P50 | P95 | Timeout |
|-----------|-----|-----|---------|
| PaymentIntent.create | 250ms | 400ms | 30s |
| PaymentIntent.retrieve | 100ms | 200ms | 10s |
| Refund.create | 300ms | 500ms | 30s |
| Webhook signature verify | 1ms | 2ms | N/A |

---

## Throughput Estimates

### Orders Per Hour

| Scenario | Year 1 | Year 2-3 |
|----------|--------|----------|
| Normal | 3-5 | 10-20 |
| Weekend peak | 5-10 | 30-50 |
| Sale event | 15-30 | 50-100 |
| Black Friday | 50-100 | 100-200 |

### API Request Capacity

| Endpoint | Peak (req/s) | Capacity |
|----------|--------------|----------|
| GET /api/products | 5-20 | 500+ |
| GET /api/products/:id | 10-50 | 500+ |
| POST /api/reserve-inventory | 0.5-2 | 50+ |
| POST /api/create-payment-intent | 0.5-2 | 50+ |
| POST /webhooks/stripe | 0.5-2 | 100+ |

---

## Scaling Limits

### Firestore Constraints

| Limit | Value | Impact |
|-------|-------|--------|
| Writes/second (sustained) | 10,000 | Well above needs |
| Reads/second (sustained) | 50,000 | Well above needs |
| Transaction writes | 500 docs | Cart limit: 50 items |
| Document size | 1MB | Orders ~3KB |

### Transaction Conflict Projections

| Concurrent Checkouts | Same Product | Conflict Rate |
|----------------------|--------------|---------------|
| 10 | 5 | 2-5% |
| 50 | 25 | 10-15% |
| 100 | 50 | 20-30% |

**Mitigation:** Automatic retry with exponential backoff handles most conflicts.

### Cloud Run Configuration

| Service | Min | Max | Memory | Timeout |
|---------|-----|-----|--------|---------|
| Go API | 1 | 10 | 512MB | 300s |
| Next.js | 0 | 10 | 1GB | 60s |
| Cleanup Jobs | 0 | 1 | 256MB | 300s |

**Cold Start Impact:** Go API 200-800ms (rare with min 1), Next.js 500-2000ms (occasional).

### Stripe Rate Limits

| Environment | Limit | Projected Peak Usage |
|-------------|-------|----------------------|
| Live mode (default) | 100 req/s | 10-20 req/s (safe) |
| Webhooks | No limit | No concern |

---

## Bottleneck Analysis

### Checkout Flow (by duration)

| Rank | Operation | Duration | Optimization |
|------|-----------|----------|--------------|
| 1 | Stripe API | 200-500ms | Cannot optimize (external) |
| 2 | Order creation transaction | 100-300ms | Batch writes |
| 3 | Inventory reservation | 50-150ms | Optimize indexes |
| 4 | Promo code validation | 30-60ms | Cache frequent codes |

### Database Hotspots

**High-Write Collections:**
- `inventory_reservations` - TTL-based cleanup handles load
- `products.reserved_quantity` - Single field update per checkout

**Product Document Contention:**
- 10 concurrent checkouts: 2-5% conflict (acceptable)
- 50 concurrent checkouts: 10-15% conflict (manageable)
- 100+ concurrent: Consider sharding reserved_quantity

---

## Caching Strategy

### What to Cache

| Data | Location | TTL | Notes |
|------|----------|-----|-------|
| Product catalog | CDN + Redis | 5 min | Invalidate on update |
| Product images | CDN | 24 hours | WebP format |
| Display inventory | Redis | 30 sec | NOT for checkout |
| Reviews (page 1) | Redis | 5 min | Invalidate on approval |
| Static assets | CDN | 1 year | Immutable, versioned |

**Never cache for checkout flow** - always read fresh inventory data.

### Cache Layers

1. **Browser:** Static assets (1 year), dynamic (no-cache for ISR)
2. **CDN:** Product API (60s), images (24h), static (1 year)
3. **Redis:** Product catalog, inventory counts, reviews
4. **Database:** No built-in cache (use Redis for reads)

### Cache Invalidation

```
Product update: Delete Redis keys + purge CDN
Inventory change: Delete inventory key only (checkout reads fresh)
Review approval: Delete reviews key + update aggregates
```

### Cache Hit Rate Targets

| Cache | Target | Critical |
|-------|--------|----------|
| CDN (static) | > 95% | < 85% |
| CDN (API) | > 80% | < 60% |
| Redis (catalog) | > 90% | < 80% |
| Redis (inventory) | > 70% | < 50% |

---

## CDN Configuration

### Static Assets

| Category | Cache Duration | Target Size |
|----------|----------------|-------------|
| JS bundles | 1 year (immutable) | < 100KB gzip |
| CSS files | 1 year (immutable) | < 30KB gzip |
| Product images | 24 hours | < 200KB WebP |
| Total initial load | - | < 200KB gzip |

### Image Optimization

| Variant | Dimensions | Format | Max Size |
|---------|------------|--------|----------|
| Thumbnail | 200x200 | WebP | 20KB |
| Card | 400x400 | WebP | 50KB |
| Detail | 800x800 | WebP | 100KB |
| Full | 1200x1200 | WebP | 200KB |

---

## Success Criteria

### Latency Targets

| Metric | Target | Critical |
|--------|--------|----------|
| Product page load | < 1s | > 3s |
| Checkout start | < 300ms | > 1s |
| Payment processing | < 1s | > 3s |
| Order confirmation | < 500ms | > 2s |

### Throughput Targets

| Metric | Target | Critical |
|--------|--------|----------|
| Orders/hour (peak) | 50+ | < 20 |
| Concurrent checkouts | 50+ | < 20 |
| Page views/second | 100+ | < 30 |

### Reliability Targets

| Metric | Target | Critical |
|--------|--------|----------|
| API availability | 99.9% | < 99% |
| Checkout success rate | 99% | < 95% |
| Zero overselling | 100% | Any failure |

---

## Optimization Roadmap

### MVP Launch
- Cloud Run auto-scaling (min 1 API instance)
- Firestore transactions with retry
- Cloud CDN for static assets
- Manual image optimization

### Post-Launch (Month 1-3)
1. **Redis caching** - 30-50% reduction in Firestore reads (+$30/month)
2. **Image processing pipeline** - 50-70% reduction in payload
3. **CDN rule optimization** - 20-30% page load improvement

### Scale Phase (Month 6+)
- Upgrade Memorystore if cache misses increase
- Implement request coalescing for hot products
- Consider sharding reservation counter if conflicts > 25%
- Queue-based checkout for flash sales if contention is critical

---

## Monitoring & Alerts

| Metric | Warning | Critical |
|--------|---------|----------|
| P95 latency | > 2s | > 5s |
| Error rate | > 1% | > 5% |
| Transaction conflicts | > 20% | > 30% |
| Cache hit ratio | < 80% | < 70% |

**Key dashboards:** Request latency by endpoint, active reservations, Firestore conflicts, CDN hit ratio, Cloud Run scaling events.
