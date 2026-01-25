---
name: doc-audit
description: Use when auditing CLAUDE.md, skills, READMEs, or design docs for progressive disclosure, DRY compliance, and context rot prevention
---

# Documentation Audit

Validates markdown documentation against four principles: Progressive Disclosure, DRY, Context Rot Prevention, and Entropy Fighting.

## Quick Start

```bash
/doc-audit path/to/file.md        # Audit a file
/doc-audit path/to/file.md --fix  # Audit and fix
/doc-audit                        # Audit current CLAUDE.md
```

## When NOT to Use

- Auto-generated documentation (API docs, TypeDoc, JSDoc output)
- Third-party files in `node_modules/` or `vendor/`
- Changelog files (`CHANGELOG.md`, `HISTORY.md`)
- License files (`LICENSE.md`)
- Meeting notes or ephemeral documents
- Files you don't control

## Execution (Follow Exactly)

### Step 1: Read Target File
Read the entire file. Do not skim.

### Step 2: Detect Document Type

| Type | Detection |
|------|-----------|
| Skill | YAML frontmatter with `name` and `description` |
| CLAUDE.md | Filename is `CLAUDE.md` |
| README | Filename is `README.md` or starts with `# Project` |
| Design Doc | Has `## Overview` + `## Architecture` |
| Generic | Default |

### Step 3: Scan for Anti-Patterns

Check each principle in order:

1. **Progressive Disclosure**: Quick Start in first 30 lines? Details collapsed? Scannable hierarchy?
2. **DRY**: Any duplicated explanations? Inconsistent terminology?
3. **Context Rot**: Absolute paths (`/Users/`, `C:\`)? Timestamps? "Currently we use"?
4. **Entropy**: Orphaned sections? TODOs? Contradictions? Multiple ways to do same thing?

### Step 4: Run Type-Specific Checks

See [TYPE-CHECKS.md](TYPE-CHECKS.md) for detailed checklists per document type.

### Step 5: Score Each Principle

See [CRITERIA.md](CRITERIA.md) for complete scoring rubric (0-10 per principle, 40 total).

**Red flags (auto-fail to <5):**
- No entry point
- Dead links
- Contradictory instructions
- Exposed credentials

### Step 6: Generate Report

Use this exact format:

```markdown
# Documentation Audit Report

**File:** [path]
**Type:** [Skill | CLAUDE.md | README | Design Doc | Generic]

## Scores

| Principle | Score | Notes |
|-----------|-------|-------|
| Progressive Disclosure | X/10 | [Brief note] |
| DRY Compliance | X/10 | [Brief note] |
| Context Rot | X/10 | [Brief note] |
| Entropy | X/10 | [Brief note] |
| **Total** | **X/40** | |

## Issues

| # | Priority | Principle | Location | Problem | Fix |
|---|----------|-----------|----------|---------|-----|
| 1 | High | [principle] | L[n]-[m] | [what's wrong] | [how to fix] |
| 2 | Medium | ... | ... | ... | ... |

## Recommended Actions

1. [Highest impact fix]
2. [Second priority]
3. ...
```

### Step 7: Fix Mode (if --fix)

If `--fix` flag provided:

1. Show report first (Step 6)
2. For each High priority issue:
   - Show proposed diff
   - Apply fix
3. Re-run audit
4. **Termination criteria** (stop when ANY met):
   - All High priority issues resolved
   - 3 fix iterations completed
   - Score improves by <2 points between iterations
5. Show final report with before/after scores

## Core Principles

### Progressive Disclosure
- Quick Start first (users accomplish something in 30 seconds)
- Details collapsed with `<details>`
- Scannable hierarchy over walls of text

### DRY (Don't Repeat Yourself)
- Each concept explained once
- Link to definitions, don't duplicate
- Consistent terminology throughout

### Context Rot Prevention
- Relative paths only (no `/Users/`, `/home/`, `C:\`)
- No timestamps or "currently we use X"
- Evergreen examples that remain valid

### Entropy Fighting
- Remove obsolete content before adding new
- Consolidate duplicates before expanding
- Every section has clear purpose

## Examples

### Skill Frontmatter Issue

**Before:**
```yaml
---
name: my_skill
description: This skill helps with async testing by providing helpers
---
```

**After:**
```yaml
---
name: my-skill
description: Use when tests have race conditions or timing-dependent failures
---
```

**Issues:** Underscore in name, description doesn't start with "Use when...", explains what not when.

### Progressive Disclosure Violation

**Before:**
```markdown
# My Project

This project uses React, TypeScript, Vite, and Tailwind. It follows
a modular architecture with feature-based organization...
[500 words before any actionable content]
```

**After:**
```markdown
# My Project

npm install && npm run dev

<details>
<summary>Architecture</summary>
Stack: React, TypeScript, Vite, Tailwind
</details>
```

## Reference Files

- [CRITERIA.md](CRITERIA.md) - Complete scoring rubric with examples
- [TYPE-CHECKS.md](TYPE-CHECKS.md) - Type-specific checklists
