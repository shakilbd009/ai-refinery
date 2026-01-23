# Compound Knowledge System

Build institutional knowledge by documenting problems once, using solutions forever.

## The Principle

**Knowledge compounds.**

- First time: 30 minutes research → solution
- After documentation: 2 minutes lookup → apply
- After patterns emerge: Prevention built in

Each documented solution makes your team smarter.

## Quick Start

### 1. Solve a Problem
Work through your issue normally using ai-baseline workflows.

### 2. Document the Solution
```bash
/compound
```

Claude will:
- Extract problem context from conversation
- Determine the appropriate category
- Generate YAML frontmatter for searchability
- Create structured solution document
- Save to `docs/solutions/[category]/[slug].md`

### 3. Reuse When Similar Issues Occur
```bash
# Search for solutions
grep -r "keyword" docs/solutions/
rg "error pattern" docs/solutions/

# Or browse by category
ls docs/solutions/workflow-issues/
```

## Solution Categories

### idea-refinement/
**When to use:** Design decisions during stage progression
- Architectural tradeoffs
- Component design patterns
- Data flow decisions
- Technology choices

**Example:** "Why we chose modular stages over monolithic design"

### workflow-issues/
**When to use:** Problems with skills, tools, automation
- Skill integration failures
- Parallel agent coordination
- Workflow optimization discoveries
- Tool invocation issues

**Example:** "Skill fails to read registry JSON"

### standards-application/
**When to use:** Edge cases in applying docs/ standards
- Folder naming edge cases
- File naming exceptions
- CLAUDE.md structure questions
- Convention conflicts

**Example:** "How to handle nested list items in CLAUDE.md"

### graduation-blockers/
**When to use:** Issues preventing advancement or graduation
- Stage validation failures
- Incomplete checklist detection
- Readiness criteria edge cases
- Template merge conflicts

**Example:** "Checklist validation fails on nested items"

### template-fixes/
**When to use:** Template improvements and corrections
- README template formatting
- Config file templates
- Starter file updates
- Template bugs

**Example:** "README template missing license section"

### tooling-problems/
**When to use:** Registry, validation, helper script issues
- JSON schema problems
- Script execution errors
- Automation failures
- Tool integration bugs

**Example:** "Registry tool corrupts JSON on concurrent writes"

## Solution Document Structure

Every solution follows this template:

```yaml
---
problem_type: workflow_issue
component: skills
symptoms:
  - "Observable behavior"
  - "Error messages"
tags: [searchable, keywords]
related_issues: []
related_solutions: []
created: 2026-01-22
---

## Problem
What went wrong, context, why it matters

## Investigation
What was tried and why it didn't work

## Root Cause
Technical explanation

## Solution
Step-by-step fix with code examples

## Prevention
How to avoid in future

## Cross-References
Links to related docs and solutions
```

## Usage Patterns

### Pattern 1: Immediate Documentation
```bash
# Solve a problem during idea refinement
/new-idea my-app
# ... work through stages ...
# Hit validation issue
# Fix it
/compound  # Document immediately while fresh
```

### Pattern 2: Batch Documentation
```bash
# After completing a stage with multiple issues
/advance-stage my-app
# Document each non-trivial fix
/compound  # For issue 1
/compound  # For issue 2
/compound  # For issue 3
```

### Pattern 3: Search Before Solve
```bash
# Before spending time solving
grep -r "similar symptom" docs/solutions/
# Check if already documented
# If yes: apply solution (2 min)
# If no: solve, then document (30 min + 5 min doc)
```

### Pattern 4: Pattern Recognition
```bash
# After documenting 3+ similar issues
# Recognize the pattern
# Update docs/ standards to prevent recurrence
# Future instances: prevented automatically
```

## Integration with ai-baseline Workflows

### During `/new-idea`
```
Create idea → Work on design → Hit edge case →
Solve it → /compound → Continue
```

Solutions document design decisions for reuse in future ideas.

### During `/advance-stage`
```
Work through checklist → Hit blocker →
Solve it → /compound → Advance stage
```

Solutions help future ideas advance faster.

### During `/graduate`
```
Graduate idea → Template issue occurs →
Fix template → /compound → Next graduation smoother
```

Solutions improve templates over time.

## When to Use /compound

### DO Document
✓ Non-trivial problems with reusable solutions
✓ Edge cases in standards or workflows
✓ Design decisions with clear reasoning
✓ Tool/script bugs and fixes
✓ Template improvements

### DON'T Document
✗ Simple typos or obvious errors
✗ One-off issues specific to single idea
✗ Problems still being debugged
✗ Unverified solutions

## The Compounding Effect

### Month 1
- Document 5 solutions
- Save 0 minutes (building knowledge base)

### Month 2
- Document 3 more solutions
- Reference existing solutions 4 times
- Save 112 minutes (4 × 28 min avoided research)

### Month 3
- Document 2 more solutions
- Reference existing solutions 12 times
- Patterns emerge, prevention built into standards
- Save 336 minutes + prevented issues

### Month 6
- Knowledge base mature
- Most issues have documented solutions
- New team members onboard faster
- **Knowledge has compounded**

## Advanced Usage

### Create Solution Manually
```bash
./tools/create-solution.sh workflow-issues my-problem-slug \
  --component skills \
  --symptom "Skill fails to invoke" \
  --tag automation --tag debugging
```

### Search Solutions
```bash
# By keyword
grep -r "validation" docs/solutions/

# By tag (in YAML frontmatter)
rg "tags: \[.*automation.*\]" docs/solutions/

# By component
rg "component: skills" docs/solutions/

# By date
rg "created: 2026-01" docs/solutions/
```

### Update Solutions Index
```bash
# Manual update (future automation)
# Update docs/solutions/README.md with new entries
```

### Link Solutions in Skills
```markdown
# In skills/advance-stage.md
See [nested checklist validation](../docs/solutions/tooling-problems/nested-checklist-validation.md)
if validation fails on nested items.
```

## Philosophy

**Compound Engineering Principle:**
> Each unit of engineering work should make subsequent units easier, not harder.

**Applied to knowledge:**
> Each problem solved should be documented once, making future occurrences instant to resolve.

**Result:**
Teams that compound knowledge scale better than teams that repeatedly solve the same problems.

## Examples

See existing solutions:
- [Compound skill creation](solutions/workflow-issues/compound-skill-creation.md) - This very system
- More examples as they're created...

## Related Skills

- `/new-idea` - May hit documented issues during creation
- `/advance-stage` - May reference solutions for blockers
- `/graduate` - Benefits from template fix solutions

## Future Enhancements

As the system matures, consider:

1. **Solution search command**: `/find-solution [keywords]`
2. **Auto-linking**: Automatically suggest solutions when errors match symptoms
3. **Pattern detection**: AI identifies recurring problem types
4. **Prevention automation**: Generate validation rules from solutions
5. **Graduation inclusion**: Include relevant solutions in graduated repos

---

**Start documenting today. Each problem you solve can help future you.**

Use `/compound` after solving your next non-trivial issue.
