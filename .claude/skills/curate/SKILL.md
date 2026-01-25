---
name: curate
description: Packages refined idea artifacts into graduation-ready structure. Applies after completing stage 6 refinement, before /graduate. Triggers on requests to curate, package, organize, or prepare ideas for graduation.
---

# Curate Skill

Transforms scattered refinement artifacts (stages 1-6) into an organized, graduation-ready package.

## Usage

```bash
/curate <idea-name>
```

## When to Use

- After completing stage 6 (Refine L3)
- Before running `/graduate`
- When you have 95%+ confidence in design

## Output Structure

All files kept under 300 lines for parallel agent efficiency:

```
ideas/<name>/curated/
├── overview.md                    # Executive summary (~100 lines)
├── requirements.md                # Functional + non-functional (~200 lines)
├── architecture/
│   ├── overview.md                # System architecture (~150 lines)
│   ├── data-model.md              # Database schema (~200 lines)
│   ├── api-contracts.md           # API specifications (~200 lines)
│   └── components/
│       ├── <component-a>.md       # Per-component design (~200 lines each)
│       └── ...
├── decisions/
│   ├── index.md                   # ADR index with summaries (~100 lines)
│   └── ADR-*.md                   # Individual ADRs (~100 lines each)
├── edge-cases/
│   ├── index.md                   # Edge case summary (~50 lines)
│   ├── data-boundaries.md         # Empty/null/max/special chars (~150 lines)
│   ├── state-transitions.md       # Concurrent/retry/out-of-order (~150 lines)
│   ├── timing.md                  # Timeout/race/long-running (~150 lines)
│   └── integration.md             # External service failures (~150 lines)
├── security/
│   ├── threat-model.md            # Security analysis (~200 lines)
│   └── compliance/
│       ├── overview.md            # Compliance summary (~100 lines)
│       └── <type>.md              # GDPR, PCI, etc. (~150 lines each)
├── operations/
│   ├── runbooks.md                # Operational procedures (~200 lines)
│   └── monitoring.md              # Alerts and metrics (~150 lines)
├── performance.md                 # Scaling and bottlenecks (~200 lines)
└── trade-offs.md                  # Key trade-offs summary (~200 lines)
```

## Process

### Phase 1: Analysis (Sequential)

1. **Scan source artifacts**
   - Read `ideas/<name>/stage-*/` folders
   - Identify all documents
   - Map source → target locations

2. **Build curation plan**
   - List files to create
   - Identify source files for each
   - Estimate parallel batches

3. **Create directory structure**
   ```bash
   mkdir -p ideas/<name>/curated/{architecture/components,decisions,edge-cases,security/compliance,operations}
   ```

### Phase 2: Parallel Curation

**MANDATORY**: Dispatch all independent curation tasks in parallel.

```
<parallel-dispatch>
# Core documents (batch 1):
- Task 1 (general-purpose): Create overview.md from stage-1/idea.md + stage-6 summaries
- Task 2 (general-purpose): Create requirements.md from stage-2/requirements.md
- Task 3 (general-purpose): Create trade-offs.md from stage-3 trade-off analyses

# Architecture (batch 1 continued):
- Task 4 (feature-dev:code-architect): Create architecture/overview.md from stage-4 + stage-6 architecture docs
- Task 5 (feature-dev:code-architect): Create architecture/data-model.md from stage-4/database-schema.md
- Task 6 (feature-dev:code-architect): Create architecture/api-contracts.md from stage-4/api-contracts.md

# Components (batch 1 continued - one per component):
- Task 7 (feature-dev:code-architect): Create architecture/components/<component-a>.md from L1+L2+L3 docs
- Task 8 (feature-dev:code-architect): Create architecture/components/<component-b>.md from L1+L2+L3 docs
- ... (one task per component)

# Edge cases (batch 1 continued):
- Task N (general-purpose): Create edge-cases/index.md + edge-cases/data-boundaries.md
- Task N+1 (general-purpose): Create edge-cases/state-transitions.md
- Task N+2 (general-purpose): Create edge-cases/timing.md
- Task N+3 (general-purpose): Create edge-cases/integration.md

# Security & Compliance (batch 1 continued):
- Task M (general-purpose): Create security/threat-model.md from stage-6/security-threat-model.md
- Task M+1 (general-purpose): Create security/compliance/overview.md + individual compliance docs

# Operations (batch 1 continued):
- Task P (general-purpose): Create operations/runbooks.md from stage-6/operational-runbooks.md
- Task P+1 (general-purpose): Create performance.md from stage-6/performance-analysis.md
</parallel-dispatch>
```

### Phase 3: Decisions Curation (After batch 1)

ADRs need special handling - collect from all stages:

```
<parallel-dispatch>
# One task per ADR:
- Task 1 (general-purpose): Curate ADR-001 → decisions/ADR-001-*.md
- Task 2 (general-purpose): Curate ADR-002 → decisions/ADR-002-*.md
- ... (one task per ADR)
- Task N (general-purpose): Create decisions/index.md (after ADRs complete)
</parallel-dispatch>
```

### Phase 4: Validation (Sequential)

**Feedback loop**: Run validation → fix errors → repeat until all checks pass.

1. **Verify completeness**
   - All curated files exist
   - No file exceeds 300 lines
   - No broken internal links
   - **If issues found**: Return to Phase 2, dispatch fix tasks in parallel

2. **Verify content quality**
   - No TBDs or placeholders
   - All decisions have rationale
   - Edge cases have handling strategies
   - **If issues found**: Return to Phase 2, dispatch fix tasks in parallel

3. **Update status** (only after all validations pass)
   - Mark idea as "curated" in registry
   - Create `curated/status.md` with checklist

---

## Artifact Mapping

| Source (stages 1-6) | Target (curated/) |
|---------------------|-------------------|
| stage-1/idea.md | overview.md (partial) |
| stage-2/requirements.md | requirements.md |
| stage-3/*trade-off*.md | trade-offs.md |
| stage-3/*recommendation*.md | trade-offs.md |
| stage-4/architecture*.md | architecture/overview.md |
| stage-4/database-schema.md | architecture/data-model.md |
| stage-4/api-contracts.md | architecture/api-contracts.md |
| stage-4/*-L1.md | architecture/components/*.md (merged) |
| stage-5/*-L2.md | architecture/components/*.md (merged) |
| stage-6/*-L3.md | architecture/components/*.md (merged) |
| stage-6/edge-cases*.md | edge-cases/*.md (split by category) |
| stage-6/security-threat-model.md | security/threat-model.md |
| stage-6/compliance-*.md | security/compliance/*.md |
| stage-6/operational-runbooks.md | operations/runbooks.md |
| stage-6/performance-analysis.md | performance.md |
| ADRs/*.md | decisions/ADR-*.md |

---

## Curation Guidelines

### For Each File

1. **Extract essence** - Remove exploration artifacts, keep decisions
2. **Maintain context** - Include enough background to understand
3. **Link related docs** - Use relative links: `[See API contracts](../architecture/api-contracts.md)`
4. **Preserve rationale** - WHY matters more than WHAT
5. **Keep actionable** - Implementation team should understand next steps

### Component Files (L1+L2+L3 → Single Doc)

Merge progressive deepening levels into coherent narrative:

```markdown
# Component: <Name>

## Overview
[From L1 - What and Why]

## Design
[From L2 - How and Interactions]

## Implementation Details
[From L3 - Exhaustive coverage]

## Edge Cases
[Extracted from L2/L3]

## Failure Modes
[From L3 failure analysis]
```

### Edge Case Files

Split comprehensive edge cases by category:

```markdown
# Edge Cases: Data Boundaries

## Empty/Null Values
| Scenario | Handling | Test |
|----------|----------|------|
| ... | ... | ... |

## Maximum Values
...

## Special Characters
...
```

---

## Concrete Examples

### Example 1: Curating Overview

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

**Output (curated/overview.md):**
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

### Example 2: Merging L1+L2+L3 into Component Doc

**Sources:**
- `stage-4/checkout-L1.md`: Basic checkout flow description
- `stage-5/checkout-L2.md`: Payment integration details, state machine
- `stage-6/checkout-L3.md`: Race conditions, failure modes, retry logic

**Output (curated/architecture/components/checkout.md):**
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

### Example 3: Splitting Edge Cases by Category

**Source (stage-6/edge-cases-comprehensive.md):**
```markdown
## All Edge Cases
- Empty cart checkout → block with message
- 100+ items in cart → paginate, warn about shipping
- Concurrent cart updates → last-write-wins with conflict UI
- Payment timeout after 30s → mark pending, email user
- Special chars in address → sanitize, preserve unicode
```

**Output (curated/edge-cases/data-boundaries.md):**
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

**Output (curated/edge-cases/state-transitions.md):**
```markdown
# Edge Cases: State Transitions

## Concurrent Operations
| Scenario | Handling | Test |
|----------|----------|------|
| Concurrent cart updates | Last-write-wins with conflict notification UI | `test_concurrent_cart_conflict` |
```

**Output (curated/edge-cases/timing.md):**
```markdown
# Edge Cases: Timing

## Timeouts
| Scenario | Handling | Test |
|----------|----------|------|
| Payment timeout (30s) | Mark as pending, send status email to user | `test_payment_timeout_recovery` |
```

---

## Validation Checklist

Before marking curation complete:

- [ ] All source artifacts mapped to targets
- [ ] No file exceeds 300 lines
- [ ] overview.md has executive summary
- [ ] requirements.md has acceptance criteria
- [ ] Each component has merged L1+L2+L3 doc
- [ ] ADRs indexed with summaries
- [ ] Edge cases split by category
- [ ] Security threat model included
- [ ] Compliance docs included (if applicable)
- [ ] Operations runbooks included
- [ ] Performance analysis included
- [ ] Trade-offs summarized
- [ ] No TBDs or placeholders remain
- [ ] Internal links work

---

## After Curation

```bash
# Verify curation
ls -la ideas/<name>/curated/

# Graduate when ready
/graduate <idea-name> ~/projects/<project-name>
```

The `/graduate` skill will read from `curated/` folder and transfer to the new repo.

---

## Error Handling

| Error | Resolution |
|-------|------------|
| Missing stage-6 artifacts | Cannot curate - complete refinement first |
| File exceeds 300 lines | Split into focused sub-documents |
| Missing ADRs | Create ADRs for undocumented decisions |
| Broken links | Fix paths before completing |
| TBDs found | Resolve or document as explicit assumptions |
