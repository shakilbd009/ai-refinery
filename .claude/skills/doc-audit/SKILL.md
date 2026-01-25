---
name: doc-audit
description: Use when reviewing any markdown documentation for quality - CLAUDE.md files, skill files, READMEs, design docs. Checks progressive disclosure, DRY, context rot, entropy. Triggers on audit requests, documentation reviews, or pre-commit doc checks.
---

# Documentation Audit

Validates and improves markdown documentation against best practices. Works on any doc type: CLAUDE.md, skills, READMEs, design docs, guides.

## Quick Start

```bash
# Audit a file
/doc-audit path/to/file.md

# Audit with auto-fix
/doc-audit path/to/file.md --fix

# Audit current directory's CLAUDE.md
/doc-audit
```

## Core Principles

### Progressive Disclosure
- **Quick Start first**: Users accomplish something in 30 seconds
- **Details collapsed**: Use `<details>` for depth
- **Hierarchy over length**: Scannable structure beats walls of text
- **Just-in-time info**: Show details when needed, not upfront

### DRY (Don't Repeat Yourself)
- **Single source of truth**: Each concept explained once
- **Link to definitions**: Reference, don't duplicate
- **Consistent terminology**: Same term for same concept

### Context Rot Prevention
- **No hardcoded paths**: Use relative paths or placeholders
- **No timestamps**: Document principles, not point-in-time state
- **No "current" references**: Avoid "currently we use X"
- **Evergreen examples**: Examples that remain valid

### Entropy Fighting
- **Remove before adding**: Delete obsolete content first
- **Consolidate before expanding**: Merge duplicates
- **Clarify before elaborating**: Fix confusion before adding detail

## Document Type Detection

The audit adapts criteria based on document type:

| Type | Detection | Extra Checks |
|------|-----------|--------------|
| CLAUDE.md | Filename | Quick Start, project context |
| Skill | YAML frontmatter with `name`/`description` | Frontmatter validation, trigger clarity |
| README | Filename or `# Project` heading | Installation, usage examples |
| Design Doc | `## Overview` + `## Architecture` | Completeness, ADR links |
| Generic | Default | Core principles only |

## Audit Process

### Phase 1: Detect & Scan

1. **Detect document type** from filename/content
2. **Scan for anti-patterns**:
   - Progressive disclosure violations (walls of text, no quick start)
   - DRY violations (duplicate explanations, inconsistent terms)
   - Context rot (absolute paths, timestamps, "currently")
   - Entropy (orphaned sections, contradictions, bloat)

### Phase 2: Type-Specific Checks

**For Skills:**
- [ ] YAML frontmatter valid (only `name` and `description`)
- [ ] Name uses only letters, numbers, hyphens
- [ ] Description starts with "Use when..."
- [ ] Description under 500 chars, no workflow summary
- [ ] Clear trigger conditions in description

**For CLAUDE.md:**
- [ ] Quick Start in first 30 lines
- [ ] Project commands documented
- [ ] File structure explained or linked

**For READMEs:**
- [ ] Installation steps present
- [ ] Usage examples shown
- [ ] Prerequisites stated

**For Design Docs:**
- [ ] Overview section exists
- [ ] Architecture diagram or description
- [ ] Trade-offs documented

### Phase 3: Generate Report

For each issue found:

```markdown
## Issue: [Category]

**Location:** Line X-Y / Section "[Name]"
**Problem:** [Specific violation]
**Fix:** [Actionable recommendation]
**Priority:** [High/Medium/Low]
```

## Scoring System

Each principle scored 0-10:
- **10**: Exemplary, no improvements needed
- **7-9**: Good, minor improvements possible
- **4-6**: Needs work, multiple issues
- **1-3**: Poor, major violations
- **0**: Missing or completely broken

**Overall: X/40** (sum of all four principles)

## Red Flags (Auto-fail to <5)

These immediately drop score below 5:
- No clear entry point (Quick Start/Overview)
- Dead links to non-existent files
- Contradictory instructions
- Security issues (exposed credentials)
- Impossible instructions

## Output Format

```markdown
# Documentation Audit Report

**File:** [path]
**Type:** [CLAUDE.md | Skill | README | Design Doc | Generic]
**Date:** [YYYY-MM-DD]

## Summary

- Progressive Disclosure: [Score/10]
- DRY Compliance: [Score/10]
- Context Rot: [Score/10]
- Entropy: [Score/10]

**Overall:** [Score/40]

## Issues Found

### High Priority (N)
[List issues]

### Medium Priority (N)
[List issues]

### Low Priority (N)
[List issues]

## Type-Specific Notes
[Issues specific to document type]

## Recommended Actions

1. [First action with biggest impact]
2. [Second action]
...

## Next Steps

- [ ] Review recommendations
- [ ] Apply critical fixes
- [ ] Re-run audit
```

## Fix Mode

With `--fix`, the audit will:
1. Report all issues first
2. Offer to apply high-priority fixes automatically
3. Show diff for each change before applying
4. Re-run audit after fixes to verify improvement

## Examples

### Skill Frontmatter Issue

**Before:**
```yaml
---
name: my_skill
description: This skill helps with async testing by providing helpers
---
```

**Issues:**
- Name uses underscore (should be hyphen)
- Description doesn't start with "Use when..."
- Description explains what, not when

**After:**
```yaml
---
name: my-skill
description: Use when tests have race conditions or timing-dependent failures
---
```

### Progressive Disclosure Violation

**Before:**
```markdown
# My Project

This project uses React, TypeScript, Vite, and Tailwind. It follows a modular architecture with feature-based organization. The build system supports both development and production modes with hot reloading...

[500 more words before any actionable content]
```

**After:**
```markdown
# My Project

```bash
npm install && npm run dev
```

<details>
<summary>Architecture Details</summary>
Stack: React, TypeScript, Vite, Tailwind
[Details here...]
</details>
```

## Detailed Criteria

See [CRITERIA.md](CRITERIA.md) for complete scoring rubric with examples for each principle and document type.

## Guidelines

- **Start with entry point audit**: Most critical for user experience
- **Fix DRY violations first**: Reduces maintenance burden immediately
- **Archive, don't delete**: Move obsolete content to `<details>` sections
- **Use relative paths**: Make documentation portable
- **Test recommendations**: Ensure suggested changes actually improve clarity
