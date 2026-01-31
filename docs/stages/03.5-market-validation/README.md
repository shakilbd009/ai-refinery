# Stage 3.5: Market Validation

## Purpose

Validate the business viability before committing to technical implementation. 
Technical excellence means nothing if there's no market.

## Why This Stage Exists

**Problem:** Engineers build beautiful solutions to problems nobody has.
**Solution:** Force market analysis before architecture decisions.

## Criteria

### Market Size Analysis
- [ ] **TAM (Total Addressable Market)** - If you captured 100% of market
- [ ] **SAM (Serviceable Addressable Market)** - Realistically reachable
- [ ] **SOM (Serviceable Obtainable Market)** - First 3 years target
- [ ] Growth rate of the market (CAGR)
- [ ] Market trends (growing, shrinking, stable?)

### Competitive Landscape
- [ ] **Direct competitors** (same solution, same market)
- [ ] **Indirect competitors** (different solution, same problem)
- [ ] **Substitutes** (customers doing nothing, or manual workaround)
- [ ] Competitor matrix (features, pricing, positioning)
- [ ] **Differentiation strategy** - Why you vs them?

### Customer Validation
- [ ] Target customer segments identified
- [ ] Customer interviews conducted (minimum 5)
- [ ] Pain points validated (not assumed)
- [ ] Willingness to pay established
- [ ] **Beachhead market** - Easiest first 100 customers

### Business Model
- [ ] **Pricing strategy** (subscription, usage-based, freemium, etc.)
- [ ] Price point validated with customers
- [ ] Unit economics estimated:
  - Customer Acquisition Cost (CAC)
  - Lifetime Value (LTV)
  - LTV/CAC ratio (target >3)
  - Payback period (target <12 months)
- [ ] Revenue model projection (MRR/ARR growth)

### Go-to-Market Strategy
- [ ] **Distribution channels** identified
- [ ] Marketing channels (organic, paid, partnerships)
- [ ] Sales motion (self-serve, sales-led, hybrid)
- [ ] **Beachhead acquisition strategy** - How first 100 customers?
- [ ] Viral/growth loops (if applicable)

### Risk Assessment
- [ ] Market risks (timing, saturation, regulation)
- [ ] Execution risks (team, capital, competition)
- [ ] **Risk-adjusted ROI** - Is this worth building?
- [ ] Plan B if primary strategy fails

## Artifacts

```
ideas/<name>/03.5-market-validation/
├── market-size.md          # TAM/SAM/SOM analysis
├── competitive-landscape.md # Competitor matrix and differentiation
├── customer-validation.md  # Interview findings, willingness to pay
├── business-model.md       # Pricing, unit economics, projections
├── go-to-market.md         # Distribution and acquisition strategy
└── risk-assessment.md      # Risks and mitigation strategies
```

## Gate Criteria (Must Pass to Advance)

**Hard Gates (blocking):**
- [ ] Market size > $10M (SOM) OR strategic value justifies smaller market
- [ ] Clear differentiation from competitors
- [ ] Customer interviews validate problem exists
- [ ] Business model shows path to profitability

**Soft Gates (document, but can proceed):**
- [ ] Exact pricing finalized
- [ ] Complete competitive analysis
- [ ] Detailed financial projections

## Red Flags (Stop and Reconsider)

🚩 **"Everyone is our customer"** - No beachhead market
🚩 **"We have no competitors"** - Either wrong, or no market exists
🚩 **"Build it and they will come"** - No GTM strategy
🚩 **LTV/CAC < 3** - Unit economics don't work
🚩 **"Customers love it but won't pay"** - Not a business, it's a hobby

## When to Skip This Stage

- Internal tools (company-specific, no external market)
- Learning projects (deliberate build-to-learn)
- Open source (different success metrics)
- Portfolio pieces (demonstration, not business)

**Note:** If skipping, document WHY in `03.5-market-validation/SKIPPED.md`

## Success Metrics

After this stage, you should be able to answer:
1. Who exactly will buy this?
2. Why will they choose you over alternatives?
3. How much will they pay?
4. How will you reach them?
5. Will this be profitable?

If you can't answer confidently, **do not proceed to architecture.**
