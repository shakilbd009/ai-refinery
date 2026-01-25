# GDPR Compliance Requirements

**Project:** Manik Golden Honey Co
**Stage:** L3 (Refine L3 - Exhaustive Coverage)
**Date:** 2026-01-25

---

## Applicability

Even as a US-based business, GDPR applies when processing personal data of EU residents. Compliance is required if EU customers access the site.

---

## 1. Data Collection Disclosure

**Requirement:** Inform users at point of collection what data is collected and why.

### Checkout Form Disclosure
```
We collect this information to:
- Process and ship your order
- Send order confirmations and shipping updates
- Contact you if there are issues with your order

See our Privacy Policy for complete details.
```

### Account Registration Disclosure
```
Creating an account stores your:
- Email address (for login and communications)
- Name (for order personalization)
- Shipping address (to pre-fill checkout)

You can delete your account at any time.
```

### Newsletter Signup Disclosure
```
By subscribing, you consent to receive:
- New product announcements
- Special offers and discounts
- Honey tips and recipes

Unsubscribe anytime via the link in each email.
```

---

## 2. Data Retention Policy

**Principle:** Retain data only as long as necessary for the purpose collected.

| Data Category | Retention Period | Justification |
|---------------|------------------|---------------|
| **Order Data** | 7 years | Tax/accounting legal requirement (IRS) |
| **Customer Accounts** | Until deletion requested + 30 days | Active service provision |
| **Payment Intent IDs** | 7 years | Dispute resolution, tax records |
| **Email Marketing Consent** | Until unsubscribe + 90 days | Compliance proof |
| **Auth Tokens** | 48 hours | Passwordless login functionality |
| **Session Data** | 30 days | User experience (cart persistence) |
| **Analytics Data** | 26 months | GA4 default, business insights |
| **Review History** | 7 years or account deletion | Audit trail for moderation disputes |
| **Cancellation Requests** | 7 years | Dispute resolution records |
| **IP Addresses (spam)** | 90 days | Fraud prevention |
| **Soft-Deleted Data** | 90 days | Recovery window, then hard delete |

### Automated Cleanup Jobs

```
Daily job (02:00 UTC):
- DELETE auth_tokens WHERE expires_at < now - 48 hours
- DELETE sessions WHERE last_active < now - 30 days

Weekly job (Sunday 03:00 UTC):
- DELETE soft_deleted_records WHERE deleted_at < now - 90 days
- DELETE ip_spam_logs WHERE logged_at < now - 90 days

Annual job (January 1):
- Archive orders older than 7 years (export to cold storage)
- Delete analytics data older than 26 months
```

---

## 3. Data Deletion Procedures (Right to Erasure)

**GDPR Article 17:** Data subjects can request deletion of their personal data.

### Request Channels
1. **Self-Service:** Account Settings > "Delete My Account" button
2. **Email:** privacy@manikgoldenhoney.com
3. **Contact Form:** Subject "Data Deletion Request"

### Verification Process
```
1. Customer initiates deletion request
2. Send confirmation email: "Please confirm account deletion"
3. Customer clicks confirmation link (expires in 24 hours)
4. 30-day cooling-off period begins
5. Customer can cancel during cooling-off period
6. After 30 days: Execute deletion
```

### Deletion Scope

| Data | Action | Retention Exception |
|------|--------|---------------------|
| Customer profile | Hard delete | None |
| Email address | Hard delete | Retained in orders (legal) |
| Shipping addresses | Hard delete | Retained in orders (legal) |
| Order history | Anonymize | Order records required 7 years |
| Reviews | Anonymize | Display as "Deleted User" |
| Cart data | Hard delete | None |
| Session data | Hard delete | None |
| Auth tokens | Hard delete | None |
| Marketing consent | Hard delete | Unsubscribe proof retained |

### Order Anonymization
```json
// Before
{
  "customerId": "cust_abc123",
  "customerEmail": "john@example.com",
  "shippingAddress": { "street": "123 Main St", ... }
}

// After anonymization
{
  "customerId": "DELETED",
  "customerEmail": "[email deleted]",
  "shippingAddress": { "street": "[address deleted]", ... }
}
```

### Response Timeline
- Acknowledge request: Within 72 hours
- Complete deletion: Within 30 days (GDPR requirement)
- Confirmation email: Upon completion

---

## 4. Data Export Procedures (Right to Portability)

**GDPR Article 20:** Data subjects can request their data in machine-readable format.

### Request Process
```
1. Customer requests export via Account Settings or email
2. Verify identity (send confirmation code to registered email)
3. Generate export package (JSON + CSV formats)
4. Send secure download link (expires in 7 days)
5. Log export request for compliance records
```

### Export Package Contents

```
data-export-2026-01-25/
├── profile.json           # Customer profile data
├── orders.json            # Complete order history
├── orders.csv             # Spreadsheet-friendly format
├── reviews.json           # All submitted reviews
├── preferences.json       # Marketing consent, settings
├── activity-log.json      # Login history, actions
└── README.txt             # Explanation of contents
```

### Sample profile.json
```json
{
  "exportDate": "2026-01-25T10:00:00Z",
  "dataSubject": {
    "id": "cust_abc123",
    "email": "john@example.com",
    "name": "John Doe",
    "phone": "+1-555-0100",
    "createdAt": "2025-06-15T14:30:00Z"
  },
  "shippingAddresses": [
    {
      "street": "123 Main St",
      "city": "Springfield",
      "state": "IL",
      "zip": "62701",
      "isDefault": true
    }
  ],
  "marketingConsent": {
    "email": true,
    "consentedAt": "2025-06-15T14:31:00Z"
  }
}
```

### Response Timeline
- Acknowledge request: Within 72 hours
- Deliver export: Within 30 days (GDPR requirement)

---

## 5. Marketing Consent Requirements

**GDPR Article 7:** Consent must be freely given, specific, informed, and unambiguous.

### Newsletter Signup
- **Explicit opt-in required:** Unchecked checkbox, user must actively select
- **No pre-checked boxes:** GDPR prohibits assumed consent
- **Clear language:** "Yes, I want to receive marketing emails about new products and offers"
- **Easy withdrawal:** Every email includes unsubscribe link
- **Double opt-in:** Confirmation email with verification link

### Checkout Marketing Checkbox
```
[ ] Keep me updated about new products and special offers (optional)

Your email will only be used for order updates unless you check this box.
```

### Consent Record
```json
{
  "customerId": "cust_abc123",
  "consentType": "email_marketing",
  "consented": true,
  "consentedAt": "2026-01-25T14:30:00Z",
  "source": "checkout_form",
  "ipAddress": "192.168.1.1",
  "userAgent": "Mozilla/5.0...",
  "withdrawnAt": null
}
```

### Unsubscribe Process
1. Click unsubscribe link in email
2. Immediate removal from marketing lists (no confirmation required)
3. Show confirmation page: "You've been unsubscribed"
4. Update consent record with `withdrawnAt` timestamp
5. Continue sending transactional emails (order confirmations, shipping updates)

---

## 6. Cookie Consent Requirements

### Cookie Consent Banner

**First Visit Banner:**
```
+------------------------------------------------------------------+
|                                                                  |
|  We use cookies to improve your experience.                      |
|                                                                  |
|  Essential cookies keep the site working. Analytics cookies      |
|  help us understand how you use our site.                        |
|                                                                  |
|  [Accept All]  [Essential Only]  [Customize]                     |
|                                                                  |
|  Learn more in our Cookie Policy                                 |
|                                                                  |
+------------------------------------------------------------------+
```

### Cookie Categories

**Essential Cookies (No consent required):**
| Cookie Name | Purpose | Duration |
|-------------|---------|----------|
| `session_id` | Identify user session | Browser session |
| `cart_id` | Shopping cart contents | 30 days |
| `csrf_token` | Security protection | Browser session |
| `cookie_consent` | Remember preferences | 1 year |

**Analytics Cookies (Consent required):**
| Cookie Name | Purpose | Duration |
|-------------|---------|----------|
| `_ga` | Distinguish users | 2 years |
| `_ga_*` | Store session state | 2 years |
| `_gid` | Distinguish users | 24 hours |

### Consent Implementation
```javascript
// Only load GA4 after consent
if (hasAnalyticsConsent()) {
  gtag('consent', 'update', { 'analytics_storage': 'granted' });
} else {
  gtag('consent', 'default', { 'analytics_storage': 'denied' });
}
```

### Opt-Out Mechanisms
- Cookie Settings page (accessible from footer)
- Google Analytics opt-out browser add-on
- Do Not Track header respected

---

**Last Updated:** 2026-01-25
**Related Documents:** [compliance-overview.md](./compliance-overview.md)
