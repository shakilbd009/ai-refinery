---
name: production-checklist
description: Generate actionable production readiness checklist from curated design docs
---

# Production Checklist Skill

Extracts actionable deployment items from curated design docs and generates a production readiness checklist.

## Usage

```bash
# Standalone - writes to 07-curated/production-checklist.md
/production-checklist <idea-name>

# Automatically invoked by /graduate - writes to docs/production-checklist.md
```

## Prerequisites

- Idea must have `07-curated/` folder
- Completeness score must pass (when called from /graduate)

## Process

### 1. Load Source Documents

Read all curated docs that contain actionable items:

```bash
# Primary sources
cat 07-curated/architecture/overview.md
cat 07-curated/security/threat-model.md
cat 07-curated/operations/runbooks.md
cat 07-curated/performance.md

# Component sources
cat 07-curated/architecture/components/*.md

# Edge case sources
cat 07-curated/edge-cases/*.md

# Compliance sources (if exist)
cat 07-curated/security/compliance/*.md
```

### 2. Extract Items by Category

For each category, apply extraction rules from [EXTRACTORS.md](./EXTRACTORS.md):

| Category | Primary Sources |
|----------|-----------------|
| Infrastructure | `architecture/overview.md` |
| Security | `security/threat-model.md` |
| Integrations | `architecture/components/*.md` |
| Monitoring | `operations/runbooks.md`, `performance.md` |
| Testing | `edge-cases/*.md` |
| Compliance | `security/compliance/*.md` |

### 3. Deduplicate and Organize

- Remove duplicate items across sources
- Group by category
- Order by priority within category
- Format as actionable checklist items

### 4. Generate Output

Write checklist using format from [OUTPUT-FORMAT.md](./OUTPUT-FORMAT.md).

**Standalone mode:** Write to `ideas/<idea-name>/07-curated/production-checklist.md`

**Graduate mode:** Write to `<target-path>/docs/production-checklist.md`

## Extraction Principles

### What Makes a Good Checklist Item

**Good:**
- `[ ] Deploy Go API to Cloud Run` - Specific, actionable
- `[ ] Implement rate limiting (100 req/min per IP)` - Includes config detail
- `[ ] Test: reservation expires during checkout` - Derived from edge case

**Bad:**
- `[ ] Set up infrastructure` - Too vague
- `[ ] Handle errors` - Not actionable
- `[ ] Make it secure` - No specific action

### Extraction Signals

Look for:
1. **Technology names** - Cloud Run, Firestore, Stripe, Redis
2. **Action verbs** - deploy, configure, set up, implement, enable
3. **Requirements** - must, required, needs, should
4. **Metrics** - P95 < 200ms, 99.9% uptime, 100 req/min
5. **Edge cases** - Each becomes a test scenario

### Deduplication

Same item may appear in multiple docs. Keep the most specific version:

```
# From overview.md: "Uses Firestore"
# From components/checkout.md: "Firestore with transactions for orders"

Keep: "[ ] Provision Firestore database with transaction support"
```

## Integration with /graduate

```
/graduate <idea-name> <target-path>
    │
    ├─► /completeness-score (must pass)
    │
    ├─► Create repo structure
    │
    ├─► Transfer curated docs
    │
    ├─► /production-checklist
    │       │
    │       └─► Write docs/production-checklist.md
    │
    └─► Git init & commit
```

## Error Handling

| Error | Resolution |
|-------|------------|
| No 07-curated/ folder | Run `/curating-artifacts` first |
| Missing source files | Check curation completed |
| No items extracted | Verify docs contain actionable content |

## Example Output

See [OUTPUT-FORMAT.md](./OUTPUT-FORMAT.md) for full template.

```markdown
# Production Readiness Checklist

Generated from design docs on 2026-01-26.

## Infrastructure
- [ ] Deploy Go API to Cloud Run
- [ ] Provision Firestore database

## Security
- [ ] Implement rate limiting (100 req/min per IP)
...
```
