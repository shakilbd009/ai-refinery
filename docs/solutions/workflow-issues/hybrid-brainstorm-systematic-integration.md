---
problem_type: workflow_issues
component: skills
symptoms:
  - "User must explain hybrid brainstorm → systematic-refinement workflow every time"
  - "Claude doesn't automatically know to start with brainstorming"
  - "Manual decision required for when to escalate to systematic refinement"
tags: [workflow, automation, brainstorming, systematic-refinement, skill-integration, orchestration]
related_issues: []
related_solutions: []
created: 2026-01-24
---

# Hybrid Brainstorm → Systematic Refinement Workflow Integration

## Problem

**What went wrong:**
Users wanted a hybrid approach where every new idea starts with lightweight brainstorming, then automatically escalates to systematic refinement only when complexity warrants it. However, Claude required explicit instructions each time about:
- Which skill to use first (brainstorming vs systematic-refinement)
- When to transition between them
- What criteria determine the transition
- How to orchestrate the handoff

**Context:**
This affected the `/new-idea` workflow. Users had to manually:
1. Decide whether to start with brainstorming or go straight to systematic refinement
2. Remember to transition after brainstorming completes
3. Set up the systematic refinement stage structure if escalating
4. Transfer brainstorming insights to the ideas registry

**Why it matters:**
- **Cognitive overhead**: User must make meta-decisions about process instead of focusing on the idea
- **Inconsistency**: Different ideas might skip brainstorming or skip systematic refinement inappropriately
- **Lost context**: Transition between skills loses context from brainstorming phase
- **Repetition**: User explains the same workflow pattern every time

## Investigation

**Attempts that didn't work:**

1. **Tried:** Document the hybrid approach in a guide (markdown file in `docs/`)
   - **Why it failed:** Claude doesn't automatically read guides unless explicitly pointed to them. Users still had to reference the guide each time.
   - **Learning:** Passive documentation doesn't change default behavior. Need active orchestration.

2. **Tried:** Add instructions to CLAUDE.md about when to use each skill
   - **Why it failed:** CLAUDE.md provides context but doesn't enforce workflow. Claude still waited for user to choose which skill to invoke.
   - **Learning:** Instructions set expectations but don't automate decisions. Need executable workflow.

3. **Considered:** Merge brainstorming and systematic-refinement into one mega-skill
   - **Why rejected:** Would lose the benefits of each skill being focused and reusable independently. Violates single-responsibility principle for skills.
   - **Learning:** Need orchestration layer, not skill merger.

## Root Cause

**Technical explanation:**
The underlying issue was **lack of executable orchestration** for multi-skill workflows. Claude Code skills are:
- **Invoked explicitly** by user via `/skill-name`
- **Independent** - no built-in handoff mechanism between skills
- **Stateless** - each invocation starts fresh without knowing about prior skills in the workflow

When users wanted "brainstorm first, then escalate if needed," this required:
1. Manual invocation of `/superpowers:brainstorming`
2. Manual decision point after brainstorming completes
3. Manual setup of systematic refinement structure
4. Manual invocation of `/systematic-refinement`
5. Manual context transfer between the two skills

**Missing piece:** An orchestrator skill that:
- Knows the workflow steps
- Makes the transition decision based on criteria
- Handles context transfer between skills
- Invokes sub-skills automatically

**Why this matters:**
Without orchestration, complex workflows require users to be "process managers" instead of focusing on their actual work. The orchestrator pattern enables Claude to own the workflow logic.

## Solution

**Step-by-step fix:**

1. **Create orchestrator skill: `/new-idea`**
   ```bash
   mkdir -p skills/new-idea
   # Created skills/new-idea/SKILL.md
   ```

   The skill implements the workflow:
   - Phase 1: Auto-invoke `/superpowers:brainstorming`
   - Decision Point: Ask user "Simple or Complex?" with clear criteria
   - Phase 2: If complex, auto-invoke `/systematic-refinement`
   - Context Transfer: Move brainstorming outputs to systematic refinement structure

2. **Update CLAUDE.md to document hybrid as default**
   ```markdown
   ### Default Workflow: Hybrid Approach

   1. Phase 1: Rapid Exploration (automatic)
      - /new-idea triggers brainstorming
   2. Phase 2: Deep Refinement (automatic transition)
      - Escalates to systematic-refinement if warranted
   3. Graduation
      - Production-ready repo
   ```

3. **Add decision criteria to skill**
   The `/new-idea` skill documents when to stay lightweight vs escalate:

   **Implement directly if:**
   - Simple, well-understood problem
   - Low stakes (internal tool, prototype)
   - Single implementer

   **Escalate to systematic refinement if:**
   - Complex with many unknowns
   - High stakes (production, users depend on it)
   - Team implementation
   - Security/safety/compliance critical

4. **Add Mermaid workflow diagram to CLAUDE.md**
   Visual representation showing both paths from `/new-idea`

**Key implementation details:**

```markdown
# In /new-idea SKILL.md

## How This Works

1. Phase 1: Brainstorming (Automatic)
   - Invoke /superpowers:brainstorming
   - Explore conversationally
   - Create initial design doc

2. Transition Decision (Automatic)
   - Ask: "Simple or Complex?"
   - Present decision criteria
   - Get user choice

3. Phase 2: Systematic Refinement (If Needed)
   - Create ideas registry entry
   - Initialize stage structure
   - Invoke /systematic-refinement stage-2
```

**Result:**
Users now just type `/new-idea my-project` and Claude:
✓ Automatically starts with brainstorming
✓ Presents the decision point with criteria
✓ Handles transition to systematic refinement
✓ Transfers context between workflows
✓ Never requires explanation of the workflow

## Prevention

**How to avoid this in future:**

1. **Use orchestrator pattern for complex workflows**
   - When workflow has 2+ distinct phases, create an orchestrator skill
   - Orchestrator owns: phase sequencing, decision logic, context transfer
   - Sub-skills remain focused and reusable

2. **Document decision criteria in the skill itself**
   - Don't rely on users to know when to escalate
   - Embed decision criteria directly in orchestrator skill
   - Present criteria to user, don't make them guess

3. **Make CLAUDE.md executable, not just documentation**
   - CLAUDE.md should point to executable skills
   - Skills should implement what CLAUDE.md describes
   - Avoid "user must remember to..." - automate it

4. **Add workflow diagrams to CLAUDE.md**
   - Visual representation helps users understand flow
   - Mermaid diagrams render in GitHub
   - Show decision points and both paths

**Checklist for similar multi-skill workflows:**
- [ ] Is there a clear sequence of phases?
- [ ] Are there decision points between phases?
- [ ] Does context need to transfer between skills?
- [ ] Would users have to remember the workflow?

If yes to 2+, create an orchestrator skill.

**Pattern to reuse:**
```markdown
# Orchestrator Skill Template

## Phase 1: [First Skill] (Automatic)
- Invoke /first-skill automatically
- Capture outputs

## Decision Point: [Criteria]
- Present decision criteria
- Get user choice
- Document why each path exists

## Phase 2: [Second Skill] (Conditional)
- If [condition], invoke /second-skill
- Transfer context from Phase 1
- Handle integration

## Phase 3: [Alternative Path]
- If not Phase 2, do alternative
- May invoke different skill or exit
```

## Cross-References

**Related documentation:**
- [claude.md](../../claude.md#default-workflow-hybrid-approach) - Documents the hybrid workflow as default
- [skills/new-idea/SKILL.md](../../skills/new-idea/SKILL.md) - The orchestrator skill implementation
- [skills/systematic-refinement/SKILL.md](../../skills/systematic-refinement/SKILL.md) - Stage-by-stage refinement workflow

**Related skills:**
- `/superpowers:brainstorming` - Phase 1 of hybrid workflow
- `/systematic-refinement` - Phase 2 of hybrid workflow (when escalating)
- `/superpowers:using-git-worktrees` - Integration point after brainstorming for direct implementation
- `/superpowers:writing-plans` - Integration point after brainstorming for direct implementation

**Key files created:**
- `skills/new-idea/SKILL.md` - Orchestrator skill
- `claude.md` (updated) - Hybrid workflow documentation + Mermaid diagram

**Pattern applications:**
This orchestrator pattern can be reused for other multi-phase workflows:
- Design review → Implementation → Testing
- Research → Planning → Execution
- Exploration → Decision → Deep dive

---

**Tags for search:** #workflow #orchestration #brainstorming #systematic-refinement #skill-integration #automation #decision-criteria #hybrid-approach #multi-phase-workflow
