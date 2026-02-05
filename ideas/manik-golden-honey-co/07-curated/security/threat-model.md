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

### Rate Limiting Implementation (REQUIRED PRE-LAUNCH)

**Primary Implementation: GCP Cloud Armor** (recommended)
- WAF-level rate limiting on Cloud Run
- DDoS protection included
- No application code changes required
- Configure rules per endpoint table above

**Fallback: Redis-backed middleware** (if fine-grained control needed)
```typescript
// Using @upstash/ratelimit for serverless Redis
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const redis = new Redis({ url: process.env.UPSTASH_URL, token: process.env.UPSTASH_TOKEN });

const rateLimiters = {
  authSendCode: new Ratelimit({
    redis,
    limiter: Ratelimit.slidingWindow(3, '1h'),
    prefix: 'rl:auth:send',
  }),
  adminLogin: new Ratelimit({
    redis,
    limiter: Ratelimit.slidingWindow(5, '1h'),
    prefix: 'rl:admin:login',
  }),
};

// Middleware pattern
async function rateLimitMiddleware(req, endpoint) {
  const key = `${req.ip}:${endpoint}`;
  const { success, remaining, reset } = await rateLimiters[endpoint].limit(key);

  if (!success) {
    res.setHeader('X-RateLimit-Remaining', remaining);
    res.setHeader('X-RateLimit-Reset', reset);
    throw new TooManyRequestsError();
  }
}
```

**Response Headers (required on all rate-limited endpoints):**
- `X-RateLimit-Limit`: Maximum requests allowed
- `X-RateLimit-Remaining`: Requests remaining in window
- `X-RateLimit-Reset`: Unix timestamp when limit resets

**Bypass Strategy:** Authenticated admin users exempt from general API limits (not auth limits).

---

## Required Security Headers

```
Content-Security-Policy: default-src 'self'; script-src 'self' https://js.stripe.com 'nonce-{random}'; frame-src https://js.stripe.com; style-src 'self' 'unsafe-inline'; img-src 'self' https://storage.googleapis.com data:; connect-src 'self' https://api.stripe.com
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 0
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

**Implementation:** Next.js middleware or Cloud Run reverse proxy

**Testing:** Validate with securityheaders.com before launch

---

## CSRF Protection (REQUIRED PRE-LAUNCH)

**Scope:** All state-changing operations (POST, PUT, DELETE)

**Strategy: Double Submit Cookie Pattern**

1. Generate cryptographically random CSRF token per session
2. Store in HttpOnly cookie AND require in request header
3. Validate both match on server

**Implementation:**
```typescript
import crypto from 'crypto';

// Generate CSRF token on session creation
function generateCsrfToken(): string {
  return crypto.randomBytes(32).toString('hex');
}

// Set CSRF cookie (called on auth)
function setCsrfCookie(res: Response, token: string) {
  res.headers.set('Set-Cookie',
    `__Host-csrf=${token}; Secure; HttpOnly; SameSite=Strict; Path=/; Max-Age=28800`
  );
}

// Middleware: validate CSRF on state-changing requests
function csrfMiddleware(req: Request, res: Response, next: Function) {
  if (['POST', 'PUT', 'DELETE', 'PATCH'].includes(req.method)) {
    const cookieToken = getCookie(req, '__Host-csrf');
    const headerToken = req.headers.get('X-CSRF-Token');

    if (!cookieToken || !headerToken) {
      return res.status(403).json({ error: 'Missing CSRF token' });
    }

    // Constant-time comparison
    if (!crypto.timingSafeEqual(
      Buffer.from(cookieToken),
      Buffer.from(headerToken)
    )) {
      logSecurityEvent('csrf_validation_failure', { ip: req.ip, path: req.url });
      return res.status(403).json({ error: 'Invalid CSRF token' });
    }
  }
  next();
}
```

**Frontend Integration:**
```typescript
// Fetch wrapper that includes CSRF token
async function apiRequest(url: string, options: RequestInit = {}) {
  const csrfToken = getCsrfTokenFromMeta(); // Read from <meta name="csrf-token">

  return fetch(url, {
    ...options,
    headers: {
      ...options.headers,
      'X-CSRF-Token': csrfToken,
    },
    credentials: 'same-origin',
  });
}
```

**Token Lifecycle:**
- Generated on login/session creation
- Stored in cookie with 8-hour expiry
- Rotated on sensitive actions (password change, admin elevation)
- Invalidated on logout

---

## Authentication Requirements

| Requirement | Implementation |
|-------------|----------------|
| JWT validation on protected endpoints | Middleware |
| Role-based access (customer vs admin) | JWT role claim |
| Admin 2FA (TOTP) | **REQUIRED PRE-LAUNCH** |
| Session expiry | Customer: 48 hours, Admin: 1 hour (activity-based renewal) |
| Token storage | HttpOnly cookies only |
| Cookie flags | __Host- prefix + Secure + SameSite=Strict |

### Admin 2FA Implementation (REQUIRED PRE-LAUNCH)

**Rationale:** Admin accounts have full system access (inventory, orders, customer data, refunds). Single-factor authentication is unacceptable risk for privileged access.

**Implementation: TOTP (Time-based One-Time Password)**

```typescript
import { authenticator } from 'otplib';
import qrcode from 'qrcode';

// Step 1: Generate secret during admin account setup
async function setupAdmin2FA(adminId: string) {
  const secret = authenticator.generateSecret();
  const otpauth = authenticator.keyuri(adminId, 'GoldenHoney Admin', secret);
  const qrCodeUrl = await qrcode.toDataURL(otpauth);

  // Store secret encrypted in admin profile (not activated yet)
  await firestore.collection('admins').doc(adminId).update({
    totp_secret_pending: encrypt(secret),
    totp_setup_started: FieldValue.serverTimestamp(),
  });

  return { qrCodeUrl, secret }; // Show QR to admin
}

// Step 2: Verify and activate 2FA
async function verifyAndActivate2FA(adminId: string, code: string) {
  const admin = await getAdmin(adminId);
  const secret = decrypt(admin.totp_secret_pending);

  if (!authenticator.verify({ token: code, secret })) {
    throw new Error('Invalid verification code');
  }

  // Generate backup codes
  const backupCodes = Array.from({ length: 10 }, () =>
    crypto.randomBytes(4).toString('hex').toUpperCase()
  );

  await firestore.collection('admins').doc(adminId).update({
    totp_secret: encrypt(secret),
    totp_secret_pending: FieldValue.delete(),
    totp_enabled: true,
    totp_backup_codes: backupCodes.map(c => hashBackupCode(c)),
    totp_activated_at: FieldValue.serverTimestamp(),
  });

  return { backupCodes }; // Show once, never again
}

// Step 3: Verify TOTP on login
async function verifyAdminLogin(adminId: string, password: string, totpCode: string) {
  const admin = await getAdmin(adminId);

  // Verify password first
  if (!await verifyPassword(password, admin.password_hash)) {
    throw new AuthError('Invalid credentials');
  }

  // Require 2FA if enabled (must be enabled for all admins)
  if (!admin.totp_enabled) {
    throw new AuthError('2FA setup required');
  }

  const secret = decrypt(admin.totp_secret);

  // Check TOTP code
  if (authenticator.verify({ token: totpCode, secret })) {
    return generateAdminSession(admin);
  }

  // Check backup codes
  for (const hashedCode of admin.totp_backup_codes) {
    if (verifyBackupCode(totpCode, hashedCode)) {
      // Remove used backup code
      await removeUsedBackupCode(adminId, hashedCode);
      alertAdmin('BACKUP_CODE_USED', { adminId, remainingCodes: admin.totp_backup_codes.length - 1 });
      return generateAdminSession(admin);
    }
  }

  throw new AuthError('Invalid 2FA code');
}
```

**Admin Onboarding Flow:**
1. First admin login redirects to 2FA setup page
2. Display QR code for authenticator app (Google Authenticator, Authy, 1Password)
3. Require verification code to confirm setup
4. Display backup codes ONCE - admin must save securely
5. Cannot access admin panel until 2FA verified

**Backup Code Policy:**
- 10 backup codes generated on setup
- Each code usable once
- Alert when backup code used
- Require 2FA re-setup when <3 codes remain

**Recovery Process:**
- Lost device: Use backup code, then re-setup 2FA
- Lost backup codes: Manual identity verification by super-admin
- Document recovery process in admin runbook

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

### Webhook Signature Verification Implementation (REQUIRED PRE-LAUNCH)

**CRITICAL: Use constant-time comparison to prevent timing attacks**

```typescript
import Stripe from 'stripe';
import crypto from 'crypto';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

// Set to track processed event IDs (use Redis in production)
const processedEvents = new Set<string>();

async function handleWebhook(req: Request): Promise<Response> {
  const signature = req.headers.get('stripe-signature');
  const body = await req.text();

  // Step 1: Verify signature exists
  if (!signature) {
    logSecurityEvent('webhook_missing_signature', { ip: req.ip });
    return new Response('Missing signature', { status: 401 });
  }

  // Step 2: Verify signature with constant-time comparison (Stripe SDK handles this)
  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(body, signature, webhookSecret);
  } catch (err) {
    logSecurityEvent('webhook_signature_failure', {
      ip: req.ip,
      timestamp: new Date().toISOString(),
      payloadHash: crypto.createHash('sha256').update(body).digest('hex'),
      error: err.message,
    });
    await checkAndBlockIP(req.ip); // Auto-block after 3 failures
    return new Response('Invalid signature', { status: 401 });
  }

  // Step 3: Replay prevention - check event ID
  if (processedEvents.has(event.id)) {
    logSecurityEvent('webhook_replay_attempt', { eventId: event.id, ip: req.ip });
    return new Response('Event already processed', { status: 200 });
  }

  // Step 4: Timestamp validation (Stripe SDK validates within tolerance)
  const eventTimestamp = event.created * 1000;
  const maxAge = 5 * 60 * 1000; // 5 minutes
  if (Date.now() - eventTimestamp > maxAge) {
    logSecurityEvent('webhook_too_old', { eventId: event.id, age: Date.now() - eventTimestamp });
    return new Response('Event too old', { status: 400 });
  }

  // Step 5: Process event (with idempotency)
  try {
    await processStripeEvent(event);
    processedEvents.add(event.id); // In production: Redis SET with 24h TTL
  } catch (err) {
    // Return 500 so Stripe retries
    return new Response('Processing failed', { status: 500 });
  }

  return new Response('OK', { status: 200 });
}

async function checkAndBlockIP(ip: string) {
  const key = `webhook_failures:${ip}`;
  const count = await redis.incr(key);
  await redis.expire(key, 86400); // 24 hour window

  if (count >= 3) {
    await redis.sadd('blocked_ips', ip);
    alertSecurityTeam('IP_BLOCKED_WEBHOOK_ABUSE', { ip, failureCount: count });
  }
}
```

**Database-Level Protection (Firestore):**
```typescript
// Ensure idempotency with unique constraint check
async function createOrderFromWebhook(event: Stripe.PaymentIntent) {
  const ordersRef = firestore.collection('orders');

  // Check for existing order with this payment_intent_id
  const existing = await ordersRef
    .where('stripe_payment_intent_id', '==', event.id)
    .limit(1)
    .get();

  if (!existing.empty) {
    console.log('Order already exists for payment intent', event.id);
    return existing.docs[0].data(); // Idempotent return
  }

  // Create order - Firestore doesn't support unique constraints,
  // so use transaction with double-check
  return firestore.runTransaction(async (tx) => {
    // Double-check inside transaction
    const check = await tx.get(ordersRef.where('stripe_payment_intent_id', '==', event.id));
    if (!check.empty) {
      return check.docs[0].data();
    }

    const orderRef = ordersRef.doc();
    const order = {
      id: orderRef.id,
      stripe_payment_intent_id: event.id,
      // ... other fields
    };
    tx.set(orderRef, order);
    return order;
  });
}
```

---

## Input Validation Requirements

| Input | Validation |
|-------|------------|
| Email | RFC 5322 format; normalize (block +aliases) |
| Quantity | Integer 1-100 per item |
| Price/Amount | Server-calculated only; never trust client |
| Promo codes | Alphanumeric only; 6+ chars |
| Review text | Length limits; URL/phone detection; XSS escaping |

### Input Validation Implementation (REQUIRED PRE-LAUNCH)

**Validation Library:** Zod (TypeScript-native, compile-time type inference)

**Validation Layer:** API middleware (validate before handler executes)

**Schema Definitions:**
```typescript
import { z } from 'zod';

// Email with normalization
export const emailSchema = z.string()
  .email()
  .transform(email => {
    const [local, domain] = email.toLowerCase().split('@');
    // Normalize Gmail: remove dots, strip +suffix
    if (domain === 'gmail.com' || domain === 'googlemail.com') {
      const normalized = local.replace(/\./g, '').split('+')[0];
      return `${normalized}@gmail.com`;
    }
    // Strip +suffix for other providers
    return `${local.split('+')[0]}@${domain}`;
  });

// Product quantity
export const quantitySchema = z.number()
  .int()
  .min(1, 'Minimum quantity is 1')
  .max(100, 'Maximum quantity is 100');

// Promo code
export const promoCodeSchema = z.string()
  .min(6, 'Code must be at least 6 characters')
  .max(20)
  .regex(/^[A-Z0-9]+$/, 'Code must be uppercase alphanumeric')
  .transform(s => s.toUpperCase());

// Review text with XSS prevention
export const reviewTextSchema = z.string()
  .min(10, 'Review must be at least 10 characters')
  .max(1000, 'Review cannot exceed 1000 characters')
  .transform(text => sanitizeHtml(text, { allowedTags: [], allowedAttributes: {} }));

// Shipping address
export const addressSchema = z.object({
  name: z.string().min(1).max(100),
  line1: z.string().min(1).max(200),
  line2: z.string().max(200).optional(),
  city: z.string().min(1).max(100),
  state: z.string().length(2),
  postalCode: z.string().regex(/^\d{5}(-\d{4})?$/),
  country: z.literal('US'),
});

// Phone (E.164 format)
export const phoneSchema = z.string()
  .regex(/^\+1\d{10}$/, 'Phone must be US format: +1XXXXXXXXXX');
```

**Disposable Email Blocking:** Use `disposable-email-domains` npm package to reject known temporary email providers.

**Server-Side Validation Middleware:**
```typescript
function validateRequest<T>(schema: z.Schema<T>) {
  return async (req, res, next) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      return res.status(400).json({
        error: 'validation_error',
        details: result.error.flatten(),
      });
    }
    req.validated = result.data;
    next();
  };
}
```

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

### Secrets Rotation Procedures (REQUIRED PRE-LAUNCH)

**Automated Rotation Alerts:**
- 2 weeks before deadline: Email reminder to admin
- 1 week before: Slack alert + email
- Day of: Critical alert

**Rotation Procedure: Stripe API Key**
```
Pre-rotation (Day -7):
1. Create new restricted API key in Stripe dashboard
2. Add to GCP Secret Manager as version N+1
3. Deploy to staging with dual-key support
4. Run full integration test suite

Rotation (Day 0):
1. Deploy to production with dual-key config
2. Monitor for 24 hours:
   - Error rate < 0.1%
   - Payment success rate stable
   - No webhook failures
3. If stable, update config to use new key only

Post-rotation (Day +1):
1. Verify all services using new key
2. Revoke old key in Stripe dashboard
3. Delete old version from Secret Manager
4. Update rotation log

Rollback:
- If errors detected, revert to old key within 1 hour
- Do not revoke old key until new key verified
```

**Rotation Procedure: Webhook Secret**
```
CRITICAL: Webhook rotation requires zero-downtime strategy

Pre-rotation:
1. Generate new webhook endpoint in Stripe dashboard (same URL)
2. This creates a new signing secret
3. Add new secret to Secret Manager as version N+1

Rotation:
1. Deploy with BOTH secrets in array:
   const secrets = [process.env.WEBHOOK_SECRET_NEW, process.env.WEBHOOK_SECRET_OLD];
2. Verify signature against BOTH (accept if either matches)
3. Monitor for 48 hours (webhooks can retry for 3 days)
4. After 48h stable, remove old webhook endpoint from Stripe
5. Update config to single new secret

Rollback:
- Keep old endpoint active until new verified
- Old webhooks continue working during transition
```

**Rotation Procedure: JWT Secret**
```
CRITICAL: JWT rotation invalidates ALL existing sessions

Pre-rotation:
1. Choose rotation window (low-traffic period, 2-4 AM)
2. Notify admins of brief re-auth requirement
3. Add new secret to Secret Manager

Rotation:
1. Deploy with dual-secret validation:
   - Sign new tokens with NEW secret
   - Verify tokens against BOTH secrets
2. After 48 hours (max session lifetime), remove old secret
3. All old tokens now invalid (by design)

Alternative: Gradual rotation
- Generate new tokens with new secret
- Accept both for 48 hours
- Sessions refresh naturally
```

**Rotation Log Template:**
```yaml
rotation:
  secret: STRIPE_SECRET_KEY
  date: 2026-01-15
  performed_by: admin@goldenhoney.co
  staging_verified: true
  production_deployed: 2026-01-15T14:00:00Z
  old_key_revoked: 2026-01-16T14:00:00Z
  issues: none
  next_rotation: 2026-04-15
```

**Testing Rotation (Quarterly):**
- Rotate one secret per quarter in staging
- Document any issues encountered
- Update procedures based on learnings

---

## Pre-Launch Checklist

- [ ] **Admin 2FA (TOTP)** - All admin accounts must have 2FA enabled
- [ ] **Rate limiting** implemented per specification (Cloud Armor or Redis)
- [ ] **Input validation** schemas deployed on all endpoints (Zod)
- [ ] **CSRF protection** enabled on all state-changing endpoints
- [ ] **Webhook signature verification** with constant-time comparison and replay prevention
- [ ] **Secrets rotation procedures** documented and tested in staging
- [ ] Security headers configured and validated (securityheaders.com)
- [ ] All authorization checks reviewed and tested
- [ ] Security alerts configured in Cloud Monitoring
- [ ] OWASP ZAP scan completed with no critical findings
- [ ] Dependency vulnerability scan clean (npm audit, Dependabot)

## Post-Launch (30 Days)

- [ ] Automated dependency scanning in CI/CD pipeline
- [ ] Internal penetration test completed
- [ ] Security runbooks documented (incident response per threat)
- [ ] First secrets rotation executed successfully
- [ ] Security metrics dashboard operational

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
