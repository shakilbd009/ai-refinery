# Requirements: Manik Golden Honey Co

Integrated e-commerce platform for online honey sales with admin management capabilities. Serves two user groups: customers purchasing products and administrators managing inventory, orders, and customer data.

---

## MVP Scope

**In Scope:**
- Single product category (honey products only)
- Customer storefront with cart and checkout
- Admin dashboard for product, order, and inventory management
- Passwordless customer auth, password-based admin auth
- Product reviews with moderation
- Percentage-based discount codes
- Order cancellation requests

**Out of Scope:**
- Multiple product categories
- Loyalty/points programs
- Advanced analytics dashboards
- Multi-language support
- Mobile native apps
- Subscription/recurring orders
- Wholesale/bulk ordering
- Customer service chat
- Automated marketing emails
- Social media integrations
- Review photo uploads

---

## Functional Requirements

### Customer Features

| ID | Feature | Priority |
|----|---------|----------|
| FR-1 | Product Browsing | Must Have |
| FR-2 | Shopping Cart | Must Have |
| FR-3 | Checkout & Payment | Must Have |
| FR-4 | Customer Authentication | Must Have |
| FR-5 | Order Tracking | Must Have |
| FR-6 | Order Cancellation Request | Must Have |
| FR-7 | Product Reviews & Ratings | Must Have |

**FR-1: Product Browsing**
- Product listing displays all active products
- Product detail page shows full information (name, description, price, images, quantities)
- Product images load via CDN caching
- Out-of-stock products visually indicated
- SEO-optimized pages (SSR with meta tags)

**FR-2: Shopping Cart**
- Add to cart from product pages
- Update quantities and remove items
- Cart persists across sessions (localStorage)
- Real-time price calculations
- Inventory validation before checkout

**FR-3: Checkout & Payment**
- Collect shipping address
- Stripe embedded payment form
- Inventory validation and reservation during checkout
- Order record created on successful payment
- Order confirmation email sent
- Graceful payment failure handling

**FR-4: Customer Authentication**
- Passwordless 6-digit email codes
- 10-minute code expiration
- JWT token on successful verification
- Returning customer recognition
- Rate-limited code requests

**FR-5: Order Tracking**
- Order history sorted by date (newest first)
- Order status display (pending, processing, shipped, delivered, cancelled)
- Order line items with quantities
- Shipping address and total paid
- Email notifications on status changes

**FR-6: Order Cancellation Request**
- Request button on order detail page
- Available only for pending/processing orders
- Optional cancellation reason
- Admin notification and email alert
- Order shows "cancellation requested" status during review
- Customer notified of approval/denial

**FR-7: Product Reviews & Ratings**
- Verified purchasers only (must have ordered product)
- 5-star rating + text (10-500 characters)
- Reviews go to moderation queue
- Product pages show average rating and approved reviews
- One review per customer per product (edit allowed)
- Customers can edit (re-moderates) or delete own reviews

### Admin Features

| ID | Feature | Priority |
|----|---------|----------|
| FR-8 | Admin Authentication | Must Have |
| FR-9 | Product Management | Must Have |
| FR-10 | Order Management | Must Have |
| FR-11 | Inventory Management | Must Have |
| FR-12 | Customer Management | Should Have |
| FR-13 | Review Moderation | Must Have |
| FR-14 | Order Cancellation Management | Must Have |
| FR-15 | Discount Code System | Must Have |

**FR-8: Admin Authentication**
- Email/password login with bcrypt hashing
- Admin JWT with role claim
- Protected `/admin/*` routes via middleware
- 8-hour session timeout

**FR-9: Product Management**
- Create products with images
- Edit product details (name, description, price)
- Upload/replace product images
- Mark products active/inactive
- Product list with search/filter

**FR-10: Order Management**
- View all orders with filters (status, date range)
- View order details (items, customer, payment)
- Update order status (processing -> shipped -> delivered)
- Email notifications on status updates
- Mark orders as fulfilled

**FR-11: Inventory Management**
- View current inventory per product
- Manual stock quantity updates
- Low-stock alerts (< 10 units)
- Automatic decrement on order creation
- Overselling prevention (checkout validation)

**FR-12: Customer Management**
- List customers with search
- View customer profile (email, order count, total spent)
- View customer order history
- Read-only access (no editing)

**FR-13: Review Moderation**
- Pending reviews queue
- Approve/reject reviews (with optional reason)
- View all reviews with status filters
- Delete approved reviews if needed
- Email notifications for new reviews

**FR-14: Order Cancellation Management**
- Pending cancellation requests queue
- View order details and cancellation reason
- Approve (triggers Stripe refund + inventory return)
- Deny with optional explanation
- Email notifications for new requests
- Cancellation history and statistics

**FR-15: Discount Code System**
- Create percentage-based codes
- Minimum order value requirement
- Expiration date and max redemptions limit
- One-time use per customer option
- Edit details (except code) and deactivate codes
- Usage statistics (redemptions, total discount)
- Customer applies code at checkout (pre-payment validation)
- Order records discount code and amount saved

---

## Non-Functional Requirements

### Performance

| Metric | Target |
|--------|--------|
| User interactions | < 200ms |
| API endpoints (p95) | < 500ms |
| Product image loads | < 1s (CDN) |
| Checkout flow per step | < 2s |
| Typical throughput | 10 req/s |
| Peak load capacity | 100 req/s |

**Scalability:** 500 customers at launch, 2,000 Year 1, 5,000 Year 2. ~100 orders/week initially.

### Security

- Customer auth: Passwordless 6-digit codes (10-min expiration)
- Admin auth: Email/password with bcrypt
- JWT tokens: 8-hour expiration, HttpOnly cookies
- Role-based access control (customer vs admin)
- Admin routes protected by middleware
- Audit logging for admin actions
- PII: Email, shipping address (TLS 1.3 in transit)
- Payment data: Stripe-hosted (PCI-compliant via Stripe)
- Data at rest: Firestore default encryption

### Reliability

| Metric | Target |
|--------|--------|
| Availability | 99.5% |
| Acceptable downtime | 1-2 hours/month |
| Backup frequency | Daily (Firestore automatic) |
| Backup retention | 7 days |
| RTO | 4 hours |
| RPO | 24 hours |

- Maintenance window: Sunday 2-4am EST
- DR strategy: Firestore multi-region replication, Cloud Run auto-restart
- Error tracking: Cloud Logging + Sentry
- Alerting: Email on 5xx errors > 10/min

### Usability

- Target customers: General consumers, age 25-65, basic web literacy
- Target admins: Business owner/staff, basic technical skills
- WCAG: Level AA target
- Keyboard navigation: Required for forms
- Languages: English only
- Regional formats: USD, US date format
- Desktop browsers: Chrome, Firefox, Safari, Edge (latest 2 versions)
- Mobile browsers: Safari iOS, Chrome Android (latest 2 versions)

### Maintainability

- Team: 1-2 developers (mid to senior)
- Tech stack: Next.js (TypeScript), Go, GCP (Cloud Run, Firestore, Cloud Storage)
- Documentation: OpenAPI spec, inline comments, README per service, runbooks
- Monitoring: Cloud Monitoring, Cloud Logging (structured JSON)
- Dashboards: Error rate, latency p95, active orders, inventory levels

---

## Constraints

**Budget:**
- Infrastructure: < $100/month (free tiers)
- Stripe: 2.9% + $0.30 per transaction
- Email: < $10/month

**Timeline:** 6-8 weeks MVP, phased rollout (soft launch then public)

**Technology:**
- Required: GCP, Stripe, Next.js, Go
- Excluded: AWS/Azure, traditional SQL, microservices
- Preferred: TypeScript, repository pattern, SSR

**Regulatory:** PCI DSS delegated to Stripe. Sales tax not handled (owner responsibility).

**Integrations:**
- Required: Stripe API, email service (SendGrid/Mailgun)
- Excluded: Third-party analytics (privacy-first)

---

## Success Metrics

| Category | Metric | Target |
|----------|--------|--------|
| User | Conversion rate | > 2% |
| User | Cart abandonment | < 70% |
| User | Repeat customer rate | > 20% (3 months) |
| Technical | API error rate | < 1% |
| Technical | P95 latency | < 500ms |
| Technical | Uptime | > 99.5% |
| Technical | Page load time | < 2s (Lighthouse > 80) |
| Business | Orders per week | > 10 (after month 1) |
| Business | Average order value | $30-50 |

---

## Dependencies

**External (Critical):**
- Stripe API: Payment processing
- Email service: Transactional emails
- GCP services: Infrastructure

**Internal:**
- Product images uploaded before sales
- Initial inventory seeded before launch

---

## Key Design Decisions

| Decision | Resolution |
|----------|------------|
| Concurrent order inventory | Pessimistic locking with 15-min reservation |
| Order cancellation | Customer request with admin approval |
| Review timing | Immediately after order placement |
| Discount code scope | Order-wide only (not product-specific) |
