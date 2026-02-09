---
name: curating-artifacts
description: Packages refined idea artifacts into graduation-ready structure. Applies after completing stage 6 refinement, before /graduate. Triggers on requests to curate, package, organize, or prepare ideas for graduation.
---

# Curating Artifacts

Transforms scattered refinement artifacts (stages 1-6) into an organized, graduation-ready package.

## Contents

- [Usage](#usage)
- [When to Use](#when-to-use)
- [Output Structure](#output-structure)
- [Process](#process)
- [Curation Guidelines](#curation-guidelines)
- [After Curation](#after-curation)

## Usage

```bash
/curating-artifacts <idea-name>
```

## When to Use

- After completing stage 6 (Refine L3)
- Before running `/graduate`
- When you have 95%+ confidence in design

## Output Structure

Creates organized files in `ideas/<name>/07-curated/` with all files kept under 300 lines for parallel agent efficiency.

See [OUTPUT-STRUCTURE.md](OUTPUT-STRUCTURE.md) for the complete directory layout.

## Process

### Phase 0: Read Memory

**Reference:** See [_memory.md](../_memory.md) for memory operations.

Check if memory exists and load context:

```bash
ls ideas/<name>/.memory/ 2>/dev/null
```

**If memory exists:**

Read context.md for preferences (do NOT read runs.jsonl for this skill):
```bash
cat ideas/<name>/.memory/context.md
```

Report relevant context:
```
Context loaded:
  - <relevant preference>
  - <relevant decision>
```

Use loaded preferences to inform curation decisions (e.g., tech choices, architectural patterns).

**If no memory:** Proceed normally without memory context.

### Phase 1: Analysis (Sequential)

1. **Scan source artifacts**
   - Read `ideas/<name>/0*-*/` folders (01-brainstorm through 06-design-l3)
   - Identify all documents
   - Map source → target locations (see [ARTIFACT-MAPPING.md](ARTIFACT-MAPPING.md))

2. **Build curation plan**
   - List files to create
   - Identify source files for each
   - Estimate parallel batches

3. **Create directory structure**
   ```bash
   mkdir -p ideas/<name>/07-curated/{architecture/components,decisions,edge-cases,security/compliance,operations,implementation}
   ```

### Phase 2: Parallel Curation

**MANDATORY**: Dispatch all independent curation tasks in parallel.

```
<parallel-dispatch>
# Core documents (batch 1):
- Task 1 (general-purpose): Create overview.md from 01-brainstorm/idea.md + 06-design-l3 summaries
- Task 2 (general-purpose): Create requirements.md from 02-requirements/requirements.md
- Task 3 (general-purpose): Create trade-offs.md from 03-trade-offs trade-off analyses

# Architecture (batch 1 continued):
- Task 4 (feature-dev:code-architect): Create architecture/overview.md from 04-design-l1 + 06-design-l3 architecture docs
- Task 5 (feature-dev:code-architect): Create architecture/data-model.md from 04-design-l1/database-schema.md
- Task 6 (feature-dev:code-architect): Create architecture/api-contracts.md from 04-design-l1/api-contracts.md

# Components (batch 1 continued - one per component):
- Task 7 (feature-dev:code-architect): Create architecture/components/<component-a>.md from L1+L2+L3 docs
- Task 8 (feature-dev:code-architect): Create architecture/components/<component-b>.md from L1+L2+L3 docs
- ... (one task per component)

# Edge cases (batch 1 continued - index created in Phase 3):
- Task N (general-purpose): Create edge-cases/data-boundaries.md
- Task N+1 (general-purpose): Create edge-cases/state-transitions.md
- Task N+2 (general-purpose): Create edge-cases/timing.md
- Task N+3 (general-purpose): Create edge-cases/integration.md

# Security & Compliance (batch 1 continued):
- Task M (general-purpose): Create security/threat-model.md from 06-design-l3/security-threat-model.md
- Task M+1 (general-purpose): Create security/compliance/overview.md + individual compliance docs

# Implementation (batch 1 continued):
- Task O (general-purpose): Create implementation/tdd.md from templates/tdd.md + testing strategy in stages 4-6, customized with project tech stack

# Operations (batch 1 continued):
- Task P (general-purpose): Create operations/runbooks.md from 06-design-l3/operational-runbooks.md
- Task P+1 (general-purpose): Create operations/monitoring.md from 06-design-l3/monitoring*.md (if present)
- Task P+2 (general-purpose): Create performance.md from 06-design-l3/performance-analysis.md
</parallel-dispatch>
```

### Phase 3: Decisions Curation (After batch 1)

ADRs need special handling - scan ALL stages for `ADR-*.md` files (commonly in 03-trade-offs, but may appear anywhere):

**Step 1: Curate individual ADRs (parallel)**
```
<parallel-dispatch>
# One task per ADR found across all stages:
- Task 1 (general-purpose): Curate ADR-001 → decisions/ADR-001-*.md
- Task 2 (general-purpose): Curate ADR-002 → decisions/ADR-002-*.md
- ... (one task per ADR)
</parallel-dispatch>
```

**Step 2: Create index files (after Phase 2 and Step 1 complete)**
```
<parallel-dispatch>
- Task N (general-purpose): Create decisions/index.md summarizing all ADRs
- Task N+1 (general-purpose): Create edge-cases/index.md summarizing all edge case categories
</parallel-dispatch>
```

These indexes must wait because they reference files created in earlier phases. Both can run in parallel since they don't depend on each other.

### Phase 4: Validation (Sequential)

**Feedback loop**: Run validation → fix errors → repeat until all checks pass.

See [VALIDATION.md](VALIDATION.md) for the complete validation checklist and error handling.

1. **Verify completeness** - All files exist, under 300 lines, no broken links
2. **Verify content quality** - No TBDs, all decisions have rationale
3. **Update status** - Mark as "curated" in registry (only after all validations pass)

### Phase 5: Write Memory

**Reference:** See [_memory.md](../_memory.md) for memory operations.

1. **Create memory folder (if needed):**
   ```bash
   mkdir -p ideas/<name>/.memory
   ```

2. **Append to runs.jsonl:**
   ```bash
   echo '{"skill":"curating-artifacts","ts":"<ISO-8601>","idea":"<name>","result":"completed","data":{"files_created":<n>,"categories":["architecture","decisions","edge-cases","security","operations"]}}' >> ideas/<name>/.memory/runs.jsonl
   ```

3. **Ask about context.md (if significant decisions emerged):**

   If the user made notable curation decisions:
   ```
   I noticed you decided <decision>.
   Want me to save this to memory for future reference? (y/n)
   ```

   If yes, append to appropriate section in context.md.

Report:
```
Updating memory...
✓ Logged run to .memory/runs.jsonl
```

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

## After Curation

```bash
# Verify curation
ls -la ideas/<name>/07-curated/

# Optional: Run specialist validation (recommended for high-stakes projects)
/validate-design <idea-name> --all      # Full validation
/validate-design <idea-name> --quick    # Security + architecture only

# Graduate when ready
/graduate <idea-name> ~/projects/<project-name>
```

The `/validate-design` skill runs specialist agents (security, architecture, performance, UX, devil's advocate) against the curated artifacts to catch blind spots. Recommended for payment systems, auth, public APIs.

The `/graduate` skill will read from `07-curated/` folder and transfer to the new repo.

---

**Additional Resources:**
- [OUTPUT-STRUCTURE.md](OUTPUT-STRUCTURE.md) - Complete directory layout
- [ARTIFACT-MAPPING.md](ARTIFACT-MAPPING.md) - Source → target file mapping
- [EXAMPLES.md](EXAMPLES.md) - Concrete curation examples
- [VALIDATION.md](VALIDATION.md) - Validation checklist and error handling
