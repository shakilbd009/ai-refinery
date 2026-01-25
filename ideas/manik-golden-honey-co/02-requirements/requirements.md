# Requirements: Manik Golden Honey Co

## Overview

Integrated e-commerce + management platform enabling online honey sales with admin management capabilities. The system serves two distinct user groups: customers purchasing honey products and administrators managing inventory, orders, and customer data. This MVP focuses on essential e-commerce functionality with a single product category (honey).

---

## Functional Requirements

### Core Capabilities

1. **Product Browsing**
   - Description: Customers can view honey products with details (name, description, price, images, available quantities)
   - Acceptance Criteria:
     - [ ] Product listing page displays all active products
     - [ ] Product detail page shows full product information
     - [ ] Product images load efficiently with CDN caching
     - [ ] Out-of-stock products are visually indicated
     - [ ] Product pages are SEO-optimized (SSR with meta tags)
   - Priority: Must Have

2. **Shopping Cart**
   - Description: Customers can add products to cart, adjust quantities, and view cart total
   - Acceptance Criteria:
     - [ ] Add to cart from product pages
     - [ ] Update quantities in cart view
     - [ ] Remove items from cart
     - [ ] Cart persists across sessions (localStorage)
     - [ ] Cart shows real-time price calculations
     - [ ] Cart validates inventory availability before checkout
   - Priority: Must Have

3. **Checkout & Payment**
   - Description: Customers can complete purchases using credit/debit cards via Stripe
   - Acceptance Criteria:
     - [ ] Collect shipping address
     - [ ] Integrate Stripe payment form (embedded)
     - [ ] Validate inventory availability at checkout
     - [ ] Reserve inventory during payment processing
     - [ ] Create order record on successful payment
     - [ ] Send order confirmation email
     - [ ] Handle payment failures gracefully
   - Priority: Must Have

4. **Customer Authentication**
   - Description: Passwordless authentication using 6-digit email codes
   - Acceptance Criteria:
     - [ ] Send verification code to customer email
     - [ ] Validate code within 10-minute expiration window
     - [ ] Generate JWT token on successful verification
     - [ ] Support returning customers (recognize email)
     - [ ] Rate limit code requests (prevent abuse)
   - Priority: Must Have

5. **Order Tracking**
   - Description: Customers can view order history and status
   - Acceptance Criteria:
     - [ ] Display orders sorted by date (newest first)
     - [ ] Show order status (pending, processing, shipped, delivered, cancelled)
     - [ ] Display order line items with quantities
     - [ ] Show shipping address and total paid
     - [ ] Email notifications on status changes
   - Priority: Must Have

5a. **Order Cancellation Request**
   - Description: Customers can request order cancellation (admin approval required)
   - Acceptance Criteria:
     - [ ] "Request Cancellation" button visible on order detail page
     - [ ] Only available if order status is "pending" or "processing" (not shipped/delivered)
     - [ ] Customer can provide optional cancellation reason
     - [ ] Request creates notification for admin
     - [ ] Admin receives email alert for cancellation request
     - [ ] Order status shows "cancellation requested" during review
     - [ ] Admin can approve (triggers refund + inventory return) or deny request
     - [ ] Customer receives email notification of approval/denial
   - Priority: Must Have

6. **Product Reviews & Ratings**
   - Description: Verified purchasers can leave star ratings (1-5) and written reviews for products they've ordered
   - Acceptance Criteria:
     - [ ] Only verified purchasers can submit reviews (must have ordered the product)
     - [ ] Review form includes 5-star rating + text field (min 10 chars, max 500 chars)
     - [ ] Reviews go to moderation queue (not visible until admin approves)
     - [ ] Product pages display average rating + review count
     - [ ] Product pages show approved reviews sorted by date (newest first)
     - [ ] Customers can edit their own reviews (goes back to moderation)
     - [ ] Customers can delete their own reviews
     - [ ] One review per customer per product (can edit, not duplicate)
   - Priority: Must Have

7. **Admin Authentication**
   - Description: Admin login with email/password
   - Acceptance Criteria:
     - [ ] Email/password login form
     - [ ] Generate admin JWT with role claim
     - [ ] Protect all `/admin/*` routes with middleware
     - [ ] Session timeout after 8 hours
   - Priority: Must Have

8. **Product Management (Admin)**
   - Description: Admins can CRUD honey products
   - Acceptance Criteria:
     - [ ] Create new products with images
     - [ ] Edit product details (name, description, price)
     - [ ] Upload/replace product images
     - [ ] Mark products as active/inactive
     - [ ] View product list with search/filter
   - Priority: Must Have

9. **Order Management (Admin)**
   - Description: Admins can view and update order status
   - Acceptance Criteria:
     - [ ] View all orders with filters (status, date range)
     - [ ] View order details (items, customer, payment info)
     - [ ] Update order status (processing → shipped → delivered)
     - [ ] Send email notifications on status update
     - [ ] Mark orders as fulfilled
   - Priority: Must Have

10. **Inventory Management (Admin)**
   - Description: Admins can track and update inventory levels
   - Acceptance Criteria:
     - [ ] View current inventory per product
     - [ ] Update stock quantities manually
     - [ ] View low-stock alerts (< 10 units)
     - [ ] Inventory automatically decrements on order creation
     - [ ] Prevent overselling (inventory validation at checkout)
   - Priority: Must Have

11. **Customer Management (Admin)**
    - Description: Admins can view customer data and order history
    - Acceptance Criteria:
      - [ ] List all customers with search
      - [ ] View customer profile (email, order count, total spent)
      - [ ] View customer order history
      - [ ] Read-only access (no customer data editing in MVP)
    - Priority: Should Have

12. **Review Moderation (Admin)**
    - Description: Admins can moderate customer reviews before they appear publicly
    - Acceptance Criteria:
      - [ ] View pending reviews queue (awaiting approval)
      - [ ] Approve reviews (makes them visible on product pages)
      - [ ] Reject reviews with optional reason note
      - [ ] View all reviews (approved, pending, rejected) with filters
      - [ ] Delete approved reviews if needed (inappropriate content)
      - [ ] Email notifications for new reviews awaiting moderation
    - Priority: Must Have

12a. **Order Cancellation Management (Admin)**
    - Description: Admins can review and approve/deny customer cancellation requests
    - Acceptance Criteria:
      - [ ] View pending cancellation requests queue
      - [ ] View order details + customer's cancellation reason
      - [ ] Approve cancellation (triggers Stripe refund + returns inventory)
      - [ ] Deny cancellation with optional explanation
      - [ ] Email notifications for new cancellation requests
      - [ ] Track cancellation history per order
      - [ ] View cancellation statistics (total cancellations, refund amounts)
    - Priority: Must Have

13. **Discount Code System**
    - Description: Admins can create percentage-based discount codes that customers apply at checkout
    - Acceptance Criteria:
      - [ ] Admin can create discount codes with percentage off (e.g., 10% off)
      - [ ] Set minimum order value requirement (e.g., $25 minimum)
      - [ ] Set expiration date for code
      - [ ] Set maximum redemptions limit (e.g., first 100 customers)
      - [ ] Mark code as one-time use per customer
      - [ ] Admin can edit code details (except code itself once created)
      - [ ] Admin can deactivate codes mid-campaign
      - [ ] Admin can view usage statistics (redemptions count, total discount given)
      - [ ] Customer enters code at checkout (validates before payment)
      - [ ] Discount applied to order total (before tax/shipping if applicable)
      - [ ] Order record shows discount code used and amount saved
    - Priority: Must Have

---

## Non-Functional Requirements

### Performance

**Response Time:**
- User interactions: < 200ms (page navigation, cart updates)
- API endpoints: < 500ms (p95)
- Product image loads: < 1s (with CDN)
- Checkout flow: < 2s per step

**Throughput:**
- Expected requests/second: 10 (typical)
- Peak load capacity: 100 req/s (holiday sales)

**Scalability:**
- Target users at launch: 500 customers
- Growth projection (Year 1): 2,000 customers
- Growth projection (Year 2): 5,000 customers
- Data growth expectations: ~100 orders/week initially

---

### Security

**Authentication:**
- [ ] Customer: Passwordless 6-digit email codes (10-min expiration)
- [ ] Admin: Email/password with bcrypt hashing
- [ ] JWT tokens with 8-hour expiration
- [ ] HttpOnly cookies for token storage

**Authorization:**
- [ ] Role-based access control (customer vs admin)
- [ ] Admin routes protected by middleware
- [ ] API endpoints validate JWT and role claims
- [ ] Audit logging for admin actions (order updates, product changes)

**Data Sensitivity:**
- PII handled: Yes (email, shipping address)
- Payment data: Yes (Stripe-hosted, PCI-compliant via Stripe)
- Encryption at rest: Not required (Firestore encrypts by default)
- Encryption in transit: TLS 1.3

**Compliance:**
- GDPR: Not applicable (no EU customers initially)
- HIPAA: Not applicable
- SOC 2: Not applicable
- PCI DSS: Stripe handles compliance (payment data never touches our servers)

---

### Reliability

**Uptime:**
- Target availability: 99.5% (MVP)
- Acceptable downtime: 1-2 hours/month for maintenance
- Maintenance windows: Sunday 2-4am EST (minimal traffic)

**Data Durability:**
- Backup frequency: Firestore automatic backups (daily)
- Backup retention: 7 days
- Point-in-time recovery: Yes (Firestore supports PITR)

**Disaster Recovery:**
- Recovery Time Objective (RTO): 4 hours
- Recovery Point Objective (RPO): 24 hours
- DR strategy: Firestore multi-region replication, Cloud Run auto-restart

**Error Handling:**
- User-facing error messages: Friendly (e.g., "Oops! Something went wrong. Please try again.")
- Error tracking: Cloud Logging + Sentry (optional)
- Alerting: Email alerts on 5xx errors > 10/min

---

### Usability

**Target Users:**
- Primary persona (Customer): General consumers, age 25-65, basic web literacy
- Primary persona (Admin): Business owner or staff, basic technical skills
- Technical expertise: Beginner to intermediate
- Domain knowledge: None required (intuitive e-commerce flow)

**Accessibility:**
- WCAG compliance: Level AA (target for MVP)
- Screen reader support: Nice to have (not required for MVP)
- Keyboard navigation: Required (tab navigation for forms)

**Localization:**
- Languages supported: English only (MVP)
- Regional formats: USD currency, US date format
- RTL support: Not required

**Device Support:**
- Desktop browsers: Chrome, Firefox, Safari, Edge (latest 2 versions)
- Mobile browsers: Safari iOS, Chrome Android (latest 2 versions)
- Native apps: Neither (web-responsive only)

---

### Maintainability

**Team:**
- Team size: 1-2 developers
- Skill level: Mid to Senior
- Technology familiarity: React/Next.js, Go, GCP

**Technology Constraints:**
- Must use: GCP (Cloud Run, Firestore, Cloud Storage), Stripe for payments
- Must avoid: AWS services (no multi-cloud for MVP)
- Preferred: TypeScript for Next.js, Go stdlib over heavy frameworks

**Documentation:**
- API documentation: OpenAPI/Swagger spec
- Code documentation: Inline comments for complex logic, README per service
- Runbooks: Required (deployment, rollback, common issues)

**Monitoring:**
- Application monitoring: Cloud Monitoring (request latency, error rates)
- Infrastructure monitoring: Cloud Run metrics (CPU, memory, instance count)
- Log aggregation: Cloud Logging (structured JSON logs)
- Dashboards: Error rate, latency p95, active orders, inventory levels

---

## Constraints

### Budget
- Infrastructure cost: < $100/month for MVP (Cloud Run free tier + Firestore free tier)
- Stripe fees: 2.9% + $0.30 per transaction (industry standard)
- Email service: < $10/month (SendGrid free tier or Mailgun)

### Timeline
- MVP launch: 6-8 weeks (no hard deadline)
- Phased rollout: Soft launch to friends/family, then public

### Technology
**Required:**
- GCP (Cloud Run, Firestore, Cloud Storage, Secret Manager)
- Stripe (payment processing)
- Next.js (frontend framework)
- Go (backend API)

**Excluded:**
- AWS, Azure (avoid multi-cloud complexity)
- Traditional SQL databases for MVP (Firestore simplicity preferred)
- Microservices (monolithic API for MVP)

**Preferred:**
- TypeScript (type safety)
- Repository pattern (database abstraction)
- Server-side rendering for SEO

### Regulatory
- PCI DSS: Delegated to Stripe (Stripe Checkout/Elements)
- Sales tax: Not handled by MVP (owner responsible for tax collection)

### Integration
**Must integrate with:**
- Stripe API: Payment processing and webhook handling
- Email service (SendGrid/Mailgun): Transactional emails (order confirmations, status updates)

**Cannot integrate with:**
- Third-party analytics (e.g., Google Analytics): Privacy-first approach for MVP

---

## Out of Scope

Explicitly list what we're NOT doing to avoid scope creep:

- Multiple product categories (only honey for MVP)
- Loyalty programs with points system (discount codes are IN scope, but not points/tiers)
- Advanced analytics/reporting dashboards
- Multi-language support
- Mobile native apps
- Subscription/recurring orders
- Wholesale/bulk ordering features
- Customer service chat or ticketing
- Automated marketing emails (newsletters, abandoned cart)
- Social media integrations
- Review photo uploads (text reviews only)

---

## Success Metrics

**How we'll measure success:**

**User Metrics:**
- Conversion rate: > 2% (visitors → orders)
- Cart abandonment: < 70%
- Repeat customer rate: > 20% (within 3 months)

**Technical Metrics:**
- API error rate: < 1%
- P95 latency: < 500ms
- Uptime: > 99.5%
- Page load time: < 2s (Lighthouse score > 80)

**Business Metrics:**
- Orders per week: > 10 (after first month)
- Average order value: $30-50
- Customer acquisition cost: Organic only (no paid ads for MVP)

---

## Dependencies

**External Dependencies:**
- Stripe API: Critical (no payment processing without it)
- Email service (SendGrid/Mailgun): High priority (order confirmations required)
- GCP services: Critical (entire infrastructure)

**Internal Dependencies:**
- Product images: Admin must upload before products can be sold
- Initial inventory data: Admin must seed inventory before launch

**Database Schema Implications (New Features):**
- `reviews` collection: product_id, customer_id, order_id, rating (1-5), review_text, status (pending/approved/rejected), created_at, updated_at
- `promo_codes` collection: code, discount_percentage, min_order_value, expiration_date, max_redemptions, used_count, active (boolean)
- `promo_code_usage` collection: code_id, customer_id, order_id, used_at (for one-time-per-customer enforcement)
- `inventory_reservations` collection: product_id, quantity, reserved_at, expires_at, session_id (for pessimistic locking)
- `cancellation_requests` collection: order_id, customer_id, reason, status (pending/approved/denied), requested_at, resolved_at
- **Products schema update**: Add `reserved_quantity` field (int, default 0) for inventory locking
- **Orders schema update**: Add `cancellation_status` enum (none/requested/approved/denied)
- Index requirements: reviews by product_id + status, promo_codes by code (unique), usage by code_id + customer_id, reservations by expires_at (for cleanup job), cancellation_requests by status

---

## Assumptions

List critical assumptions that, if proven false, would significantly impact the project:

1. **Firestore performance is sufficient** - Validation plan: Load testing with 100 concurrent users, 1000 products
2. **Customers will tolerate passwordless auth** - Validation plan: User testing with 10 customers during beta
3. **Single product category is enough for MVP** - Validation plan: Interview 5 potential customers about product variety expectations
4. **Cloud Run cold starts are acceptable** - Validation plan: Monitor cold start latency (< 2s acceptable)
5. **Email deliverability is reliable** - Validation plan: Monitor bounce rates, ensure SPF/DKIM configured
6. **No need for real-time inventory updates** - Validation plan: Confirm with admin that daily inventory checks are sufficient
7. **Stripe hosted forms are acceptable UX** - Validation plan: User testing of checkout flow
8. **Admin can handle review moderation workload manually** - Validation plan: Estimate reviews per week (10 orders/week × 30% review rate = 3 reviews/week, manageable)
9. **Percentage-based discounts are sufficient** - Validation plan: Confirm with admin that fixed-amount discounts ($5 off) are not needed for MVP
10. **15-minute reservation window is sufficient for checkout** - Validation plan: Monitor checkout completion times (expect < 5 min typically)
11. **Admin can manually approve cancellation requests within 24 hours** - Validation plan: Estimate cancellation rate (< 5% of orders, ~0.5 requests/week, manageable)
12. **Customers will leave authentic reviews immediately after ordering** - Validation plan: Monitor review quality during beta (⚠️ **RISK:** Reviews before product received may be inauthentic, **MITIGATION:** Admin moderation can reject premature reviews)

---

## Open Questions

Questions that need answering before finalizing design:

1. **Should customers be able to edit shipping address after order placement?** - Owner: Product - Due: Before Stage 3
2. ~~**What happens if inventory goes negative due to concurrent orders?**~~ - **RESOLVED:** Pessimistic locking (Option A) - inventory reserved during checkout, released after 15min if abandoned
3. ~~**Do we need order cancellation for customers?**~~ - **RESOLVED:** Cancellation request with admin approval (Option C)
4. **Should admin be able to create multiple admin users?** - Owner: Product - Due: Before Stage 4
5. **What email templates do we need?** - Owner: Product - Due: Stage 4 (list: order confirmation, status update, password reset, review moderation alert, cancellation request alert)
6. **How should admin be notified of reviews awaiting moderation?** - Owner: Product - Due: Stage 3 (email immediately? Daily digest? Dashboard badge?)
7. ~~**Can customers leave reviews before order is marked "delivered"?**~~ - **RESOLVED:** Immediately after order placement (Option A) - ⚠️ **Risk flagged:** Reviews before product received
8. **Should discount codes stack with other promotions?** - Owner: Product - Due: Stage 3 (N/A for MVP if only one promo at a time)
9. ~~**Can discount codes apply to specific products or order-wide only?**~~ - **RESOLVED:** Order-wide only (Option A) - simplest for MVP
10. **What happens if customer edits review multiple times?** - Owner: Product - Due: Stage 3 (limit edits? Always re-moderate?)

---

**Version:** 1.0
**Date:** 2026-01-24
**Author(s):** Claude
**Reviewed By:** [Pending]
**Next Review:** After Stage 2 validation
