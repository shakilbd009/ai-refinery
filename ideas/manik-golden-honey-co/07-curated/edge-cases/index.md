# Edge Cases Index

Comprehensive edge case coverage organized by category.

## Categories

| Category | File | Coverage |
|----------|------|----------|
| [Data Boundaries](./data-boundaries.md) | Empty/null values, max/min limits, special characters, type mismatches | Input validation |
| [State Transitions](./state-transitions.md) | Invalid transitions, race conditions, orphaned states, recovery | State machines |
| [Timing](./timing.md) | Timeouts, expiration, clock skew, DST, concurrent operations | Temporal edge cases |
| [Integration](./integration.md) | Service outages, slow responses, rate limits, webhook failures | External dependencies |

## Quick Reference

### Data Boundaries
- **Empty inputs:** All fields validated for null/empty
- **Maximum values:** Quantity 100/item, 50 items/cart, prices in cents
- **Special characters:** Unicode allowed, SQL/XSS prevented
- **Type coercion:** String-to-number with validation

### State Transitions
- **Order states:** pending → confirmed → shipped → delivered (no backwards)
- **Reservation states:** active → completing → completed/expired
- **Review states:** pending → approved/rejected
- **Race prevention:** Firestore transactions with conflict retry

### Timing
- **Reservation TTL:** 15 minutes
- **Promo code grace:** 5 minutes after expiration
- **Session timeout:** 30 minutes
- **Webhook retry:** Up to 3 days (Stripe automatic)

### Integration
- **Stripe down:** No fallback (critical path), retry with backoff
- **Mailgun down:** Queue for retry, non-blocking
- **Firestore down:** Site unavailable (no fallback for MVP)
- **Rate limits:** Exponential backoff (1s, 2s, 4s)

## Testing Priority

**Critical (must test):**
1. Two customers checkout last item simultaneously
2. Reservation expires during payment
3. Webhook and frontend create order simultaneously
4. Promo code expires during checkout

**High (should test):**
1. Admin updates inventory while customer reserves
2. Multiple browser tabs with same cart
3. Payment timeout and retry
4. Service degradation scenarios

**Medium (good to test):**
1. DST transitions for expiration
2. Unicode in all text fields
3. Maximum cart size (50 items)
4. Cleanup job crash recovery
