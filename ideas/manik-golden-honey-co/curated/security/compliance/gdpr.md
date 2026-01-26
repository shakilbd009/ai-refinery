# GDPR Compliance

GDPR applies when processing personal data of EU residents. This document specifies requirements for data collection disclosure, retention, deletion, export, and consent.

## Data Collection Disclosure

Display clear disclosures at the point of data collection.

**Checkout Form:**
```
We collect this information to:
- Process and ship your order
- Send order confirmations and shipping updates
- Contact you if there are issues with your order

See our Privacy Policy for complete details.
```

**Account Registration:**
```
Creating an account stores your:
- Email address (for login and communications)
- Name (for order personalization)
- Shipping address (to pre-fill checkout)

You can delete your account at any time.
```

**Newsletter Signup:**
```
By subscribing, you consent to receive:
- New product announcements
- Special offers and discounts
- Honey tips and recipes

Unsubscribe anytime via the link in each email.
```

## Data Retention Policy

| Data Category | Retention Period | Justification |
|---------------|------------------|---------------|
| Order Data | 7 years | Tax/accounting legal requirement |
| Customer Accounts | Until deletion + 30 days | Active service provision |
| Payment Intent IDs | 7 years | Dispute resolution, tax records |
| Email Marketing Consent | Until unsubscribe + 90 days | Compliance proof |
| Auth Tokens | 48 hours | Passwordless login functionality |
| Session Data | 30 days | Cart persistence |
| Analytics Data | 26 months | Business insights |
| Review History | 7 years or account deletion | Audit trail |
| IP Addresses (spam) | 90 days | Fraud prevention |
| Soft-Deleted Data | 90 days | Recovery window |

**Automated Cleanup Jobs:**
- Daily (02:00 UTC): Delete expired auth tokens and inactive sessions
- Weekly (Sunday 03:00 UTC): Hard delete soft-deleted records and spam logs older than 90 days
- Annual (January 1): Archive orders older than 7 years, delete analytics older than 26 months

## Data Deletion (Right to Erasure)

**Request Channels:**
1. Self-Service: Account Settings > "Delete My Account"
2. Email: privacy@manikgoldenhoney.com
3. Contact Form: Subject "Data Deletion Request"

**Process:**
1. Customer initiates deletion request
2. Confirmation email sent (24-hour link expiry)
3. 30-day cooling-off period begins
4. Customer can cancel during cooling-off
5. After 30 days: Execute deletion

**Deletion Scope:**

| Data | Action | Exception |
|------|--------|-----------|
| Customer profile | Hard delete | None |
| Email address | Hard delete | Retained in orders (legal) |
| Shipping addresses | Hard delete | Retained in orders (legal) |
| Order history | Anonymize | Order records required 7 years |
| Reviews | Anonymize | Display as "Deleted User" |
| Cart/session/auth data | Hard delete | None |
| Marketing consent | Hard delete | Unsubscribe proof retained |

**Order Anonymization Format:**
```json
{
  "customerId": "DELETED",
  "customerEmail": "[email deleted]",
  "shippingAddress": { "street": "[address deleted]" }
}
```

**Response Timeline:**
- Acknowledge: Within 72 hours
- Complete: Within 30 days
- Confirmation email upon completion

## Data Export (Right to Portability)

**Process:**
1. Request via Account Settings or email
2. Verify identity (confirmation code to registered email)
3. Generate export package (JSON + CSV)
4. Send secure download link (7-day expiry)
5. Log request for compliance records

**Export Package Contents:**
```
data-export-YYYY-MM-DD/
  profile.json        # Customer profile data
  orders.json         # Complete order history
  orders.csv          # Spreadsheet format
  reviews.json        # Submitted reviews
  preferences.json    # Marketing consent, settings
  activity-log.json   # Login history, actions
  README.txt          # Explanation of contents
```

**Response Timeline:**
- Acknowledge: Within 72 hours
- Deliver: Within 30 days

## Marketing Consent

**Requirements:**
- Explicit opt-in: Unchecked checkbox, user must actively select
- No pre-checked boxes
- Clear language: "Yes, I want to receive marketing emails about new products and offers"
- Double opt-in: Confirmation email with verification link
- Easy withdrawal: Unsubscribe link in every email

**Checkout Checkbox:**
```
[ ] Keep me updated about new products and special offers (optional)

Your email will only be used for order updates unless you check this box.
```

**Consent Record Schema:**
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

**Unsubscribe Process:**
1. Click unsubscribe link (no confirmation required)
2. Immediate removal from marketing lists
3. Show confirmation page
4. Update consent record with `withdrawnAt` timestamp
5. Continue sending transactional emails

## Cookie Consent

**Banner Layout:**
```
+------------------------------------------------------------------+
|  We use cookies to improve your experience.                       |
|  Essential cookies keep the site working. Analytics cookies       |
|  help us understand how you use our site.                         |
|                                                                   |
|  [Accept All]  [Essential Only]  [Customize]                      |
|  Learn more in our Cookie Policy                                  |
+------------------------------------------------------------------+
```

**Essential Cookies (No consent required):**

| Cookie | Purpose | Duration |
|--------|---------|----------|
| `session_id` | Identify user session | Session |
| `cart_id` | Shopping cart contents | 30 days |
| `csrf_token` | Security protection | Session |
| `cookie_consent` | Remember preferences | 1 year |

**Analytics Cookies (Consent required):**

| Cookie | Purpose | Duration |
|--------|---------|----------|
| `_ga` | Distinguish users | 2 years |
| `_ga_*` | Store session state | 2 years |
| `_gid` | Distinguish users | 24 hours |

**Implementation:**
```javascript
if (hasAnalyticsConsent()) {
  gtag('consent', 'update', { 'analytics_storage': 'granted' });
} else {
  gtag('consent', 'default', { 'analytics_storage': 'denied' });
}
```

**Opt-Out Mechanisms:**
- Cookie Settings page (accessible from footer)
- Google Analytics opt-out browser add-on
- Do Not Track header respected
