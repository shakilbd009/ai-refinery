# ADR-004: Order-Wide Discount Codes (Not Product-Specific)

## Status

Accepted

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

## Rationale

### Why not product-specific discount codes?

While offering more marketing flexibility, this approach was rejected because:
- **Implementation complexity**: Requires product tagging/categorization system
- **Admin UI complexity**: Must select eligible products when creating code
- **Validation complexity**: Must check cart items against eligible products at checkout
- **Edge case handling**: What if customer removes eligible item after applying code?
- **Testing burden**: Many more scenarios to test (eligible/ineligible product combinations)
- **MVP timeline impact**: +1-2 weeks development time
- **Limited value for MVP**: Single product category (honey) means all products are similar

### Why not tiered order value discounts?

While increasing average order value, this approach was rejected because:
- **More complex**: Requires threshold checking + multiple discount tiers
- **Customer confusion**: "I'm at $48, should I add $2 to get discount?"
- **Admin UI complexity**: Must configure multiple tiers per code
- **Not requested**: No requirement for this in MVP scope
- **Can be added later**: Not mutually exclusive with order-wide codes

### Why percentage-only (not fixed-amount)?

- **MVP scope decision**: Percentage-only chosen in requirements
- **Implementation simplicity**: Single calculation type
- **Marketing clarity**: Percentages are simpler to communicate
- **Can add fixed-amount later**: Not architecturally limiting to start with percentage only

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

- Product catalog growth may require product-specific codes later
- Can still run effective campaigns with order-wide discounts
- Discount stacking not addressed (out of scope for MVP)
