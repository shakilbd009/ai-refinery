# Architecture Validation: manik-golden-honey-co

**Validated:** 2026-01-25
**Validator:** architecture-strategist

## Verdict: PASS

This architecture demonstrates exceptional design maturity with comprehensive consideration of distributed systems challenges, clear separation of concerns, and well-documented decision-making processes. The design is production-ready with minor recommendations for future enhancement.

---

## Critical Issues (Blocking Architecture Problems)

None identified.

---

## High Priority (Should Address)

### H1: Missing Distributed Lock for Promo Code Redemption Race Condition

**Location:** `/Users/shakilakram/projects/ai-baseline/ideas/manik-golden-honey-co/curated/decisions/ADR-012-discount-code-lock-in.md`

**Issue:** The design acknowledges a race condition for `max_redemptions` enforcement but accepts over-redemption as tolerable. While this may be acceptable for MVP, the lack of atomic enforcement could lead to revenue loss at scale.

**Analysis:**
- Two customers can validate a promo code simultaneously when it's at max_redemptions - 1
- Both see valid status, both get discounts, total redemptions exceeds limit
- ADR-012 states "over-redemption possible (max_redemptions race condition accepted)"
- No distributed locking mechanism documented for this scenario

**Impact:**
- Direct revenue impact if high-value discount codes are over-redeemed
- Admin confusion when usage reports show redemptions > max_redemptions
- Brand reputation risk if customers share codes expecting limited availability

**Recommendation:**
- Implement atomic increment with transaction check: `if (used_count + 1 <= max_redemptions)`
- Firestore transaction can handle this pattern - already used for inventory
- Add validation in `POST /api/checkout/validate-promo-code` before PaymentIntent creation
- Document this in ADR-012 as a post-MVP improvement with clear migration path

**Architectural Pattern Violated:** Atomicity of business constraints

---

### H2: Reservation State "completing" Creates Ambiguous Recovery Path

**Location:** `/Users/shakilakram/projects/ai-baseline/ideas/manik-golden-honey-co/curated/architecture/components/inventory-reservation.md`

**Issue:** The reservation lifecycle includes a "completing" state to prevent cleanup during payment, but the recovery path from this state is unclear if payment fails or times out indefinitely.

**Analysis:**
```
active → completing (payment started, blocks cleanup)
       → completed (order created)
       → expired (cleanup released)
```

**Questions:**
- What happens if a reservation is stuck in "completing" for > 15 minutes?
- If payment fails after 10 minutes, does reservation transition back to "active" or directly to "expired"?
- Does cleanup job skip "completing" reservations forever, or is there a secondary timeout?

**Impact:**
- Inventory could be locked indefinitely if "completing" state has no timeout
- No documented recovery for stuck transactions
- Potential revenue loss from permanently reserved inventory

**Recommendation:**
- Define maximum duration for "completing" state (e.g., 20 minutes absolute)
- Add `completing_started_at` timestamp field
- Cleanup job should release reservations where `status = completing AND completing_started_at < now - 20min`
- Document state transition recovery in component documentation
- Add monitoring alert for reservations stuck in "completing" > 15 minutes

**Architectural Pattern Violated:** State machine completeness - missing terminal state timeout

---

### H3: No Reconciliation Strategy for Inventory Drift

**Location:** `/Users/shakilakram/projects/ai-baseline/ideas/manik-golden-honey-co/curated/edge-cases/state-transitions.md`

**Issue:** While a reconciliation function is documented in edge cases, there's no architectural commitment to when/how reconciliation runs automatically.

**Analysis:**
- Reconciliation pattern exists: `reconcileReservedQuantity(productId)`
- Documented as manual recovery, not proactive monitoring
- If `reserved_quantity` becomes inconsistent due to bugs or race conditions, there's no automatic detection
- Core invariant `available = quantity - reserved_quantity >= 0` could be violated silently

**Impact:**
- Data integrity issues could persist undetected
- Manual reconciliation is error-prone and requires admin intervention
- Negative inventory states could block legitimate sales

**Recommendation:**
- Schedule reconciliation job daily (off-peak hours)
- Add real-time validation: before creating reservation, verify `reserved_quantity` matches sum of active reservations
- Implement monitoring query: `WHERE quantity - reserved_quantity < 0` with CRITICAL alert
- Add reconciliation endpoint to admin API for on-demand execution
- Document reconciliation schedule in operations runbook

**Architectural Pattern Violated:** Data integrity monitoring and self-healing

---

## Medium Priority

### M1: Cart Size Limit Not Enforced at API Layer

**Location:** `/Users/shakilakram/projects/ai-baseline/ideas/manik-golden-honey-co/curated/performance.md`

**Issue:** Firestore transaction limit is 500 writes, documented cart limit is "50 items" in performance.md, but API contract doesn't show this validation.

**Analysis:**
- Performance.md states "Transaction writes | 500 docs | Cart limit: 50 items"
- API contract for `POST /api/checkout/reserve-inventory` shows no max items validation
- If customer submits cart with 600 items (edge case), transaction would fail with unclear error
- No documented error message for oversized carts

**Recommendation:**
- Add explicit cart size validation in API: `max 50 items, max 10 units per item`
- Return clear error: `400 "Cart exceeds maximum of 50 items"`
- Document this limit in API contract and customer-facing error messages
- Consider whether 50 items is realistic for honey business (seems high)

**Architectural Pattern:** Input validation at API boundary

---

### M2: Email Queue Retry Strategy Lacks Exponential Backoff Details

**Location:** `/Users/shakilakram/projects/ai-baseline/ideas/manik-golden-honey-co/curated/edge-cases/integration.md`

**Issue:** Email failure handling queues failed emails with `next_retry: now + 5min`, but no exponential backoff or maximum retry limit documented.

**Analysis:**
```javascript
next_retry: new Date(Date.now() + 5 * 60 * 1000), // Always 5 minutes
```
- Fixed 5-minute retry could overwhelm email service if it's rate-limited
- No max retry count means emails could retry forever
- No dead-letter queue for permanently failed emails
- Admin has no visibility into queued/failed emails

**Recommendation:**
- Implement exponential backoff: 5min, 15min, 1hr, 4hr, 24hr
- Maximum 5 retry attempts, then move to dead-letter collection
- Add `email_status` collection for admin monitoring: `{email_id, status, attempts, last_error}`
- Admin dashboard should show failed emails requiring attention
- Document retry strategy in operations runbook

**Architectural Pattern:** Resilient retry with circuit breaker

---

### M3: Review Edit Cooldown Implementation Missing from API Contract

**Location:** `/Users/shakilakram/projects/ai-baseline/ideas/manik-golden-honey-co/curated/architecture/data-model.md` and `api-contracts.md`

**Issue:** Data model shows `next_edit_allowed_at` field, but API contract for `PUT /api/reviews/:id` only mentions "429 (cooldown active)" without details.

**Analysis:**
- Data model defines: `next_edit_allowed_at: timestamp | null`
- API contract error: "429 (cooldown active)" - semantically incorrect status code
- 429 is for rate limiting, not temporal cooldowns (should be 403 or 409)
- No specification for cooldown duration
- ADR-002 mentions "3 edits max" but no timing constraints documented

**Recommendation:**
- Use 403 Forbidden with clear message: "Review cannot be edited until {timestamp}"
- Document cooldown duration in requirements (e.g., 24 hours between edits)
- API response should include: `{ error: "edit_cooldown_active", retry_after: "2026-01-26T14:30:00Z" }`
- Add this to data model documentation and API contract

**Architectural Pattern:** Consistent HTTP semantics and error handling

---

### M4: Missing Circuit Breaker for Stripe API Failures

**Location:** `/Users/shakilakram/projects/ai-baseline/ideas/manik-golden-honey-co/curated/edge-cases/integration.md`

**Issue:** Stripe API failure handling shows timeout logic but no circuit breaker to prevent cascading failures.

**Analysis:**
- Stripe is documented as "dominant bottleneck (40-60% of checkout time)"
- If Stripe has partial outage, every checkout attempt will wait 30s before timeout
- No circuit breaker means continued requests during known outage
- Could overwhelm application with timeout threads/resources

**Recommendation:**
- Implement circuit breaker pattern for Stripe API calls
- States: Closed (normal) → Open (failing, fast-fail) → Half-Open (testing recovery)
- Threshold: 5 consecutive failures → Open for 60 seconds
- During Open state: return immediate error "Payment system temporarily unavailable, please try again in 1 minute"
- Add to edge-cases documentation and component design

**Architectural Pattern:** Circuit breaker for external service resilience

---

### M5: Admin Audit Log Pattern Not Specified

**Location:** `/Users/shakilakram/projects/ai-baseline/ideas/manik-golden-honey-co/curated/security/threat-model.md`

**Issue:** Security requirements state "All admin actions with before/after state" must be logged, but no schema or storage pattern is defined.

**Analysis:**
- Security threat model requires comprehensive admin audit logging
- No `admin_audit_log` collection defined in data model
- No specification for retention policy (mentioned 2 years in logging requirements)
- No query pattern for investigating admin actions

**Recommendation:**
- Define `admin_audit_log` collection schema:
  ```typescript
  {
    id: string,
    admin_id: string,
    action: string, // "product.update", "order.cancel", etc.
    resource_type: string,
    resource_id: string,
    before_state: object | null,
    after_state: object | null,
    timestamp: timestamp,
    ip_address: string,
    user_agent: string
  }
  ```
- Add indexes: `(admin_id, timestamp DESC)`, `(resource_type, resource_id, timestamp DESC)`
- Document retention policy and export strategy
- Add to data-model.md and security documentation

**Architectural Pattern:** Comprehensive audit trail for compliance

---

## Low Priority / Improvements

### L1: Consider Event Sourcing for Order State Transitions

**Observation:** Order status transitions are documented extensively in edge-cases, but using simple status field updates loses transition history.

**Enhancement:** Consider adding `order_events` collection to track all state transitions:
```typescript
{
  order_id: string,
  event_type: string, // "created", "shipped", "cancelled"
  previous_state: string,
  new_state: string,
  triggered_by: string,
  timestamp: timestamp
}
```

**Benefits:**
- Full audit trail of order lifecycle
- Easier debugging of state transition bugs
- Foundation for advanced analytics

**Trade-off:** Additional writes per status change, more complex queries for current state

---

### L2: Repository Pattern Abstraction Could Be More Explicit

**Observation:** Overview mentions "Repository Pattern - Database abstraction layer" but no Go repository interfaces are defined in architecture docs.

**Enhancement:** Document repository interface contracts explicitly:
```go
type ProductRepository interface {
  GetByID(ctx, id) (*Product, error)
  List(ctx, filters) ([]*Product, error)
  Create(ctx, product) error
  UpdateInventory(ctx, productID, delta int) error
}
```

**Benefits:**
- Clearer abstraction boundaries
- Easier testing with mocks
- Documented migration path from Firestore to PostgreSQL

---

### L3: Observability Pattern for Distributed Tracing Not Documented

**Observation:** Monitoring requirements mention latency targets and error rates, but no distributed tracing strategy for checkout flow.

**Enhancement:**
- Add OpenTelemetry instrumentation to trace requests across Next.js → Go API → Firestore → Stripe
- Document trace IDs in correlation pattern for debugging
- Add to operations documentation

**Benefits:**
- Faster debugging of performance bottlenecks
- Visualization of checkout flow latency distribution
- Correlation between frontend and backend failures

---

### L4: API Versioning Strategy Not Defined

**Observation:** External service API versioning is documented (Stripe pinned to `2023-10-16`), but internal API versioning strategy is absent.

**Enhancement:**
- Define API versioning approach (URL-based `/v1/` vs header-based)
- Document breaking change policy
- Add to API contracts documentation

**Benefits:**
- Enables safe evolution of API contracts
- Supports mobile app future (mentioned as out-of-scope but potential Year 2 feature)

---

### L5: Database Migration Strategy Not Specified

**Observation:** Soft-delete pattern and schema evolution mentioned, but no formal migration strategy for schema changes.

**Enhancement:**
- Document Firestore schema change process
- Define migration scripts pattern (Go code with transactions)
- Add rollback strategy for failed migrations
- Document in operations runbook

---

## Architecture Strengths

### Exceptional Documentation Quality
- 12 comprehensive ADRs with clear rationale, consequences, and alternatives
- Every major decision traced to business requirements
- Edge cases thoroughly documented with code examples
- Consistent terminology across all documents

### Appropriate Use of Transactions
- Firestore transactions correctly applied to all critical paths
- Race condition handling with automatic retry
- Clear understanding of ACID guarantees and limitations
- Transaction patterns well-documented with examples

### Defense in Depth for Critical Paths
- Checkout flow: 5-layer mitigation (ADR-009)
- Inventory management: pessimistic locking + reconciliation + monitoring
- Order creation: dual-path (webhook + frontend) with idempotency
- Security: layered rate limiting, validation, and authentication

### Honest Trade-off Analysis
- Every ADR explicitly documents negative consequences
- Trade-offs clearly stated in trade-offs.md
- No over-engineering - appropriate complexity for scale
- MVP constraints respected without compromising core integrity

### Strong Separation of Concerns
- Clean service boundaries (Product, Reservation, Order, Payment, Email, Auth)
- Background jobs isolated in separate Cloud Run service
- Frontend and backend responsibilities clearly delineated
- Data model normalized appropriately with strategic denormalization

### Comprehensive Edge Case Coverage
- State transitions documented with invalid paths prevented
- Integration failures handled with fallbacks
- Timing issues (expiration, grace periods) thoroughly considered
- Orphaned states detected and cleaned up

### Scalability-Aware Design
- Cloud Run auto-scaling with appropriate min/max instances
- Firestore chosen for auto-scaling database
- Caching strategy defined with invalidation patterns
- Performance budgets established with monitoring

### Security First Approach
- Threat model with attack surface analysis
- Rate limiting specified per endpoint
- Webhook signature verification emphasized as critical
- Secret management through GCP Secret Manager
- Comprehensive audit logging requirements

---

## Recommendations

### Immediate (Before Implementation Starts)

1. **Address H1-H3 issues** - These represent gaps in atomic consistency and recovery paths that should be resolved in design phase
2. **Define admin audit log schema** (M5) - Required for security compliance, easier to design now than retrofit
3. **Document cart size validation** (M1) - Simple addition to API contract
4. **Clarify reservation "completing" state timeout** (H2) - Critical for inventory accuracy

### Post-MVP (Within 3 Months)

1. **Implement circuit breaker for Stripe** (M4) - Will improve customer experience during outages
2. **Add reconciliation job** (H3) - Proactive data integrity monitoring
3. **Improve email retry strategy** (M2) - Important for order confirmation reliability
4. **Add distributed tracing** (L3) - Valuable for production debugging

### Long-term (6+ Months)

1. **Consider event sourcing for orders** (L1) - If analytics or compliance needs grow
2. **Define API versioning strategy** (L4) - Before any mobile app development
3. **Document repository interfaces** (L2) - If PostgreSQL migration becomes likely
4. **Implement database migration process** (L5) - As schema evolves with features

---

## Summary

This architecture demonstrates production-grade thinking with exceptional attention to distributed systems challenges, data integrity, and operational concerns. The design is well-suited for the stated business requirements and scale targets.

**Key Strengths:**
- Comprehensive ADR coverage with honest trade-off analysis
- Strong transactional guarantees for inventory and payment critical paths
- Defense-in-depth for reliability (multi-layer job failure mitigation)
- Appropriate technology choices for serverless, cost-efficient deployment

**Areas for Enhancement:**
- Atomic enforcement of business constraints (promo code redemptions)
- State machine completeness (reservation "completing" state timeout)
- Proactive data integrity monitoring (reconciliation jobs)
- Operational tooling (circuit breakers, audit logs)

**Overall Assessment:** The architecture is sound and ready for implementation with the recommended adjustments to address H1-H3 issues. The design shows strong understanding of CAP theorem trade-offs, eventual consistency patterns, and operational realities of distributed systems.

The documented edge cases, failure modes, and recovery patterns indicate this system will be maintainable and debuggable in production. The explicit acknowledgment of trade-offs (e.g., accepting promo code over-redemption, choosing conversion over speed) shows mature architectural decision-making aligned with business priorities.

**Confidence Level:** High - This design will successfully serve the business requirements for 12-24 months at stated scale (500-5000 customers, ~100 orders/week).
