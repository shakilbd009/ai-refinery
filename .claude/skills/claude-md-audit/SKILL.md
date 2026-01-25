---
name: claude-md-audit
description: Validates and improves CLAUDE.md files for best practices - progressive disclosure, DRY principles, context rot prevention, entropy fighting. Use when reviewing CLAUDE.md files, creating new project documentation, or ensuring documentation quality standards.
---

# CLAUDE.md Audit

Validates and improves CLAUDE.md files against best practices to fight entropy and ensure documentation remains in top condition.

## Quick Start

Run this skill on any CLAUDE.md file to check for:
- Progressive disclosure violations
- DRY principle violations
- Context rot symptoms
- Entropy accumulation

The skill provides actionable recommendations and can optionally apply fixes.

## Core Principles

### Progressive Disclosure
- **Quick Start first**: Users should accomplish something in 30 seconds
- **Details in collapsible sections**: Use `<details>` for depth
- **Hierarchy over length**: Scannable structure beats long text
- **Just-in-time information**: Show details when needed, not upfront

### DRY (Don't Repeat Yourself)
- **Single source of truth**: Each concept explained once
- **Link to definitions**: Reference, don't duplicate
- **Templates over duplication**: Shared patterns extracted
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
- **Archive before preserving**: Move old patterns to history

## Audit Checklist

When you run this skill, verify each item:

### Structure
- [ ] Quick Start section exists and is actionable
- [ ] Common tasks in first 100 lines
- [ ] Advanced details in `<details>` sections
- [ ] Table of contents for >300 line files
- [ ] Consistent heading hierarchy

### Content Quality
- [ ] No duplicate explanations
- [ ] Consistent terminology throughout
- [ ] Links to definitions instead of re-explaining
- [ ] Examples use relative paths
- [ ] No time-sensitive language ("currently", "now", "recently")

### Clarity
- [ ] Each section has clear purpose
- [ ] Instructions are imperative ("Do X" not "You can do X")
- [ ] Examples show input AND expected output
- [ ] Error cases documented
- [ ] Prerequisites stated upfront

### Maintenance
- [ ] No dead links
- [ ] No references to moved/deleted files
- [ ] Dependencies explicitly stated
- [ ] Version-specific info in version-specific sections
- [ ] Old patterns archived, not deleted

## Audit Process

### Phase 1: Scan for Anti-Patterns

**Progressive Disclosure Violations:**
- Wall of text in first 100 lines
- No Quick Start section
- Details not collapsed
- Deep nesting (>3 levels visible)

**DRY Violations:**
- Same concept explained multiple times
- Copy-pasted instructions
- Inconsistent terminology for same concept
- Duplicate examples

**Context Rot:**
- Absolute file paths
- Timestamps or dates
- "Currently we use..."
- References to deprecated tools

**Entropy:**
- Orphaned sections
- Contradictory instructions
- Out-of-date examples
- Bloated sections that should be split

### Phase 2: Generate Recommendations

For each issue found, provide:

```markdown
## Issue: [Category]

**Location:** Line X - Y / Section "[Name]"

**Problem:** [Specific violation]

**Fix:** [Actionable recommendation]

**Priority:** [High/Medium/Low]
```

### Phase 3: Offer Improvements

Present options:

1. **Report only** - List all issues found
2. **Interactive fix** - Review each recommendation, apply selectively
3. **Auto-fix** - Apply all high-priority fixes automatically

## Examples

### Example 1: Progressive Disclosure Violation

**Before:**
```markdown
# My Project

This project uses React, TypeScript, Vite, and Tailwind. It has a complex build system with multiple entry points and supports both development and production modes. The architecture follows a modular pattern with feature-based organization...
```

**After:**
```markdown
# My Project

**Quick Start:**
```bash
npm install
npm run dev
```

<details>
<summary>Architecture Details</summary>

Stack: React, TypeScript, Vite, Tailwind

[Details here...]
</details>
```

### Example 2: DRY Violation

**Before:**
```markdown
# Setup

Run `npm install` to install dependencies.

...

# Development

First, run `npm install` to ensure dependencies are installed.
```

**After:**
```markdown
# Setup

```bash
npm install
```

# Development

See [Setup](#setup) for dependency installation, then:

```bash
npm run dev
```
```

### Example 3: Context Rot

**Before:**
```markdown
# Database

Currently we use PostgreSQL 14.2 installed at /usr/local/pgsql/bin
```

**After:**
```markdown
# Database

**Requirements:** PostgreSQL 14+

**Configuration:** Set `DATABASE_URL` in `.env`
```

## Detailed Criteria

See [CRITERIA.md](CRITERIA.md) for complete scoring rubric and examples of each principle.

## Running the Audit

### On Current CLAUDE.md

```
/claude-md-audit
```

### On Specific File

```
/claude-md-audit path/to/CLAUDE.md
```

### With Auto-Fix

```
/claude-md-audit --fix
```

## Success Criteria

A well-maintained CLAUDE.md:
- New users accomplish first task in <1 minute
- Zero duplicate explanations
- Works in any environment (no hardcoded paths)
- Remains accurate for >6 months without updates
- Each section has clear, unique purpose

## Guidelines

- **Start with Quick Start audit**: Most critical for user experience
- **Fix DRY violations first**: Reduces maintenance burden immediately
- **Archive, don't delete**: Move obsolete content to `<details><summary>Old Patterns</summary>` sections
- **Use relative paths**: Make documentation portable
- **Link to source**: Reference code examples from actual project files
- **Test recommendations**: Ensure suggested changes actually improve clarity
- **Preserve history**: Context rot prevention ≠ deleting evolution

## Output Format

Generate audit report as:

```markdown
# CLAUDE.md Audit Report

**File:** [path]
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

## Recommended Actions

1. [First action with biggest impact]
2. [Second action]
...

## Next Steps

- [ ] Review recommendations
- [ ] Apply critical fixes
- [ ] Re-run audit
```
