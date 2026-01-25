---
problem_type: workflow_issues
component: skills
symptoms:
  - "No systematic guidance when refining ideas through stages"
  - "Inconsistent application of thinking frameworks"
  - "Unclear when to use which framework at which stage"
  - "Templates exist but no coaching on how to fill them"
tags: [systematic-refinement, design-thinking, frameworks, coaching, everything-claude-code, templates, stage-guidance]
related_issues: []
related_solutions:
  - frameworks-from-everything-claude-code.md
created: 2026-01-24
---

# Creating the Systematic Refinement Skill - Design Thinking Coach

## Problem

**What went wrong:**
ai-baseline had excellent thinking frameworks (requirements analysis, trade-off analysis, ADRs, progressive deepening, edge case discovery, red flags checklist) but no systematic way to apply them when working on ideas.

Users had to remember:
- Which frameworks to use at which stage
- How to fill in templates correctly
- What questions to ask themselves
- When they're "done" with a stage
- What red flags to watch for

This led to:
- Inconsistent rigor across ideas
- Skipped frameworks (forgotten or seen as optional)
- Unclear quality bar for stage advancement
- Templates copied but poorly filled
- Missing edge cases discovered during implementation (too late)

**Context:**
After creating the design-refinement skill and templates (from everything-claude-code frameworks), we had the building blocks but no conductor to orchestrate them.

**Why it matters:**
Without systematic guidance, frameworks become documentation theater—boxes checked without real thinking. The value of rigorous design refinement is lost.

## Investigation

**Attempts that didn't work:**

1. **Tried:** Just providing templates and documentation
   - **Why it failed:** Passive documentation doesn't ensure usage. Users skip steps, fill templates superficially, or don't know when to use which framework.
   - **Learning:** Need active guidance, not passive documentation.

2. **Tried:** Enhanced stage checklists with framework references
   - **Why it failed:** Checklists tell you WHAT to do, not HOW to do it or WHY. Still requires user to remember and self-enforce.
   - **Learning:** Need interactive coaching that asks questions and verifies completeness.

## Root Cause

**Technical explanation:**

The frameworks existed in isolation:
- `design-refinement/SKILL.md` - Framework definitions
- `templates/*.md` - Empty templates
- `stage-checklists-enhanced.md` - Criteria lists

But there was no **orchestration layer** that:
1. Detects current stage
2. Applies appropriate frameworks for that stage
3. Asks critical questions to ensure thorough thinking
4. Creates templates in correct locations
5. Verifies completeness against stage criteria
6. Blocks advancement if quality bar not met

**Why this matters:**
Frameworks are only valuable if applied consistently. Without a coach enforcing them, they degrade to optional suggestions.

## Solution

**Created the systematic-refinement skill** - an interactive design thinking coach that guides users through every stage.

### Step 1: Define the Skill Structure

Created `skills/systematic-refinement/SKILL.md` with:

**Core capabilities:**
- Stage detection and context awareness
- Framework application guidance
- Template creation automation
- Critical question prompts
- Red flags enforcement
- Readiness verification

**Usage patterns:**
```bash
/systematic-refinement new <idea>         # Start new idea (guided)
/systematic-refinement stage-N <idea>     # Work on specific stage
/systematic-refinement check <idea>       # Verify readiness
```

### Step 2: Stage-Specific Workflows

For each stage (1-7), defined:

**What happens:**
- Which frameworks apply
- What questions get asked
- What templates get created
- What red flags to watch for
- Readiness criteria

**Example (Stage 3: Explore → Refine L1):**
```markdown
I will help you:
1. Identify 2-3 viable approaches
2. Create trade-off analysis for each
3. Document first ADRs for major decisions
4. Run red flags checklist
5. Make recommendation with clear rationale

Critical questions I'll ask:
- What are 3 different ways to approach this?
- For each option: What's the biggest pro? Biggest con?
- What trade-offs are you willing to accept?
- How will you know if you chose right?

Red flags I'll catch:
- ❌ Only 1 approach (no comparison)
- ❌ Rubber-stamping (chosen option has "no downsides")
- ❌ Hand-waving complexity ("just use AI")

Readiness check:
- [ ] At least 2-3 approaches identified
- [ ] Each has honest pros/cons
- [ ] First ADRs created (1-2 minimum)
- [ ] Red flags checklist passed
```

### Step 3: Interactive Coaching Style

Defined interaction patterns:

**I will:**
- Ask probing questions
- Challenge vague answers until specific
- Point out missing edge cases
- Remind of frameworks when skipped
- Create files/templates in right locations
- Check work against stage criteria
- Be honest about readiness (no rubber-stamping)

**I won't:**
- Let you skip frameworks
- Accept vague answers ("fast", "good UX")
- Advance stages prematurely
- Ignore red flags
- Make decisions for you (guide, not decide)

### Step 4: Red Flags Enforcement

Built in systematic red flags detection:

**Process Red Flags:**
- Analysis Paralysis → Fix: 80% confidence + assumptions = advance
- False Precision → Fix: Document assumptions
- Solution First → Fix: Start with requirements
- Ignoring Trade-Offs → Fix: Every decision trades something

**Design Red Flags:**
- Hand-Waving → Fix: Specify HOW, not just WHAT
- Rubber-Stamping → Fix: Honestly analyze alternatives
- God Object → Fix: Separate concerns
- Figure It Out Later → Fix: Decide now with best info

**Documentation Red Flags:**
- No Rationale → Fix: Always document why
- Vague Requirements → Fix: Specific, measurable
- Missing Edge Cases → Fix: Apply discovery framework
- Undocumented Assumptions → Fix: Explicitly list

**Enforcement levels:**
- Stages 3-5: Flag and prompt fixing
- Stage 6: **BLOCK advancement if ANY critical red flag**

### Step 5: Template Automation

Skill creates files automatically:

```bash
# Stage 2
cp docs/templates/requirements.md ideas/<name>/stage-2/

# Stage 3
cp docs/templates/trade-off-analysis.md ideas/<name>/stage-3/decision-X.md
cp docs/templates/adr-template.md ideas/<name>/ADRs/ADR-001-topic.md

# Stages 4-6
cp docs/templates/progressive-deepening.md ideas/<name>/stage-4/component-X.md
```

### Step 6: Example Session Flow

Documented realistic interaction:

```
User: /systematic-refinement new photo-sharing-app

Skill: Starting new idea: photo-sharing-app
       Creating directory structure...
       I'll help you capture the raw idea.
       Q1: What problem are you solving?

User: People want to share photos with friends

Skill: That's a bit broad. Let me probe deeper:
       Q2: What's wrong with existing photo sharing?
       What specific pain point are you addressing?

User: Privacy - people want small group sharing without everything being public

Skill: Much better! Now we have a real problem.
       ✓ Problem: Private photo sharing fragmented across platforms
       Q3: Who specifically faces this problem?

[Continues with guided refinement...]
```

### Step 7: Documentation

Created supporting documentation:

**`docs/systematic-refinement-guide.md`:**
- Complete usage guide
- Stage-by-stage breakdown
- Files created throughout
- Benefits (before/after comparison)
- Quick command reference

**Updated `CLAUDE.md`:**
```markdown
### Recommended Workflow

For rigorous refinement, use /systematic-refinement at each stage:
1. /systematic-refinement new my-idea
2. /systematic-refinement stage-2 my-idea
3. /systematic-refinement stage-3 my-idea
...
8. /graduate my-idea ~/code/my-project
```

## Result

**Skill created:** `skills/systematic-refinement/SKILL.md`
**Guide created:** `docs/systematic-refinement-guide.md`
**CLAUDE.md updated:** With systematic workflow

**What it enables:**
- ✅ Interactive coaching through every stage
- ✅ Frameworks applied automatically
- ✅ Critical questions prompt thorough thinking
- ✅ Templates created in correct locations
- ✅ Red flags caught before advancement
- ✅ Clear quality bar enforced
- ✅ Consistent rigor across all ideas
- ✅ 95%+ confidence at graduation

## Prevention

**How to avoid this in future:**

1. **Skills need orchestration:** When creating frameworks/templates, always create a coach skill that applies them
2. **Make frameworks active, not passive:** Interactive guidance > documentation
3. **Enforce quality bars:** Red flags system prevents regression
4. **Document interaction patterns:** Show realistic Q&A sessions

**Checklist for similar situations:**
- [ ] Have frameworks been defined? (✓ design-refinement skill)
- [ ] Have templates been created? (✓ docs/templates/)
- [ ] Is there a coach to apply them? (✓ systematic-refinement skill)
- [ ] Are interaction patterns documented? (✓ example sessions)
- [ ] Is quality bar enforced? (✓ red flags checklist)

## Cross-References

**Related documentation:**
- [skills/systematic-refinement/SKILL.md](../../skills/systematic-refinement/SKILL.md) - The skill itself
- [skills/design-refinement/SKILL.md](../../skills/design-refinement/SKILL.md) - Frameworks it orchestrates
- [docs/systematic-refinement-guide.md](../systematic-refinement-guide.md) - Complete usage guide
- [docs/stage-checklists-enhanced.md](../stage-checklists-enhanced.md) - Enhanced stage criteria
- [docs/templates/README.md](../templates/README.md) - Templates guide

**Related solutions:**
- [frameworks-from-everything-claude-code.md](frameworks-from-everything-claude-code.md) - Where frameworks came from
- [compound-skill-creation.md](compound-skill-creation.md) - Similar skill creation pattern
- [enhance-skill-creation.md](enhance-skill-creation.md) - Another coaching skill

**External inspiration:**
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) - Original framework source
- everything-claude-code agents (architect.md, planner.md) - Thinking patterns adapted

---

## Implementation Files

```
skills/systematic-refinement/
└── SKILL.md                              # Interactive coach skill

docs/
├── systematic-refinement-guide.md        # Complete usage guide
├── stage-checklists-enhanced.md          # Framework integration
└── templates/
    ├── README.md                         # Templates guide
    ├── requirements.md
    ├── trade-off-analysis.md
    ├── adr-template.md
    └── progressive-deepening.md

docs/solutions/workflow-issues/
├── frameworks-from-everything-claude-code.md  # Framework origins
└── systematic-refinement-skill-creation.md    # This document
```

---

## The Complete System

**Layer 1: Frameworks** (What to do)
- Requirements Analysis
- Trade-Off Analysis
- Architecture Decision Records
- Progressive Deepening (L1→L2→L3)
- Edge Case Discovery
- Red Flags Checklist

**Layer 2: Templates** (How to document)
- requirements.md
- trade-off-analysis.md
- adr-template.md
- progressive-deepening.md

**Layer 3: Coach** (When and why to apply) ← **This solution**
- systematic-refinement skill
- Stage-specific guidance
- Interactive Q&A
- Red flags enforcement
- Readiness verification

**Result:** Complete design thinking system with consistent rigor.

---

**Tags for search:** #systematic-refinement #design-thinking #coaching-skill #frameworks #orchestration #quality-enforcement #interactive-guidance #stage-advancement #red-flags #everything-claude-code