# Compliance & Legal Requirements - Overview

**Project:** Manik Golden Honey Co
**Stage:** L3 (Refine L3 - Exhaustive Coverage)
**Date:** 2026-01-25

---

## Overview

This document set specifies compliance and legal requirements for the Manik Golden Honey Co e-commerce platform. While primarily US-based, the platform must address international privacy regulations (GDPR) for potential EU visitors, payment card industry standards, accessibility requirements, and consumer protection disclosures.

**Applicable Regulations:**
- GDPR (EU General Data Protection Regulation) - for EU visitors
- CCPA (California Consumer Privacy Act) - for California residents
- PCI DSS (Payment Card Industry Data Security Standard)
- ADA/WCAG 2.1 AA (Web Content Accessibility Guidelines)
- FTC Act (Federal Trade Commission consumer protection)

---

## Document Structure

Compliance requirements are split into focused documents:

| Document | Contents |
|----------|----------|
| [compliance-gdpr.md](./compliance-gdpr.md) | GDPR compliance: data collection, retention, deletion, export, consent |
| [compliance-pci.md](./compliance-pci.md) | PCI compliance: Stripe responsibilities, our obligations, SAQ A checklist |
| [compliance-privacy-policy.md](./compliance-privacy-policy.md) | Privacy policy requirements: data collected, usage, third parties, cookies |
| [compliance-terms-of-service.md](./compliance-terms-of-service.md) | ToS requirements: cancellation, refunds, shipping, reviews, liability |
| [compliance-accessibility.md](./compliance-accessibility.md) | WCAG 2.1 AA: forms, images, keyboard, contrast, testing |

---

## Implementation Checklist

### Phase 1: Legal Documents (Week 1)
- [ ] Draft Privacy Policy
- [ ] Draft Terms of Service
- [ ] Draft Cookie Policy
- [ ] Legal review of all documents
- [ ] Publish to `/privacy`, `/terms`, `/cookies` pages

### Phase 2: Technical Implementation (Week 2-3)
- [ ] Cookie consent banner implementation
- [ ] GA4 consent mode integration
- [ ] Data export endpoint (`/api/customer/export`)
- [ ] Account deletion endpoint (`/api/customer/delete`)
- [ ] Soft-delete implementation for customer data

### Phase 3: Accessibility (Week 3-4)
- [ ] Axe-core integration in CI/CD
- [ ] Fix existing accessibility violations
- [ ] Add skip-to-content link
- [ ] Verify all form labels and error messages
- [ ] Test keyboard navigation on all pages
- [ ] Screen reader testing of checkout flow

### Phase 4: Verification (Week 4)
- [ ] Complete SAQ A questionnaire
- [ ] Full WCAG 2.1 AA audit
- [ ] Privacy policy completeness review
- [ ] Test data export and deletion flows
- [ ] Document all compliance procedures

---

## Quick Reference

### Data Retention Summary

| Data Category | Retention Period |
|---------------|------------------|
| Order Data | 7 years (IRS requirement) |
| Customer Accounts | Until deletion + 30 days |
| Auth Tokens | 48 hours |
| Session Data | 30 days |
| Analytics Data | 26 months |
| Soft-Deleted Data | 90 days |

### Key Response Timelines

| Request Type | Acknowledge | Complete |
|--------------|-------------|----------|
| Data Deletion | 72 hours | 30 days |
| Data Export | 72 hours | 30 days |
| Privacy Inquiry | 72 hours | - |

### Accessibility Targets

| Metric | Target |
|--------|--------|
| Lighthouse Score | >= 90 |
| axe-core Violations | 0 |
| Color Contrast | 4.5:1 (text), 3:1 (large/UI) |

---

**Last Updated:** 2026-01-25
**Stage:** L3
**Status:** Complete - Compliance requirements documented
**Next Review:** Before launch, then annually
