---
problem_type: workflow_issue
component: skills
symptoms:
  - "Need to replicate compound engineering principle for ai-baseline"
  - "Want to build institutional knowledge system"
tags: [compound, knowledge-management, documentation, workflow, skills]
related_issues: []
related_solutions: []
created: 2026-01-22
---

# Creating Compound Knowledge System for ai-baseline

## Problem

**What was needed:**
Replicate the `/workflows:compound` skill pattern from compound-engineering plugin for the ai-baseline meta-repository to build institutional knowledge.

**Context:**
User is a fan of compound engineering principles and wants to capture learnings as they work through idea refinement, stage advancement, and graduation workflows.

**Why it matters:**
Without documentation, teams repeatedly solve the same problems. Each problem solved should be documented once and referenced forever - knowledge compounds.

## Investigation

**Approach taken:**

1. **Examined existing compound skill:**
   - Invoked `/workflows:compound` to understand full implementation
   - Analyzed parallel subagent strategy
   - Reviewed YAML frontmatter structure
   - Studied categorization system

2. **Analyzed ai-baseline structure:**
   - Reviewed CLAUDE.md for current skills
   - Examined docs/ folder organization
   - Checked skills/ folder for existing patterns
   - Identified gaps in knowledge capture

## Root Cause

**Core requirement:**
ai-baseline needed a systematic way to capture:
- Design decisions during refinement
- Problems solved during stage progression
- Standards application edge cases
- Workflow and tooling issues
- Template improvements

**Why this matters:**
Meta-repositories compound knowledge across multiple projects. Documenting solutions once saves time on every future idea.

## Solution

**Created comprehensive compound system:**

### 1. Created `/compound` skill
```bash
skills/compound.md
```

**Key features:**
- Category system matching ai-baseline workflows
- YAML frontmatter for searchability
- Structured solution format
- Auto-invoke triggers
- Integration with existing skills

### 2. Created solutions folder structure
```bash
docs/solutions/
├── README.md                    # Index and usage guide
├── .template.md                 # Template for new solutions
├── idea-refinement/            # Design decisions
├── workflow-issues/            # Skills and automation
├── standards-application/      # How to apply docs/
├── graduation-blockers/        # Advancement issues
├── template-fixes/             # Template improvements
└── tooling-problems/           # Scripts and validation
```

### 3. Adapted categories for ai-baseline
Original compound-engineering categories focused on:
- build-errors, test-failures, runtime-errors
- performance, database, security issues

ai-baseline categories focus on:
- idea refinement, workflow issues
- standards application, graduation blockers
- templates, tooling

### 4. Created solution template
```bash
docs/solutions/.template.md
```

Provides consistent structure:
- YAML frontmatter
- Problem description
- Investigation steps
- Root cause analysis
- Step-by-step solution
- Prevention strategies
- Cross-references

### 5. Updated CLAUDE.md
Added `/compound` to Skills Reference section.

**Result:**
Complete compound knowledge system ready to use. Every problem solved can now be documented and searchable.

## Prevention

**How to build compound knowledge habit:**

1. **Use /compound after solving non-trivial problems**
   ```bash
   # Solve a problem
   /compound  # Document it immediately
   ```

2. **Search before solving**
   ```bash
   grep -r "similar issue" docs/solutions/
   # Check if already documented
   ```

3. **Update CLAUDE.md with patterns**
   As patterns emerge from solutions, codify them into standards.

4. **Link solutions in skills**
   Reference solutions in skill documentation where relevant.

**Checklist for compound workflow:**
- [ ] Problem is solved and verified
- [ ] Solution is non-trivial and reusable
- [ ] Run `/compound` to document
- [ ] Tag appropriately for search
- [ ] Link related solutions

## Cross-References

**Related documentation:**
- [docs/claude-md-guide.md](../claude-md-guide.md) - Progressive disclosure principle
- [skills/compound.md](../../skills/compound.md) - The skill itself

**Skills that benefit:**
- `/new-idea` - Document refinement patterns
- `/advance-stage` - Document blocker solutions
- `/graduate` - Document template issues

**Philosophy:**
"Each unit of engineering work should make subsequent units easier, not harder."

---

**Tags for search:** #compound #knowledge-management #meta #workflow #documentation #skills
