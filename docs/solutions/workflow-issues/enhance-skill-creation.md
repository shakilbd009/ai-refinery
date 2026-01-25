---
problem_type: workflow_issue
component: skills
symptoms:
  - "/critique skill too questioning and challenging"
  - "User wants supportive innovation, not critical evaluation"
  - "Need collaborative skill that amplifies ideas"
tags: [skills, critique, enhancement, user-feedback, skill-design]
related_issues: []
related_solutions: [compound-skill-creation.md]
created: 2026-01-24
---

## Problem

The `/critique` skill follows an exhaustive evaluation framework that challenges assumptions, questions the problem itself, and explores failure modes. While valuable for validation, it was not appropriate for users who have a clear vision and want collaborative support to make their ideas better, not different.

**User feedback:** "I don't like how /critique skill is evaluating my ideas, the goal should be to enhance my ideas but not doubting it... /critique is not doing a great job helping me."

**Root issue:** Only had one mode (critical evaluation), missing a generative/supportive mode.

## Investigation

**What was tried:**
1. Considered modifying /critique to be less challenging
2. Rejected - would lose value for users who DO want critical evaluation
3. Decided to create separate skill for different use case

**Why separate skill is better:**
- Preserves /critique for validation use cases
- Creates clear choice: critique vs enhance
- Different mental models, different outputs
- Users can choose based on current need

## Root Cause

**Design gap:** The skill library lacked a generative, amplification-focused skill. Only had:
- `/critique` - Challenge and evaluate
- `/brainstorming` - Explore idea space
- Missing: "Make my specific vision better"

**User need:** Structure and standards for Claude-built apps requires supportive innovation within framework, not alternatives to framework.

## Solution

Created new `/enhance` skill with complementary approach to /critique:

### Step 1: Created Skill Structure

```bash
mkdir -p /Users/shakilakram/projects/ai-baseline/skills/enhance
```

### Step 2: Wrote SKILL.md

**Key design principles:**
- Accept user's vision completely (no questioning)
- Build on their foundation (additive, not substitutive)
- Focus on "yes, and..." thinking
- Organize enhancements by priority
- Identify synergies between features

**Core framework:**
1. **Vision Clarity** - Understand what user wants
2. **Opportunity Mining** - Find what's missing
3. **Creative Extension** - Generate innovations within framework
4. **Missing Capabilities** - Identify gaps without calling them flaws
5. **Enhancement Synthesis** - Organize into actionable roadmap

**Output categories:**
- Quick Wins (easy, high value)
- Strategic Enhancements (bigger features)
- Future Possibilities (later consideration)
- Synergistic Combinations (features that multiply value)
- Missing Capabilities (completeness)

### Step 3: Created Supporting Documentation

**COMPARISON.md:**
- Side-by-side comparison of /critique vs /enhance
- When to use each skill
- Examples showing different outputs
- Can be used together in sequence

**README.md:**
- User-facing documentation
- Quick start guide
- Philosophy explanation
- Integration with ai-baseline

### Step 4: Demonstrated the Skill

Applied /enhance to the ai-baseline project itself:
- Generated 20 enhancement ideas
- Organized by priority (Quick Wins → Strategic → Future)
- Identified synergistic combinations
- Created implementation roadmap
- Documented in `docs/solutions/idea-refinement/ai-baseline-enhancement-roadmap.md`

### Step 5: Updated Solutions Index

Added new solution to `docs/solutions/README.md` for discoverability.

## Code Examples

**Skill frontmatter:**
```yaml
---
name: enhance
description: Amplify and expand ideas with innovation suggestions, missing opportunities, and creative extensions. Use when the user wants to make their idea better, not question it. Triggers on "enhance", "improve", "make better", "expand", or when user has clear vision needing support.
---
```

**Enhancement checklist (before finishing):**
```markdown
- [ ] Vision fully understood and accepted
- [ ] 10+ enhancement ideas generated
- [ ] Ideas organized by priority (Now/Next/Later)
- [ ] Synergies between features identified
- [ ] Quick wins highlighted
- [ ] Strategic additions outlined
- [ ] Future possibilities mentioned
- [ ] All ideas FIT the user's vision
- [ ] Nothing questions their core direction
- [ ] Everything is additive, not substitutive
```

**Output template:**
```markdown
# Enhanced Vision: [Project Name]

## Core Vision (Understood)
[Restate their vision]

## Quick Wins
[5-10 easy additions]

## Strategic Enhancements
[5-10 bigger features]

## Future Possibilities
[5-10 ideas for later]

## Synergistic Combinations
[Features that multiply value]

## Missing Capabilities
[Gaps that would make it complete]
```

## Prevention

**To avoid similar issues in future:**

1. **Gather user feedback early** - Don't assume skill is working well
2. **Provide skill alternatives** - Different modes for different needs
3. **Make stance explicit** - Clear about whether skill is supportive vs critical
4. **Document when to use** - Help users choose right skill
5. **Create comparison docs** - Side-by-side clarity

**Design principle:** When creating skills with strong stance (critical, supportive, exploratory), ensure complementary skills exist for alternative stances.

## Testing the Solution

**User validation:**
- User explicitly asked for Option B (create new /enhance skill)
- Confirmed this approach matches their needs
- Vision: "structure and standards for Claude-built apps"

**Immediate value:**
- Used /enhance on ai-baseline itself
- Generated comprehensive enhancement roadmap
- User asked to document for future reference
- Solution documented in compound system

## Files Created

```
skills/enhance/
├── SKILL.md           # Main skill instructions
├── COMPARISON.md      # When to use enhance vs critique
└── README.md          # User documentation

docs/solutions/
└── idea-refinement/
    └── ai-baseline-enhancement-roadmap.md
```

## Integration with ai-baseline Workflow

The /enhance skill integrates naturally:

**During refinement:**
```bash
/new-idea my-app
# Work through stages
/enhance <current design>  # Get enhancement ideas
# Add best enhancements to design
/advance-stage my-app
```

**Pre-graduation:**
```bash
# Before graduating
/enhance <final design>  # Final enhancement pass
# Add quick wins
/graduate my-app ~/code
```

## Cross-References

- [Critique Skill](../../skills/critique/SKILL.md) - Complementary critical evaluation skill
- [Compound Guide](../compound-guide.md) - Knowledge compounding philosophy
- [AI-Baseline Enhancement Roadmap](../solutions/idea-refinement/ai-baseline-enhancement-roadmap.md) - Example of /enhance output

## Related Solutions

- [Compound Skill Creation](compound-skill-creation.md) - Similar process for creating /compound
- [Replicating Compound Engineering](replicating-compound-engineering.md) - Setting up compound workflow

## Success Metrics

Track these to measure /enhance effectiveness:

- User satisfaction with skill output
- Number of enhancements actually implemented
- Time saved vs manual brainstorming
- Quality of ideas generated
- Fit with user's vision (should be 100%)

## Notes

This solution demonstrates the value of user feedback in skill design. The /critique skill remains valuable for validation scenarios, while /enhance fills a critical gap for supportive innovation.

**Key insight:** Different mental contexts require different skill stances. Provide options, document differences, let users choose.

**Time saved on future occurrences:** When creating new skills, immediately consider complementary stances and create both proactively.
