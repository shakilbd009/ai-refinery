# Stage 3.5: Market Validation

## Purpose

Validate the business viability before committing to technical implementation. 
Technical excellence means nothing if there's no market.

## The Process

### Step 1: Research the Market Landscape

Before talking to anyone, build a foundation of knowledge:

- Search for existing solutions (Google, Product Hunt, G2, Capterra)
- Read industry reports and analyst predictions (Gartner, Forrester, CB Insights)
- Check startup databases (Crunchbase, PitchBook) for funded competitors
- Look at job postings in the space — they reveal what companies actually invest in
- Estimate TAM/SAM/SOM using bottom-up calculations (number of potential customers × average spend)

**Output:** `market-size.md` and `competitive-landscape.md` drafts

### Step 2: Talk to Real Customers

Desk research tells you what exists. Conversations tell you what's missing:

- Identify 5-10 people in your target segment (LinkedIn, communities, existing networks)
- Run problem interviews, **not** solution interviews — ask about their pain, not your idea
- Use open-ended questions: "Walk me through how you handle X today" and "What's the most frustrating part?"
- Listen for **frequency** and **intensity** of the pain — occasional annoyances aren't markets
- Ask the "magic wand" question: "If you could wave a magic wand, what would change?"
- End with willingness to pay: "If something solved this, what would you budget for it?"

**Output:** `customer-validation.md` with interview summaries and pattern analysis

### Step 3: Validate the Business Model

Now connect market reality to financial viability:

- Choose a pricing model that matches how customers already buy (subscription, usage, per-seat)
- Sanity-check price points against competitor pricing and customer interview responses
- Calculate unit economics: CAC (how much to acquire one customer) vs LTV (how much they'll pay over their lifetime)
- Target LTV/CAC > 3 and payback period < 12 months — if the math doesn't work, the business doesn't work
- Model revenue scenarios: pessimistic (10% of target), realistic (30%), optimistic (60%)

**Output:** `business-model.md` with pricing strategy and unit economics

### Step 4: Design the Go-to-Market Path

A great product with no distribution channel is a tree falling in an empty forest:

- Identify your **beachhead market** — the smallest segment you can dominate first
- Map the customer journey: how do they discover solutions today? (Search, communities, referrals, conferences)
- Pick 1-2 acquisition channels to test first — don't spread thin across five channels
- Define your sales motion: self-serve (low price, high volume) vs sales-led (high price, relationship-driven)
- Write your one-sentence positioning: "For [audience] who [problem], [product] is the [category] that [differentiator]"

**Output:** `go-to-market.md` with channel strategy and positioning

### Step 5: Assess Risk and Make the Call

Pull everything together into a go/no-go decision:

- List every market, execution, and business risk you've uncovered
- For each risk, assign likelihood (high/medium/low) and impact (fatal/painful/manageable)
- Calculate risk-adjusted ROI: is the upside worth the identified downside?
- Define your **kill criteria** — what evidence would make you walk away?
- Make the call: proceed to architecture, pivot the idea, or shelve it

**Output:** `risk-assessment.md` with risk matrix and decision

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
