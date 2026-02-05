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
- `products.reserved_quantity` - **Sharded counter required for MVP**

**Product Document Contention (Without Sharding):**
- 10 concurrent checkouts: 2-5% conflict (acceptable)
- 50 concurrent checkouts: 10-15% conflict (P95 latency degrades)
- 100 concurrent: 20-30% conflict (P95 latency >1s, customer errors)

### Distributed Counter Sharding (REQUIRED PRE-LAUNCH)

**Rationale:** Single `reserved_quantity` field creates write hot spot during flash sales. At 100 concurrent checkouts, expect 20-30% transaction conflicts with 3-5 retries per transaction, pushing P95 latency to 800-1200ms.

**Solution:** Distribute reservation writes across 10 shards

```typescript
const SHARD_COUNT = 10;

// Collection: product_reservations/{productId}_shard_{0-9}
// Each shard document: { reserved: number }

async function reserveInventory(
  productId: string,
  quantity: number,
  customerId: string
): Promise<Reservation> {
  // Random shard selection distributes contention
  const shardId = Math.floor(Math.random() * SHARD_COUNT);
  const shardRef = firestore
    .collection('product_reservations')
    .doc(`${productId}_shard_${shardId}`);
  const productRef = firestore.collection('products').doc(productId);

  return firestore.runTransaction(async (tx) => {
    // Read all shards to get total reserved
    const shardRefs = Array.from({ length: SHARD_COUNT }, (_, i) =>
      firestore.collection('product_reservations').doc(`${productId}_shard_${i}`)
    );
    const shardDocs = await Promise.all(shardRefs.map(ref => tx.get(ref)));
    const totalReserved = shardDocs.reduce(
      (sum, doc) => sum + (doc.data()?.reserved || 0),
      0
    );

    // Read product for available quantity
    const productDoc = await tx.get(productRef);
    const product = productDoc.data();
    const available = product.quantity - totalReserved;

    if (available < quantity) {
      throw new InsufficientInventoryError(productId, available, quantity);
    }

    // Write to random shard (distributes contention across 10 documents)
    const shardData = shardDocs[shardId].data() || { reserved: 0 };
    tx.set(shardRef, {
      reserved: shardData.reserved + quantity,
      updated_at: FieldValue.serverTimestamp(),
    });

    // Create reservation record
    const reservationRef = firestore.collection('reservations').doc();
    const reservation: Reservation = {
      id: reservationRef.id,
      product_id: productId,
      shard_id: shardId,
      customer_id: customerId,
      quantity,
      status: 'active',
      expires_at: Date.now() + 10 * 60 * 1000, // 10 minutes (reduced from 15)
      created_at: FieldValue.serverTimestamp(),
    };
    tx.set(reservationRef, reservation);

    return reservation;
  });
}

async function releaseReservation(reservationId: string): Promise<void> {
  const reservationRef = firestore.collection('reservations').doc(reservationId);

  return firestore.runTransaction(async (tx) => {
    const reservationDoc = await tx.get(reservationRef);
    const reservation = reservationDoc.data();

    if (!reservation || reservation.status !== 'active') {
      return; // Already released
    }

    // Decrement the specific shard
    const shardRef = firestore
      .collection('product_reservations')
      .doc(`${reservation.product_id}_shard_${reservation.shard_id}`);

    tx.update(shardRef, {
      reserved: FieldValue.increment(-reservation.quantity),
      updated_at: FieldValue.serverTimestamp(),
    });

    tx.update(reservationRef, {
      status: 'released',
      released_at: FieldValue.serverTimestamp(),
    });
  });
}
```

**Performance Impact with Sharding:**
| Concurrent Checkouts | Conflict Rate | P95 Latency |
|----------------------|---------------|-------------|
| 10 | <1% | 150ms |
| 50 | 1-3% | 200ms |
| 100 | 2-5% | 300ms |

**Sharding vs No Sharding:**
- 100 concurrent: 2-5% conflicts vs 20-30% (10x improvement)
- P95 latency: 300ms vs 800-1200ms (3-4x improvement)
- Throughput headroom: 200+ concurrent vs ~100 max

---

## Caching Strategy

### What to Cache

| Data | Location | TTL | Notes |
|------|----------|-----|-------|
| Product catalog | In-memory + CDN | 1 min | Invalidate on update |
| Product images | CDN | 24 hours | WebP format |
| Display inventory | In-memory | 30 sec | NOT for checkout |
| Reviews (page 1) | In-memory | 5 min | Invalidate on approval |
| Static assets | CDN | 1 year | Immutable, versioned |

**Never cache for checkout flow** - always read fresh inventory data.

### MVP In-Memory Caching (REQUIRED PRE-LAUNCH)

**Rationale:** Without caching, Firestore costs spike to ~$1,530/month at 100 page views/second (8.6M reads/day). In-memory caching reduces this by 80-90%.

```typescript
// Simple in-memory cache with TTL - no Redis dependency for MVP
interface CacheEntry<T> {
  data: T;
  expires: number;
}

class InMemoryCache {
  private cache = new Map<string, CacheEntry<any>>();

  get<T>(key: string): T | null {
    const entry = this.cache.get(key);
    if (!entry) return null;
    if (entry.expires < Date.now()) {
      this.cache.delete(key);
      return null;
    }
    return entry.data;
  }

  set<T>(key: string, data: T, ttlMs: number): void {
    this.cache.set(key, {
      data,
      expires: Date.now() + ttlMs,
    });
  }

  invalidate(pattern: string): void {
    for (const key of this.cache.keys()) {
      if (key.startsWith(pattern)) {
        this.cache.delete(key);
      }
    }
  }
}

const cache = new InMemoryCache();

// Product fetch with caching
async function getProduct(id: string): Promise<Product> {
  const cacheKey = `product:${id}`;
  const cached = cache.get<Product>(cacheKey);
  if (cached) return cached;

  const doc = await firestore.collection('products').doc(id).get();
  const product = doc.data() as Product;
  cache.set(cacheKey, product, 60_000); // 1 min TTL
  return product;
}

// Product list with caching
async function getActiveProducts(): Promise<Product[]> {
  const cacheKey = 'products:active';
  const cached = cache.get<Product[]>(cacheKey);
  if (cached) return cached;

  const snapshot = await firestore
    .collection('products')
    .where('status', '==', 'active')
    .get();
  const products = snapshot.docs.map(doc => doc.data() as Product);
  cache.set(cacheKey, products, 60_000); // 1 min TTL
  return products;
}

// Invalidate on product update (called from admin API)
function invalidateProductCache(productId?: string): void {
  if (productId) {
    cache.invalidate(`product:${productId}`);
  }
  cache.invalidate('products:'); // Invalidate list caches
}
```

**Request Coalescing (Thundering Herd Prevention):**
```typescript
const inflightRequests = new Map<string, Promise<any>>();

async function getProductWithCoalescing(id: string): Promise<Product> {
  const cacheKey = `product:${id}`;

  // Check cache first
  const cached = cache.get<Product>(cacheKey);
  if (cached) return cached;

  // Check if request already in-flight
  if (inflightRequests.has(cacheKey)) {
    return inflightRequests.get(cacheKey)!;
  }

  // Start new request, share result with concurrent callers
  const promise = fetchAndCacheProduct(id);
  inflightRequests.set(cacheKey, promise);

  try {
    return await promise;
  } finally {
    inflightRequests.delete(cacheKey);
  }
}
```

**Expected MVP Impact:**
- Firestore reads: 80-90% reduction for catalog browsing
- Cost: ~$50/month vs ~$1,530/month without caching
- P95 product page latency: ~100ms vs ~300ms

### Cache Layers

1. **Browser:** Static assets (1 year), dynamic (no-cache for ISR)
2. **CDN:** Product API (60s), images (24h), static (1 year)
3. **In-Memory (MVP):** Product catalog, inventory counts, reviews
4. **Redis (Post-Launch):** Replace in-memory when scaling beyond single instance

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

### MVP Launch (REQUIRED)
- Cloud Run auto-scaling (min 1 API instance)
- Firestore transactions with retry
- Cloud CDN for static assets
- **In-memory caching for product catalog** (see Caching Strategy above)
- **Distributed counter sharding for reservations** (see Database Hotspots above)
- **Bounded batch processing for cleanup jobs** (see ADR-009)
- Manual image optimization

### Post-Launch (Month 1-3)
1. **Redis caching** - Replace in-memory cache when scaling beyond single instance
2. **Image processing pipeline** - 50-70% reduction in payload (Cloud Functions + sharp)
3. **CDN rule optimization** - 20-30% page load improvement

### Scale Phase (Month 6+)
- Upgrade to Redis cluster if traffic exceeds single instance capacity
- Queue-based checkout for flash sales (Pub/Sub + deferred processing)
- Geographic load balancing if expanding beyond US

---

## Monitoring & Alerts

| Metric | Warning | Critical |
|--------|---------|----------|
| P95 latency | > 2s | > 5s |
| Error rate | > 1% | > 5% |
| Transaction conflicts | > 20% | > 30% |
| Cache hit ratio | < 80% | < 70% |

**Key dashboards:** Request latency by endpoint, active reservations, Firestore conflicts, CDN hit ratio, Cloud Run scaling events.
