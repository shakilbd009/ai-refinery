# Compound System Quick Reference

One-page reference for the compound knowledge system.

## The Principle

**Knowledge compounds.** Document once, use forever.

## Commands

```bash
# Document a solved problem
/compound

# Document with context hint
/compound [brief description]

# Search solutions
grep -r "keyword" docs/solutions/
rg "error pattern" docs/solutions/

# Create solution manually
./tools/create-solution.sh <category> <slug>

# Browse by category
ls docs/solutions/<category>/
```

## Categories

| Category | Use For | Example |
|----------|---------|---------|
| `idea-refinement/` | Design decisions | "Why modular vs monolithic" |
| `workflow-issues/` | Skills/tools problems | "Skill invocation failure" |
| `standards-application/` | Edge cases in standards | "Nested CLAUDE.md lists" |
| `graduation-blockers/` | Advancement issues | "Checklist validation fails" |
| `template-fixes/` | Template improvements | "Missing README section" |
| `tooling-problems/` | Scripts/registry issues | "JSON corruption on write" |

## When to Document

### DO Document ✓
- Non-trivial problems (>5 min to solve)
- Reusable solutions
- Edge cases in standards
- Design decisions with reasoning
- Tool/script bugs and fixes

### DON'T Document ✗
- Simple typos
- One-off issues
- Unverified solutions
- Problems still debugging

## Solution Structure

```yaml
---
problem_type: [category_name]
component: ideas|skills|tools|templates|docs
symptoms: ["observable", "behaviors"]
tags: [searchable, keywords]
created: YYYY-MM-DD
---

## Problem
What, context, why it matters

## Investigation
What didn't work and why

## Root Cause
Technical explanation

## Solution
Step-by-step with code

## Prevention
How to avoid

## Cross-References
Related docs
```

## Workflow Integration

```bash
# During idea work
/new-idea my-app
# ... solve problem ...
/compound
/advance-stage my-app

# During graduation
/graduate my-app ~/code
# ... fix template ...
/compound
```

## Search Patterns

```bash
# By keyword
grep -r "validation" docs/solutions/

# By tag
rg "tags: \[.*automation.*\]" docs/solutions/

# By component
rg "component: skills" docs/solutions/

# By category
ls docs/solutions/workflow-issues/

# By date
rg "created: 2026-01" docs/solutions/
```

## The Compounding Effect

| Time | Action | Result |
|------|--------|--------|
| First solve | 30 min research → document | 5 min overhead |
| Second occurrence | 2 min lookup → apply | 28 min saved |
| Third occurrence | 2 min lookup → apply | 28 min saved |
| After pattern | Built into standards | **Prevented** |

## Files

```
skills/compound.md                 # The skill
docs/compound-guide.md             # Full guide
docs/solutions/                    # All solutions
docs/solutions/README.md           # Index
docs/solutions/.template.md        # Template
docs/solutions/SETUP.md            # Setup guide
docs/solutions/QUICK-REFERENCE.md  # This file
tools/create-solution.sh           # Helper script
```

## Example Solution

See: `docs/solutions/workflow-issues/compound-skill-creation.md`

## Philosophy

> Each unit of engineering work should make subsequent units easier, not harder.

## Next Action

**Solve a problem? Run `/compound`**

---

Keep this reference handy. Build the habit. Watch knowledge compound.
