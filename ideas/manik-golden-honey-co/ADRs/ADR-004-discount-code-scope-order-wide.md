# ADR-004: Order-Wide Discount Codes (Not Product-Specific)

## Status

Accepted

---

## Context

Discount codes (promo codes) are a common e-commerce feature for marketing campaigns, launches, and customer acquisition. The scope of discount application can vary:
- **Order-wide**: Discount applies to entire cart total
- **Product-specific**: Discount applies only to selected products
- **Category-specific**: Discount applies to product categories

For MVP with single product category (honey only), deciding the discount scope affects implementation complexity and marketing flexibility.

**Key factors:**
- Single product category for MVP (all honey products)
- Small product catalog expected (< 20 SKUs initially)
- Simple pricing model (no tiered pricing, bundles, or subscriptions)
- Admin is not technical (simpler UI needed)
- Marketing campaigns likely to be simple ("10% off everything" for launch)

---

## Decision

Discount codes apply **order-wide only** (entire cart total).

**Examples:**
- "LAUNCH10" = 10% off entire order
- "HONEY15" = 15% off everything in cart
- "SPRING20" = 20% off total purchase

**Not supported in MVP:**
- Product-specific codes ("WILDFLOWER15" applies only to Wildflower Honey)
- Tiered discounts ("10% off if > $50, 15% if > $100")
- Buy-one-get-one (BOGO) promotions
- Free shipping codes

---

## Consequences

### Positive

- **Simplest implementation**: Single percentage calculation on cart total
- **Simple admin UI**: Create code, set percentage, set restrictions (min order, expiration, etc.)
- **Clear customer UX**: Discount applies to everything (no confusion about eligibility)
- **Fast development**: No product tagging, filtering, or eligibility logic needed
- **Easier testing**: Fewer edge cases to validate
- **Marketing simplicity**: "X% off your entire order" is clear messaging

### Negative

- **Limited marketing flexibility**: Can't run product-specific promotions ("Try our new Clover Honey - 20% off!")
- **All-or-nothing discounts**: Can't incentivize purchase of slow-moving products specifically
- **No upsell mechanics**: Can't offer "Add $10 more to get free shipping"
- **Margin impact**: Discount applies to all products (even high-margin ones)
- **Competitive disadvantage**: Other honey sellers may offer more sophisticated promotions

### Neutral

- Product catalog growth may require product-specific codes later (revisit in 6 months)
- Can still run effective campaigns with order-wide discounts
- Discount stacking not addressed (out of scope for MVP)

---

## Alternatives Considered

### Alternative 1: Product-Specific Discount Codes

**Why considered:**
- **Marketing flexibility**: Target specific products for promotion
- **Inventory management**: Move slow-selling products with targeted discounts
- **Higher perceived value**: "20% off this special variety" feels more exclusive
- **Industry standard**: Many e-commerce platforms support this

**Why rejected:**
- **Implementation complexity**: Requires product tagging/categorization system
- **Admin UI complexity**: Must select eligible products when creating code
- **Validation complexity**: Must check cart items against eligible products at checkout
- **Edge case handling**: What if customer removes eligible item after applying code?
- **Testing burden**: Many more scenarios to test (eligible/ineligible product combinations)
- **MVP timeline impact**: +1-2 weeks development time
- **Limited value for MVP**: Single product category (honey) means all products are similar

### Alternative 2: Tiered Order Value Discounts

**Why considered:**
- **Upselling**: Incentivizes larger orders ("Spend $50, get 15% off")
- **Average order value**: Increases AOV through discount gamification
- **Common pattern**: "Free shipping over $X" is very common

**Why rejected:**
- **More complex**: Requires threshold checking + multiple discount tiers
- **Customer confusion**: "I'm at $48, should I add $2 to get discount?"
- **Admin UI complexity**: Must configure multiple tiers per code
- **Not requested**: No requirement for this in MVP scope
- **Can be added later**: Not mutually exclusive with order-wide codes

### Alternative 3: Discount Code Types (Percentage + Fixed Amount)

**Why considered:**
- **Flexibility**: "10% off" OR "$5 off"
- **Small orders**: Fixed amount better for low-value carts
- **Large orders**: Percentage better for high-value carts

**Why rejected:**
- **MVP scope decision**: Percentage-only chosen in requirements (Assumption #9)
- **Implementation simplicity**: Single calculation type
- **Marketing clarity**: Percentages are simpler to communicate
- **Can add fixed-amount later**: Not architecturally limiting to start with percentage only

---

## Implementation Notes

**Database schema:**
```
promo_codes {
  code: string (unique),
  discount_percentage: float (0-100),
  min_order_value: float (nullable, default 0),
  expiration_date: timestamp (nullable),
  max_redemptions: int (nullable),
  used_count: int (default 0),
  active: boolean (default true),
  created_at: timestamp,
  created_by: string (admin_id)
}
```

**Discount calculation logic:**
```
cart_total = sum(item.price * item.quantity)

if promo_code_applied:
  if cart_total < promo_code.min_order_value:
    error: "Minimum order value not met"

  discount_amount = cart_total * (promo_code.discount_percentage / 100)
  final_total = cart_total - discount_amount
```

**Admin UI:**
- Create code form: Code (text), Percentage (0-100), Min Order ($), Expiration (date), Max Uses (int)
- Code list: Active/Inactive toggle, Usage stats (X of Y used), Deactivate button
- Validation: Code must be unique, percentage 0-100, min order >= 0

**Customer UI:**
- Checkout page: "Have a promo code?" (collapsible field)
- Enter code → validate → show: "LAUNCH10 applied: -$X.XX"
- Invalid code: "Code not found or expired"
- Doesn't meet minimum: "Add $X.XX more to use this code"

**Edge cases:**
- Code expires during checkout: Validate at final payment, reject if expired
- Code reaches max redemptions: First come, first served (race condition acceptable)
- Customer applies multiple codes: Not supported (single code per order)
- Customer removes items after applying code: Recalculate, show warning if below minimum

---

## Success Criteria

**How we'll know this decision was correct:**
- Admin can create/manage discount codes without support
- < 5% of discount code applications fail (validation errors)
- Customer satisfaction with discount code UX > 4/5
- No requests for product-specific codes in first 3 months
- Discount codes drive > 15% of total orders during campaigns

**Red flags to watch for:**
- Admin requests product-specific promotions frequently
- Customers confused about discount application
- Margin pressure due to blanket discounts

---

## Review Date

**Review after 6 months of marketing campaigns** or if:
- Admin requests product-specific codes 3+ times
- Inventory strategy requires targeted promotions
- Competitor promotions significantly more sophisticated
- New product categories added (multi-category = more need for targeting)

**Future enhancements (if needed):**
- Product-specific codes (add `eligible_product_ids` array to schema)
- Tiered discounts (add `discount_tiers` array)
- Fixed-amount discounts (add `discount_type` enum)
- Free shipping codes (add `free_shipping` boolean)

---

## References

- [requirements.md](../stage-2/requirements.md) - Open Question #9 resolution, Functional Requirement #13
- Related ADRs: None
- Industry patterns: Shopify discount codes, Stripe coupons

---

**Date:** 2026-01-24
**Author(s):** Claude (Systematic Refinement)
**Reviewers:** [Pending]
