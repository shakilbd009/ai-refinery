# Stage 6 Backlog - Remaining Work

**Project:** Manik Golden Honey Co
**Stage:** 6 - Refine L3 → Graduate
**Last Updated:** 2026-01-24
**Status:** 50% Complete (2 of 4 L3 docs done)

---

## Priority 1: Complete L3 Documents (2 remaining)

### 1.1 Inventory Reservation L3

**Estimated effort:** 1-2 hours
**Status:** Not started
**Dependencies:** None (can start immediately)

**Scope:**
- [ ] Document 6-7 flow variants
  - Happy path: Reserve → Checkout → Release
  - Reservation expiration
  - Admin inventory update with active reservations
  - Concurrent reservation attempts (race conditions)
  - Background cleanup job scenarios
  - Product deletion with active reservations
  - Manual cleanup (admin trigger)
- [ ] Specify 3-4 timeout scenarios
  - Network timeout (frontend → API)
  - Firestore transaction timeout
  - Background cleanup job timeout
  - Lazy cleanup timeout threshold
- [ ] Document 12-15 error scenarios across categories
  - E1: Reservation errors (insufficient inventory, already reserved, product inactive)
  - E2: Race condition errors (concurrent checkouts, concurrent cleanups)
  - E3: Background job errors (job failure, multiple instances, monitoring gaps)
  - E4: Admin operation errors (validation failures, active reservation conflicts)
- [ ] Define 2-3 security attack vectors
  - Inventory locking DoS (malicious reservations)
  - Reservation manipulation (extend/modify others' reservations)
  - Cleanup bypass attempts
- [ ] Specify performance characteristics
  - Transaction latency (P50/P95/P99)
  - Cleanup job execution time
  - Concurrent reservation throughput
  - Firestore transaction conflict rate
- [ ] Define monitoring metrics
  - Reservation funnel (created, expired, converted, cleaned)
  - Cleanup job health (success rate, latency, failures)
  - Transaction conflicts (count, retry rate)
  - Inventory accuracy (reserved vs actual)
- [ ] Create testing strategy
  - 30-40 unit tests (transaction logic, validation, expiration)
  - 15-20 integration tests (full reservation flows, cleanup)
  - 2-3 load tests (concurrent reservations, conflict handling)

**References:**
- ADR-001: Pessimistic Inventory Locking
- ADR-008: Firestore Transaction Strategy
- ADR-009: Multi-Layered Job Failure Mitigation
- 05-design-l2/inventory-race-conditions-L2.md
- 05-design-l2/inventory-operations-L2.md

---

### 1.2 Discount Code L3

**Estimated effort:** 1-2 hours
**Status:** Not started
**Dependencies:** None (can start immediately, but recommend after Inventory L3)

**Scope:**
- [ ] Document 5-6 flow variants
  - Happy path: Apply code → Lock at payment → Honor at order creation
  - Code expiration during checkout (grace period)
  - Cart changes after code applied
  - Admin modifies code mid-checkout
  - Max redemptions reached (race condition)
  - Invalid/expired code attempts
- [ ] Specify 2-3 timeout scenarios
  - Code validation timeout
  - Lock-in at payment intent creation timeout
  - Grace period expiration
- [ ] Document 10-12 error scenarios across categories
  - E1: Validation errors (code not found, expired, inactive, max uses)
  - E2: Race condition errors (concurrent redemptions, max limit)
  - E3: Cart mismatch errors (min purchase, excluded products)
  - E4: Admin change errors (code modified/deleted during checkout)
- [ ] Define 2-3 security attack vectors
  - Promo code farming (brute force, scraping)
  - Over-redemption exploitation (race condition abuse)
  - Discount stacking attempts
- [ ] Specify performance characteristics
  - Code lookup latency (P50/P95/P99)
  - Validation overhead per checkout
  - Grace period monitoring cost
  - Concurrent redemption throughput
- [ ] Define monitoring metrics
  - Code usage funnel (applied, locked, redeemed, expired)
  - Grace period triggers (count, success rate)
  - Validation errors (by type, frequency)
  - Fraud attempts (farming, over-redemption)
- [ ] Create testing strategy
  - 30-40 unit tests (validation, lock-in, grace period, race conditions)
  - 15-20 integration tests (full checkout flows with codes)
  - 2 load tests (concurrent redemptions, farming attempts)

**References:**
- ADR-004: Discount Code Scope Order-Wide
- ADR-012: Discount Code Lock-In
- 05-design-l2/discount-code-validation-L2.md
- 05-design-l2/business-rules-L2.md (discount policies)

---

## Priority 2: Edge Case Discovery Framework (100% Coverage)

**Estimated effort:** 1-2 hours
**Status:** Not started
**Dependencies:** All 4 L3 documents complete

**Scope:**
- [ ] Apply framework systematically across all components
  - Data boundary cases
    - [ ] Empty inputs (null, empty string, empty arrays)
    - [ ] Maximum values (integer overflow, string limits, array limits)
    - [ ] Minimum values (zero, negative, boundary conditions)
    - [ ] Special characters (Unicode, emoji, SQL injection, XSS)
    - [ ] Type mismatches (string as number, null as object)
  - State transition cases
    - [ ] Invalid transitions (canceled → shipped, refunded → paid)
    - [ ] Race conditions on state changes (concurrent updates)
    - [ ] State persistence failures (DB write fails mid-transition)
    - [ ] Orphaned states (reservation without order, order without payment)
    - [ ] Partial state recovery (transaction rollback)
  - Timing cases
    - [ ] Timeouts (network, database, external API)
    - [ ] Expiration (reservations, codes, sessions, JWT tokens)
    - [ ] Clock skew (server vs client time, timezone issues)
    - [ ] Daylight saving transitions (code expires at 2 AM DST)
    - [ ] Concurrent operations (two users, two jobs, user + job)
  - Integration cases
    - [ ] External service down (Stripe, Mailgun, Firestore)
    - [ ] External service slow (timeout, retry logic)
    - [ ] External service rate limiting (429 errors, backoff)
    - [ ] Webhook delivery failures (retry exhaustion, delayed)
    - [ ] API version mismatches (Stripe upgrade breaks integration)
- [ ] Document handling approach for each edge case
- [ ] Prioritize edge cases (must-fix vs defer to post-launch)
- [ ] Create test scenarios for critical edge cases
- [ ] Add to monitoring strategy (edge case occurrence tracking)

**Output:**
- `06-design-l3/edge-cases-catalog.md` - Comprehensive cross-component catalog

---

## Priority 3: Architecture Finalization

**Estimated effort:** 30-60 minutes
**Status:** Not started
**Dependencies:** All L3 documents complete

**Scope:**
- [ ] Review all 12 ADRs for accuracy
  - [ ] Validate status field (Accepted/Deprecated/Superseded)
  - [ ] Verify references between ADRs are correct
  - [ ] Check implementation notes are complete
  - [ ] Ensure success criteria are measurable
  - [ ] Confirm review dates are appropriate (1-6 months post-launch)
- [ ] Validate component interactions
  - [ ] Checkout ↔ Inventory (reservation flow)
  - [ ] Checkout ↔ Discount Codes (validation, lock-in)
  - [ ] Orders ↔ Reviews (purchase verification)
  - [ ] All ↔ Firestore (transaction patterns)
- [ ] Finalize API contracts
  - [ ] Document all endpoints with request/response schemas
  - [ ] Define error response formats
  - [ ] Specify authentication/authorization per endpoint
- [ ] Document deployment architecture
  - [ ] Cloud Run services (API, background jobs)
  - [ ] Cloud Scheduler jobs (cleanup)
  - [ ] Firestore database structure
  - [ ] Stripe webhook configuration
  - [ ] Mailgun email configuration

**Output:**
- Updates to existing ADRs
- `06-design-l3/api-contracts.md`
- `06-design-l3/deployment-architecture.md`

---

## Priority 4: Performance & Security Analysis

**Estimated effort:** 30-60 minutes
**Status:** Not started
**Dependencies:** All L3 documents complete

**Scope:**

### Performance Analysis
- [ ] Latency budget per critical path
  - [ ] Checkout flow: Reserve → Payment → Order (target: < 3s)
  - [ ] Payment confirmation: Webhook → Order creation (target: < 10s)
  - [ ] Order creation: Transaction → Email (target: < 5s)
- [ ] Throughput estimates
  - [ ] Orders per hour (expected: 10-50 in MVP)
  - [ ] Concurrent users (expected: 5-20 in MVP)
  - [ ] Peak load scenarios (launch day, promotions)
- [ ] Scaling limits identified
  - [ ] Firestore queries/sec (current tier limits)
  - [ ] Transaction conflict rate (acceptable: < 5%)
  - [ ] Cloud Run instance limits
- [ ] Bottleneck analysis
  - [ ] Slowest operations (transaction commits, email sends)
  - [ ] Contention points (popular product reservations)
  - [ ] External dependencies (Stripe API, Mailgun)
- [ ] Caching strategy
  - [ ] Product catalog (cache duration, invalidation)
  - [ ] Discount codes (cache vs fresh lookup)
  - [ ] Customer session data
- [ ] CDN strategy
  - [ ] Product images (Firebase Storage + CDN)
  - [ ] CSS/JS bundles
  - [ ] Static assets

### Security Threat Model
- [ ] Attack surface mapped
  - [ ] Public endpoints (product pages, checkout, webhooks)
  - [ ] Admin routes (dashboard, moderation, inventory)
  - [ ] Webhook endpoints (Stripe)
- [ ] Threat actors identified
  - [ ] Competitors (scraping, sabotage)
  - [ ] Fraudsters (discount abuse, fake reviews)
  - [ ] Script kiddies (DoS, SQL injection attempts)
- [ ] Attack vectors per threat
  - [ ] Credential stuffing (admin accounts)
  - [ ] SQL injection (none - Firestore, but validate inputs)
  - [ ] XSS (review content, product descriptions)
  - [ ] DoS (inventory locking, review bombing)
- [ ] Mitigations specified
  - [ ] Rate limiting (per endpoint, per IP)
  - [ ] Input validation (sanitization, length limits)
  - [ ] WAF rules (if using Cloud Armor)
  - [ ] Webhook signature verification
- [ ] Detection mechanisms
  - [ ] Alerts (failed login attempts, webhook failures)
  - [ ] Logging (security events, admin actions)
  - [ ] Anomaly detection (unusual traffic patterns)
- [ ] Incident response procedures
  - [ ] Who to contact (admin email, monitoring service)
  - [ ] What to do (disable account, block IP, rollback)
  - [ ] When to escalate (data breach, sustained attack)
  - [ ] How to recover (restore from backup, audit logs)

**Output:**
- `06-design-l3/performance-analysis.md`
- `06-design-l3/security-threat-model.md`

---

## Priority 5: Red Flags & Stability Check

**Estimated effort:** 30 minutes
**Status:** Not started
**Dependencies:** All above priorities complete

**Scope:**

### Red Flags Checklist (100% Pass Required)
- [ ] Critical Red Flags
  - [ ] No "figure it out later" on critical paths
  - [ ] Zero hand-waving on complexity
  - [ ] Every decision has clear rationale documented
  - [ ] All trade-offs explicitly acknowledged
  - [ ] No god objects in architecture
  - [ ] Clear separation of concerns throughout
  - [ ] No circular dependencies between components
  - [ ] All failure modes identified and mitigated
- [ ] Quality Red Flags
  - [ ] No magic numbers (all constants named and explained)
  - [ ] No duplicated logic (DRY principle applied)
  - [ ] Error messages are helpful (actionable guidance)
  - [ ] Logging strategy comprehensive (debug, error, audit)
  - [ ] Monitoring gaps identified (what can't be observed?)
  - [ ] Testing gaps identified (what can't be tested?)
- [ ] Security Red Flags
  - [ ] Input validation specified for all endpoints
  - [ ] Authentication enforced on all protected routes
  - [ ] Authorization checks documented per operation
  - [ ] Secrets management strategy defined
  - [ ] SQL injection prevention verified
  - [ ] XSS prevention verified
  - [ ] CSRF protection specified
  - [ ] Rate limiting defined for public endpoints

### Stability Check (L1 → L2 → L3)
- [ ] Verify design evolution was refinement, not pivots
  - [ ] Core concepts stable from L1 (no fundamental changes)
  - [ ] L2 built on L1 (additive refinement, not replacement)
  - [ ] L3 completes L2 (exhaustive detail, not new direction)
  - [ ] No major rework needed (stable foundation)
  - [ ] Trade-offs consistent across levels (no contradictions)
- [ ] Consistency validation
  - [ ] Terminology consistent across all documents
  - [ ] Component names match (architecture, ADRs, L3 docs)
  - [ ] API contracts match database schema
  - [ ] Error codes consistent across endpoints
  - [ ] Monitoring metrics align with ADR success criteria

**Output:**
- `06-design-l3/red-flags-review.md`
- `06-design-l3/stability-check.md`

---

## Priority 6: Graduation Preparation

**Estimated effort:** 1 hour
**Status:** Not started
**Dependencies:** All above priorities complete

**Scope:**
- [ ] Curate final design documents
  - [ ] Extract key content from L3 docs (remove exploration notes)
  - [ ] Consolidate architecture diagrams
  - [ ] Create decision summary (from ADRs)
  - [ ] Include edge case catalog
- [ ] Remove exploration artifacts
  - [ ] Keep only L3 content (or summaries of L1/L2)
  - [ ] Remove dead-end approaches from L2
  - [ ] Clean up redundant documentation
- [ ] Create executive summary
  - [ ] Project overview (1-2 pages)
  - [ ] Key architectural decisions
  - [ ] Critical paths (checkout, payment, moderation)
  - [ ] Known risks and mitigations
  - [ ] Success metrics
- [ ] Package for graduation
  - [ ] Requirements document
  - [ ] Architecture overview
  - [ ] All 12 ADRs
  - [ ] L3 component designs (4 docs)
  - [ ] Edge case catalog
  - [ ] Performance analysis
  - [ ] Security threat model
  - [ ] Testing strategy
- [ ] Verify design completeness
  - [ ] 95%+ confidence level achieved
  - [ ] Zero TBDs or unknowns
  - [ ] Implementation team can start coding immediately
  - [ ] All questions answered

**Output:**
- `curated/` directory created
- `curated/curated-design.md`
- `curated/executive-summary.md`
- Ready for `/graduate` command

---

## Completion Criteria

**Stage 6 is complete when:**
- ✅ All 4 L3 documents created (Checkout ✅, Reviews ✅, Inventory ⏳, Codes ⏳)
- ✅ Edge Case Discovery Framework applied (100% coverage)
- ✅ Red Flags Checklist passed (100% - all items checked)
- ✅ Stability Check passed (L1→L2→L3 consistent)
- ✅ Performance analysis complete
- ✅ Security threat model complete
- ✅ All ADRs reviewed and current
- ✅ Curated design package ready
- ✅ 95%+ confidence in design soundness
- ✅ Zero ambiguity remaining

**Then:**
- Advance to Stage 7 (Graduate)
- Run `/graduate manik-golden-honey-co path/to/production-repo`

---

## Time Estimate Summary

| Priority | Tasks | Estimated Time |
|----------|-------|----------------|
| P1: L3 Documents | Inventory + Discount Codes | 2-4 hours |
| P2: Edge Cases | Systematic catalog | 1-2 hours |
| P3: Architecture | ADR review, API contracts | 30-60 min |
| P4: Perf & Security | Analysis + threat model | 30-60 min |
| P5: Red Flags | Review + stability check | 30 min |
| P6: Graduation Prep | Curate + package | 1 hour |
| **TOTAL** | | **5-8 hours** |

---

**Backlog created:** 2026-01-24
**Status:** 2 of 4 L3 docs complete (50%)
**Next action:** Create Inventory Reservation L3
**Estimated time to graduation:** 5-8 hours of focused work
