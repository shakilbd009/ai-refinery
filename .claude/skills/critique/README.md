# Critique Skill - Usage Guide

## Overview

The **critique** skill pushes ideas to their innovative limits through exhaustive analysis. It prevents settling for "thorough enough" and instead explores every angle until breakthrough insights emerge.

## When to Use

Use the critique skill when:
- Refining project ideas in the ai-baseline pipeline
- Evaluating proposals or designs where innovation matters
- User explicitly asks to "push to the limit" or "leave no stone unturned"
- You need to ensure comprehensive analysis, not just satisfactory feedback

## How to Invoke

The critique skill is now installed in `~/.claude/skills/critique/` and will be available for invocation in Claude Code sessions.

### In Claude Code

Simply ask Claude to critique using the skill:

```
Use the critique skill to analyze my idea: [describe idea]
```

Or:

```
I want exhaustive critique of this proposal: [describe proposal]
```

Claude will automatically load and apply the critique framework.

## What to Expect

When the critique skill is applied, you'll get:

### Depth
- **4-5x more comprehensive** than standard critique
- Analysis continues past "feels thorough" to exhaustive coverage
- 20+ alternatives generated (not just 3-5)
- 30+ assumptions extracted and tested

### Innovation Techniques
- **Inversion** - exploring opposite approaches
- **First principles** - rebuilding from atomic truths
- **Constraint manipulation** - removing/adding constraints
- **Combinatorial thinking** - cross-pollination from other domains
- **Extreme scenarios** - best/worst/weirdest cases
- **Second-order effects** - what happens after success?

### Multi-Dimensional Analysis
- Problem dimension (is this the right problem?)
- Solution dimension (why this approach?)
- Assumptions (explicit and implicit)
- Constraints (real vs imagined)
- Context (who benefits/loses?)
- Timing (why now?)
- Scale (10x vs 10% thinking)
- Adjacent possible (what becomes possible?)

### Systematic Coverage
- 10+ failure modes mapped
- All assumptions tested with experiments
- Problem itself challenged
- Far-fetched angles explored
- Business, technical, and organizational dimensions

## Example Usage

### Before (Standard Critique)
```
User: Critique my idea for a productivity app
Claude: [Provides 800 words covering obvious problems,
         suggests 3 alternatives, stops at "thorough"]
```

### After (With Critique Skill)
```
User: Use the critique skill to analyze my productivity app idea
Claude: [Provides 4,000+ words with:
         - 21 alternatives
         - 40+ failure modes
         - 30+ assumptions tested
         - Cross-pollination from 8 domains
         - First principles deconstruction
         - 10x thinking pushed
         - Problem itself challenged]
```

## Integration with AI-Baseline

The critique skill works exceptionally well with the ai-baseline refinement pipeline:

1. **New idea stage**: Use critique to explore all angles before committing
2. **Refinement stages**: Apply critique at each stage to deepen progressively
3. **Pre-graduation**: Final exhaustive critique before creating production repo

### Suggested Workflow

```bash
# Start new idea
/new-idea my-project

# Work on initial concept
# Then apply critique
"Use the critique skill to push this idea to its limits"

# Refine based on insights
# Advance stage when ready
/advance-stage my-project

# Repeat at each stage - each critique gets deeper
# Graduate when idea has survived exhaustive critique
/graduate my-project ~/code/my-project
```

## Tips for Effective Use

1. **Be specific about your idea** - The more context you provide, the better the critique
2. **Embrace discomfort** - If the critique feels too deep, it's working
3. **Don't filter feedback** - Far-fetched angles often yield best insights
4. **Use iteratively** - Apply critique multiple times as idea evolves
5. **Combine with /compound** - Document breakthrough insights for reuse

## What Makes This Different

### Standard Critique
- Stops when "feels thorough"
- Linear analysis
- 3-5 alternatives
- Accepts problem as stated
- Conservative depth

### Critique Skill
- Stops when exhausted every angle
- Multi-technique innovation framework
- 20+ alternatives including absurd ones
- Challenges the problem itself
- Relentless depth

## Red Flags (You're Not Going Deep Enough)

If you find yourself thinking:
- "This is thorough enough"
- "That angle seems far-fetched"
- "More would be redundant"
- "I've covered the main points"

**You haven't used the skill correctly.** Keep digging.

## Success Criteria

You've successfully used the critique skill when:
- You're slightly uncomfortable with how deep the analysis went
- You've discovered angles you never considered
- The checklist is fully completed
- You have 4-5x more material than a standard critique
- The problem itself was challenged, not just the solution

## Troubleshooting

**"The critique is too long"**
- That's the point. Innovation requires exhaustive exploration.
- Skim the checklist sections, deep-dive on areas most relevant.

**"Some sections seem irrelevant"**
- Far-fetched often yields breakthrough insights.
- Don't filter prematurely - you'll miss connections.

**"I just want quick feedback"**
- Don't use critique skill for quick feedback.
- Use standard analysis for minor details.

## Development Notes

This skill was created following TDD principles for skill development:
- ✅ Baseline scenarios tested without skill
- ✅ Skill written to address specific failures
- ✅ Skill tested and verified effective
- ✅ Produces 4-5x more comprehensive analysis
- ✅ Prevents premature stopping

See `baseline-analysis.md` and `testing-results.md` for full development process.

## Related

- **Skill creation process**: `/skills/superpowers/writing-skills/`
- **TDD principles**: `/skills/superpowers/test-driven-development/`
- **AI-baseline workflow**: `/CLAUDE.md`
