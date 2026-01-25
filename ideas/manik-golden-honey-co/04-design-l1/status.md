# Stage 4: Refine L1 - Detailed Design - Status

**Project:** Manik Golden Honey Co
**Stage:** 4 - Refine L1 → Refine L2
**Date Started:** 2026-01-24
**Date Completed:** 2026-01-24
**Status:** ✅ Complete - Ready for Stage 5

---

## Stage 4 Completion Checklist

### Architecture Documentation
- [x] Detailed system architecture diagram created
- [x] Component responsibilities documented (Next.js, Go API, Cleanup Service)
- [x] Data flow diagrams created (4 major flows)
- [x] Technology stack specifications
- [x] Security architecture documented (auth/authorization)

### Progressive Deepening L1 Documents
- [x] Checkout Flow L1 (critical path)
- [x] Review Moderation System L1
- [x] Inventory Reservation System L1
- [x] Discount Code System L1

### Database Schema
- [x] 10 Firestore collections fully specified
- [x] Field types and constraints documented
- [x] Indexes identified
- [x] Denormalization strategy documented
- [x] Data size estimates calculated

### API Contracts
- [x] Authentication endpoints specified
- [x] Checkout endpoints specified
- [x] Review endpoints specified
- [x] Cancellation endpoints specified
- [x] Admin promo code endpoints specified
- [x] Common error format defined
- [x] Request/response examples provided

### Error Scenarios
- [x] 19 basic error scenarios identified
- [x] Handling strategies documented
- [x] Impact analysis completed
- [x] Mitigation approaches noted

---

## Key Deliverables

### 1. Detailed Architecture (architecture-detailed.md)

**System components:**
- Next.js App (customer + admin UI)
- Go Backend API (business logic)
- Cleanup Service (background jobs)
- Firestore Database (10 collections)
- Cloud Scheduler (job orchestration)
- External services (Stripe, Mailgun)

**Data flow sequences:**
- Customer checkout (reservation → payment → order)
- Review moderation (submit → queue → approve)
- Cancellation workflow (request → admin review → refund)
- Background cleanup (expired reservations)

---

### 2. Progressive Deepening L1 Documents

**Four critical components analyzed:**

**Checkout Flow:**
- What: Inventory reservation + payment + order creation
- Why: Revenue path, must prevent overselling
- Key Insight: Pessimistic locking prevents race conditions
- Questions: Payment success but order failure, webhook timing, partial inventory

**Review Moderation:**
- What: Verified purchaser reviews with admin approval
- Why: Trust building, quality control
- Key Insight: Triple-gated (purchaser + moderation + edit re-moderation)
- Questions: Multiple purchases same product, admin editing, review bombing

**Inventory Reservation:**
- What: Temporary locks during checkout (15-min TTL)
- Why: Prevent overselling for small producer
- Key Insight: Three inventory states (physical, reserved, available)
- Questions: Background job failure, concurrent cleanup, admin update conflicts

**Discount Code System:**
- What: Percentage-based promotional codes (order-wide)
- Why: Marketing tool, customer acquisition
- Key Insight: Triple validation (application, payment, confirmation)
- Questions: Code expiration mid-checkout, max redemptions race, customer multiple tabs

---

### 3. Database Schema (10 Collections)

**Core collections:**
1. `products` - Product catalog (20 expected)
2. `customers` - Customer accounts (500 year 1)
3. `orders` - Order records (2,000 year 1)
4. `reviews` - Product reviews (600 year 1)
5. `inventory_reservations` - Checkout locks (~10 active)
6. `promo_codes` - Discount codes (10 campaigns)
7. `promo_code_usage` - Redemption tracking (1,200 year 1)
8. `cancellation_requests` - Cancellation workflow (50 year 1)
9. `verification_codes` - Passwordless auth (~50 active)
10. `admins` - Admin users (1 for MVP)

**Total estimated storage:** ~7.3MB (well within Firestore free tier)

**Key design decisions:**
- Denormalization for read performance (order snapshots, customer aggregates)
- Composite indexes for common queries
- Soft deletes for audit trail (promo codes)

---

### 4. API Contracts

**30+ endpoints specified:**
- Authentication: 4 endpoints (customer passwordless, admin login)
- Products: 5 endpoints (CRUD + list)
- Orders: 4 endpoints
- Checkout: 5 endpoints (reserve, validate, payment, confirm, release)
- Reviews: 7 endpoints (submit, edit, admin moderation)
- Cancellations: 4 endpoints (request, admin approve/deny)
- Admin promo codes: 5 endpoints (CRUD + stats)

**Common error format standardized:**
```json
{
  "error": "error_code",
  "message": "Human-readable message",
  "details": {}
}
```

---

### 5. Error Scenarios Identified

**19 basic errors documented:**

**Checkout (8 errors):**
- Insufficient inventory
- Reservation expired
- Payment success but order failure
- Promo code expiration mid-checkout
- Concurrent checkout race
- Payment declined
- Stripe timeout
- Webhook signature failure

**Reviews (2 errors):**
- Unpurchased product review attempt
- Review edit spam

**Email (2 errors):**
- Email service down
- Email bounce

**Inventory (3 errors):**
- Background job failure
- Admin sets inventory below reserved
- Reservation cleanup double-delete

**Cancellation (2 errors):**
- Stripe refund failure
- Cancellation after shipment

**Admin Auth (2 errors):**
- Brute force login attempts
- JWT token expiration

---

## Architecture Summary

**Serverless Infrastructure (GCP):**
- 3 Cloud Run services (Next.js, Go API, Cleanup)
- Firestore database (10 collections)
- Cloud Storage (product images)
- Cloud Scheduler (background jobs)
- Secret Manager (credentials)

**Key Patterns:**
- Pessimistic locking (inventory reservations)
- Admin approval workflows (reviews, cancellations)
- Dual notifications (dashboard badges + email)
- Repository pattern (database abstraction)
- Denormalization (read performance)

**Security:**
- Passwordless customer auth (6-digit email codes)
- Admin email/password (bcrypt)
- JWT tokens (8-hour expiration)
- Stripe handles PCI compliance
- Service account tokens for internal services

---

## Progressive Deepening Insights

**L1 Analysis Raised 24 Questions:**

These questions will drive L2 (Stage 5) and L3 (Stage 6) analysis:

**Checkout Flow (5 questions):**
1. Payment success but order creation failure handling?
2. Webhook vs frontend confirmation race condition?
3. Partial inventory fulfillment support?
4. Discount code expiration validation timing?
5. Multiple tab reservation management?

**Review Moderation (6 questions):**
1. Multiple purchases → multiple reviews?
2. Can admin edit review text?
3. Cascade delete reviews when product deleted?
4. Review bombing prevention?
5. Review edit limits?
6. Show rejected reviews to customer?

**Inventory Reservation (7 questions):**
1. Background job failure mitigation?
2. Concurrent cleanup prevention?
3. Admin inventory update validation?
4. Expired session handling?
5. Reservation countdown timer UX?
6. Product deletion with active reservations?
7. Firestore transaction atomicity?

**Discount Codes (6 questions):**
1. Cart change validation after code applied?
2. Max redemptions race condition?
3. Multiple code enforcement?
4. Mid-checkout code modification?
5. Duplicate code prevention?
6. Refunded order usage decrement?

---

## Metrics & Estimates

**API Endpoints:** 30+ documented
**Database Collections:** 10 specified
**Indexes Required:** 15 composite indexes
**Error Scenarios:** 19 identified
**Data Flow Diagrams:** 4 sequences
**Progressive Deepening Docs:** 4 components
**Total Storage (Year 1):** ~7.3MB
**Firestore Costs:** Within free tier (<$1/month)

---

## Files Created in Stage 4

```
ideas/manik-golden-honey-co/04-design-l1/
├── architecture-detailed.md       (System architecture + data flows)
├── checkout-flow-L1.md           (Progressive deepening L1)
├── review-moderation-L1.md       (Progressive deepening L1)
├── inventory-reservation-L1.md   (Progressive deepening L1)
├── discount-code-L1.md           (Progressive deepening L1)
├── database-schema.md            (10 collections detailed)
├── api-contracts.md              (30+ endpoints specified)
├── error-scenarios.md            (19 basic errors)
└── status.md                     (this file)
```

---

## Stage 5 Preview

**Next Stage:** Refine L2 → Refine L3 (Detailed Level)

**Objective:** Comprehensive coverage with edge cases

**Key Activities:**
1. Complete Progressive Deepening L2 sections for all 4 components
2. Apply Edge Case Discovery Framework systematically
3. Document error handling for all edge cases
4. Create failure mode analysis tables
5. Answer all 24 questions raised in L1
6. Specify component interactions in detail
7. Document alternatives considered
8. Identify risks with mitigations

**Frameworks to apply:**
- Progressive Deepening Template (L2)
- Edge Case Discovery Framework
- Design Red Flags Checklist (stricter)

**Estimated time:** 3-4 hours for L2 level documentation

---

## Success Metrics

**Stage 4 Goals Achieved:**
- ✅ Detailed system architecture with all services mapped
- ✅ Data flow sequences for critical paths
- ✅ Database schema fully specified
- ✅ API contracts documented with examples
- ✅ Basic error scenarios identified
- ✅ Progressive Deepening L1 for major components
- ✅ 24 design questions surfaced for L2 resolution

**Quality Indicators:**
- All L1 documents follow template structure
- "What, Why, Key Insight" clearly stated for each component
- Questions raised are substantive (not trivial)
- Database schema includes constraints and indexes
- API contracts include error cases
- Error scenarios include handling strategies

---

**Completed By:** Claude (Systematic Refinement)
**Date:** 2026-01-24
**Ready for Stage 5:** ✅ YES
