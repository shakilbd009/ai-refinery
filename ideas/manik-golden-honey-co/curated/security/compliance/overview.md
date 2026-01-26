# Compliance Overview

This document summarizes compliance requirements for the Manik Golden Honey Co e-commerce platform.

## Applicable Regulations

| Regulation | Scope | Details |
|------------|-------|---------|
| GDPR | EU visitors | Data collection, retention, deletion, export, consent |
| CCPA | California residents | Consumer privacy rights |
| PCI DSS | Payment processing | Stripe integration obligations |
| ADA/WCAG 2.1 AA | All users | Web accessibility standards |
| FTC Act | All US customers | Consumer protection disclosures |

## Related Documents

- [gdpr.md](./gdpr.md) - Data protection compliance
- [pci.md](./pci.md) - Payment card security
- [accessibility.md](./accessibility.md) - WCAG 2.1 AA requirements

## Data Retention Summary

| Data Category | Retention Period |
|---------------|------------------|
| Order Data | 7 years (IRS requirement) |
| Customer Accounts | Until deletion + 30 days |
| Auth Tokens | 48 hours |
| Session Data | 30 days |
| Analytics Data | 26 months |
| Soft-Deleted Data | 90 days |

## Response Timelines

| Request Type | Acknowledge | Complete |
|--------------|-------------|----------|
| Data Deletion | 72 hours | 30 days |
| Data Export | 72 hours | 30 days |
| Privacy Inquiry | 72 hours | - |

## Accessibility Targets

| Metric | Target |
|--------|--------|
| Lighthouse Score | >= 90 |
| axe-core Violations | 0 |
| Color Contrast | 4.5:1 (text), 3:1 (large/UI) |

## Privacy Policy Summary

The privacy policy must disclose:

**Data Collected:**
- Account information (email, name, phone)
- Shipping addresses
- Order history and payment confirmations (via Stripe)
- Product reviews
- Browsing behavior (with consent)

**Data Usage:**
- Order fulfillment and shipping
- Account management
- Transactional and marketing communications (with consent)
- Site analytics and improvement
- Fraud prevention

**Third-Party Sharing:**
- Stripe (payment processing)
- SendGrid/Mailgun (transactional email)
- Google Analytics (site analytics)
- Google Cloud Platform (hosting)
- Cloudflare (CDN, DDoS protection)

**Key Commitments:**
- No selling of personal data
- No sharing with advertisers
- All processors have signed DPAs

## Terms of Service Summary

The terms of service must cover:

**Order Policies:**
- Cancellation allowed before shipping; 24-hour review period
- Refunds for damaged/defective products within 14 days
- 30-day return window for unopened products
- 5-7 business day refund processing

**Shipping:**
- Standard (5-7 days), Express (2-3 days), Local Pickup options
- US addresses only
- Orders before 2 PM ET ship same day

**Review Guidelines:**
- Honest product opinions only
- No personal information or external links
- Moderation within 24 hours

**Liability:**
- Limited to purchase price or $100
- No liability for allergic reactions, carrier delays, force majeure
- Honey not for children under 1 year old

**Disputes:**
- Informal resolution first
- Binding arbitration if unresolved
- Class action waiver
- 1-year statute of limitations

## Implementation Phases

**Phase 1 - Legal Documents:** Draft and publish Privacy Policy, Terms of Service, Cookie Policy to `/privacy`, `/terms`, `/cookies` pages.

**Phase 2 - Technical Implementation:** Cookie consent banner, GA4 consent mode, data export/deletion endpoints.

**Phase 3 - Accessibility:** axe-core CI integration, skip-to-content link, form accessibility, keyboard navigation testing.

**Phase 4 - Verification:** SAQ A questionnaire, WCAG audit, data flow testing, compliance documentation.
