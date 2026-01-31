---
name: new-idea
description: Start a new project idea using the hybrid brainstorm → systematic refinement workflow
---

# New Idea - Hybrid Workflow

Automatically orchestrates the hybrid approach: rapid brainstorming first, then deep systematic refinement if warranted.

## How This Works

When you run `/new-idea <project-name>`, I will:

1. **Phase 1: Brainstorming (Automatic)**
   - Invoke `/superpowers:brainstorming`
   - Explore your idea conversationally
   - Create initial design document
   - Validate concept viability

2. **Transition Decision (Automatic)**
   - After brainstorming completes, I ask:
     - "Is this idea simple enough to implement directly?"
     - "Or does it need systematic refinement?"

   **Decision criteria:**
   - ✅ **Go direct to implementation** if:
     - Simple, well-understood problem
     - Low stakes (internal tool, prototype)
     - You're implementing it yourself
     - MVP/experiment

   - ✅ **Escalate to systematic refinement** if:
     - Complex with many unknowns
     - High stakes (production system, users depend on it)
     - Team implementation
     - Security/safety/compliance critical
     - Novel problem space

3. **Phase 2: Systematic Refinement (If Needed)**
   - Create ideas registry entry
   - Initialize stage structure
   - Invoke `/systematic-refinement` starting at Stage 2
   - Apply all frameworks systematically
   - Progress through L1 → L2 → L3 refinement

## Usage

```bash
# Standard usage (recommended)
/new-idea my-project

# I'll handle the rest automatically!
```

## What Gets Created

**If staying in brainstorming:**
- Create idea entry in registry: `ideas/ideas-registry.json`
- `ideas/<project>/01-brainstorm/design.md` (initial design)
- Ready for implementation planning

**If escalating to systematic refinement:**
```
ideas/my-project/
├── 01-brainstorm/
│   └── idea.md (from brainstorming)
├── 02-requirements/
│   └── requirements.md
├── 03-trade-offs/
│   ├── trade-off-analysis.md
│   └── recommendation.md
├── 07-curated/
│   └── decisions/
│       └── ADR-001-*.md
└── status.md
```

**File Size Principle**: Keep each .md file under 300 lines. Split large designs into focused documents:
- `architecture.md` - System architecture and component overview
- `components/auth.md` - Individual component details
- `data-flows.md` - Data flow diagrams and descriptions
- `edge-cases.md` - Edge case catalog

## My Role

I will:
1. ✅ **Invoke brainstorming automatically** - no need to ask
2. ✅ **Ask the transition question** - help you decide
3. ✅ **Set up systematic refinement** if needed
4. ✅ **Guide you through stages** if escalating
5. ✅ **Know when to stay lightweight** vs go deep

I won't:
- ❌ Make you do systematic refinement for simple ideas
- ❌ Let you skip frameworks for complex ones
- ❌ Force a decision without criteria

## Philosophy

**The right amount of design for the stakes.**

- Brainstorming prevents over-engineering simple problems
- Systematic refinement prevents under-engineering complex ones
- The hybrid approach gives you both, automatically

## Examples

### Example 1: Simple Idea (Stays in Brainstorming)

**You:** `/new-idea cli-tool-for-renaming-files`

**Me:**
```
[Invokes brainstorming automatically]
[Explores idea conversationally]
[Creates registry entry and design doc]

✓ Registered: ideas/cli-tool-for-renaming-files
✓ Design complete: ideas/cli-tool-for-renaming-files/01-brainstorm/design.md

This looks straightforward - probably 1-2 files, standard CLI patterns.

Ready to implement directly, or do you want systematic refinement?

Recommendation: Implement directly (low complexity, low stakes)
```

### Example 2: Complex Idea (Escalates to Systematic)

**You:** `/new-idea multi-tenant-saas-platform`

**Me:**
```
[Invokes brainstorming automatically]
[Explores idea conversationally]
[Creates initial design doc]

✓ Initial design complete.

This is complex with high stakes:
- Multi-tenancy (security implications)
- SaaS (scalability, reliability)
- Many unknowns (auth, data isolation, billing)

Recommendation: Escalate to systematic refinement

Shall I set up the systematic refinement workflow?
[Yes (Recommended) / No, implement directly]
```

**You:** Yes

**Me:**
```
✓ Creating ideas registry entry
✓ Initializing stage structure
✓ Transferring brainstorming insights to 01-brainstorm

Now invoking systematic refinement starting at Stage 2...

[Launches systematic-refinement workflow automatically]
```

## Integration Points

**After brainstorming completes:**
- Create registry entry in `ideas/ideas-registry.json`
- Design doc → `ideas/<name>/01-brainstorm/design.md`
- Commit design document
- Ask transition question

**If escalating:**
- Register idea in `ideas/ideas-registry.json`
- Create stage directories
- Copy brainstorming output to `01-brainstorm/idea.md`
- Invoke `/systematic-refinement 02-requirements <name>`

**If implementing directly:**
- Ask: "Ready to set up implementation workspace?"
- If yes: invoke `/superpowers:using-git-worktrees`
- Then: invoke `/superpowers:writing-plans`

## The Transition Question

I will present this after brainstorming:

```
Design complete! Now deciding next steps:

Option 1: Implement directly (Recommended if)
✓ Simple, well-understood problem
✓ Low stakes (internal tool, prototype)
✓ You're implementing it yourself
→ Next: Create worktree + implementation plan

Option 2: Systematic refinement (Recommended if)
✓ Complex with many unknowns
✓ High stakes (production, users depend on it)
✓ Team implementation or handoff
✓ Security/safety/compliance critical
→ Next: Stage-by-stage framework application

Which path? [1 / 2]
```

## Success Criteria

This skill succeeds when:
1. ✅ Every new idea gets brainstorming first (no exceptions)
2. ✅ The transition decision is based on criteria, not guessing
3. ✅ Simple ideas don't get bogged down in process
4. ✅ Complex ideas don't skip critical thinking
5. ✅ You never have to remember the workflow - I orchestrate it

---

Ready to start a new idea? Just tell me the project name!
