# Security Threat Model

E-commerce platform handling customer PII, payment processing (Stripe), and business-critical data.

**Risk Profile:** Medium-High

---

## Critical Assets

| Asset | Sensitivity | Protection Priority |
|-------|-------------|---------------------|
| Stripe API keys & webhook secret | Critical | Highest |
| Admin credentials | Critical | Highest |
| Customer PII (email, addresses) | High | High |
| Order/transaction data | High | High |
| Business data (pricing, promo codes) | Medium | Medium |

---

## Attack Surface

### Public Endpoints (Highest Risk)

| Endpoint | Risk | Primary Threats |
|----------|------|-----------------|
| `POST /api/auth/verify-code` | CRITICAL | Brute force, code guessing |
| `POST /api/admin/login` | CRITICAL | Credential stuffing |
| `POST /webhooks/stripe` | CRITICAL | Spoofing, replay attacks |
| `POST /api/checkout/create-payment-intent` | HIGH | Payment manipulation |
| `POST /api/checkout/confirm-order` | HIGH | Order fraud, replay |
| `POST /api/auth/send-code` | HIGH | Enumeration, DoS, email bombing |

### Third-Party Integrations

| Integration | Risk | Primary Concern |
|-------------|------|-----------------|
| Stripe Webhooks (inbound) | CRITICAL | Signature bypass, spoofing |
| Stripe API (outbound) | HIGH | API key compromise |
| Email Service (outbound) | MEDIUM | API key compromise |
| Firestore | HIGH | Injection, misconfiguration |
| GCP Secret Manager | CRITICAL | IAM misconfiguration |

---

## Threat Actors & Priority Attacks

### P1 - Critical (Must Address Before Launch)

| Attack | Actor | Mitigation |
|--------|-------|------------|
| **Webhook Spoofing** | Any | Verify `stripe-signature` header; reject events >5min old; alert on ANY failure |
| **Admin Credential Stuffing** | Script Kiddie | Rate limit (5/email/hr, 20/IP/hr); lockout after 5 failures; implement TOTP 2FA |
| **Auth Code Brute Force** | Script Kiddie | 3 attempts/code; 3 codes/email/hr; 10-min expiry; IP rate limiting |
| **Customer Data Enumeration** | Fraudster | Authorization check per request; use UUIDs not sequential IDs |
| **Secret Exposure** | Any | GCP Secret Manager; no hardcoding; pre-commit hooks (gitleaks) |

### P2 - High (Address Within 30 Days)

| Attack | Actor | Mitigation |
|--------|-------|------------|
| **Discount Code Abuse** | Fraudster | Email normalization; IP/address tracking; max redemptions |
| **Inventory Locking DoS** | Competitor | 15-min TTL; max 2 active reservations/customer; 5/IP/hr |
| **Review Bombing** | Competitor | Purchase verification; moderation queue; rate limits |
| **Session Hijacking** | Any | HttpOnly + Secure + SameSite=Strict cookies; 48hr expiry |

---

## Required Rate Limits

| Endpoint | Per IP | Per User/Resource |
|----------|--------|-------------------|
| `/api/auth/send-code` | 10/min | 3/email/hour |
| `/api/auth/verify-code` | 10/min | 3 attempts/code |
| `/api/admin/login` | 20/hour | 5/email/hour |
| `/api/checkout/reserve-inventory` | 5/hour | 2 active |
| `/api/checkout/validate-promo-code` | 5/min | 20/user/hour |
| `/api/reviews` | 10/hour | 5/user/day |
| `/webhooks/stripe` | 100/min | - |
| General API | 100/min | 1000/hour |

---

## Required Security Headers

```
Content-Security-Policy: default-src 'self'; script-src 'self' https://js.stripe.com; frame-src https://js.stripe.com; style-src 'self' 'unsafe-inline'
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
```

---

## Authentication Requirements

| Requirement | Implementation |
|-------------|----------------|
| JWT validation on protected endpoints | Middleware |
| Role-based access (customer vs admin) | JWT role claim |
| Admin 2FA (TOTP) | Required before production |
| Session expiry | 48 hours via JWT exp |
| Token storage | HttpOnly cookies only |
| Cookie flags | Secure + SameSite=Strict |

---

## Webhook Security (Critical Path)

**Verification Process:**
1. Reject immediately if `stripe-signature` header missing
2. Verify signature using webhook secret
3. Reject events older than 5 minutes (replay prevention)
4. Log ALL requests; alert on ANY signature failure
5. Auto-block IP after 3 failed verifications (24hr)

**Order Fraud Prevention:**
- Query orders by `payment_intent_id` before creating (idempotency)
- Database-level unique constraint on `stripe_payment_intent_id`
- Verify payment status via Stripe API before order confirmation

---

## Input Validation Requirements

| Input | Validation |
|-------|------------|
| Email | RFC 5322 format; normalize (block +aliases) |
| Quantity | Integer 1-100 per item |
| Price/Amount | Server-calculated only; never trust client |
| Promo codes | Alphanumeric only; 6+ chars |
| Review text | Length limits; URL/phone detection; XSS escaping |

---

## Logging Requirements

**Must Log:**
- All auth attempts (success/failure)
- All admin actions with before/after state
- Order creation and status changes
- Payment events (no card data)
- Rate limit violations
- Security events (invalid signatures, unauthorized access)

**Never Log:**
- Passwords or hashes
- Card numbers
- JWT tokens
- API keys/secrets
- Full email addresses (mask: `j***@example.com`)

**Retention:**
- Security events: 1 year
- Audit logs: 2 years
- Application logs: 90 days

---

## Real-Time Alerts

| Alert | Condition | Severity |
|-------|-----------|----------|
| Invalid webhook signature | Any occurrence | CRITICAL |
| Failed admin login | Any occurrence | HIGH |
| Admin account locked | 5 failed attempts | HIGH |
| Bulk data access | >50 records/hour | HIGH |
| Order creation failure after payment | Any occurrence | CRITICAL |
| Sustained rate limiting | >10 violations/5min | MEDIUM |

---

## Incident Severity Levels

| Level | Response Time | Examples |
|-------|---------------|----------|
| P1 - Critical | 15 min | Webhook compromise, admin credential leak |
| P2 - High | 1 hour | Brute force attack, discount abuse |
| P3 - Medium | 4 hours | Review bombing, scraping |
| P4 - Low | 24 hours | Single failed login |

---

## Secrets Inventory

| Secret | Purpose | Rotation |
|--------|---------|----------|
| `STRIPE_SECRET_KEY` | Payment API | 90 days |
| `STRIPE_WEBHOOK_SECRET` | Webhook verification | 90 days |
| `JWT_SECRET` | Token signing | 90 days |
| `EMAIL_API_KEY` | Email service | 90 days |
| `FIRESTORE_SERVICE_ACCOUNT` | Database access | As needed |

All secrets stored in GCP Secret Manager. Different secrets per environment.

---

## Pre-Launch Checklist

- [ ] All rate limits implemented per specification
- [ ] Webhook signature verification configured and tested
- [ ] Security alerts configured in Cloud Monitoring
- [ ] All authorization checks reviewed and tested
- [ ] Security headers configured
- [ ] Input validation on all endpoints
- [ ] OWASP ZAP scan completed
- [ ] Dependency vulnerability scan clean

## Post-Launch (30 Days)

- [ ] Admin 2FA (TOTP) implemented
- [ ] Automated dependency scanning in CI/CD
- [ ] Internal penetration test completed
- [ ] Security runbooks documented

---

## PCI DSS Compliance

**Status:** Not directly applicable (Stripe handles card data)

**Responsibilities:**
- Never store/process/transmit card data
- Use Stripe Elements for payment forms
- Verify webhook signatures
- Secure Stripe API keys

---

## Data Privacy

**Customer Data Collected:** Email, name, shipping address, order history, reviews

**Retention:**
- Active accounts: Retained while active
- Inactive (2 years): Anonymize
- Order data: 7 years (legal requirement)
- Deleted accounts: Anonymize within 30 days
