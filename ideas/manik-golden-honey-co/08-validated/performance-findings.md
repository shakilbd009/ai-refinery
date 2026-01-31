# Performance Validation: manik-golden-honey-co

**Validated:** 2026-01-27
**Validator:** performance-oracle

## Verdict: NEEDS_ATTENTION

The design demonstrates solid understanding of performance fundamentals with appropriate caching, transaction strategies, and scaling considerations. However, several issues could impact production performance and require attention before launch.

---

## Critical Issues (Must Fix Before Launch)

### 1. No Redis Caching Implementation Plan for MVP
**Location:** performance.md, architecture overview
**Issue:** The performance document defers Redis caching to "Post-Launch (Month 1-3)" but targets "30-50% reduction in Firestore reads." Without caching at MVP:
- Product catalog will query Firestore on every page view
- P95 latency targets may not be achievable under load
- Firestore costs will be 2-3x higher than projected
- Cache hit rate targets (>90% catalog, >80% CDN) are unmet by design

**Impact at Scale:** At 100 page views/second (stated target), you'll hit 8.6M Firestore reads/day. Free tier: 50K/day. That's $0.06/10K reads = $51/day = $1,530/month just for product reads.

**Recommended Solution:**
```typescript
// Add application-level caching at MVP (no Redis needed initially)
const productCache = new Map<string, {data: Product, expires: number}>();

async function getProduct(id: string): Promise<Product> {
  const cached = productCache.get(id);
  if (cached && cached.expires > Date.now()) {
    return cached.data;
  }

  const product = await firestore.collection('products').doc(id).get();
  productCache.set(id, {
    data: product.data(),
    expires: Date.now() + 60000 // 1 min TTL
  });
  return product.data();
}
```

**Complexity:** Low. Can be implemented in 2-3 hours.
**Expected Gain:** 80-90% reduction in product reads for catalog browsing.

---

### 2. Product Document Hot Spot Under Flash Sale Conditions
**Location:** performance.md line 114-118, inventory-reservation.md
**Issue:** Single product document updated on every reservation creates write contention:
- Product has `reserved_quantity` field updated in every checkout transaction
- At 100 concurrent checkouts (Black Friday scenario), 20-30% conflict rate projected
- Each conflict triggers exponential backoff retry (100-500ms)
- P95 latency degrades to >1s per the design

**Algorithmic Analysis:**
- Current: O(1) document writes, but serialized by Firestore transaction isolation
- Worst case: O(n) retries where n = concurrent checkouts
- At 100 concurrent: Expected 3-5 retries per transaction = 400-600ms additional latency

**Projected Impact at Scale:**
```
50 concurrent checkouts (Year 2-3 weekend peak):
- 10-15% conflicts
- Average 2 retries
- P95 latency: 500-800ms (vs 150ms target)

100 concurrent (Black Friday):
- 20-30% conflicts
- Average 3-4 retries
- P95 latency: 800-1200ms (vs 150ms target)
- Some customers see "High demand, try again" errors
```

**Recommended Solution:**
Implement distributed counter sharding for `reserved_quantity`:

```typescript
// Instead of single product.reserved_quantity field
// Create 10 shards: product_reservations/{productId}_shard_{0-9}
const SHARD_COUNT = 10;

async function reserveInventory(productId: string, quantity: number) {
  const shardId = Math.floor(Math.random() * SHARD_COUNT);
  const shardRef = firestore
    .collection('product_reservations')
    .doc(`${productId}_shard_${shardId}`);

  return firestore.runTransaction(async (tx) => {
    // Read all shards to get total reserved
    const shardPromises = Array.from({length: SHARD_COUNT}, (_, i) =>
      tx.get(firestore.collection('product_reservations')
        .doc(`${productId}_shard_${i}`))
    );
    const shards = await Promise.all(shardPromises);
    const totalReserved = shards.reduce((sum, s) =>
      sum + (s.data()?.reserved || 0), 0);

    const product = await tx.get(productRef);
    const available = product.data().quantity - totalReserved;

    if (available < quantity) {
      throw new Error('Insufficient inventory');
    }

    // Write to random shard (distributes contention)
    tx.update(shardRef, {
      reserved: FieldValue.increment(quantity)
    });
  });
}
```

**Expected Performance Gain:**
- Conflicts reduced from 20-30% to 2-5% at 100 concurrent checkouts
- P95 latency stays under 300ms even at Black Friday load
- 10x improvement in throughput headroom

**Implementation Complexity:** Medium (2-3 days). Requires schema change and testing.

---

### 3. Unbounded Query in Cleanup Job
**Location:** ADR-009, inventory-reservation.md line 60
**Issue:** Cleanup job queries "WHERE expires_at < now AND status = active" without limit:
- No pagination or batching specified
- Memory usage unbounded if cleanup fails for extended period
- Could timeout Cloud Run's 300s limit if backlog grows

**Memory Analysis:**
```
Scenario: Cleanup fails for 3 hours during Black Friday
- 100 orders/hour × 3 hours = 300 orders
- Average 2 line items = 600 reservations
- Each reservation ~1KB in memory
- Total: 600KB (acceptable)

Scenario: Cleanup fails for 24 hours
- 100 orders/hour × 24 = 2,400 orders
- 4,800 reservations
- 4.8MB (still acceptable, but growing)

Scenario: Week-long outage (pathological)
- 33,600 reservations
- 33MB + query overhead = potential memory issues
- Query timeout likely
```

**Recommended Solution:**
```typescript
async function cleanupExpiredReservations() {
  const BATCH_SIZE = 100;
  let processed = 0;
  let hasMore = true;

  while (hasMore && processed < 500) { // Safety limit
    const batch = await firestore
      .collection('inventory_reservations')
      .where('expires_at', '<', Date.now())
      .where('status', '==', 'active')
      .limit(BATCH_SIZE)
      .get();

    if (batch.empty) {
      hasMore = false;
      break;
    }

    // Process batch in parallel transactions
    await Promise.all(batch.docs.map(doc =>
      releaseReservation(doc.id)
    ));

    processed += batch.size;
  }

  if (processed >= 500) {
    console.warn('Hit cleanup safety limit, backlog remains');
  }
}
```

**Complexity:** Low (1-2 hours to implement).
**Expected Gain:** Bounded memory usage, predictable execution time under all conditions.

---

## High Priority Issues (Should Fix)

### 4. Missing Index on Composite Query
**Location:** data-model.md, review-moderation.md
**Issue:** Query `WHERE product_id = X AND status = 'approved' ORDER BY created_at DESC` requires composite index not mentioned in schema.

**Impact:** Without index, query falls back to full collection scan or fails entirely. At 600 reviews (Year 1), this means scanning all documents for every product page load.

**Recommended Solution:**
```yaml
# firestore.indexes.json
indexes:
  - collectionGroup: reviews
    fields:
      - fieldPath: product_id
        order: ASCENDING
      - fieldPath: status
        order: ASCENDING
      - fieldPath: created_at
        order: DESCENDING
```

**Complexity:** Low (5 minutes to add, 10-30 minutes for Firestore to build).

---

### 5. N+1 Query Pattern in Order History
**Location:** api-contracts.md, data-model.md
**Issue:** Order line items contain product_id but product name is snapshotted. If order history displays current product images:

```typescript
// Potential N+1 pattern if not careful
const orders = await getOrders(customerId); // 1 query
for (const order of orders) {
  for (const item of order.line_items) {
    // If we need current product data (image, active status)
    const product = await getProduct(item.product_id); // N queries
  }
}
```

**Performance at Scale:**
- Customer with 20 orders, average 2 items = 40 product queries
- Without caching: 40 Firestore reads per page load
- With cache (90% hit): 4 Firestore reads (acceptable)

**Recommended Solution:**
Ensure order history UI uses snapshotted data only:
```typescript
// Good: Use snapshotted product_name, don't fetch current product
<LineItem
  name={item.product_name}
  price={item.price_per_unit}
/>

// Bad: Fetching current product for each line item
const product = await getProduct(item.product_id);
<LineItem name={product.name} />
```

**If current product data needed:** Batch fetch all unique product IDs:
```typescript
const productIds = [...new Set(
  orders.flatMap(o => o.line_items.map(i => i.product_id))
)];
const products = await batchGetProducts(productIds); // Single query
```

**Complexity:** Low (document pattern, no code change if done correctly).

---

### 6. Promo Code Over-Redemption Acceptance Creates Unbounded Cost Risk
**Location:** discount-code.md lines 96-105
**Issue:** Design explicitly accepts over-redemption during race conditions:
> "Better to honor discount than refund customer"

While customer-friendly, this creates financial risk without monitoring:
- Viral promo code could be redeemed 1000x before admin notices
- No automatic circuit breaker when redemptions spike
- Alert threshold ">50 redemptions/hour" is manual intervention

**Financial Impact Projection:**
```
Scenario: 20% off code goes viral on social media
- 500 redemptions in 1 hour (10x normal)
- Average order $50
- Revenue loss: 500 × $50 × 0.20 = $5,000
- Small producer margin: ~30%
- Net loss: $3,500 (exceeds monthly revenue)
```

**Recommended Solution:**
Add automatic deactivation at breach threshold:
```typescript
async function incrementPromoUsage(code: string) {
  const updatedCode = await firestore.runTransaction(async (tx) => {
    const codeRef = firestore.collection('promo_codes').doc(code);
    const codeDoc = await tx.get(codeRef);
    const data = codeDoc.data();

    const newCount = data.used_count + 1;

    // Circuit breaker: auto-deactivate at 125% of max
    if (data.max_redemptions &&
        newCount > data.max_redemptions * 1.25) {
      tx.update(codeRef, {
        used_count: newCount,
        active: false,
        auto_deactivated_at: FieldValue.serverTimestamp(),
        deactivation_reason: 'over_redemption_threshold'
      });
      // Alert admin immediately
      await sendAlert('PROMO_CODE_AUTO_DEACTIVATED', {code, newCount});
    } else {
      tx.update(codeRef, {used_count: newCount});
    }

    return newCount;
  });
}
```

**Complexity:** Low (2-3 hours including alerts).
**Expected Gain:** Limits blast radius of viral codes to 25% over-redemption vs unbounded.

---

### 7. No Query Timeout Configuration Specified
**Location:** Architecture overview, timeout configuration
**Issue:** Firestore SDK default timeout is 60s, but timeout configuration shows 10s for reads, 30s for transactions. Need explicit timeout configuration to enforce these limits.

**Recommended Solution:**
```typescript
// Initialize Firestore with explicit timeouts
const firestore = new Firestore({
  settings: {
    // Force 10s timeout on all operations
    timeout: 10000,
  }
});

// Override for specific transactions
const transactionOptions = {
  timeout: 30000,
  maxAttempts: 3
};
```

**Complexity:** Low (30 minutes to configure and test).

---

## Medium Priority Issues (Consider Fixing)

### 8. Lazy Cleanup Adds Latency to Innocent Customers
**Location:** ADR-009 layer 4
**Issue:** "Lazy Cleanup on Checkout" processes up to 10 expired reservations during customer checkout flow. This adds 1-2s latency (per document) to customers who happen to checkout when cleanup job has failed.

**User Experience Impact:**
- Customer A checkouts at T+0: 150ms (normal)
- Cleanup job fails at T+5
- Customer B checkouts at T+20: 150ms + 10×100ms = 1,150ms
- Customer C checkouts at T+21: 150ms (cleanup already done)

**Performance Analysis:**
Best case: 0 expired reservations = 0ms overhead
Worst case: 10 expired = 1,000-2,000ms added latency
Probability: Depends on cleanup job reliability

**Recommended Solution:**
Move lazy cleanup to async background task triggered by checkout:
```typescript
// During checkout, just log if backlog exists
if (await hasExpiredReservations(productId)) {
  // Don't block checkout, trigger async cleanup
  pubsub.publish('cleanup-reservations', {productId});
}

// Separate Cloud Function handles cleanup
export const asyncCleanup = functions.pubsub
  .topic('cleanup-reservations')
  .onPublish(async (message) => {
    await cleanupReservationsForProduct(message.data.productId);
  });
```

**Complexity:** Medium (requires Pub/Sub setup, 1 day).
**Expected Gain:** Removes 1-2s latency spike for customers during cleanup failures.

---

### 9. Order Creation Transaction May Exceed Firestore Limits
**Location:** checkout-flow.md, ADR-008
**Issue:** Order creation transaction writes:
1. Create order document
2. Delete reservation document
3. Update product.reserved_quantity for each line item
4. Update customer.order_count and total_spent
5. Update promo_codes.used_count
6. Create promo_code_usage document

For 50-item cart (stated limit):
- 1 order write
- 1 reservation delete
- 50 product updates
- 1 customer update
- 1 promo code update
- 1 promo usage write
= 55 writes (well under 500 limit)

**However:** Firestore transaction limit is 500 writes, but practical limit is ~100 before performance degrades significantly.

**Recommended Solution:**
Split into two transactions:
```typescript
// Transaction 1: Critical path (inventory + order)
await firestore.runTransaction(async (tx) => {
  // Validate inventory, create order, update products
});

// Transaction 2: Non-critical updates (can fail and retry)
await firestore.runTransaction(async (tx) => {
  // Update customer stats, promo code counts
});
```

**Complexity:** Medium (requires refactoring, 4-6 hours).
**Risk of not fixing:** Cart limit must stay under 20 items to maintain <300ms transaction time.

---

### 10. Missing Rate Limiting Specifications
**Location:** architecture/overview.md mentions "rate limiting on all public endpoints" but no thresholds defined
**Issue:** Without specific limits, risk of:
- Brute force on verification codes (email flooding)
- API abuse (scraping product catalog)
- DDoS amplification (expensive operations)

**Recommended Solution:**
```typescript
// Rate limits by endpoint
const RATE_LIMITS = {
  '/api/auth/send-code': '5 per 15min per email',
  '/api/auth/verify-code': '10 per 15min per email',
  '/api/checkout/reserve-inventory': '20 per 15min per IP',
  '/api/checkout/validate-promo-code': '30 per 15min per IP',
  '/api/reviews': '5 per hour per customer',
  '/api/products': '100 per 15min per IP'
};
```

**Complexity:** Low (Cloud Armor or API Gateway config, 2-3 hours).

---

## Low Priority Issues (Nice to Have)

### 11. No Request Coalescing for Hot Products
**Location:** performance.md line 228
**Issue:** Multiple simultaneous requests for same product all query Firestore independently. Even with caching, cache misses cause "thundering herd" where 100 requests all fetch same product simultaneously.

**Recommended Solution:**
```typescript
// De-duplicate in-flight requests
const inflightRequests = new Map<string, Promise<Product>>();

async function getProduct(id: string): Promise<Product> {
  if (inflightRequests.has(id)) {
    return inflightRequests.get(id);
  }

  const promise = fetchProductFromFirestore(id);
  inflightRequests.set(id, promise);

  try {
    const result = await promise;
    return result;
  } finally {
    inflightRequests.delete(id);
  }
}
```

**Expected Gain:** 95% reduction in redundant queries during cache misses.
**Complexity:** Low (2-3 hours).

---

### 12. Image Optimization Pipeline Deferred to Post-Launch
**Location:** performance.md lines 220-222
**Issue:** Manual image optimization at MVP means inconsistent file sizes, no responsive images, potential for 5MB product photos.

**Recommended Solution:**
Use Cloud Functions for automatic WebP conversion on upload:
```typescript
export const optimizeImage = functions.storage
  .object()
  .onFinalize(async (object) => {
    const filePath = object.name;
    if (!filePath.startsWith('products/')) return;

    // Generate variants
    const variants = [
      {name: 'thumb', size: 200},
      {name: 'card', size: 400},
      {name: 'detail', size: 800},
      {name: 'full', size: 1200}
    ];

    for (const variant of variants) {
      await sharp(filePath)
        .resize(variant.size, variant.size, {fit: 'inside'})
        .webp({quality: 85})
        .toFile(`${filePath}_${variant.name}.webp`);
    }
  });
```

**Complexity:** Low (1 day for setup and testing).

---

## Observations

### Positive Performance Characteristics

1. **Excellent documentation quality**: Performance budgets, scaling projections, and failure modes well-documented. This is rare and valuable.

2. **Appropriate technology choices**:
   - Cloud Run auto-scaling fits traffic pattern (low volume with spikes)
   - Firestore transactions correctly used for consistency
   - Pessimistic locking prevents overselling (business-critical)

3. **Realistic performance targets**: P95 latency targets account for Stripe API being 40-60% of checkout time. Not over-optimizing controllable portions.

4. **Good failure mode analysis**: Multi-layered cleanup (ADR-009) shows defensive thinking. Dual-path order creation (ADR-007) ensures payment-to-order conversion.

5. **Cost-conscious architecture**: Free tier usage projected correctly ($30-50/month at launch). Appropriate for small business.

### Areas of Concern

1. **MVP deferring critical caching**: Without Redis at launch, Firestore costs and latency targets both at risk. In-memory caching should be MVP.

2. **Hot spot not addressed until "Month 6+"**: Product document contention will hurt Black Friday (first occurrence likely Year 1). Sharding should be implemented sooner.

3. **Unbounded operations accepted**: Cleanup job, lazy cleanup, and over-redemption all have scenarios where bounds are soft or missing. Defensive programming should add hard limits.

4. **Performance monitoring unclear**: Document mentions "Key dashboards" but doesn't specify SLIs/SLOs or alerting thresholds beyond conflicts and cache hits.

5. **Testing strategy not discussed**: No mention of load testing, performance regression tests, or how to validate P95 targets before launch.

### Scalability Assessment

**Current capacity (no optimization):**
- 10-20 orders/hour: Comfortable
- 50 orders/hour: Approaching limits (10-15% conflicts)
- 100 orders/hour: Degraded performance (20-30% conflicts)

**With recommended fixes (Critical + High Priority):**
- 10-20 orders/hour: Excellent performance
- 50 orders/hour: Comfortable
- 100 orders/hour: Good performance (2-5% conflicts)
- 200+ orders/hour: Consider sharding (addressed in roadmap)

**Data volume scaling (5-year projection):**
- Year 1: 7MB (documented)
- Year 5: ~100MB (20K orders, 2K products, 5K reviews)
- Firestore handles this easily, cost remains low

**Cost projection with fixes:**
- MVP with in-memory cache: $35-55/month
- MVP without cache: $100-150/month (Firestore read costs)
- Year 2: $150-250/month (Redis + increased traffic)

### Risk Assessment

**High risk (must address):**
- Critical Issue #1: Without caching, may miss latency targets and exceed budget
- Critical Issue #2: Black Friday conflicts could impact revenue during peak

**Medium risk (monitor closely):**
- High Priority Issue #6: Viral promo code could cause significant loss
- Medium Priority Issue #8: Cleanup failures create inconsistent customer experience

**Low risk (acceptable for MVP):**
- All other issues can be addressed post-launch without major impact

---

## Summary

**Critical Issues:** 3
**High Priority Issues:** 4
**Medium Priority Issues:** 3
**Low Priority Issues:** 2

**Overall Assessment:** The design demonstrates strong performance engineering fundamentals but defers two critical optimizations (caching and hot spot mitigation) that should be addressed before launch. The team clearly understands performance trade-offs and has documented them well, but the MVP scope may be too minimal for stated traffic goals.

**Recommendation:** Implement Critical Issues #1 and #2 before launch. High Priority issues can be addressed in first month post-launch with monitoring. Medium/Low priority issues are acceptable technical debt for MVP.

**Estimated effort to achieve PASS verdict:** 5-7 days of development time to implement critical fixes and validate performance under load.
