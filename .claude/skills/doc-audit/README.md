# Documentation Audit Skill

Validates and improves any markdown documentation following best practices.

## Quick Reference

```bash
# Audit any file
/doc-audit path/to/file.md

# Audit with auto-fix
/doc-audit path/to/file.md --fix

# Default: audit current CLAUDE.md
/doc-audit
```

## Supported Document Types

- **CLAUDE.md** - Project instructions for Claude
- **Skill files** - Skills with YAML frontmatter
- **READMEs** - Project documentation
- **Design docs** - Architecture and design documents
- **Any markdown** - Generic documentation

## What It Checks

### Core Principles (All Types)

| Principle | What | Score |
|-----------|------|-------|
| Progressive Disclosure | Quick entry point, collapsed details | /10 |
| DRY | No duplication, consistent terminology | /10 |
| Context Rot | No absolute paths, evergreen content | /10 |
| Entropy | Clear purpose, no orphaned content | /10 |

### Type-Specific Checks

**Skills:** Frontmatter validation, trigger clarity, CSO keywords
**CLAUDE.md:** Quick Start, project commands, conventions
**READMEs:** Installation, usage, prerequisites
**Design Docs:** Overview, architecture, trade-offs

## Output

Generates scored report (0-40):
- Each principle scored 0-10
- Issues with line numbers
- Actionable recommendations
- Priority levels (High/Medium/Low)

## Files

- `SKILL.md` - Main skill file
- `CRITERIA.md` - Detailed scoring rubric
- `README.md` - This file

## Example Usage

**Review a skill before deployment:**
```bash
/doc-audit .claude/skills/my-skill/SKILL.md
```

**Check CLAUDE.md before committing:**
```bash
/doc-audit CLAUDE.md
```

**Audit design docs:**
```bash
/doc-audit docs/architecture.md
```

## Philosophy

Documentation fights entropy or succumbs to it. This skill:
- Catches decay early
- Enforces standards across doc types
- Prevents accumulation of cruft
- Maintains clarity over time

**Leave documentation better than you found it.**
