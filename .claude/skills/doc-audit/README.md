# Documentation Audit Skill

Validates markdown documentation against progressive disclosure, DRY, context rot, and entropy principles.

## Quick Reference

```bash
/doc-audit path/to/file.md        # Audit a file
/doc-audit path/to/file.md --fix  # Audit and auto-fix
/doc-audit                        # Audit current CLAUDE.md
```

## Supported Document Types

| Type | Detection |
|------|-----------|
| Skill | YAML frontmatter with `name`/`description` |
| CLAUDE.md | Filename |
| README | Filename or `# Project` heading |
| Design Doc | `## Overview` + `## Architecture` |
| Generic | Default |

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Main skill with execution steps |
| `CRITERIA.md` | Scoring rubric (0-10 per principle) |
| `TYPE-CHECKS.md` | Type-specific checklists |

## Example Output

```
| Principle | Score |
|-----------|-------|
| Progressive Disclosure | 8/10 |
| DRY Compliance | 6/10 |
| Context Rot | 9/10 |
| Entropy | 7/10 |
| **Total** | **30/40** |
```

See `SKILL.md` for full execution workflow.
