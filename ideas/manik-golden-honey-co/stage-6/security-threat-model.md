# Security Threat Model: Manik Golden Honey Co

**Document Type:** Security Architecture
**Stage:** 6 - Final Refinement
**Date:** 2026-01-25
**Classification:** Internal Use Only

---

## Executive Summary

This threat model provides comprehensive security analysis for the Manik Golden Honey Co e-commerce platform. The system handles customer PII, payment processing (via Stripe), and business-critical inventory/order data.

**Risk Profile:** Medium-High (e-commerce with payment processing)

**Key Assets:**
- Customer personal information (email, addresses)
- Order and transaction data
- Admin credentials and access
- Business data (pricing, inventory, discount codes)
- Stripe integration secrets

**Critical Paths:**
1. Authentication flows (customer and admin)
2. Checkout and payment processing
3. Stripe webhook handling
4. Admin operations

---

## 1. Attack Surface Mapping

### 1.1 Public Customer Endpoints

| Endpoint | Method | Auth | Risk Level | Attack Vectors |
|----------|--------|------|------------|----------------|
| `/api/auth/send-code` | POST | None | HIGH | Enumeration, DoS, email bombing |
| `/api/auth/verify-code` | POST | None | CRITICAL | Brute force, code guessing |
| `/api/products` | GET | None | LOW | Scraping, information leakage |
| `/api/products/{id}` | GET | None | LOW | IDOR (product enumeration) |
| `/api/checkout/reserve-inventory` | POST | Optional | MEDIUM | Inventory locking DoS |
| `/api/checkout/validate-promo-code` | POST | Optional | MEDIUM | Code enumeration, abuse |
| `/api/checkout/create-payment-intent` | POST | Optional | HIGH | Payment manipulation |
| `/api/checkout/confirm-order` | POST | Optional | HIGH | Order fraud, replay attacks |
| `/api/reviews` | POST | Required | MEDIUM | Spam, fake reviews |
| `/api/reviews` | GET | None | LOW | Scraping |
| `/api/orders/{id}` | GET | Required | MEDIUM | IDOR, order enumeration |
| `/api/cancellations` | POST | Required | MEDIUM | Cancellation abuse |

### 1.2 Webhook Endpoints

| Endpoint | Method | Auth | Risk Level | Attack Vectors |
|----------|--------|------|------------|----------------|
| `/webhooks/stripe` | POST | Signature | CRITICAL | Spoofing, replay, order fraud |

### 1.3 Admin Endpoints

| Endpoint | Method | Auth | Risk Level | Attack Vectors |
|----------|--------|------|------------|----------------|
| `/api/admin/login` | POST | None | CRITICAL | Credential stuffing, brute force |
| `/api/admin/products/*` | ALL | Admin JWT | HIGH | Unauthorized access, data manipulation |
| `/api/admin/orders/*` | ALL | Admin JWT | HIGH | Order manipulation, refund fraud |
| `/api/admin/customers/*` | GET | Admin JWT | HIGH | PII exposure |
| `/api/admin/promo-codes/*` | ALL | Admin JWT | HIGH | Discount abuse |
| `/api/admin/reviews/*` | ALL | Admin JWT | MEDIUM | Review manipulation |
| `/api/admin/inventory/*` | ALL | Admin JWT | HIGH | Inventory manipulation |

### 1.4 Third-Party Integrations

| Integration | Direction | Risk Level | Attack Vectors |
|-------------|-----------|------------|----------------|
| Stripe API | Outbound | HIGH | API key compromise, MitM |
| Stripe Webhooks | Inbound | CRITICAL | Signature bypass, replay |
| SendGrid/Mailgun | Outbound | MEDIUM | API key compromise, email spoofing |
| Firestore | Internal | HIGH | Injection, unauthorized access |
| Cloud Storage | Public Read | MEDIUM | Bucket misconfiguration |

### 1.5 Infrastructure Components

| Component | Exposure | Risk Level | Attack Vectors |
|-----------|----------|------------|----------------|
| Cloud Run (Next.js) | Public | MEDIUM | Container escape, SSRF |
| Cloud Run (Go API) | Public | HIGH | API vulnerabilities |
| Firestore | Internal only | HIGH | Misconfigurations, injection |
| Cloud Storage (images) | Public read | LOW | Bucket enumeration |
| Secret Manager | Internal only | CRITICAL | IAM misconfiguration |

---

## 2. Threat Actors

### 2.1 Competitor (Sophistication: Low-Medium)

**Motivation:** Business intelligence, reputation damage, competitive advantage

**Capabilities:**
- Automated scraping tools
- Fake accounts for review manipulation
- Price monitoring bots

**Likely Attacks:**
| Attack | Likelihood | Impact | Priority |
|--------|------------|--------|----------|
| Price scraping | HIGH | LOW | P3 |
| Review sabotage (fake negative reviews) | MEDIUM | MEDIUM | P2 |
| Inventory monitoring | MEDIUM | LOW | P4 |
| Discount code enumeration | LOW | MEDIUM | P3 |

### 2.2 Fraudster (Sophistication: Medium)

**Motivation:** Financial gain through discount abuse, chargebacks, reselling

**Capabilities:**
- Multiple account creation
- Stolen payment credentials
- Social engineering
- VPNs/proxies for IP rotation

**Likely Attacks:**
| Attack | Likelihood | Impact | Priority |
|--------|------------|--------|----------|
| Discount code abuse (multi-account) | HIGH | HIGH | P1 |
| Chargeback fraud (friendly fraud) | HIGH | HIGH | P1 |
| Fake order/refund schemes | MEDIUM | HIGH | P1 |
| Account takeover | MEDIUM | HIGH | P1 |
| Review manipulation for resale | LOW | LOW | P4 |

### 2.3 Script Kiddie (Sophistication: Low)

**Motivation:** Disruption, proving skills, opportunistic gain

**Capabilities:**
- Automated vulnerability scanners
- Pre-built exploit kits
- DDoS tools (booter services)
- Credential stuffing tools

**Likely Attacks:**
| Attack | Likelihood | Impact | Priority |
|--------|------------|--------|----------|
| Credential stuffing on admin login | HIGH | CRITICAL | P1 |
| Auth code brute force | HIGH | HIGH | P1 |
| Generic vulnerability scanning | HIGH | LOW | P3 |
| Application-layer DoS | MEDIUM | MEDIUM | P2 |
| SQL injection attempts | HIGH | LOW* | P3 |

*Low impact due to Firestore (NoSQL) not vulnerable to SQL injection

### 2.4 Disgruntled Customer (Sophistication: Low)

**Motivation:** Revenge, frustration, attention

**Capabilities:**
- Multiple account creation
- Social media amplification
- Basic automation (browser extensions)

**Likely Attacks:**
| Attack | Likelihood | Impact | Priority |
|--------|------------|--------|----------|
| Review bombing | MEDIUM | MEDIUM | P2 |
| Order cancellation abuse | LOW | LOW | P4 |
| Support ticket flooding | LOW | LOW | P4 |
| Inventory locking (checkout abandonment) | LOW | MEDIUM | P3 |

### 2.5 Insider Threat (Sophistication: High)

**Motivation:** Financial gain, grudge, coercion

**Capabilities:**
- Legitimate admin access
- Knowledge of systems and processes
- Ability to bypass controls

**Likely Attacks:**
| Attack | Likelihood | Impact | Priority |
|--------|------------|--------|----------|
| Data exfiltration (customer PII) | LOW | CRITICAL | P1 |
| Unauthorized discount creation | LOW | HIGH | P2 |
| Order manipulation for personal gain | LOW | HIGH | P2 |
| Credential sharing | MEDIUM | HIGH | P2 |

---

## 3. Attack Vectors & Mitigations

### 3.1 Authentication Attacks

#### Attack: Auth Code Brute Force

**Description:** Attacker attempts to guess 6-digit verification codes

**Likelihood:** HIGH | **Impact:** HIGH

**Attack Flow:**
```
1. Attacker obtains target email address
2. Triggers code send: POST /api/auth/send-code
3. Attempts all 1,000,000 combinations (000000-999999)
4. At 100 req/sec: ~2.7 hours to exhaust
```

**Mitigations:**

| Control | Implementation | Effectiveness |
|---------|----------------|---------------|
| Attempt limiting | Max 3 failed attempts per code, then invalidate | HIGH |
| Code rate limiting | Max 3 codes per email per hour | HIGH |
| Code expiry | 10-minute TTL on verification codes | MEDIUM |
| IP rate limiting | 10 requests/minute per IP to verify endpoint | HIGH |
| Account lockout | Temporary 1-hour lockout after 5 failed attempts | HIGH |
| Monitoring | Alert on >10 failed attempts for any email | MEDIUM |

**Specific Rate Limits:**
- `POST /api/auth/send-code`: 3 requests per email per hour, 10 per IP per minute
- `POST /api/auth/verify-code`: 3 attempts per code, 10 per IP per minute

---

#### Attack: Admin Credential Stuffing

**Description:** Attacker uses leaked credential databases against admin login

**Likelihood:** HIGH | **Impact:** CRITICAL

**Attack Flow:**
```
1. Attacker obtains credential dump (email/password pairs)
2. Filters for likely admin emails (admin@*, support@*, etc.)
3. Attempts bulk login: POST /api/admin/login
4. Successful login grants full admin access
```

**Mitigations:**

| Control | Implementation | Effectiveness |
|---------|----------------|---------------|
| Rate limiting | 5 attempts per email per hour, 20 per IP per hour | HIGH |
| Account lockout | Lock admin account after 5 failed attempts (24hr) | HIGH |
| Strong passwords | Require 12+ chars, complexity requirements | MEDIUM |
| IP allowlisting | Restrict admin login to known IPs (optional) | HIGH |
| 2FA/MFA | Require second factor for admin login | CRITICAL |
| Monitoring | Alert on ANY failed admin login attempt | HIGH |
| Audit logging | Log all admin login attempts with IP, user-agent | HIGH |

**Specific Rate Limits:**
- `POST /api/admin/login`: 5 attempts per email per hour, 20 per IP per hour
- Alert threshold: ANY failed admin login attempt

**Recommendation:** Implement TOTP-based 2FA for admin accounts before production launch.

---

#### Attack: Session Hijacking

**Description:** Attacker steals JWT token to impersonate user

**Likelihood:** MEDIUM | **Impact:** HIGH

**Attack Vectors:**
- XSS to steal token from JavaScript
- Network sniffing (if HTTP used)
- Token leakage in logs/URLs

**Mitigations:**

| Control | Implementation | Effectiveness |
|---------|----------------|---------------|
| HttpOnly cookies | Store JWT in HttpOnly cookie (not localStorage) | HIGH |
| Secure flag | Cookie only sent over HTTPS | HIGH |
| SameSite=Strict | Prevent CSRF via cookie policy | HIGH |
| Short expiry | 48-hour token lifetime | MEDIUM |
| Token rotation | Issue new token on sensitive operations | MEDIUM |
| IP binding | Optional: bind token to originating IP | MEDIUM |

---

### 3.2 Payment & Checkout Attacks

#### Attack: Stripe Webhook Spoofing

**Description:** Attacker sends fake webhook to create fraudulent orders

**Likelihood:** HIGH | **Impact:** CRITICAL

**Attack Flow:**
```
1. Attacker discovers webhook endpoint: POST /webhooks/stripe
2. Crafts fake payment_intent.succeeded event
3. Sends to endpoint without valid signature
4. If accepted: Order created without payment
```

**Mitigations:**

| Control | Implementation | Effectiveness |
|---------|----------------|---------------|
| Signature verification | Verify stripe-signature header using webhook secret | CRITICAL |
| Reject missing signatures | Return 400 immediately if signature header absent | HIGH |
| Timing validation | Reject events older than 5 minutes (replay prevention) | HIGH |
| IP logging | Log all webhook requests, alert on invalid signatures | HIGH |
| Endpoint obscurity | Use random path: `/webhooks/stripe-{random}` | LOW |
| Rate limiting | 100 requests/minute per IP to webhook endpoint | MEDIUM |

**Implementation:**
```go
func verifyStripeWebhook(payload []byte, signature string) error {
    event, err := webhook.ConstructEvent(payload, signature, webhookSecret)
    if err != nil {
        // CRITICAL: Log security event
        logSecurityEvent("webhook_signature_invalid", signature, clientIP)
        alertSecurityTeam("Invalid webhook signature detected")
        return err
    }
    return nil
}
```

**Monitoring:**
- Alert on ANY signature verification failure (should be zero in normal operation)
- Auto-block IP after 3 failed signature verifications (24-hour block)

---

#### Attack: Payment Intent Replay

**Description:** Attacker captures payment_intent_id to create multiple orders

**Likelihood:** MEDIUM | **Impact:** HIGH

**Attack Flow:**
```
1. Legitimate payment completes, order created
2. Attacker captures payment_intent_id from network traffic
3. Attempts POST /api/checkout/confirm-order with same ID
4. If accepted: Duplicate order created
```

**Mitigations:**

| Control | Implementation | Effectiveness |
|---------|----------------|---------------|
| Idempotency check | Query orders by payment_intent_id before creating | CRITICAL |
| Unique constraint | Database-level unique on stripe_payment_intent_id | HIGH |
| Payment status verification | Query Stripe API to confirm payment status | HIGH |
| Request deduplication | Track processed payment_intent_ids in cache (1hr TTL) | MEDIUM |

---

#### Attack: Inventory Locking DoS

**Description:** Attacker creates many reservations without completing checkout

**Likelihood:** MEDIUM | **Impact:** MEDIUM

**Attack Flow:**
```
1. Attacker identifies high-value/limited product
2. Creates multiple reservations via POST /api/checkout/reserve-inventory
3. Never completes payment, ties up inventory for 15 minutes
4. Legitimate customers see "out of stock"
5. Repeat to continuously lock inventory
```

**Mitigations:**

| Control | Implementation | Effectiveness |
|---------|----------------|---------------|
| Short TTL | 15-minute reservation expiry | MEDIUM |
| Customer rate limit | Max 2 active reservations per customer | HIGH |
| IP rate limit | Max 5 reservation requests per IP per hour | HIGH |
| Session tracking | Link reservations to browser fingerprint | MEDIUM |
| CAPTCHA | Require CAPTCHA on checkout button after 2 attempts | MEDIUM |
| Monitoring | Alert if >50 active reservations globally | HIGH |

**Specific Rate Limits:**
- `POST /api/checkout/reserve-inventory`: 5 per IP per hour, 2 active per customer
- Reservation TTL: 15 minutes (non-negotiable)

**Detection:**
- Track reservation:order conversion ratio (target >60%)
- Alert if ratio drops below 30% (possible attack)

---

#### Attack: Price Manipulation

**Description:** Attacker modifies cart total or discount amount in transit

**Likelihood:** LOW | **Impact:** HIGH

**Attack Flow:**
```
1. Attacker intercepts create-payment-intent request
2. Modifies amount field to lower value
3. Submits modified request
4. Charged less than actual cart value
```

**Mitigations:**

| Control | Implementation | Effectiveness |
|---------|----------------|---------------|
| Server-side calculation | Never trust client-provided totals | CRITICAL |
| Recalculate at payment | Compute amount from reservation items + DB prices | CRITICAL |
| Validate promo codes | Re-validate discount at payment intent creation | HIGH |
| Stripe metadata | Store item details in PaymentIntent metadata | HIGH |
| Reconciliation | Compare order total vs Stripe charge amount | HIGH |

---

### 3.3 Discount Code Attacks

#### Attack: Promo Code Enumeration

**Description:** Attacker attempts to discover valid discount codes

**Likelihood:** HIGH | **Impact:** MEDIUM

**Attack Flow:**
```
1. Attacker generates common code patterns (SAVE10, WELCOME, etc.)
2. Attempts validation: POST /api/checkout/validate-promo-code
3. Distinguishes valid from invalid by response
4. Uses or shares discovered codes
```

**Mitigations:**

| Control | Implementation | Effectiveness |
|---------|----------------|---------------|
| Rate limiting | 5 validation attempts per IP per minute | HIGH |
| Generic responses | "Invalid or expired code" (don't distinguish) | MEDIUM |
| Code complexity | Min 6 chars, alphanumeric, avoid patterns | MEDIUM |
| CAPTCHA | Require after 3 failed attempts per session | HIGH |
| Monitoring | Track validation attempts per code, alert on spikes | HIGH |

**Specific Rate Limits:**
- `POST /api/checkout/validate-promo-code`: 5 per IP per minute, 20 per customer per hour
- Alert threshold: >100 validation attempts for any single code in 1 hour

---

#### Attack: Multi-Account Code Abuse

**Description:** Fraudster creates multiple accounts to reuse one-time codes

**Likelihood:** HIGH | **Impact:** HIGH

**Attack Flow:**
```
1. Valuable code "WELCOME20" is one_time_per_customer
2. Fraudster creates accounts with different emails
3. Uses code on each account, ships to same address
4. Effectively unlimited code usage
```

**Mitigations:**

| Control | Implementation | Effectiveness |
|---------|----------------|---------------|
| Email normalization | Block Gmail +aliases, normalize domains | HIGH |
| IP tracking | Flag same IP using code >3 times | MEDIUM |
| Address matching | Flag same shipping address + different accounts | HIGH |
| Device fingerprinting | Track device across accounts (future) | HIGH |
| Manual review | Flag orders with fraud indicators for review | MEDIUM |
| Code limits | Set max_redemptions even for "unlimited" codes | MEDIUM |

**Detection:**
- Alert if >5 accounts from same IP use same code
- Alert if >3 orders with same shipping address use same code

---

### 3.4 Review System Attacks

#### Attack: Review Bombing

**Description:** Competitor or disgruntled user posts many negative reviews

**Likelihood:** MEDIUM | **Impact:** MEDIUM

**Attack Flow:**
```
1. Attacker purchases product (creates verified account)
2. Posts negative review
3. Repeats with multiple accounts
4. Damages product/brand reputation
```

**Mitigations:**

| Control | Implementation | Effectiveness |
|---------|----------------|---------------|
| Purchase verification | Must purchase product to review | HIGH |
| Moderation queue | All reviews require admin approval | CRITICAL |
| Rate limiting | Max 5 reviews per customer per 24 hours | HIGH |
| Duplicate detection | Flag identical/similar review text | HIGH |
| IP tracking | Flag multiple reviews from same IP | HIGH |
| Edit limits | Escalating cooldowns after rejections | MEDIUM |

**Specific Rate Limits:**
- `POST /api/reviews`: 5 per customer per 24 hours, 10 per IP per hour
- Review submission: Require CAPTCHA after 3 reviews in 1 hour

**Detection Thresholds:**
- Alert if >10 negative reviews (1-2 stars) for same product in 24 hours
- Alert if same IP submits >5 reviews in 1 hour

---

#### Attack: Spam Injection

**Description:** Attacker includes links/ads in review content

**Likelihood:** HIGH | **Impact:** MEDIUM

**Attack Flow:**
```
1. Attacker creates legitimate-looking review
2. Includes external URLs, phone numbers, or promotional content
3. Review appears on product page (if approved)
4. Drives traffic to competitor or spam site
```

**Mitigations:**

| Control | Implementation | Effectiveness |
|---------|----------------|---------------|
| Content filtering | Detect URLs, emails, phone numbers | HIGH |
| Moderation | All reviews reviewed before publishing | CRITICAL |
| Pattern detection | Flag common spam phrases | MEDIUM |
| XSS prevention | HTML escape all review content on display | CRITICAL |
| Auto-reject | Reject reviews with URL + phone number | HIGH |

**Spam Detection Patterns:**
```
HIGH severity (auto-flag):
- Contains URL (https?:// or www.)
- Contains phone number (\d{3}[-.]?\d{3}[-.]?\d{4})
- Contains email address
- Duplicate of existing review

MEDIUM severity (flag for review):
- Contains spam keywords ["buy now", "click here", "limited time"]
- >3 reviews from same IP in 1 hour
- Review text <20 characters
```

---

### 3.5 Data Exposure Attacks

#### Attack: Customer Data Enumeration

**Description:** Attacker enumerates customer data via API

**Likelihood:** MEDIUM | **Impact:** HIGH

**Attack Flow:**
```
1. Attacker discovers pattern in order IDs
2. Iterates through IDs: GET /api/orders/{id}
3. Accesses other customers' order details
4. Collects PII (names, addresses, order history)
```

**Mitigations:**

| Control | Implementation | Effectiveness |
|---------|----------------|---------------|
| Authorization check | Verify order belongs to authenticated customer | CRITICAL |
| Random IDs | Use UUIDs not sequential integers | HIGH |
| Rate limiting | 20 requests per minute to order endpoints | MEDIUM |
| Logging | Log all order access attempts with customer context | HIGH |
| Field filtering | Don't expose unnecessary fields in responses | MEDIUM |

**Implementation:**
```go
func getOrder(orderID string, customerID string) (*Order, error) {
    order, err := db.GetOrder(orderID)
    if err != nil {
        return nil, err
    }
    // CRITICAL: Verify ownership
    if order.CustomerID != customerID {
        logSecurityEvent("unauthorized_order_access", orderID, customerID)
        return nil, ErrForbidden
    }
    return order, nil
}
```

---

#### Attack: Admin Data Exfiltration

**Description:** Compromised admin account exports customer data

**Likelihood:** LOW | **Impact:** CRITICAL

**Mitigations:**

| Control | Implementation | Effectiveness |
|---------|----------------|---------------|
| Audit logging | Log all admin data access with timestamp, admin ID | CRITICAL |
| Export limits | Max 100 records per export, require reason | HIGH |
| Alerts | Alert on bulk data access (>50 customer records) | HIGH |
| Access review | Quarterly review of admin access patterns | MEDIUM |
| Principle of least privilege | Separate read/write admin roles (future) | HIGH |

---

### 3.6 Infrastructure Attacks

#### Attack: Secret Exposure

**Description:** API keys or secrets leaked in code, logs, or config

**Likelihood:** MEDIUM | **Impact:** CRITICAL

**Attack Vectors:**
- Secrets committed to git repository
- Secrets logged in error messages
- Secrets in client-side code
- Cloud metadata endpoint exposure

**Mitigations:**

| Control | Implementation | Effectiveness |
|---------|----------------|---------------|
| Secret Manager | All secrets stored in GCP Secret Manager | CRITICAL |
| No hardcoding | Never commit secrets to repository | CRITICAL |
| Log sanitization | Redact any potential secret patterns in logs | HIGH |
| Pre-commit hooks | Scan for secrets before commit (gitleaks) | HIGH |
| Rotation policy | Rotate API keys every 90 days | MEDIUM |
| Environment isolation | Different secrets per environment | HIGH |

**Secrets Inventory:**
- `STRIPE_SECRET_KEY` - Payment processing
- `STRIPE_WEBHOOK_SECRET` - Webhook verification
- `JWT_SECRET` - Token signing
- `EMAIL_API_KEY` - Email service
- `FIRESTORE_SERVICE_ACCOUNT` - Database access

---

#### Attack: Container/Cloud Run Exploitation

**Description:** Attacker exploits vulnerability in Cloud Run environment

**Likelihood:** LOW | **Impact:** HIGH

**Mitigations:**

| Control | Implementation | Effectiveness |
|---------|----------------|---------------|
| Minimal base images | Use distroless or alpine images | HIGH |
| Regular updates | Rebuild containers weekly with latest patches | HIGH |
| No root user | Run container as non-root user | HIGH |
| Resource limits | Set memory/CPU limits to prevent abuse | MEDIUM |
| Network isolation | Internal-only access for API <-> Firestore | HIGH |
| IAM principle of least privilege | Minimal permissions for service accounts | CRITICAL |

---

## 4. Security Requirements Checklist

### 4.1 Input Validation

| Requirement | Status | Implementation |
|-------------|--------|----------------|
| All inputs validated server-side | REQUIRED | Go validation middleware |
| Email format validation | REQUIRED | RFC 5322 regex |
| Quantity bounds (1-100 per item) | REQUIRED | Reject out-of-range |
| Price validation (server-calculated) | REQUIRED | Never trust client amounts |
| Text length limits | REQUIRED | See edge-cases-comprehensive.md |
| XSS prevention (HTML escaping) | REQUIRED | Escape on output, CSP headers |
| Alphanumeric-only promo codes | REQUIRED | Regex validation |

### 4.2 Authentication & Authorization

| Requirement | Status | Implementation |
|-------------|--------|----------------|
| JWT validation on all protected endpoints | REQUIRED | Middleware |
| Role-based access (customer vs admin) | REQUIRED | JWT role claim |
| Admin 2FA | RECOMMENDED | TOTP before production |
| Session expiry (48 hours) | REQUIRED | JWT exp claim |
| HttpOnly cookies | REQUIRED | Cookie settings |
| Secure + SameSite cookies | REQUIRED | Cookie settings |
| Admin IP allowlisting | OPTIONAL | Cloud Run IAM |

### 4.3 Rate Limiting Summary

| Endpoint | Per IP | Per User | Per Resource |
|----------|--------|----------|--------------|
| `/api/auth/send-code` | 10/min | - | 3/email/hour |
| `/api/auth/verify-code` | 10/min | - | 3 attempts/code |
| `/api/admin/login` | 20/hour | 5/hour | - |
| `/api/checkout/reserve-inventory` | 5/hour | 2 active | - |
| `/api/checkout/validate-promo-code` | 5/min | 20/hour | - |
| `/api/reviews` | 10/hour | 5/day | - |
| `/webhooks/stripe` | 100/min | - | - |
| General API | 100/min | 1000/hour | - |

### 4.4 Security Headers

| Header | Value | Purpose |
|--------|-------|---------|
| `Content-Security-Policy` | `default-src 'self'; script-src 'self' https://js.stripe.com; frame-src https://js.stripe.com; style-src 'self' 'unsafe-inline'` | XSS prevention |
| `X-Content-Type-Options` | `nosniff` | MIME sniffing prevention |
| `X-Frame-Options` | `DENY` | Clickjacking prevention |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` | HTTPS enforcement |
| `X-XSS-Protection` | `1; mode=block` | Legacy XSS protection |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Referrer leakage prevention |

### 4.5 Logging Requirements

**What to Log:**
- All authentication attempts (success and failure)
- All admin actions (with before/after state)
- Order creation and status changes
- Payment events (without card data)
- Rate limit violations
- Security events (invalid signatures, unauthorized access)
- API errors (with request context)

**What NOT to Log:**
- Passwords or password hashes
- Full credit card numbers (never touch these)
- JWT tokens
- API keys or secrets
- Full email addresses (mask: `j***@example.com`)

**Log Retention:**
- Security events: 1 year
- Audit logs: 2 years
- Application logs: 90 days
- Access logs: 30 days

---

## 5. Detection Mechanisms

### 5.1 Real-Time Alerts

| Alert | Condition | Severity | Notification |
|-------|-----------|----------|--------------|
| Invalid webhook signature | Any occurrence | CRITICAL | PagerDuty + Slack |
| Failed admin login | Any occurrence | HIGH | Email + Slack |
| Admin account locked | 5 failed attempts | HIGH | PagerDuty + Email |
| Bulk data access | >50 customer records in 1 hour | HIGH | Slack |
| Order creation failure after payment | Any occurrence | CRITICAL | PagerDuty + Email |
| Rate limit exceeded (sustained) | >10 violations in 5 minutes | MEDIUM | Slack |
| Review bombing detected | >10 negative reviews/product/day | MEDIUM | Email |
| Promo code over-redemption | >10% over max | MEDIUM | Email |
| Inventory locking anomaly | Reservation:order ratio <30% | MEDIUM | Slack |

### 5.2 Anomaly Detection

**Order Patterns:**
- Unusual order velocity (>10 orders/hour to same address)
- Multiple accounts, same payment method
- Order value significantly above average (>3 standard deviations)
- Rapid order-then-cancel pattern

**Review Patterns:**
- Multiple reviews from same IP
- Identical or near-identical review text
- All 1-star or all 5-star reviews from same source
- Review submission outside business hours (unusual)

**Authentication Patterns:**
- Login attempts from multiple countries in short time
- High volume of code requests for single email
- Login immediately after code request (potential interception)

### 5.3 Dashboard Metrics

**Security Dashboard (Admin):**
- Failed login attempts (24hr rolling)
- Rate limit violations (24hr rolling)
- Flagged reviews pending moderation
- Active security alerts
- Webhook signature failures (should be 0)

---

## 6. Incident Response Procedures

### 6.1 Severity Levels

| Level | Description | Response Time | Examples |
|-------|-------------|---------------|----------|
| P1 - Critical | Active attack, data breach, service down | 15 minutes | Webhook compromise, admin credential leak |
| P2 - High | Significant security risk, limited impact | 1 hour | Sustained brute force, discount abuse |
| P3 - Medium | Security concern, no immediate threat | 4 hours | Review bombing, scraping |
| P4 - Low | Minor security issue | 24 hours | Single failed login, low-impact anomaly |

### 6.2 Response Playbooks

#### Playbook: Invalid Webhook Signature Detected

**Trigger:** Alert fires on webhook signature verification failure

**Immediate Actions (0-15 minutes):**
1. Verify alert is not false positive (check logs for request details)
2. Check Stripe dashboard for webhook delivery status
3. If attack confirmed:
   - Block source IP immediately via Cloud Run firewall
   - Rotate webhook secret in Secret Manager
   - Update Stripe dashboard with new secret
   - Verify legitimate webhooks still processing

**Investigation (15-60 minutes):**
1. Analyze request payload for attack intent
2. Check if any orders were fraudulently created
3. Review all orders created in past 1 hour manually
4. Determine if endpoint was discovered (check access logs)

**Post-Incident:**
1. Implement additional webhook endpoint obscurity if needed
2. Review webhook processing code for vulnerabilities
3. Document incident and learnings
4. Update threat model if new attack vector identified

---

#### Playbook: Admin Account Compromise Suspected

**Trigger:** Unusual admin activity or admin reports unauthorized access

**Immediate Actions (0-15 minutes):**
1. Disable suspected admin account immediately
2. Rotate JWT signing secret (invalidates all sessions)
3. Review recent admin actions in audit log
4. Check for data exports or bulk modifications

**Investigation (15-60 minutes):**
1. Identify compromise vector (password, session hijack, etc.)
2. Review all changes made by compromised account
3. Check for created/modified promo codes
4. Review customer data access patterns
5. Check for unauthorized order refunds

**Remediation:**
1. Revert any unauthorized changes
2. Contact affected customers if data exposed
3. Implement 2FA for all admin accounts
4. Review and strengthen admin access controls

**Post-Incident:**
1. Root cause analysis
2. Implement additional controls
3. Consider breach notification requirements
4. Update security training

---

#### Playbook: Discount Code Abuse Detected

**Trigger:** Alert on over-redemption or multi-account pattern

**Immediate Actions (0-30 minutes):**
1. Deactivate abused discount code
2. Review recent orders using the code
3. Flag suspicious orders for manual review

**Investigation:**
1. Identify abuse pattern (multi-account, sharing, etc.)
2. Calculate financial impact
3. Identify linked accounts (same IP, address, payment)

**Remediation:**
1. Refund and cancel fraudulent orders
2. Block identified fraudulent accounts
3. Implement stricter code controls
4. Consider legal action if significant

---

#### Playbook: Review Bombing Attack

**Trigger:** Alert on negative review spike

**Immediate Actions (0-1 hour):**
1. Hold all pending reviews for product
2. Review submitted reviews for patterns
3. Identify attacking accounts

**Investigation:**
1. Analyze IP addresses and account creation times
2. Check for duplicate or similar review content
3. Determine if legitimate unhappy customers or coordinated attack

**Remediation:**
1. Reject spam/fake reviews
2. Ban attacking accounts
3. Block identified attack IPs
4. Approve legitimate negative reviews (don't censor valid criticism)

---

### 6.3 Escalation Path

```
Level 1: On-call Engineer
    |
    v (P1/P2 or unresolved after 1 hour)
Level 2: Engineering Lead
    |
    v (Data breach or legal implications)
Level 3: CEO / Legal Counsel
    |
    v (if required)
External: Law enforcement, breach notification
```

### 6.4 Communication Templates

**Internal Alert:**
```
SECURITY ALERT: [SEVERITY]
Time: [TIMESTAMP]
Type: [ALERT TYPE]
Description: [BRIEF DESCRIPTION]
Affected: [SYSTEMS/DATA]
Action Required: [IMMEDIATE STEPS]
Incident Lead: [NAME]
```

**Customer Notification (if required):**
```
Subject: Important Security Notice from Manik Golden Honey Co

Dear Customer,

We are writing to inform you of a security incident that may have affected your account. [DESCRIPTION]

What happened: [BRIEF EXPLANATION]
What information was affected: [DATA TYPES]
What we're doing: [REMEDIATION STEPS]
What you should do: [CUSTOMER ACTIONS]

We sincerely apologize for any inconvenience. If you have questions, contact support@manikgoldenhoney.com.
```

---

## 7. Post-Incident Review Process

### 7.1 Review Timeline

| Timeframe | Activity |
|-----------|----------|
| Within 24 hours | Initial incident report drafted |
| Within 72 hours | Full timeline reconstruction |
| Within 1 week | Root cause analysis complete |
| Within 2 weeks | Remediation plan approved |
| Within 30 days | All remediations implemented |
| Within 45 days | Final incident report published |

### 7.2 Review Questions

1. What happened and when?
2. How was it detected?
3. What was the impact?
4. What was the root cause?
5. What controls failed or were missing?
6. What went well in the response?
7. What could be improved?
8. What specific actions will prevent recurrence?

### 7.3 Documentation Requirements

- Full incident timeline
- Technical analysis
- Impact assessment (data, financial, reputational)
- Root cause analysis
- Lessons learned
- Action items with owners and deadlines
- Updated threat model (if applicable)
- Updated runbooks (if applicable)

---

## 8. Security Testing Requirements

### 8.1 Pre-Launch Checklist

| Test | Frequency | Owner |
|------|-----------|-------|
| Dependency vulnerability scan | Every build | CI/CD |
| OWASP ZAP automated scan | Weekly | Security |
| Rate limit testing | Before launch | Engineering |
| Authentication flow testing | Before launch | Engineering |
| Webhook signature verification test | Before launch | Engineering |
| Input validation fuzzing | Before launch | Security |
| Admin authorization testing | Before launch | Engineering |

### 8.2 Ongoing Security Activities

| Activity | Frequency | Owner |
|----------|-----------|-------|
| Dependency updates | Weekly | Engineering |
| Access review | Quarterly | Security |
| Penetration testing | Annually | External |
| Secret rotation | Every 90 days | Engineering |
| Security training | Annually | All staff |
| Incident response drill | Bi-annually | Security |
| Threat model review | Annually | Security |

---

## 9. Compliance Considerations

### 9.1 PCI DSS

**Status:** Not directly applicable (Stripe handles card data)

**Our Responsibilities:**
- Never store, process, or transmit card data
- Use Stripe Elements for payment form
- Verify webhook signatures
- Secure Stripe API keys

### 9.2 Data Privacy

**Customer Data Collected:**
- Email address (required for auth)
- Name (for shipping)
- Shipping address (for orders)
- Order history
- Review content

**Retention Policy:**
- Active customer data: Retained while account active
- Inactive accounts (no login for 2 years): Anonymize
- Order data: Retain 7 years (tax/legal requirements)
- Deleted accounts: Anonymize within 30 days

**Customer Rights:**
- Data export (provide on request)
- Data deletion (anonymize, retain order records)
- Data correction (self-service via account settings)

---

## 10. Risk Matrix Summary

| Threat | Likelihood | Impact | Risk Score | Priority |
|--------|------------|--------|------------|----------|
| Auth code brute force | HIGH | HIGH | HIGH | P1 |
| Admin credential stuffing | HIGH | CRITICAL | CRITICAL | P1 |
| Webhook spoofing | HIGH | CRITICAL | CRITICAL | P1 |
| Discount code abuse | HIGH | HIGH | HIGH | P1 |
| Inventory locking DoS | MEDIUM | MEDIUM | MEDIUM | P2 |
| Review bombing | MEDIUM | MEDIUM | MEDIUM | P2 |
| Price scraping | HIGH | LOW | MEDIUM | P3 |
| Customer data enumeration | MEDIUM | HIGH | HIGH | P1 |
| Secret exposure | MEDIUM | CRITICAL | HIGH | P1 |
| Container exploitation | LOW | HIGH | MEDIUM | P3 |

---

## 11. Open Items & Recommendations

### 11.1 Critical (Before Launch)

| Item | Owner | Target Date |
|------|-------|-------------|
| Implement all rate limits per specification | Engineering | Pre-launch |
| Configure webhook signature verification | Engineering | Pre-launch |
| Set up security alerts in Cloud Monitoring | DevOps | Pre-launch |
| Review and test all authorization checks | Engineering | Pre-launch |
| Configure security headers | Engineering | Pre-launch |

### 11.2 High Priority (Within 30 Days of Launch)

| Item | Owner | Target Date |
|------|-------|-------------|
| Implement admin 2FA (TOTP) | Engineering | Launch + 30 days |
| Set up automated dependency scanning | DevOps | Launch + 14 days |
| Create security runbook | Security | Launch + 14 days |
| Conduct internal penetration test | Security | Launch + 30 days |

### 11.3 Medium Priority (Within 90 Days)

| Item | Owner | Target Date |
|------|-------|-------------|
| Implement device fingerprinting for fraud detection | Engineering | Launch + 90 days |
| Add admin IP allowlisting option | Engineering | Launch + 60 days |
| Conduct external penetration test | External | Launch + 90 days |
| Implement advanced anomaly detection | Engineering | Launch + 90 days |

---

**Document Control:**
- **Version:** 1.0
- **Author:** Security Review Team
- **Last Updated:** 2026-01-25
- **Next Review:** 2026-04-25 (or after significant changes)
- **Approval:** Required before production deployment
