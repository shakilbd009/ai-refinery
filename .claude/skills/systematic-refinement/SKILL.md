---
name: systematic-refinement
description: Step-by-step design thinking coach for refining ideas through stages. Use when starting a new idea, advancing stages, or ensuring design completeness. Applies all frameworks systematically.
---

# Systematic Refinement Skill

Your design thinking coach. This skill guides you through systematic idea refinement using all the frameworks, ensuring nothing is missed.

## When to Use

- **Starting a new idea**: `/systematic-refinement new <idea-name>`
- **Working on a stage**: `/systematic-refinement stage-N <idea-name>`
- **Checking readiness**: `/systematic-refinement check <idea-name>`
- **General guidance**: `/systematic-refinement` (will detect context)

---

## How This Works

I will:
1. **Detect your current stage** (or ask if unclear)
2. **Guide framework application** for that stage
3. **Ask critical questions** to ensure thoroughness
4. **Check for red flags** before advancement
5. **Create templates** in the right locations
6. **Verify completeness** against stage criteria

---

## Stage-by-Stage Workflow

### Stage 1: Raw Idea

**Goal**: Capture the seed of the idea clearly.

**I will help you**:
1. Articulate the problem statement (not the solution)
2. Identify initial motivation
3. Note any constraints you're aware of
4. List initial assumptions

**Questions I'll ask**:
- What problem are you solving? (For whom?)
- Why does this matter? (What's the impact if unsolved?)
- What sparked this idea? (Context?)
- Any initial constraints? (Budget, tech, timeline?)

**Output**: `ideas/<name>/stage-1/idea.md` with clear problem statement

**No frameworks yet** - this is pre-framework stage.

---

### Stage 2: Brainstorm → Explore

**Goal**: Understand user needs and define success.

**I will help you**:
1. Create `requirements.md` from template
2. Identify target users and their pain points
3. Define success criteria with metrics
4. Establish scope boundaries (in/out)
5. Document assumptions with validation plans

**Frameworks applied**:
- ✅ Requirements Analysis Framework

**I'll guide you through**:
```bash
# Step 1: Copy template
cp docs/templates/requirements.md ideas/<name>/stage-2/

# Step 2: Fill functional requirements
# - I'll prompt: "What must the system DO?"
# - For each capability: acceptance criteria
# - Priority: Must/Should/Nice to have

# Step 3: Fill non-functional requirements
# - Performance targets (specific numbers)
# - Security requirements
# - Scalability expectations
# - Reliability targets

# Step 4: Define constraints
# - Budget, timeline, technology limits
# - Explicitly list what's OUT of scope

# Step 5: Success metrics
# - How will you measure success?
# - User metrics, technical metrics, business metrics
```

**Critical questions I'll ask**:
- Who are the target users? (Personas?)
- What are their top 3 pain points?
- What does "done" look like? (Specific metrics?)
- What are we NOT building? (Out of scope?)
- What assumptions are we making? (How will we validate?)

**Readiness check**:
- [ ] Functional requirements have acceptance criteria
- [ ] Non-functional requirements are specific (not vague)
- [ ] Out of scope is explicitly listed
- [ ] Success metrics are measurable
- [ ] Assumptions documented with validation plans

**Red flags I'll watch for**:
- ❌ Solution bias (describing HOW, not WHAT)
- ❌ Vague requirements ("fast", "good UX")
- ❌ No success metrics
- ❌ Scope creep (everything in scope)

**Output**: Completed `requirements.md`

---

### Stage 3: Explore → Refine L1

**Goal**: Evaluate approaches and choose the best path.

**I will help you**:
1. Identify 2-3 viable approaches
2. Create trade-off analysis for each
3. Document first ADRs for major decisions
4. Run red flags checklist
5. Make recommendation with clear rationale

**Frameworks applied**:
- ✅ Trade-Off Analysis Framework
- ✅ Architecture Decision Records (start)
- ✅ Design Red Flags Checklist

**I'll guide you through**:
```bash
# Step 1: Identify approaches
# I'll prompt: "What are the different ways to solve this?"
# Minimum 2-3 distinct approaches

# Step 2: For each major decision (architecture, data model, API design):
cp docs/templates/trade-off-analysis.md ideas/<name>/stage-3/decision-X.md

# I'll help fill:
# - Option A, B, C with pros/cons
# - Complexity/Risk ratings
# - Comparison matrix
# - Decision rationale
# - Trade-offs accepted
# - Validation plan

# Step 3: Create ADRs for biggest decisions
mkdir -p ideas/<name>/ADRs
cp docs/templates/adr-template.md ideas/<name>/ADRs/ADR-001-<topic>.md

# I'll ensure:
# - Alternatives considered section is NOT empty
# - Consequences (positive + negative) documented
# - Clear decision rationale
```

**Critical questions I'll ask**:
- What are 3 different ways to approach this?
- For each option: What's the biggest pro? Biggest con?
- What trade-offs are you willing to accept?
- How will you know if you chose right? (Validation?)
- What would make you pivot to a different approach?

**Readiness check**:
- [ ] At least 2-3 approaches identified
- [ ] Each approach has honest pros/cons (not biased)
- [ ] Comparison matrix completed
- [ ] Decision has clear rationale (not "just because")
- [ ] Trade-offs explicitly accepted
- [ ] First ADRs created (1-2 minimum)
- [ ] All ADRs have alternatives section filled
- [ ] Red flags checklist passed

**Red flags I'll catch**:
- ❌ Only 1 approach (no comparison)
- ❌ Rubber-stamping (chosen option has "no downsides")
- ❌ Vague rationale ("A is better than B")
- ❌ Hand-waving complexity ("just use AI")
- ❌ No validation plan

**Output**:
- Trade-off analysis docs
- ADR-001, ADR-002, etc.
- Recommendation document

---

### Stage 4: Refine L1 → Refine L2

**Goal**: First complete pass at high level.

**I will help you**:
1. Apply progressive deepening template (L1 level) to major components
2. Create architecture diagrams (Mermaid)
3. Expand ADRs (3-5 total)
4. Map primary data flows
5. Identify basic error scenarios
6. Run red flags checklist

**Frameworks applied**:
- ✅ Progressive Deepening Template (L1)
- ✅ Architecture Decision Records (expand)
- ✅ Trade-Off Analysis (component boundaries)
- ✅ Design Red Flags Checklist

**I'll guide you through**:
```bash
# Step 1: Identify major components
# I'll ask: "What are the main building blocks?"

# Step 2: For each component:
cp docs/templates/progressive-deepening.md ideas/<name>/stage-4/component-X.md

# Fill L1 section:
# - What: Basic description
# - Why: High-level motivation
# - Key Insight: Main point to understand
# - Initial questions raised

# Step 3: Create architecture diagram
# I'll help you create Mermaid diagram showing:
# - Major components
# - Primary relationships
# - Data flows (happy paths)

# Step 4: Create ADRs for component-level decisions
# - Data modeling choices
# - API design approaches
# - Integration patterns
```

**Critical questions I'll ask**:
- What are the major components/modules?
- For each component: What's its core responsibility?
- How do components interact? (Draw it)
- What are the primary data flows? (Happy paths)
- What could go wrong? (Basic error scenarios)
- What technical decisions are left to make?

**Readiness check**:
- [ ] Major components identified
- [ ] Progressive deepening templates created (L1 completed)
- [ ] Architecture diagram created (Mermaid)
- [ ] Primary data flows mapped
- [ ] Basic error scenarios identified
- [ ] ADRs expanded (3-5 total)
- [ ] All ADRs have alternatives section
- [ ] Red flags checklist passed

**Red flags I'll catch**:
- ❌ God object (one component doing everything)
- ❌ No clear separation of concerns
- ❌ Circular dependencies
- ❌ Only happy paths (no error scenarios)
- ❌ "We'll figure it out later" on critical decisions

**Output**:
- Progressive deepening docs (L1 level)
- Architecture diagrams
- Expanded ADR set
- L1 design document

---

### Stage 5: Refine L2 → Refine L3

**Goal**: Detailed design with comprehensive coverage.

**I will help you**:
1. Complete progressive deepening L2 sections
2. Apply edge case discovery framework systematically
3. Finalize all ADRs
4. Document error paths and recovery
5. Specify component interfaces
6. Run stricter red flags checklist

**Frameworks applied**:
- ✅ Progressive Deepening Template (L2)
- ✅ Edge Case Discovery Framework
- ✅ Architecture Decision Records (finalize)
- ✅ Design Red Flags Checklist (stricter)

**I'll guide you through**:
```bash
# Step 1: Fill L2 sections in progressive deepening templates

# For each component, I'll help you document:
# - How: Approach/mechanism
# - Interactions: How it connects to other components
# - Alternatives: What else was considered
# - Edge cases: Initial list
# - Risks: Identified concerns + mitigations
# - Open questions: What needs resolution

# Step 2: Edge case discovery (systematic)
# I'll walk through each category:
# - Data boundaries (empty, null, max, special chars)
# - State transitions (concurrent, retry, out-of-order)
# - Timing (timeout, race, long-running)
# - Integration (service down, slow, invalid response)

# For each edge case:
# - What happens?
# - How do we handle it?
# - How do we test it?

# Step 3: Finalize ADRs
# I'll review each ADR:
# - Consequences complete (positive/negative/neutral)
# - Alternatives with rejection rationale
# - Implementation notes added
# - Success criteria defined
```

**Critical questions I'll ask**:
- For each component: HOW does it work internally?
- What happens when [edge case]?
- What if two users do X simultaneously?
- What if external service Y is down?
- How do we recover from failure Z?
- What are ALL the ways this could fail?
- What's the security threat model for this component?

**Readiness check**:
- [ ] Progressive deepening L2 sections completed
- [ ] Edge case discovery framework applied
- [ ] Each edge case has handling approach
- [ ] Error paths documented with recovery strategies
- [ ] All ADRs finalized (5-10 typical)
- [ ] Component interfaces specified
- [ ] Security implications documented
- [ ] Performance implications documented
- [ ] Red flags checklist passed (stricter bar)

**Red flags I'll catch**:
- ❌ "Figure it out later" on critical paths
- ❌ Undocumented edge cases
- ❌ No error recovery strategies
- ❌ Vague "handle errors gracefully"
- ❌ Missing security considerations

**Output**:
- Progressive deepening docs (L2 level)
- Complete edge case catalog
- Finalized ADR set
- Detailed sequence diagrams
- L2 design document

---

### Stage 6: Refine L3 → Graduate

**Goal**: Exhaustive coverage, zero ambiguity.

**I will help you**:
1. Complete progressive deepening L3 sections
2. Ensure 100% edge case coverage
3. Document every failure mode with recovery
4. Verify no TBDs or unknowns remain
5. Run 100% red flags checklist
6. Verify design stability across L1→L2→L3

**Frameworks applied**:
- ✅ Progressive Deepening Template (L3 - exhaustive)
- ✅ Edge Case Discovery Framework (100% coverage)
- ✅ Design Red Flags Checklist (100% pass - mandatory)

**I'll guide you through**:
```bash
# Step 1: Complete L3 sections (exhaustive)

# For each component, I'll ensure you have:
# - Complete scenario coverage (all variants)
# - Complete failure mode analysis (every way to fail)
# - Recovery strategies (for each failure mode)
# - Performance implications (scaling, bottlenecks)
# - Security threat model (every threat, every mitigation)
# - Dependencies (external systems, assumptions)
# - Unknowns resolved (NO TBDs)

# Step 2: 100% edge case coverage
# I'll verify every category checked:
# - Data boundaries: ✓
# - State transitions: ✓
# - Timing: ✓
# - Integration: ✓
# - User behavior: ✓

# Step 3: Failure mode table
# For EVERY component, I'll help create:
# | Failure Mode | Cause | Impact | Detection | Recovery | Prevention |

# Step 4: Stability check
# I'll review L1→L2→L3 progression:
# - Did core concepts change fundamentally? (red flag)
# - Were refinements additive? (good)
# - Are there contradictions? (must resolve)
```

**Critical questions I'll ask**:
- Is there ANY scenario we haven't covered?
- What's the WORST that could happen?
- How do we recover from EVERY failure mode?
- Are there ANY unknowns or TBDs left?
- Can an implementation team start coding immediately?
- What would make you 95%+ confident in this design?
- If you had to defend every decision, could you?

**Readiness check (100% required)**:
- [ ] Progressive deepening L3 sections complete
- [ ] Every scenario documented (including rare cases)
- [ ] Every failure mode has recovery strategy
- [ ] Performance implications analyzed (scaling paths)
- [ ] Security threat model complete
- [ ] All dependencies and assumptions validated
- [ ] Zero TBDs or unknowns
- [ ] Edge case discovery 100% coverage
- [ ] Red flags checklist 100% pass (mandatory)
- [ ] Stability check passed (L1→L2→L3 consistent)

**Red flags I'll enforce (100% pass required)**:
- ❌ ANY "we'll figure it out later" → BLOCK
- ❌ ANY hand-waving on complexity → BLOCK
- ❌ ANY undocumented edge case → BLOCK
- ❌ ANY decision without rationale → BLOCK
- ❌ ANY TBD or unknown → BLOCK

**If ANY red flag found**: Cannot advance. Must resolve.

**Output**:
- Progressive deepening docs (L3 - exhaustive)
- Complete failure mode analysis
- Full edge case catalog with handling
- Security threat model
- Performance analysis
- L3 design document (production-ready)

---

### Stage 7: Graduate → Export

**Goal**: Package curated design for graduation.

**I will help you**:
1. Extract final ADRs
2. Create curated design document
3. Include trade-off summaries
4. Document all red flags addressed
5. Remove exploration artifacts
6. Verify graduation readiness
7. Run `/graduate` command

**I'll guide you through**:
```bash
# Step 1: Review what gets included
# ✅ Final ADRs
# ✅ Requirements document
# ✅ Architecture diagrams
# ✅ Trade-off summaries
# ✅ Edge case catalog
# ✅ Key decision rationale

# Step 2: Review what gets excluded
# ❌ Progressive deepening templates (raw)
# ❌ L1/L2 drafts
# ❌ Exploration notes
# ❌ Dead-end approaches

# Step 3: Create curated design package
# I'll help you:
# - Write executive summary
# - Extract key trade-offs
# - Collapse progressive deepening into prose
# - Organize ADRs with index
# - Document red flags addressed

# Step 4: Verify graduation criteria
# All stage 6 criteria met + curated package ready

# Step 5: Graduate
/graduate <idea-name> ~/code/<project-name>
```

**Critical questions I'll ask**:
- Is the curated design document clean and readable?
- Can an implementation team understand all decisions?
- Are all ADRs current and accurate?
- Is the "why" behind choices clear?
- Are trade-offs explicitly documented?
- Have all red flags been addressed?
- Is there any ambiguity remaining?

**Readiness check**:
- [ ] Curated design document created
- [ ] ADRs packaged with index
- [ ] Trade-off summaries included
- [ ] Red flags review documented
- [ ] Exploration artifacts removed
- [ ] Design is complete and unambiguous
- [ ] Ready to guide implementation
- [ ] Target path identified

**Output**:
- Graduated repository at target path
- Contains: ADRs, requirements, architecture, design docs
- Ready for implementation planning (by different Claude)

---

## Red Flags Enforcement

At EVERY stage, I will check for these anti-patterns:

### Process Red Flags
- ❌ **Analysis Paralysis**: Stuck refining endlessly
  - Fix: 80% confidence + explicit assumptions = advance
- ❌ **False Precision**: Pretending to have certainty
  - Fix: Document assumptions and validation plans
- ❌ **Solution First**: Jumping to implementation before requirements
  - Fix: Always start with requirements framework
- ❌ **Ignoring Trade-Offs**: Claiming "no downsides"
  - Fix: Every decision trades something

### Design Red Flags
- ❌ **Hand-Waving Complexity**: "Just use AI/microservices"
  - Fix: Specify HOW, not just WHAT
- ❌ **Rubber-Stamping**: Fake comparison ("A wins, B exists")
  - Fix: Actually analyze alternatives honestly
- ❌ **God Object**: One component doing everything
  - Fix: Separate concerns, clear boundaries
- ❌ **Figure It Out Later**: Deferring critical decisions
  - Fix: Make decision now with best info, document assumptions

### Documentation Red Flags
- ❌ **No Rationale**: "We chose X" without why
  - Fix: Always document decision rationale
- ❌ **Vague Requirements**: "Fast", "good UX"
  - Fix: Specific, measurable criteria
- ❌ **Missing Edge Cases**: Only happy paths
  - Fix: Apply edge case discovery framework
- ❌ **Undocumented Assumptions**: Implicit assumptions
  - Fix: Explicitly list and validate

**I will BLOCK stage advancement if critical red flags remain.**

---

## My Interaction Style

### I will:
1. **Ask probing questions** to ensure thorough thinking
2. **Challenge vague answers** until they're specific
3. **Point out missing edge cases** you haven't considered
4. **Remind you of frameworks** when you skip them
5. **Create files/templates** in the right locations
6. **Check your work** against stage criteria
7. **Be honest** about readiness (won't rubber-stamp)

### I won't:
1. ❌ Let you skip frameworks ("this is obvious")
2. ❌ Accept vague answers ("it'll be fast")
3. ❌ Advance stages prematurely
4. ❌ Ignore red flags
5. ❌ Make decisions for you (I guide, you decide)

---

## Example Session

### You: `/systematic-refinement new photo-sharing-app`

**Me**:
```
Starting new idea: photo-sharing-app

Creating directory structure:
✓ ideas/photo-sharing-app/stage-1/
✓ ideas/photo-sharing-app/ADRs/

I'll help you capture the raw idea. Let's start with the problem statement.

Q1: What problem are you solving?
(Hint: Describe the need, not the solution)
```

**You**: "People want to share photos with friends"

**Me**:
```
That's a bit broad. Let me probe deeper:

Q2: What's wrong with existing photo sharing (Instagram, iCloud, etc.)?
What specific pain point are you addressing?

For example:
- Privacy concerns with public platforms?
- Difficulty organizing private albums?
- Slow sharing with specific groups?
- Something else?
```

**You**: "Privacy - people want to share with small groups without everything being public or scattered across texts"

**Me**:
```
Much better! Now we have a real problem.

✓ Problem: Private photo sharing with small groups is either too public
  (Instagram) or fragmented (texts, email, various apps)

Q3: Who specifically faces this problem? (Target users?)
```

**You**: "Families and close friend groups"

**Me**:
```
✓ Target users: Families and close friend groups

Q4: Why does this matter? What's the impact if unsolved?
```

**You**: "People either overshare publicly or don't share at all, missing out on keeping connections strong"

**Me**:
```
Perfect! Documenting...

✓ Created: ideas/photo-sharing-app/stage-1/idea.md

## Summary
Problem: Private photo sharing fragmented across platforms
Users: Families and close friend groups
Impact: Oversharing or under-sharing, weakening connections
Motivation: Need private, organized photo sharing for small groups

Q5: Any initial constraints I should know?
(Budget, timeline, technical requirements, etc.)
```

[Session continues...]

---

## Commands Summary

```bash
# Start new idea
/systematic-refinement new <idea-name>

# Work on specific stage
/systematic-refinement stage-2 <idea-name>
/systematic-refinement stage-3 <idea-name>
# ... etc

# Check readiness for advancement
/systematic-refinement check <idea-name>

# General guidance (auto-detect)
/systematic-refinement

# Get help
/systematic-refinement help
```

---

## Files I Create

Throughout the process, I will create:

```
ideas/<name>/
├── stage-1/
│   └── idea.md
├── stage-2/
│   └── requirements.md (from template)
├── stage-3/
│   ├── approach-comparison.md (trade-off analysis)
│   └── recommendation.md
├── stage-4/
│   ├── component-X.md (progressive deepening L1)
│   ├── component-Y.md
│   └── architecture.md (with Mermaid diagrams)
├── stage-5/
│   ├── edge-cases.md
│   ├── [component files with L2 sections]
│   └── detailed-flows.md
├── stage-6/
│   ├── [component files with L3 sections]
│   ├── failure-modes.md
│   └── threat-model.md
├── stage-7/
│   └── curated-design.md
└── ADRs/
    ├── ADR-001-architecture-pattern.md
    ├── ADR-002-database-choice.md
    ├── ADR-003-auth-mechanism.md
    └── ...
```

---

## File Organization Principles

### Artifact Locality
**All idea files live in `ideas/<name>/` - never scattered elsewhere.**

I will ensure:
- ✅ All design docs in idea folder
- ✅ All ADRs in `ideas/<name>/ADRs/`
- ✅ All stage artifacts in respective stage folders
- ❌ Never create files in `docs/plans/` or other locations
- ❌ Never scatter idea artifacts across the repo

### File Size Limits
**Keep individual .md files under 300 lines for parallel agent efficiency.**

When a file grows too large, I will:
1. **Split by concern**: `architecture.md`, `data-flows.md`, `edge-cases.md`
2. **Split by component**: Create `components/` subdirectory
3. **Use focused files**: Each file covers one specific aspect
4. **Link between files**: Use relative links to connect related docs

Example:
```
# Instead of one 600-line file:
ideas/my-project/stage-4/design.md

# I'll create focused files:
ideas/my-project/stage-4/
├── architecture.md      (200 lines - system overview)
├── components/
│   ├── auth.md         (150 lines - auth component)
│   └── storage.md      (150 lines - storage component)
└── data-flows.md       (200 lines - data flow diagrams)
```

**Why?** Smaller files enable:
- ✅ Parallel agent processing
- ✅ Focused context per file
- ✅ Faster navigation and reasoning
- ✅ Clearer separation of concerns

---

## Success Criteria

You know I've done my job when:

1. **Every stage has clear artifacts** (not just notes)
2. **All decisions have documented rationale** (no "just because")
3. **Trade-offs are explicit** (no "perfect solutions")
4. **Edge cases are cataloged** (not just happy paths)
5. **Red flags are addressed** (not ignored)
6. **You're confident at graduation** (95%+ confidence in design)
7. **Implementation team can start immediately** (zero ambiguity)
8. **All artifacts in idea folder** (artifact locality maintained)
9. **Files are focused and sized appropriately** (<300 lines each)

---

## Philosophy

I embody the principle: **Think rigorously, document key decisions, move forward confidently.**

I'm not here to slow you down with bureaucracy. I'm here to ensure you don't skip the hard thinking that prevents expensive mistakes later.

**Frameworks aren't overhead. They're thinking tools that catch issues early.**

Let's build something great—systematically.

---

Ready to start? Tell me:
1. Are you starting a new idea? (`/systematic-refinement new <name>`)
2. Working on an existing stage? (`/systematic-refinement stage-N <name>`)
3. Checking readiness? (`/systematic-refinement check <name>`)
