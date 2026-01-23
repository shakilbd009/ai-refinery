---
name: compound
description: Document a recently solved problem to compound your team's knowledge
---

# /compound

Document a recently solved problem to build institutional knowledge in `docs/solutions/`.

## Purpose

Captures problem solutions while context is fresh, creating searchable documentation with YAML frontmatter. Each documented solution compounds your knowledge - the first time takes research, documented solutions take minutes.

**Knowledge compounds.** Write it down once, use it forever.

## Usage

```bash
/compound                    # Document the most recent solution
/compound [brief context]    # Provide context hint about what was solved
```

## What Gets Documented

### Problem Categories
- **idea-refinement/** - Design decisions and tradeoffs during stage progression
- **workflow-issues/** - Problems with skills, tools, or automation
- **standards-application/** - How to apply docs/ standards correctly
- **graduation-blockers/** - Issues preventing idea advancement or graduation
- **template-fixes/** - Template improvements and corrections
- **tooling-problems/** - Registry, validation, or helper script issues

### Content Structure
Each solution document includes:

**YAML Frontmatter:**
```yaml
---
problem_type: workflow_issue | design_decision | standards_application | etc
component: ideas | skills | tools | templates | docs
symptoms: ["observable behavior", "error messages"]
tags: [relevant, keywords, for, search]
related_issues: []
created: YYYY-MM-DD
---
```

**Markdown Content:**
1. **Problem**: What went wrong or needed solving
2. **Investigation**: What was tried and why it didn't work
3. **Root Cause**: Technical explanation
4. **Solution**: Step-by-step fix with examples
5. **Prevention**: How to avoid this in future
6. **Cross-References**: Links to related docs

## Execution Steps

When `/compound` is invoked, follow these steps:

1. **Analyze recent conversation** (last 10-20 messages):
   - Identify what problem was being solved
   - Find what solution worked
   - Determine which component was affected (ideas/skills/tools/templates/docs)

2. **Determine category**:
   - `idea-refinement/` - Design decisions during stage work
   - `workflow-issues/` - Problems with skills/tools/automation
   - `standards-application/` - How to apply docs/ correctly
   - `graduation-blockers/` - Issues preventing advancement
   - `template-fixes/` - Template improvements
   - `tooling-problems/` - Registry/validation/script issues

3. **Generate slug**: Create kebab-case filename from problem description
   - Example: "Nested checklist validation" → `nested-checklist-validation`

4. **Create solution file**:
   ```bash
   ./tools/create-solution.sh <category> <slug> --component <component>
   ```

5. **Write solution content** to the created file with this structure:
   ```markdown
   # [Problem Title]

   ## Problem
   [What went wrong or needed solving]

   ## Investigation
   [What was tried, what didn't work, why]

   ## Root Cause
   [Technical explanation of the underlying issue]

   ## Solution
   [Step-by-step fix with code examples from conversation]

   ## Prevention
   [How to avoid this problem in future]

   ## Related
   [Links to relevant docs/ files]
   ```

6. **Confirm to user**:
   - Show file path
   - Summarize what was documented
   - Explain time saved on future occurrences

## Preconditions

Only use `/compound` when:
- ✓ Problem has been **solved** (not in-progress)
- ✓ Solution has been **verified working**
- ✓ Problem is **non-trivial** (not a simple typo)
- ✓ Solution is **reusable** (will help future work)

Skip for trivial fixes or one-off issues.

## Output Structure

```
docs/solutions/
├── idea-refinement/
│   ├── stage-checklist-validation.md
│   └── design-decision-documentation.md
├── workflow-issues/
│   ├── skill-tool-integration.md
│   └── parallel-agent-coordination.md
├── standards-application/
│   ├── folder-naming-edge-cases.md
│   └── claude-md-progressive-disclosure.md
├── graduation-blockers/
│   ├── incomplete-stage-detection.md
│   └── template-merge-conflicts.md
├── template-fixes/
│   └── readme-template-formatting.md
└── tooling-problems/
    ├── registry-json-corruption.md
    └── validation-script-errors.md
```

## Example Session

**User completes stage advancement after fixing validation logic:**

```
You: "That worked! The checklist validation now correctly handles nested items."

Claude: /compound

✓ Documentation created

Context Extracted:
  Problem: Checklist validation failed on nested list items
  Category: tooling-problems
  Component: validation script

File Created:
  docs/solutions/tooling-problems/nested-checklist-validation.md

What this captures:
  - The regex pattern that failed
  - Why nested items weren't matched
  - The corrected validation logic
  - Test cases for future validation changes

Next occurrence of this issue: 2 minutes (lookup) vs 30 minutes (research)
```

## The Compounding Effect

### First Time (30 min)
```
Problem → Research → Trial & Error → Solution → Deploy
```

### After Documentation (2 min)
```
Problem → Search docs/solutions/ → Apply Solution → Deploy
```

### After Multiple Solutions (Team Learning)
```
Problem → Patterns Emerge → Prevention Built In → No Problem
```

## Integration with ai-baseline

This skill integrates with your meta-repository workflow:

### During Idea Refinement
```bash
/new-idea my-app          # Create idea
# Work through stages...
# Hit a problem with validation
# Solve it
/compound                 # Document the solution
/advance-stage my-app     # Continue progression
```

### During Graduation
```bash
# Problem: Template merge creates conflicts
# Solve it
/compound                 # Capture the fix
/graduate my-app ~/code   # Graduate with confidence
```

### Cross-Idea Learning
```bash
# Second idea hits same validation issue
# Search docs/solutions/
# Apply documented fix immediately
# Knowledge compounded ✓
```

## Auto-Invoke Triggers

The skill can auto-detect when to offer documentation:

**Phrases that indicate solved problems:**
- "that worked"
- "it's fixed"
- "working now"
- "problem solved"
- "successfully advanced"
- "graduation complete"

**Manual override:**
```bash
/compound [context]  # Document immediately
```

## Implementation Strategy

When invoked, this skill should:

1. **Extract Context** from recent conversation
   - Identify what was broken
   - Find what fixed it
   - Determine problem category

2. **Generate YAML Frontmatter**
   ```yaml
   ---
   problem_type: tooling_problem
   component: validation
   symptoms: ["Nested checklist items not validated"]
   tags: [checklist, validation, regex, markdown]
   related_issues: []
   created: 2026-01-22
   ---
   ```

3. **Structure Solution Document**
   - Problem description
   - Investigation steps
   - Root cause
   - Working solution with code
   - Prevention strategy

4. **Choose Category & Filename**
   - Auto-detect from problem type
   - Generate slug from problem description
   - Create in `docs/solutions/[category]/[slug].md`

5. **Optional: Update Index**
   - Link from related standards docs
   - Add to searchable index

## Philosophy

Each unit of engineering work should make subsequent units easier, not harder.

**Without /compound:**
- Solve problem → Forget details → Solve again later → Waste time

**With /compound:**
- Solve problem → Document → Future problems instant → Time saved

The difference between a team that learns and a team that repeats.

## Related Skills

- `/new-idea` - Start refinement (may need compound for blockers)
- `/advance-stage` - Progress through stages (may hit documented issues)
- `/graduate` - Create production repo (uses compound knowledge)

## Future Enhancements

As your team uses `/compound`, consider adding:

1. **Search Command**: `/find-solution [keywords]` to search docs/solutions/
2. **Pattern Detection**: Auto-identify recurring problem types
3. **Prevention Automation**: Generate validation rules from solutions
4. **Graduation Enhancement**: Include relevant solutions in graduated repos

---

**Start using /compound today. Each problem you document makes your team smarter.**