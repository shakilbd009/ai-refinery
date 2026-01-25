# CLAUDE.md Audit Skill

Validates and improves CLAUDE.md files following best practices: progressive disclosure, DRY principles, context rot prevention, and entropy fighting.

## Quick Reference

```bash
# Audit current CLAUDE.md
/claude-md-audit

# Audit specific file
/claude-md-audit path/to/CLAUDE.md

# Audit and apply fixes
/claude-md-audit --fix
```

## What It Checks

### Progressive Disclosure
- Quick Start in first 30 seconds
- Details in collapsible sections
- Scannable hierarchy

### DRY Principles
- No duplicate explanations
- Consistent terminology
- Single source of truth

### Context Rot Prevention
- No hardcoded paths
- No timestamps
- Evergreen examples

### Entropy Fighting
- Clear section purposes
- No orphaned content
- Active maintenance

## Output

Generates scored report (0-40):
- Each principle scored 0-10
- Specific issues with line numbers
- Actionable recommendations
- Priority levels (High/Medium/Low)

## Files

- `SKILL.md` - Main skill file
- `CRITERIA.md` - Detailed scoring rubric
- `EXAMPLE-AUDIT.md` - Sample audit of ai-baseline's CLAUDE.md
- `README.md` - This file

## Example Output

```markdown
# CLAUDE.md Audit Report

**Overall: 38/40**

## Issues Found

### Medium Priority (1)

#### Issue: Hardcoded Path
**Location:** Line 21
**Fix:** Use relative path instead of ~/code/my-project

## Recommended Actions

1. Fix hardcoded paths
2. Add prerequisites to Quick Start
```

## Usage in Workflows

### Before Committing CLAUDE.md Changes
Run audit to catch issues before they enter codebase.

### During Project Setup
Validate new CLAUDE.md follows standards.

### Monthly Maintenance
Regular audits prevent documentation decay.

### Pre-Graduation
Ensure projects graduate with high-quality docs.

## Philosophy

Documentation fights entropy or succumbs to it. This skill:
- Catches decay early
- Enforces standards
- Prevents accumulation of cruft
- Maintains clarity over time

**Leave documentation better than you found it.**
