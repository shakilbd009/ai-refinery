# Production Checklist Output Format

Template and structure for generated checklists.

## File Header

```markdown
# Production Readiness Checklist

Generated from design docs on {YYYY-MM-DD}.
Check off items as you implement.
```

## Category Sections

Each category gets its own section with items as checkboxes:

```markdown
## {Category Name}
- [ ] {Actionable item with specifics}
- [ ] {Actionable item with specifics}
```

## Category Order

Fixed order for consistency:

1. Infrastructure
2. Security
3. Integrations
4. Monitoring
5. Testing
6. Compliance

**Skip empty categories.** If no items extracted for a category, omit it entirely.

## Item Format

### Structure

```
- [ ] {Verb} {object} {details in parentheses}
```

### Examples

```markdown
- [ ] Deploy Go API to Cloud Run
- [ ] Implement rate limiting (100 req/min per IP)
- [ ] Configure SendGrid for transactional email
- [ ] Set up error alerting (5xx > 1% triggers page)
- [ ] Test: reservation expires during checkout
- [ ] Verify PCI SAQ-A compliance (Stripe handles card data)
```

### Action Verbs

Use consistent verbs:

| Verb | Use For |
|------|---------|
| Deploy | Deploying services |
| Provision | Creating infrastructure resources |
| Configure | Setting up existing services |
| Implement | Writing new code |
| Set up | Initial configuration |
| Connect | Third-party integrations |
| Enable | Turning on features |
| Create | Dashboards, alerts, indexes |
| Test | Test scenarios |
| Verify | Compliance checks |

## Full Template

```markdown
# Production Readiness Checklist

Generated from design docs on {YYYY-MM-DD}.
Check off items as you implement.

## Infrastructure
- [ ] {item}
- [ ] {item}

## Security
- [ ] {item}
- [ ] {item}

## Integrations
- [ ] {item}
- [ ] {item}

## Monitoring
- [ ] {item}
- [ ] {item}

## Testing
- [ ] {item}
- [ ] {item}

## Compliance
- [ ] {item}
- [ ] {item}
```

## Example Complete Checklist

```markdown
# Production Readiness Checklist

Generated from design docs on 2026-01-26.
Check off items as you implement.

## Infrastructure
- [ ] Deploy Go API to Cloud Run
- [ ] Deploy Next.js frontend to Cloud Run
- [ ] Provision Firestore database
- [ ] Configure Cloud Storage bucket for product images

## Security
- [ ] Implement rate limiting (100 req/min per IP)
- [ ] Configure CORS for production domain
- [ ] Set up JWT token rotation (24h expiry)
- [ ] Enable HTTPS-only cookies
- [ ] Store API keys in Secret Manager

## Integrations
- [ ] Connect Stripe payment processing
- [ ] Configure SendGrid for transactional email
- [ ] Set up Cloud Storage SDK for image uploads

## Monitoring
- [ ] Set up error alerting (5xx > 1% triggers page)
- [ ] Configure P95 latency dashboards
- [ ] Enable structured logging to Cloud Logging
- [ ] Create order creation success rate alert

## Testing
- [ ] Test: reservation expires during checkout
- [ ] Test: promo code expires during payment
- [ ] Test: payment succeeds but order creation fails
- [ ] Test: concurrent inventory reservations
- [ ] Test: discount code at usage limit

## Compliance
- [ ] Implement GDPR data export endpoint
- [ ] Add cookie consent banner
- [ ] Verify PCI SAQ-A compliance (Stripe handles card data)
- [ ] Test WCAG 2.1 AA accessibility
```

## Output Locations

| Context | Output Path |
|---------|-------------|
| Standalone `/production-checklist` | `ideas/<idea-name>/07-curated/production-checklist.md` |
| Via `/graduate` | `<target-path>/docs/production-checklist.md` |

## Item Count Guidelines

Aim for balanced sections:

| Category | Typical Count | Too Few | Too Many |
|----------|---------------|---------|----------|
| Infrastructure | 3-6 | <2 | >10 |
| Security | 4-8 | <3 | >12 |
| Integrations | 2-5 | 0 OK | >8 |
| Monitoring | 3-6 | <2 | >10 |
| Testing | 4-10 | <3 | >15 |
| Compliance | 2-6 | 0 OK | >10 |

If a category has too many items, consider:
- Are items too granular? Combine related items.
- Are items duplicated? Deduplicate.
- Is the design overly complex? Flag for review.
