---
problem_type: workflow_issues
component: skills
symptoms:
  - "Need to replicate compound engineering principles for ai-baseline"
  - "Want systematic way to document learnings across ideas"
  - "Knowledge not being captured and reused"
tags: [compound, knowledge-management, meta, workflow, documentation, skills]
related_issues: []
related_solutions:
  - compound-skill-creation.md
created: 2026-01-22
---

# Replicating Compound Engineering System for Meta-Repository

## Problem

**What was needed:**
User wanted to replicate the `/workflows:compound` skill pattern from the compound-engineering plugin for their ai-baseline meta-repository to build institutional knowledge.

**Context:**
The ai-baseline project is a meta-repository for refining ideas through progressive stages. Without a knowledge capture system, design decisions, solved problems, and learnings were being lost. Each new idea would potentially re-solve the same problems.

**Why it matters:**
Meta-repositories benefit exponentially from compound knowledge. A single documented solution can help every future idea that goes through the pipeline. Without this, teams repeatedly solve identical problems during idea refinement, stage progression, and graduation.

## Investigation

**Approach taken:**

1. **Examined the original compound-engineering skill**
   - Invoked `/workflows:compound` to see full implementation
   - Analyzed parallel subagent strategy (not needed for ai-baseline)
   - Studied YAML frontmatter structure
   - Reviewed categorization system (build-errors, test-failures, etc.)
   - Understanding: Original focused on production code issues

2. **Analyzed ai-baseline project structure**
   - Read CLAUDE.md to understand workflows
   - Examined existing skills: /new-idea, /advance-stage, /graduate, etc.
   - Reviewed docs/ folder organization
   - Checked ideas/ registry structure
   - Understanding: Needed categories matching meta-repository workflows

3. **Identified adaptation requirements**
   - Original categories (build-errors, performance) don't fit meta-repo
   - Need categories for: design decisions, workflow issues, standards edge cases
   - Solution structure can remain similar (YAML + markdown)
   - Integration points: idea refinement, stage advancement, graduation

## Root Cause

**Core requirement:**
ai-baseline needed systematic capture of:
- **Design decisions** made during idea refinement
- **Workflow problems** with skills and automation
- **Standards edge cases** when applying docs/
- **Graduation blockers** preventing advancement
- **Template issues** discovered during use
- **Tooling problems** with registry and scripts

**Why adaptation was needed:**
The compound-engineering categories assume production codebases with tests, builds, databases, etc. A meta-repository has different problem types: process issues, design decisions, template problems, and workflow automation challenges.

**Why this matters:**
Meta-repositories compound knowledge across multiple projects. One documented solution about "how to structure stage checklists" helps every future idea. The ROI is higher than single-project knowledge bases.

## Solution

**Complete compound system created with ai-baseline-specific adaptations:**

### 1. Created `/compound` skill
**File:** `skills/compound.md`

```markdown
---
name: compound
description: Document a recently solved problem to compound your team's knowledge
---

# /compound

Document a recently solved problem to build institutional knowledge...
```

**Key adaptations:**
- Categories matched to ai-baseline workflows (not code issues)
- Integration examples with /new-idea, /advance-stage, /graduate
- Problem types: idea_refinement, workflow_issue, standards_application, etc.
- Simpler execution flow (no parallel subagents needed)

### 2. Created solution folder structure

```bash
mkdir -p docs/solutions/{idea-refinement,workflow-issues,standards-application,graduation-blockers,template-fixes,tooling-problems}
```

**Category mapping:**

| Original Compound | ai-baseline Adaptation | Reason |
|------------------|----------------------|---------|
| build-errors/ | tooling-problems/ | Registry/validation scripts |
| test-failures/ | workflow-issues/ | Skill/automation problems |
| runtime-errors/ | graduation-blockers/ | Issues preventing advancement |
| performance-issues/ | standards-application/ | Edge cases in applying standards |
| database-issues/ | idea-refinement/ | Design decision documentation |
| N/A | template-fixes/ | New category for templates |

### 3. Created supporting documentation

```bash
# Core documentation
docs/compound-guide.md              # Complete usage guide
docs/solutions/README.md            # Index and overview
docs/solutions/SETUP.md             # Setup and philosophy
docs/solutions/QUICK-REFERENCE.md  # One-page reference
docs/solutions/.template.md         # Solution template

# Example solution (meta!)
docs/solutions/workflow-issues/compound-skill-creation.md
```

### 4. Created helper tool

```bash
tools/create-solution.sh
chmod +x tools/create-solution.sh
```

**Usage:**
```bash
# Interactive mode
./tools/create-solution.sh

# Scripted mode
./tools/create-solution.sh workflow-issues my-problem \
  --component skills \
  --symptom "Observable issue" \
  --tag automation
```

### 5. Updated CLAUDE.md

```markdown
### `/compound [context]`
Document a recently solved problem to build institutional knowledge.

<details>
<summary>Compound Knowledge System</summary>
...categories, usage, philosophy...
</details>
```

### 6. Created example solution (meta-documentation)

Documented the creation of the compound system itself in:
`docs/solutions/workflow-issues/compound-skill-creation.md`

This demonstrates the complete solution format and serves as a reference.

**Verification:**

```bash
# Check structure
ls docs/solutions/
# Output: idea-refinement/ workflow-issues/ standards-application/
#         graduation-blockers/ template-fixes/ tooling-problems/
#         README.md SETUP.md QUICK-REFERENCE.md .template.md

# Check skill
cat skills/compound.md | head -5
# Output: ---
#         name: compound
#         description: Document a recently solved problem...

# Test helper
./tools/create-solution.sh --help
# Output: Usage: create-solution.sh <category> <slug> [options]

# Commit
git add -A
git commit -m "Add compound knowledge system..."
# Success: 9 files changed, 1698 insertions(+)
```

**Result:**
Complete compound knowledge system adapted for meta-repository workflows, ready to use immediately.

## Prevention

**How to build the compound habit in your workflow:**

1. **Integrate with existing workflows**
   ```bash
   # Add to workflow documentation
   /new-idea → work → solve problem → /compound → /advance-stage
   ```

2. **Make it visible**
   - Reference in CLAUDE.md ✓
   - Include in skills list ✓
   - Add to quick start guide ✓

3. **Create examples early**
   - Document the system creation itself ✓
   - Add 2-3 more examples in first week
   - Show value through time savings

4. **Search before solving**
   ```bash
   # Add to workflow habit
   grep -r "similar issue" docs/solutions/
   # If found: use (2 min)
   # If not: solve + document (30 min + 5 min)
   ```

5. **Track compound effect**
   - Week 1: Document 3 problems (baseline)
   - Week 2: Reference 1 solution, save 28 min
   - Week 3: Reference 3 solutions, save 84 min
   - Month 2: Patterns emerge, prevention built in

**Checklist for similar meta-repository enhancements:**

- [ ] Examine original implementation from source plugin
- [ ] Identify what needs adaptation vs what's universal
- [ ] Map categories to your specific domain
- [ ] Create folder structure matching your workflows
- [ ] Write comprehensive documentation (people need to understand WHY)
- [ ] Provide examples (meta-documentation works well)
- [ ] Create helper tools for ease of use
- [ ] Update main CLAUDE.md with references
- [ ] Commit with clear explanation

## Cross-References

**Related documentation:**
- [skills/compound.md](../../skills/compound.md) - The skill itself
- [docs/compound-guide.md](../compound-guide.md) - Complete usage guide
- [docs/solutions/SETUP.md](../solutions/SETUP.md) - Setup and philosophy
- [docs/solutions/QUICK-REFERENCE.md](../solutions/QUICK-REFERENCE.md) - Quick reference

**Related solutions:**
- [compound-skill-creation.md](compound-skill-creation.md) - How we built the system

**Skills that integrate:**
- `/new-idea` - Document refinement patterns found during ideation
- `/advance-stage` - Document blocker solutions during progression
- `/graduate` - Document template issues during graduation

**External inspiration:**
- compound-engineering plugin - Original implementation
- DHH's philosophy - "Extract knowledge into systems"
- Zettelkasten method - Compound note-taking

**Philosophy:**
"Each unit of engineering work should make subsequent units easier, not harder."

Applied to knowledge: "Each problem solved should be documented once, making future occurrences instant to resolve."

---

**Tags for search:** #compound #knowledge-management #meta-repository #workflow #adaptation #skills #documentation #institutional-learning
