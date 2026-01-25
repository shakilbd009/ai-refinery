# Detailed System Architecture - Stage 4

**Project:** Manik Golden Honey Co
**Stage:** 4 - Refine L1 (Detailed Design)
**Date:** 2026-01-24

---

## High-Level System Architecture

```mermaid
graph TB
    subgraph "Client Layer"
        CustomerBrowser[Customer Browser]
        AdminBrowser[Admin Browser]
    end

    subgraph "Application Layer - GCP Cloud Run"
        NextJS[Next.js App<br/>Customer + Admin UI]
        GoAPI[Go Backend API<br/>Business Logic]
        CleanupService[Cleanup Service<br/>Background Jobs]
    end

    subgraph "Data Layer - GCP"
        Firestore[(Firestore Database)]
        CloudStorage[Cloud Storage<br/>Product Images]
        SecretManager[Secret Manager<br/>Credentials]
    end

    subgraph "External Services"
        Stripe[Stripe Payments API]
        Mailgun[Mailgun Email API]
    end

    subgraph "Infrastructure"
        CloudScheduler[Cloud Scheduler<br/>Cron Jobs]
    end

    CustomerBrowser -->|HTTPS| NextJS
    AdminBrowser -->|HTTPS| NextJS
    NextJS -->|HTTP/JSON| GoAPI
    GoAPI -->|Firestore SDK| Firestore
    GoAPI -->|REST API| Stripe
    GoAPI -->|REST API| Mailgun
    GoAPI -->|Upload/Retrieve| CloudStorage
    GoAPI -->|Read Secrets| SecretManager

    CloudScheduler -->|HTTP POST| CleanupService
    CleanupService -->|Firestore SDK| Firestore

    style NextJS fill:#4CAF50
    style GoAPI fill:#2196F3
    style CleanupService fill:#FF9800
    style Firestore fill:#FFC107
```

---

## Component Responsibilities

### Next.js Application (Frontend)
**Port:** 3000 (internal), 443 (external HTTPS)
**Deployment:** Cloud Run (auto-scaling, min 0 instances)

**Responsibilities:**
- Render customer storefront (SSR for SEO)
- Render admin dashboard (CSR for interactive UI)
- Client-side validation (forms, cart)
- Route protection (middleware for admin routes)
- State management (cart in localStorage, admin session in memory)

**Routes:**
- **Customer:**
  - `/` - Homepage (static)
  - `/products` - Product listing (SSR)
  - `/products/[id]` - Product detail (SSR)
  - `/cart` - Shopping cart (CSR)
  - `/checkout` - Checkout flow (CSR)
  - `/account` - Customer dashboard (CSR, protected)
  - `/auth/verify` - Email code verification (CSR)
- **Admin:**
  - `/admin/login` - Admin login (CSR)
  - `/admin/dashboard` - Metrics overview (CSR, protected)
  - `/admin/products` - Product CRUD (CSR, protected)
  - `/admin/orders` - Order management (CSR, protected)
  - `/admin/reviews` - Review moderation (CSR, protected)
  - `/admin/cancellations` - Cancellation requests (CSR, protected)
  - `/admin/promo-codes` - Discount codes (CSR, protected)
  - `/admin/customers` - Customer list (CSR, protected)
  - `/admin/inventory` - Inventory dashboard (CSR, protected)

---

### Go Backend API
**Port:** 8080 (internal), 443 (external HTTPS)
**Deployment:** Cloud Run (auto-scaling, min 1 instance)

**Responsibilities:**
- All business logic and data operations
- Authentication (customer passwordless, admin email/password)
- Authorization (role-based access control)
- Payment processing (Stripe integration)
- Email notifications (Mailgun integration)
- Inventory management (reservations, updates)
- Review moderation logic
- Cancellation workflow

**API Structure:**
```
/api/health                     - Health check
/api/auth/
  POST   /send-code             - Send verification code (customer)
  POST   /verify-code           - Verify code, return JWT (customer)
  POST   /admin/login           - Admin login
  POST   /admin/logout          - Admin logout

/api/products/
  GET    /                      - List all active products
  GET    /:id                   - Get product detail
  POST   /                      - Create product (admin only)
  PUT    /:id                   - Update product (admin only)
  DELETE /:id                   - Delete product (admin only)

/api/orders/
  GET    /                      - List customer orders (customer or admin)
  GET    /:id                   - Get order detail
  POST   /                      - Create order (after payment)
  PUT    /:id/status            - Update order status (admin only)

/api/checkout/
  POST   /reserve-inventory     - Reserve inventory for checkout
  POST   /release-inventory     - Release reservation (abandoned checkout)
  POST   /validate-promo-code   - Validate discount code
  POST   /create-payment-intent - Create Stripe PaymentIntent
  POST   /confirm-order         - Confirm order after payment

/api/reviews/
  GET    /product/:id           - Get approved reviews for product
  POST   /                      - Submit review (verified purchaser)
  PUT    /:id                   - Edit review (author only)
  DELETE /:id                   - Delete review (author only)

/api/admin/reviews/
  GET    /pending               - List pending reviews
  PUT    /:id/approve           - Approve review
  PUT    /:id/reject            - Reject review
  DELETE /:id                   - Delete approved review

/api/cancellations/
  POST   /                      - Request order cancellation (customer)

/api/admin/cancellations/
  GET    /pending               - List pending cancellation requests
  PUT    /:id/approve           - Approve cancellation (triggers refund)
  PUT    /:id/deny              - Deny cancellation

/api/admin/promo-codes/
  GET    /                      - List all promo codes
  POST   /                      - Create promo code
  PUT    /:id                   - Update promo code
  DELETE /:id                   - Delete promo code (soft delete)
  PUT    /:id/deactivate        - Deactivate promo code

/api/admin/notification-counts  - Get pending counts (reviews, cancellations, etc.)
```

---

### Cleanup Service (Background Jobs)
**Port:** 8080 (internal), no external access
**Deployment:** Cloud Run (triggered by Cloud Scheduler)

**Responsibilities:**
- Release expired inventory reservations (every 5 min)
- Clean up old session data (future)
- Send email digests (future)

**Endpoints:**
```
POST /jobs/cleanup-reservations  - Clean expired inventory reservations
```

**Authentication:** Service account token (Cloud Scheduler)

---

## Data Flow Diagrams

### 1. Customer Checkout Flow

```mermaid
sequenceDiagram
    participant Customer
    participant NextJS
    participant GoAPI
    participant Firestore
    participant Stripe

    Customer->>NextJS: Click "Checkout"
    NextJS->>GoAPI: POST /checkout/reserve-inventory
    GoAPI->>Firestore: Check available_qty - reserved_qty
    alt Inventory available
        GoAPI->>Firestore: Create reservation (15-min expiry)
        GoAPI->>Firestore: Increment reserved_quantity
        GoAPI-->>NextJS: 200 OK (reservation_id, expires_at)
        NextJS-->>Customer: Show checkout form
    else Insufficient inventory
        GoAPI-->>NextJS: 400 Insufficient Inventory
        NextJS-->>Customer: "Out of stock"
    end

    Customer->>NextJS: Enter shipping + apply promo code
    NextJS->>GoAPI: POST /checkout/validate-promo-code
    GoAPI->>Firestore: Check promo code validity
    GoAPI-->>NextJS: Discount amount

    Customer->>NextJS: Submit payment
    NextJS->>GoAPI: POST /checkout/create-payment-intent
    GoAPI->>Stripe: Create PaymentIntent
    Stripe-->>GoAPI: client_secret
    GoAPI-->>NextJS: client_secret

    NextJS->>Stripe: Confirm payment (Stripe.js)
    Stripe-->>NextJS: Payment success
    NextJS->>GoAPI: POST /checkout/confirm-order
    GoAPI->>Firestore: Create order
    GoAPI->>Firestore: Decrement quantity
    GoAPI->>Firestore: Decrement reserved_quantity
    GoAPI->>Firestore: Delete reservation
    GoAPI->>Mailgun: Send confirmation email
    GoAPI-->>NextJS: 201 Created (order_id)
    NextJS-->>Customer: Order confirmation page
```

---

### 2. Review Moderation Flow

```mermaid
sequenceDiagram
    participant Customer
    participant NextJS
    participant GoAPI
    participant Firestore
    participant Mailgun
    participant Admin

    Customer->>NextJS: Submit review (from order page)
    NextJS->>GoAPI: POST /reviews
    GoAPI->>Firestore: Verify customer purchased product
    alt Verified purchaser
        GoAPI->>Firestore: Create review (status: pending)
        GoAPI->>Mailgun: Notify admin (new review)
        GoAPI-->>NextJS: 201 Created
        NextJS-->>Customer: "Review submitted for moderation"
    else Not verified
        GoAPI-->>NextJS: 403 Forbidden
    end

    Admin->>NextJS: Check /admin/reviews (sees badge: 1 pending)
    NextJS->>GoAPI: GET /admin/reviews/pending
    GoAPI->>Firestore: Query reviews WHERE status=pending
    GoAPI-->>NextJS: List of pending reviews
    NextJS-->>Admin: Display review queue

    Admin->>NextJS: Click "Approve"
    NextJS->>GoAPI: PUT /admin/reviews/:id/approve
    GoAPI->>Firestore: Update review status=approved
    GoAPI-->>NextJS: 200 OK
    NextJS-->>Admin: "Review approved"

    Note over Customer,Admin: Review now visible on product page
```

---

### 3. Cancellation Request Flow

```mermaid
sequenceDiagram
    participant Customer
    participant NextJS
    participant GoAPI
    participant Firestore
    participant Mailgun
    participant Admin
    participant Stripe

    Customer->>NextJS: Click "Request Cancellation"
    NextJS->>GoAPI: POST /cancellations
    GoAPI->>Firestore: Check order status (pending or processing)
    alt Eligible for cancellation
        GoAPI->>Firestore: Create cancellation_request (status: pending)
        GoAPI->>Firestore: Update order.cancellation_status=requested
        GoAPI->>Mailgun: Notify admin (new cancellation request)
        GoAPI-->>NextJS: 201 Created
        NextJS-->>Customer: "Request submitted, review within 24h"
    else Order already shipped
        GoAPI-->>NextJS: 400 Cannot cancel shipped order
    end

    Admin->>NextJS: Check dashboard (badge: 1 cancellation)
    NextJS->>GoAPI: GET /admin/cancellations/pending
    GoAPI->>Firestore: Query cancellation_requests WHERE status=pending
    GoAPI-->>NextJS: List of pending requests
    NextJS-->>Admin: Display cancellation queue

    alt Admin approves
        Admin->>NextJS: Click "Approve"
        NextJS->>GoAPI: PUT /admin/cancellations/:id/approve
        GoAPI->>Stripe: Create refund
        Stripe-->>GoAPI: Refund success
        GoAPI->>Firestore: Update order.status=cancelled
        GoAPI->>Firestore: Return inventory (increment quantity)
        GoAPI->>Firestore: Update cancellation_request.status=approved
        GoAPI->>Mailgun: Notify customer (cancellation approved)
        GoAPI-->>NextJS: 200 OK
        NextJS-->>Admin: "Cancellation approved, refund initiated"
    else Admin denies
        Admin->>NextJS: Click "Deny" + reason
        NextJS->>GoAPI: PUT /admin/cancellations/:id/deny
        GoAPI->>Firestore: Update cancellation_request.status=denied
        GoAPI->>Mailgun: Notify customer (denial + reason)
        GoAPI-->>NextJS: 200 OK
        NextJS-->>Admin: "Request denied"
    end
```

---

### 4. Background Reservation Cleanup

```mermaid
sequenceDiagram
    participant CloudScheduler
    participant CleanupService
    participant Firestore

    Note over CloudScheduler: Every 5 minutes

    CloudScheduler->>CleanupService: POST /jobs/cleanup-reservations
    CleanupService->>Firestore: Query reservations WHERE expires_at < NOW()
    Firestore-->>CleanupService: List of expired reservations

    loop For each expired reservation
        CleanupService->>Firestore: Get product
        CleanupService->>Firestore: Decrement product.reserved_quantity
        CleanupService->>Firestore: Delete reservation
        Note over CleanupService: Log: "Released reservation for product X"
    end

    CleanupService-->>CloudScheduler: 200 OK (released: N)
```

---

## Technology Stack Details

### Frontend (Next.js)
- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript
- **UI Library**: React 18
- **Styling**: Tailwind CSS
- **Forms**: React Hook Form + Zod validation
- **HTTP Client**: Fetch API (native)
- **State**: React Context + localStorage (cart)
- **Auth**: JWT in httpOnly cookies

### Backend (Go API)
- **Language**: Go 1.21+
- **Framework**: net/http (stdlib) + Chi router
- **Database**: Firestore Go SDK
- **Payments**: Stripe Go SDK
- **Email**: Mailgun Go SDK
- **Auth**: golang-jwt/jwt
- **Logging**: Cloud Logging (structured JSON)
- **Testing**: Go testing package + testify

### Infrastructure (GCP)
- **Compute**: Cloud Run (managed containers)
- **Database**: Firestore (native mode)
- **Storage**: Cloud Storage (public bucket with CDN)
- **Secrets**: Secret Manager
- **Scheduling**: Cloud Scheduler
- **Monitoring**: Cloud Monitoring + Cloud Logging
- **CI/CD**: Cloud Build

---

## Next Steps

Stage 4 will continue with:
1. ✅ Detailed architecture diagrams (completed above)
2. Progressive Deepening L1 for major components (next)
3. Database schema detailed specification
4. API contract specifications
5. Basic error scenarios

---

**Last Updated:** 2026-01-24
**Stage:** L1 (Refine L1)
