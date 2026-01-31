# Curation Examples

Concrete examples of transforming source artifacts into curated output.

## Example 1: Curating Overview

**Source (stage-1/idea.md excerpt):**
```markdown
# Honey E-commerce Platform

## Problem
Local honey producers struggle to reach customers online...

## Solution
A specialized e-commerce platform for artisan honey...

## Target Users
- Small-batch honey producers
- Health-conscious consumers
```

**Output (07-curated/overview.md):**
```markdown
# Honey E-commerce Platform

## Executive Summary
A specialized e-commerce platform connecting artisan honey producers with health-conscious consumers. Solves the market gap where local producers lack online sales channels.

## Vision
Enable small-batch honey producers to sell directly to consumers with minimal technical overhead.

## Key Stakeholders
| Role | Description |
|------|-------------|
| Producers | Small-batch honey makers (1-100 hives) |
| Consumers | Health-conscious buyers seeking local products |
| Platform | Marketplace operator handling payments/logistics |
```

---

## Example 2: Merging L1+L2+L3 into Component Doc

**Sources:**
- `04-design-l1/checkout-L1.md`: Basic checkout flow description
- `05-design-l2/checkout-L2.md`: Payment integration details, state machine
- `06-design-l3/checkout-L3.md`: Race conditions, failure modes, retry logic

**Output (07-curated/architecture/components/checkout.md):**
```markdown
# Component: Checkout

## Overview
Handles cart-to-order conversion with payment processing.

## Design
### State Machine
`cart` → `payment_pending` → `payment_confirmed` → `order_placed`

### Payment Integration
Uses Stripe PaymentIntents with idempotency keys...

## Implementation Details
### Idempotency
Each checkout attempt generates UUID stored in session...

### Retry Logic
Failed payments retry 3x with exponential backoff (1s, 2s, 4s)...

## Edge Cases
| Scenario | Handling |
|----------|----------|
| Payment timeout | Mark pending, retry with same idempotency key |
| Duplicate submission | Return existing order via idempotency lookup |

## Failure Modes
| Failure | Detection | Recovery |
|---------|-----------|----------|
| Stripe outage | 503 response | Queue for retry, notify user |
| Race condition | Optimistic lock failure | Reload cart, retry |
```

---

## Example 3: Splitting Edge Cases by Category

**Source (06-design-l3/edge-cases-comprehensive.md):**
```markdown
## All Edge Cases
- Empty cart checkout → block with message
- 100+ items in cart → paginate, warn about shipping
- Concurrent cart updates → last-write-wins with conflict UI
- Payment timeout after 30s → mark pending, email user
- Special chars in address → sanitize, preserve unicode
```

**Output (07-curated/edge-cases/data-boundaries.md):**
```markdown
# Edge Cases: Data Boundaries

## Empty/Null Values
| Scenario | Handling | Test |
|----------|----------|------|
| Empty cart checkout | Block with "Add items first" message | `test_empty_cart_blocked` |

## Maximum Values
| Scenario | Handling | Test |
|----------|----------|------|
| 100+ cart items | Paginate display, shipping cost warning | `test_large_cart_pagination` |

## Special Characters
| Scenario | Handling | Test |
|----------|----------|------|
| Unicode in address | Sanitize dangerous chars, preserve unicode | `test_unicode_address` |
```

**Output (07-curated/edge-cases/state-transitions.md):**
```markdown
# Edge Cases: State Transitions

## Concurrent Operations
| Scenario | Handling | Test |
|----------|----------|------|
| Concurrent cart updates | Last-write-wins with conflict notification UI | `test_concurrent_cart_conflict` |
```

**Output (07-curated/edge-cases/timing.md):**
```markdown
# Edge Cases: Timing

## Timeouts
| Scenario | Handling | Test |
|----------|----------|------|
| Payment timeout (30s) | Mark as pending, send status email to user | `test_payment_timeout_recovery` |
```
