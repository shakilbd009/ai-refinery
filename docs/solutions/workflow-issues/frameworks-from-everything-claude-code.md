---
category: workflow-issues
tags: [frameworks, design-refinement, everything-claude-code]
created: 2026-01-24
status: implemented
---

# Thinking Frameworks Stolen from everything-claude-code

## Problem

ai-baseline had stage checklists but lacked systematic thinking frameworks to ensure rigorous design decisions during refinement.

everything-claude-code has excellent frameworks for code-level work (architect agent, planner agent, coding standards). However, ai-baseline operates PRE-code, in pure design space.

**Question**: Can we adapt their code-focused frameworks for pre-code design refinement?

---

## Solution

We extracted the **thinking methodologies** (not the code tools) from everything-claude-code and adapted them for design refinement.

### What We Stole

#### 1. Trade-Off Analysis Framework (from architect.md)

**Original context**: Choosing implementation patterns
**Adapted for**: Choosing design approaches

```markdown
Original (code):
- Repository Pattern vs Service Layer
- REST vs GraphQL implementation

Adapted (design):
- Monolithic vs Microservices architecture
- SQL vs NoSQL data modeling
- Synchronous vs Event-driven patterns
```

**Where it lives**:
- Skill: `skills/design-refinement/SKILL.md` (Section 1)
- Template: `docs/templates/trade-off-analysis.md`
- Applied: Stage 3+ in enhanced checklists

---

#### 2. Architecture Decision Records (from architect.md)

**Original context**: Documenting implemented architecture choices
**Adapted for**: Documenting design-level architectural decisions

```markdown
Original (code):
ADR-001: Use Redis for Session Storage
- Assumes codebase exists to implement in

Adapted (design):
ADR-001: Use Redis for Semantic Search Vector Storage
- Assumes NO code yet, pure design justification
- Gets packaged into graduated repo for implementation team
```

**Where it lives**:
- Skill: `skills/design-refinement/SKILL.md` (Section 2)
- Template: `docs/templates/adr-template.md`
- Applied: Stage 3 (start), Stage 4-5 (expand), Stage 6 (finalize), Stage 7 (package)

**Key adaptation**: ai-baseline ADRs are DESIGN decisions that inform later implementation, not post-implementation documentation.

---

#### 3. System Design Checklist (from architect.md)

**Original context**: Pre-implementation planning checklist
**Adapted for**: Multi-stage refinement verification

```markdown
Original (code):
- [ ] API contracts defined
- [ ] Testing strategy planned
(Single-pass checklist before coding)

Adapted (design):
L1: High-level architecture sketch
L2: Detailed architecture with patterns
L3: Every architectural nuance resolved
(Progressive deepening across 3 stages)
```

**Where it lives**:
- Skill: `skills/design-refinement/SKILL.md` (Section 4: Progressive Deepening)
- Template: `docs/templates/progressive-deepening.md`
- Applied: Stage 4 (L1), Stage 5 (L2), Stage 6 (L3)

**Key adaptation**: Turned single checklist into three-level progressive deepening framework.

---

#### 4. Red Flags / Anti-Patterns (from architect.md)

**Original context**: Code smells in implementation
**Adapted for**: Design smells in pre-code refinement

```markdown
Original (code):
- Big Ball of Mud (code structure)
- God Object (class doing everything)
- Tight Coupling (code dependencies)

Adapted (design):
- Analysis Paralysis (design process)
- False Precision (design certainty)
- Solution First (skipping requirements)
- Hand-Waving Complexity (design vagueness)
```

**Where it lives**:
- Skill: `skills/design-refinement/SKILL.md` (Section 3: Red Flags Checklist)
- Applied: Stage 3+ in enhanced checklists (must pass to advance)

**Key adaptation**: Shifted from code anti-patterns to design process anti-patterns.

---

#### 5. Planning Process Structure (from planner.md)

**Original context**: Step-by-step implementation plan
**Adapted for**: Requirements Analysis Framework

```markdown
Original (code):
1. Requirements Analysis
2. Architecture Review
3. Step Breakdown (with file paths)
4. Implementation Order

Adapted (design):
1. Requirements Analysis (functional/non-functional)
2. Constraints & Assumptions
3. Out of Scope (explicit)
4. Success Metrics
(No implementation steps - those happen post-graduation)
```

**Where it lives**:
- Skill: `skills/design-refinement/SKILL.md` (Section 5: Requirements Framework)
- Template: `docs/templates/requirements.md`
- Applied: Stage 2 (create), Stage 3+ (reference)

**Key adaptation**: Removed implementation details, focused on WHAT/WHY, not HOW.

---

## What We Didn't Take

### ❌ Code-Specific Agents
- `planner.md` - Needs codebase to plan against
- `code-reviewer.md` - Reviews code
- `tdd-guide.md` - Writes tests
- `security-reviewer.md` - Reviews code for vulnerabilities

**Why**: These are for POST-graduation repos where code exists.

### ❌ Code-Specific Skills
- `coding-standards` - TypeScript/React patterns
- `tdd-workflow` - Test-first implementation
- `backend-patterns` - API implementation patterns
- `frontend-patterns` - React implementation patterns

**Why**: ai-baseline doesn't write code. These belong in graduated repos.

### ✅ What We Considered
- `continuous-learning` - Could extract design patterns from refinement sessions
- `strategic-compact` - Could suggest compact at stage boundaries

**Status**: Parking lot for future consideration.

---

## Implementation

### Files Created

1. **Skill**: `skills/design-refinement/SKILL.md`
   - Comprehensive guide to all frameworks
   - When/how to use each one
   - Stage-specific application guidance

2. **Templates** (in `docs/templates/`):
   - `trade-off-analysis.md` - Systematic option comparison
   - `adr-template.md` - Architecture Decision Records
   - `progressive-deepening.md` - L1→L2→L3 refinement template
   - `requirements.md` - Functional/non-functional requirements

3. **Enhanced Checklists**: `docs/stage-checklists-enhanced.md`
   - Shows exactly when to use each framework
   - Integrates frameworks into stage gates
   - Provides quality bar for each stage

---

## Usage Pattern

### Stage 2: Brainstorm → Explore
```bash
# Copy requirements template
cp docs/templates/requirements.md ideas/my-project/stage-2/

# Fill it in systematically
# Use as foundation for all future stages
```

### Stage 3: Explore → Refine L1
```bash
# For each major approach:
cp docs/templates/trade-off-analysis.md ideas/my-project/stage-3/approach-comparison.md

# Document first ADRs
cp docs/templates/adr-template.md ideas/my-project/ADRs/ADR-001-architecture-pattern.md
```

### Stage 4-6: Refine L1 → L2 → L3
```bash
# For each major component:
cp docs/templates/progressive-deepening.md ideas/my-project/stage-4/component-X.md

# Fill in L1 level in stage 4
# Fill in L2 level in stage 5
# Fill in L3 level in stage 6
```

### Stage 7: Graduate
```bash
# Package curated design
/graduate my-project ~/code/my-project

# Graduated repo includes:
# - All ADRs
# - Final requirements
# - Curated design docs
# - Trade-off summaries
```

---

## Benefits

### Before (Stage Checklists Only)
- ✅ Clear stage progression
- ❌ No systematic frameworks
- ❌ Decisions poorly documented
- ❌ Inconsistent rigor across ideas
- ❌ Hard to know "am I done?"

### After (With Frameworks)
- ✅ Clear stage progression
- ✅ Systematic thinking frameworks
- ✅ All decisions documented with rationale
- ✅ Consistent rigor (red flags checklist)
- ✅ Clear quality bar for advancement

---

## Examples

### Example: Trade-Off Analysis in Stage 3

**Scenario**: Choosing database for a social app

```markdown
## Options Considered

### Option A: PostgreSQL
**Pros:**
- ACID transactions
- Complex queries with joins
- JSON support for flexibility

**Cons:**
- Harder to scale horizontally
- Schema migrations required

**Complexity:** Medium
**Risk:** Low

### Option B: MongoDB
**Pros:**
- Easy horizontal scaling
- Schema flexibility
- Fast for simple queries

**Cons:**
- Weaker consistency guarantees
- Complex queries harder
- No foreign keys

**Complexity:** Low
**Risk:** Medium

### Decision
PostgreSQL. Our app has complex relationships (friends, groups, posts)
and requires strong consistency (likes/comments counts must be accurate).
We accept harder horizontal scaling because we won't hit that scale for
2-3 years, and can re-architect then if needed.

Validation: If query performance becomes an issue with >100K users,
consider adding read replicas or caching layer.
```

---

### Example: Progressive Deepening in Stages 4-6

**Scenario**: User authentication component

```markdown
# Progressive Deepening: Authentication System

## L1 Pass (Stage 4)
**What:** JWT-based authentication
**Why:** Stateless, scales well, industry standard
**Key Insight:** Trade session state for statelessness

## L2 Pass (Stage 5)
**How:**
- Login endpoint generates JWT with user claims
- Protected routes verify JWT signature
- Refresh token for long-lived sessions

**Edge Cases:**
- Expired token → 401, redirect to login
- Invalid signature → 401, possible attack
- Token stolen → rely on short expiry + HTTPS

**Risks:**
- Token theft if HTTPS not enforced
- Token bloat if too many claims

## L3 Pass (Stage 6)
**Complete Failure Mode Analysis:**
| Failure | Cause | Detection | Recovery |
|---------|-------|-----------|----------|
| Expired token | TTL passed | 401 response | Refresh token flow |
| Invalid sig | Tampered token | Signature verify fails | Force re-login |
| Stolen token | XSS/MITM | Abnormal IP/device | Short expiry + device tracking |

**Security Threat Model:**
- XSS: Store token in httpOnly cookie
- MITM: Enforce HTTPS, HSTS header
- CSRF: SameSite=Strict cookie

**Dependencies:**
- JWT library (jsonwebtoken)
- Secure random for signing key
- Redis for refresh token revocation list
```

---

## Integration with Existing ai-baseline

### Complements Existing Docs
- `architecture-guide.md` - Already had ADR format (we enhanced it)
- `stage-checklists.md` - Base checklists (we added framework layer)
- `compound-guide.md` - Documents solved problems (frameworks prevent future problems)

### Fits Into Workflow
```mermaid
graph TD
    A[/new-idea] --> B[Stage 1: Raw]
    B --> C[/superpowers:brainstorming]
    C --> D[Stage 2: Fill requirements.md]
    D --> E[Stage 3: Trade-off analysis + First ADRs]
    E --> F[Stage 4-6: Progressive deepening L1→L2→L3]
    F --> G[Stage 7: Package curated design]
    G --> H[/graduate]
    H --> I[New repo with ADRs + design docs]
    I --> J[Implementation planning begins]
```

---

## Key Principles Preserved

### From everything-claude-code
- ✅ Systematic thinking > ad-hoc exploration
- ✅ Document decisions with rationale
- ✅ Explicit trade-offs
- ✅ Red flags prevent bad patterns

### From ai-baseline
- ✅ Pre-code design focus
- ✅ Progressive deepening across stages
- ✅ Curated graduation package
- ✅ Implementation planning happens in graduated repo

### New Synthesis
- 🎯 Rigorous design thinking frameworks
- 🎯 Applied systematically across stages
- 🎯 Quality bar enforced by red flags
- 🎯 Graduated repos receive design + rationale

---

## Success Metrics

**How we'll know this works:**

1. **Design quality**: Fewer "why did we choose this?" questions post-graduation
2. **Decision clarity**: All major decisions have documented rationale
3. **Edge case coverage**: Implementation teams discover fewer surprise edge cases
4. **Consistency**: All ideas refined with same rigor (red flags ensure this)
5. **Confidence**: 95%+ confidence in design soundness at graduation

---

## Future Enhancements

### Under Consideration
1. **continuous-learning adaptation**
   - Extract design patterns from refinement sessions
   - Feed into future brainstorming
   - Build institutional design knowledge

2. **strategic-compact for stages**
   - Suggest compact after Stage 2 (post-requirements)
   - Suggest compact after Stage 5 (before final L3 push)

3. **Red flags automation**
   - Pre-flight check before `/advance-stage`
   - Scan documents for red flag indicators
   - Block advancement if critical flags detected

---

## References

- **Source**: [everything-claude-code](https://github.com/affaan-m/everything-claude-code)
- **Key files adapted**:
  - `agents/architect.md` → Trade-offs, ADRs, Red Flags
  - `agents/planner.md` → Requirements structure
  - `skills/coding-standards/SKILL.md` → Quality principles (adapted)

---

## Conclusion

We successfully "stole" the **thinking frameworks** from everything-claude-code while preserving the code/design boundary:

- **everything-claude-code**: Code execution toolkit
- **ai-baseline**: Design refinement toolkit
- **Synthesis**: Rigorous design thinking borrowed from software engineering, applied pre-code

Result: Graduated repos now receive not just designs, but **well-reasoned, well-documented, thoroughly analyzed designs** ready for confident implementation.
