# Manik Golden Honey Co - Project Overview

**Date:** 2026-01-24
**Status:** Stage 1 - Initial Design

---

## Project Summary

Integrated e-commerce + management platform for honey business.

**Core Purpose:** Enable online sales of honey products with integrated admin management for inventory, orders, and customers.

---

## Technology Stack

**Frontend:**
- Next.js (customer storefront + admin dashboard)
- React for interactive components
- Server-side rendering for SEO

**Backend:**
- Go API (RESTful)
- Handles all business logic
- Single source of truth for data

**Database:**
- Firestore (NoSQL)
- Cloud-native, auto-scaling

**Infrastructure:**
- GCP Cloud Run (auto-scaling containers)
- Cloud Storage (product images)
- Secret Manager (credentials)

**Third-Party Services:**
- Stripe (payment processing)
- SendGrid/Mailgun (transactional emails)

---

## MVP Scope

**In Scope:**
- Honey products only (single product category)
- Customer users (passwordless authentication)
- Admin users (product/order/inventory management)
- Essential e-commerce features (cart, checkout, order tracking)
- Payment processing via Stripe
- Order notifications via email

**Out of Scope (Future):**
- Multiple product categories
- Advanced analytics/reporting
- Customer reviews/ratings
- Loyalty programs
- Multi-language support
- Mobile apps (web-only for MVP)

---

## Key Design Decisions

**Unified Next.js App:** Single application serves both customer and admin interfaces (simpler deployment, shared components)

**Passwordless Auth:** 6-digit email codes (no passwords to manage, better UX, secure)

**Repository Pattern:** Database abstraction layer enables future migration from Firestore to Postgres without business logic changes

**Serverless Architecture:** Cloud Run auto-scaling keeps costs low during quiet periods, scales automatically for traffic spikes

---

## Related Documents

- [architecture.md](./architecture.md) - System architecture and component design
- [data-model.md](./data-model.md) - Database schema and indexes
- [customer-flows.md](./customer-flows.md) - Customer user journeys
- [admin-features.md](./admin-features.md) - Admin management features
- [error-handling.md](./error-handling.md) - Error handling and critical flows
- [repository-pattern.md](./repository-pattern.md) - Database abstraction layer
- [testing.md](./testing.md) - Testing strategy
- [deployment-security.md](./deployment-security.md) - Deployment and security
