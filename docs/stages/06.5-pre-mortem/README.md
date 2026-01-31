# Stage 6.5: Pre-Mortem

## Purpose

Imagine the project has failed one year after launch. Write the post-mortem now to identify failure modes before they happen.

## Why This Stage Exists

**Problem:** Confirmation bias makes us optimistic about our own ideas.
**Solution:** Force pessimistic analysis while you can still prevent failures.

> "When the project fails, we will say it was because of..."

## The Process

### Step 1: Set the Scene

It's one year from now. The project has **failed**.

- Product launch happened
- Initial traction existed (or didn't)
- Investment of time/money was made
- **Result:** Shut down, pivoted, or limping along

### Step 2: Write the Failure Story

Write 2-3 paragraphs describing what happened. Be specific:

```markdown
## The Failure

By January 2027, AgentForge was shut down. Despite initial excitement 
and a promising beta, we couldn't achieve sustainable traction.

**What went wrong:**

1. **Technical debt caught up with us.** The four-phase pipeline sounded 
   good in theory, but users found it too slow. Each phase took days 
   of back-and-forth. By month 6, competitors with simpler workflows 
   had captured the market.

2. **Pricing was wrong.** We assumed enterprises would pay $500/month, 
   but they wanted $50K annual contracts with custom features we 
   couldn't support. Self-serve customers churned at 15% monthly.

3. **The SME knowledge store was too hard to populate.** Companies 
   didn't have documented standards. We spent 6 months trying to 
   extract tribal knowledge, and it never worked well enough.

We burned through $200K and 12 months before admitting defeat.
```

### Step 3: Categorize Failures

Group failures into categories:

| Category | Examples | Prevention Strategy |
|----------|----------|---------------------|
| **Technical** | Scalability issues, tech debt, bugs | Architecture decisions, testing |
| **Market** | No demand, wrong timing, competition | Market validation stage |
| **Execution** | Team issues, funding, speed | Resource planning, milestones |
| **Product** | UX issues, missing features, complexity | User testing, MVP scope |
| **Business** | Pricing, unit economics, GTM | Business model validation |

### Step 4: Prevention Planning

For each failure mode, write:

```markdown
## Failure Mode: [Name]

**Category:** Technical/Market/Execution/Product/Business

**How we'll know it's happening (early warning):**
- Metric 1: [e.g., "Pipeline completion time > 2 weeks"]
- Metric 2: [e.g., "User drop-off at phase 2 > 50%"]

**Prevention strategy:**
- [ ] Action 1
- [ ] Action 2

**Contingency plan (if it happens anyway):**
- Option A: [e.g., "Simplify to 2-phase pipeline"]
- Option B: [e.g., "Pivot to consultancy model"]

**Owner:** [Who monitors this?]
**Review cadence:** [How often check metrics?]
```

## Criteria

### Must Address

- [ ] **Technical failures** - What breaks at scale?
- [ ] **Market failures** - Why wouldn't customers buy?
- [ ] **Execution failures** - What can the team not deliver?
- [ ] **Competitive failures** - How do competitors win?
- [ ] **Timing failures** - Too early? Too late?

### Must Have

- [ ] Early warning indicators (how to detect failure before it's fatal)
- [ ] Prevention strategies for each failure mode
- [ ] Contingency plans (Plan B for each risk)
- [ ] Assigned owners for monitoring
- [ ] Review cadence established

## Artifacts

```
ideas/<name>/06.5-pre-mortem/
├── failure-story.md        # The narrative of how it failed
├── failure-modes.md        # Categorized list with prevention
├── early-warning-metrics.md # How to detect problems early
└── contingency-plans.md    # Plan B for each major risk
```

## Gate Criteria

**Hard Gates (blocking):**
- [ ] At least 5 distinct failure modes identified
- [ ] At least one failure mode in each category (Technical, Market, Execution, Product, Business)
- [ ] Early warning metrics defined for critical risks

**Soft Gates (recommended):**
- [ ] Contingency plans for top 3 risks
- [ ] Risk owners assigned
- [ ] Review cadence established

## Common Failure Modes to Consider

### Technical
- [ ] Can't scale to 1000 users
- [ ] Third-party API breaks/changes pricing
- [ ] Security breach destroys trust
- [ ] Performance degrades with data volume
- [ ] Technical debt makes features too slow to build

### Market
- [ ] Target market doesn't exist (fake problem)
- [ ] Competitor launches same thing, better funded
- [ ] Economic downturn kills discretionary spending
- [ ] Regulation makes business model illegal
- [ ] Market shifts to different solution type

### Execution
- [ ] Key team member leaves
- [ ] Run out of money before product-market fit
- [ ] Can't hire necessary talent
- [ ] Scope creep delays launch indefinitely
- [ ] Founder burnout / loss of interest

### Product
- [ ] UX is too complex, users abandon
- [ ] Missing critical feature users expected
- [ ] Quality issues create negative word-of-mouth
- [ ] Product tries to do too much, does nothing well
- [ ] Onboarding friction kills activation

### Business
- [ ] Unit economics don't work (CAC > LTV)
- [ ] Pricing too low to sustain operations
- [ ] Can't find distribution channel that works
- [ ] Churn too high to achieve growth
- [ ] Key partnership falls through

## Red Flags (After Pre-Mortem)

🚩 Can't identify any failure modes (not thinking critically enough)
🚩 All failure modes are external (not taking responsibility)
🚩 No prevention strategies (just accepting failure)
🚩 Early warning metrics not measurable
🚩 Contingency plans are just "we'll pivot" (not specific)

## Integration with Other Stages

**Uses input from:**
- 03.5-market-validation (market risks)
- 04-design-l1/l2/l3 (technical risks)

**Informs:**
- 07-curated (risk mitigation in design)
- Implementation (monitoring, contingency plans)

## Success Metrics

After this stage, you should be able to answer:
1. What are the top 3 ways this project could fail?
2. How will we know if each is happening?
3. What will we do to prevent each?
4. What's our Plan B if prevention fails?

**If you can't answer these, you're building blind.**
