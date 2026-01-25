# Systematic Refinement Guide

Complete guide to using the systematic refinement workflow with thinking frameworks.

## Quick Start

```bash
# Start with your new idea
/systematic-refinement new my-awesome-app

# The skill will guide you through:
# - Capturing the problem clearly
# - Applying frameworks at each stage
# - Creating all necessary templates
# - Checking readiness for advancement
# - Ensuring nothing is missed

# At each stage:
/systematic-refinement <stage-name> my-awesome-app  # e.g., 02-requirements, 03-trade-offs

# When ready to graduate:
/systematic-refinement check my-awesome-app
/graduate my-awesome-app ~/code/my-awesome-app
```

---

## What You Get

### 🎯 Design Thinking Coach

The `/systematic-refinement` skill acts as your design thinking coach, ensuring:
- ✅ All frameworks applied systematically
- ✅ Critical questions asked at each stage
- ✅ Red flags caught before advancement
- ✅ Templates created in right locations
- ✅ Design completeness verified

### 📚 Thinking Frameworks

Six systematic frameworks adapted from software engineering:

1. **Requirements Analysis** (Stage 2)
   - Functional + non-functional requirements
   - Constraints, assumptions, success metrics
   - Template: `docs/templates/requirements.md`

2. **Trade-Off Analysis** (Stage 3+)
   - Systematic option comparison
   - Pros/cons, complexity/risk ratings
   - Template: `docs/templates/trade-off-analysis.md`

3. **Architecture Decision Records** (Stage 3+)
   - Document major design decisions
   - Alternatives considered, consequences
   - Template: `docs/templates/adr-template.md`

4. **Progressive Deepening** (Stages 4-6)
   - L1 → L2 → L3 refinement
   - Ensures thoroughness across stages
   - Template: `docs/templates/progressive-deepening.md`

5. **Edge Case Discovery** (Stage 5+)
   - Systematic edge case identification
   - Data boundaries, state transitions, timing, integration
   - Built into design-refinement skill

6. **Red Flags Checklist** (All stages)
   - Catches design anti-patterns
   - Enforces quality bar
   - Blocks advancement if critical issues

---

## Complete Workflow

```mermaid
graph TD
    A[/systematic-refinement new idea] --> B[Stage 1: Capture Problem]
    B --> C[Stage 2: Requirements Framework]
    C --> D[requirements.md created]
    D --> E[Stage 3: Trade-Off Analysis]
    E --> F[trade-off-analysis.md + ADRs]
    F --> G[Red Flags Check]
    G --> H[Stage 4: Progressive Deepening L1]
    H --> I[component docs L1 + architecture]
    I --> J[Stage 5: Edge Cases + L2]
    J --> K[edge cases + component L2]
    K --> L[Stage 6: Exhaustive L3]
    L --> M[component L3 + failure modes]
    M --> N[Red Flags 100% Pass]
    N --> O[Stage 7: Curate Package]
    O --> P[/graduate idea ~/code/project]
    P --> Q[Production repo ready]

    G -->|Fail| R[Fix Red Flags]
    R --> E
    N -->|Fail| S[Resolve Issues]
    S --> L
```

---

## Stage-by-Stage Breakdown

### Stage 1: Raw Idea

**What happens:**
- `/systematic-refinement new my-idea`
- Guided problem statement capture
- No frameworks yet

**Questions asked:**
- What problem are you solving?
- Who faces this problem?
- Why does this matter?
- Any initial constraints?

**Output:** `ideas/my-idea/01-brainstorm/idea.md`

---

### Stage 2 (02-requirements): Define Requirements

**What happens:**
- `/systematic-refinement 02-requirements my-idea`
- Requirements Analysis Framework applied
- Creates `requirements.md` from template

**You'll document:**
- Functional requirements (with acceptance criteria)
- Non-functional requirements (performance, security, scalability)
- Constraints and assumptions
- Out of scope (explicit)
- Success metrics

**Questions asked:**
- What must the system DO?
- What are performance targets? (specific numbers)
- What security requirements?
- What's NOT in scope?
- How will you measure success?

**Output:** Completed `requirements.md`

---

### Stage 3 (03-trade-offs): Evaluate Approaches

**What happens:**
- `/systematic-refinement 03-trade-offs my-idea`
- Trade-Off Analysis Framework applied
- First ADRs created
- Red Flags Checklist run

**You'll create:**
- Trade-off analysis for each major approach
- ADR-001, ADR-002 for biggest decisions
- Recommendation with rationale

**Questions asked:**
- What are 3 different ways to solve this?
- For each: biggest pro? biggest con?
- What trade-offs will you accept?
- How will you validate your choice?

**Frameworks used:**
- ✅ Trade-Off Analysis
- ✅ ADRs (start)
- ✅ Red Flags Checklist

**Red flags caught:**
- Only 1 approach (no comparison)
- Rubber-stamping chosen option
- Hand-waving complexity

**Output:**
- `03-trade-offs/approach-comparison.md`
- `ADRs/ADR-001-*.md`, `ADR-002-*.md`

---

### Stage 4 (04-design-l1): High-Level Design

**What happens:**
- `/systematic-refinement 04-design-l1 my-idea`
- Progressive Deepening Template (L1 level)
- Architecture diagrams created
- More ADRs added

**You'll document:**
For each component:
- What: Basic description
- Why: High-level motivation
- Key insight: Main point

Plus:
- Architecture diagram (Mermaid)
- Primary data flows
- Basic error scenarios

**Questions asked:**
- What are the major components?
- For each: what's its core responsibility?
- How do they interact?
- What are the primary data flows?
- What could go wrong?

**Frameworks used:**
- ✅ Progressive Deepening (L1)
- ✅ ADRs (expand to 3-5 total)
- ✅ Red Flags Checklist

**Output:**
- `04-design-l1/component-X.md` (L1 section filled)
- Architecture diagrams
- Expanded ADR set

---

### Stage 5 (05-design-l2): Detailed Design

**What happens:**
- `/systematic-refinement 05-design-l2 my-idea`
- Progressive Deepening L2 sections
- Edge Case Discovery Framework applied
- ADRs finalized

**You'll document:**
For each component:
- How: Approach/mechanism
- Interactions: Connections to other components
- Alternatives: What else was considered
- Edge cases: Initial list
- Risks: With mitigations

Plus:
- Systematic edge case catalog
- Error paths with recovery
- Security implications

**Questions asked:**
- HOW does each component work?
- What happens when [edge case]?
- What if service X is down?
- How do we recover from failure Y?
- What are ALL the ways this could fail?

**Frameworks used:**
- ✅ Progressive Deepening (L2)
- ✅ Edge Case Discovery
- ✅ ADRs (finalize)
- ✅ Red Flags Checklist (stricter)

**Output:**
- Component docs with L2 sections
- Edge case catalog
- Finalized ADRs (5-10 typical)

---

### Stage 6 (06-design-l3): Exhaustive Design

**What happens:**
- `/systematic-refinement 06-design-l3 my-idea`
- Progressive Deepening L3 sections (exhaustive)
- 100% edge case coverage
- Red Flags 100% pass (mandatory)

**You'll document:**
For each component:
- Complete scenario coverage (all variants)
- Complete failure mode analysis
- Recovery strategies (for each failure)
- Performance implications (scaling, bottlenecks)
- Security threat model
- All dependencies and assumptions
- Zero unknowns (NO TBDs)

**Questions asked:**
- Is there ANY scenario we haven't covered?
- What's the WORST that could happen?
- Can implementation team start immediately?
- Are there ANY unknowns left?
- What gives you 95%+ confidence?

**Frameworks used:**
- ✅ Progressive Deepening (L3 - exhaustive)
- ✅ Edge Case Discovery (100%)
- ✅ Red Flags Checklist (100% pass - blocks if fails)

**Red flags enforcement (HARD BLOCKS):**
- ❌ ANY "figure it out later" → BLOCK
- ❌ ANY hand-waving → BLOCK
- ❌ ANY undocumented edge case → BLOCK
- ❌ ANY TBD or unknown → BLOCK

**Output:**
- Component docs with L3 sections (exhaustive)
- Complete failure mode analysis
- Security threat model
- Performance analysis
- L3 design document (production-ready)

---

### Stage 7: Graduate → Export

**What happens:**
- `/systematic-refinement check my-idea` (verify readiness)
- Package curated design
- `/graduate my-idea ~/code/my-project`

**Curated package includes:**
- ✅ All ADRs (with index)
- ✅ Final requirements
- ✅ Architecture diagrams
- ✅ Trade-off summaries
- ✅ Edge case catalog
- ✅ Key decision rationale

**Excluded from package:**
- ❌ Progressive deepening templates (raw)
- ❌ L1/L2 drafts
- ❌ Exploration notes
- ❌ Dead-end approaches

**Output:**
- New repo at `~/code/my-project`
- Design docs ready for implementation planning
- Different Claude instance starts implementation

---

## Files Created Throughout

```
ideas/my-idea/
├── 01-brainstorm/
│   └── idea.md
│
├── 02-requirements/
│   └── requirements.md               ← Requirements Framework
│
├── 03-trade-offs/
│   ├── approach-comparison.md        ← Trade-Off Analysis
│   └── recommendation.md
│
├── 04-design-l1/
│   ├── auth-system.md                ← Progressive Deepening (L1)
│   ├── data-layer.md
│   ├── api-layer.md
│   └── architecture.md               ← Mermaid diagrams
│
├── 05-design-l2/
│   ├── [L2 sections added to component files]
│   ├── edge-cases.md                 ← Edge Case Discovery
│   └── detailed-flows.md
│
├── 06-design-l3/
│   ├── [L3 sections added to component files]
│   ├── failure-modes.md              ← Exhaustive analysis
│   └── threat-model.md
│
├── curated/
│   └── [graduation-ready artifacts]  ← Clean package
│
└── ADRs/
    ├── ADR-001-architecture-pattern.md
    ├── ADR-002-database-choice.md
    ├── ADR-003-auth-mechanism.md
    ├── ADR-004-api-design.md
    └── ...
```

---

## Red Flags System

### What Are Red Flags?

Design anti-patterns that lead to problems later. The systematic-refinement skill watches for these and BLOCKS advancement if critical ones exist.

### Categories

#### Process Red Flags
- ❌ Analysis Paralysis (stuck refining endlessly)
- ❌ False Precision (pretending to have certainty)
- ❌ Solution First (skipping requirements)
- ❌ Ignoring Trade-Offs (claiming "no downsides")

#### Design Red Flags
- ❌ Hand-Waving Complexity ("just use AI")
- ❌ Rubber-Stamping (fake comparison)
- ❌ God Object (one component doing everything)
- ❌ Figure It Out Later (deferring critical decisions)

#### Documentation Red Flags
- ❌ No Rationale ("we chose X" without why)
- ❌ Vague Requirements ("fast", "good UX")
- ❌ Missing Edge Cases (only happy paths)
- ❌ Undocumented Assumptions

### Enforcement

**Stages 3-5:** Red flags caught and flagged for fixing

**Stage 6:** Red flags 100% pass REQUIRED
- Cannot advance with ANY critical red flag
- Design must be unambiguous
- All decisions must have rationale

---

## Benefits

### Before Systematic Refinement
- ❌ Inconsistent rigor across ideas
- ❌ Easy to skip important thinking
- ❌ Unclear when "done" with a stage
- ❌ Decisions poorly documented
- ❌ Edge cases discovered during coding

### After Systematic Refinement
- ✅ Consistent rigor (frameworks ensure it)
- ✅ Guided thinking (skill asks critical questions)
- ✅ Clear quality bar (red flags checklist)
- ✅ All decisions documented with rationale
- ✅ Edge cases discovered during design
- ✅ 95%+ confidence at graduation
- ✅ Implementation team starts immediately

---

## Tips for Success

### General
1. **Trust the process** - Frameworks catch issues early
2. **Be honest** - Don't rubber-stamp decisions
3. **Document as you go** - Don't wait until stage end
4. **Ask "why"** - Every decision needs rationale
5. **Keep files focused** - Split documents over 300 lines into topic-specific files
6. **Artifact locality** - All idea files live in `ideas/<name>/`, nowhere else

### Working with the Skill
1. **Answer thoroughly** - Vague answers get challenged
2. **Consider alternatives** - Actually think about other options
3. **Accept being blocked** - Red flags exist for a reason
4. **Use 80% rule** - Don't seek perfection, seek confidence

### Avoiding Anti-Patterns
- ❌ "This is obvious" → Write it down anyway
- ❌ "We don't need ADRs" → If discussed, document it
- ❌ "I'll document later" → No, document now
- ❌ "Analysis paralysis" → 80% + assumptions = advance

---

## Example: Photo Sharing App

### Stage 1
```
Problem: Private photo sharing fragmented across platforms
Users: Families and close friend groups
Impact: Oversharing or under-sharing, weakening connections
```

### Stage 2
```
requirements.md:
- Functional: Private albums, group sharing, notifications
- Non-functional: <10ms upload start, E2EE, 99.9% uptime
- Out of scope: Public sharing, editing tools, printing
- Success: 80% retention, <5s to create album
```

### Stage 3
```
Trade-off: Storage architecture
- Option A: S3 (scalable, costly)
- Option B: Self-hosted (cheap, ops burden)
- Decision: S3. Trading cost for reliability.

ADR-001: E2E encryption approach
- Decision: Client-side encryption with key sharing
- Alternatives: Server-side (rejected - trust model)
```

### Stages 4-6
```
Progressive deepening: Upload component
L1: Handles photo upload with progress
L2: Chunked upload, retry on failure, compression
L3: All failure modes (network loss, disk full, corrupted file),
    recovery (resume, fallback to smaller chunks),
    performance (10 photos parallel, max 100MB total)
```

### Stage 7
```
Graduated package:
- 8 ADRs (architecture, storage, encryption, sync, etc.)
- Complete requirements
- Architecture diagrams
- Edge case catalog (47 cases documented)
- Threat model
- Performance analysis
```

**Result:** Implementation team starts coding confidently, zero ambiguity.

---

## Related Documentation

- **Skill**: `skills/systematic-refinement/SKILL.md` - Complete interactive guide
- **Frameworks**: `skills/design-refinement/SKILL.md` - Framework details
- **Templates**: `docs/templates/README.md` - Template usage guide
- **Checklists**: `docs/stage-checklists-enhanced.md` - Stage criteria
- **Solution**: `docs/solutions/workflow-issues/frameworks-from-everything-claude-code.md` - Background

---

## Quick Command Reference

```bash
# Start new idea (guided)
/systematic-refinement new my-idea

# Work on specific stage
/systematic-refinement 02-requirements my-idea  # Requirements
/systematic-refinement 03-trade-offs my-idea    # Trade-offs + ADRs
/systematic-refinement 04-design-l1 my-idea     # L1 design
/systematic-refinement 05-design-l2 my-idea     # L2 + edge cases
/systematic-refinement 06-design-l3 my-idea     # L3 exhaustive

# Check readiness
/systematic-refinement check my-idea

# Curate and graduate when ready
/curate my-idea
/graduate my-idea ~/code/my-project
```

---

**Remember**: The goal isn't bureaucracy. It's to surface hard questions BEFORE they become expensive bugs or architectural regret. Think rigorously, document key decisions, move forward confidently.

**Start your next idea with `/systematic-refinement new` and experience the difference.**
