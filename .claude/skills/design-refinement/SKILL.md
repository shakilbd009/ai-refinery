---
name: design-refinement
description: Systematic design thinking frameworks for pre-code idea refinement. Use when brainstorming, exploring approaches, or refining design decisions across stages.
---

# Design Refinement Skill

Applies systematic thinking frameworks to idea refinement BEFORE code exists. This skill adapts software engineering rigor to the design phase.

## When to Use

- During brainstorming sessions (/superpowers:brainstorming)
- When advancing through refinement stages
- Evaluating architectural approaches
- Documenting design decisions
- Identifying edge cases and failure modes

## Core Frameworks

### 1. Trade-Off Analysis Framework

For EVERY significant design decision, document:

```markdown
## Decision: [Specific Choice]

### Context
[What problem are we solving? What constraints exist?]

### Options Considered

#### Option A: [Name]
**Pros:**
- Benefit 1
- Benefit 2

**Cons:**
- Drawback 1
- Drawback 2

**Complexity:** Low/Medium/High
**Risk:** Low/Medium/High

#### Option B: [Name]
[Same format]

#### Option C: [Name]
[Same format]

### Decision
We chose [Option] because [clear rationale].

### Trade-offs Accepted
- We're trading [X] for [Y]
- We accept [limitation] to gain [benefit]

### Validation Plan
- How we'll test if this was the right choice
- What metrics/signals would indicate we should pivot
```

**Why this matters**: Forces explicit reasoning. In Stage 3+ you should have NO undocumented design decisions.

---

### 2. Architecture Decision Records (ADRs)

For major architectural choices, create numbered ADRs:

```markdown
# ADR-001: [Short Title]

## Status
Proposed | Accepted | Deprecated | Superseded by ADR-XXX

## Context
[Why is this decision needed? What forces are at play?]

## Decision
[What are we doing?]

## Consequences

### Positive
- Benefit 1
- Benefit 2

### Negative
- Cost 1
- Limitation 2

### Neutral
- Things that change but aren't clearly good/bad

## Alternatives Considered
- **Option 1**: Why rejected
- **Option 2**: Why rejected

## Notes
[Any additional context, links, research]

## Date
YYYY-MM-DD
```

**When to create ADRs**:
- Choosing core architecture patterns
- Selecting major technologies/frameworks
- Data storage/modeling decisions
- API design approaches
- Security models
- Deployment strategies

**Where to store**: `ideas/<project>/07-curated/decisions/` during refinement, then copied to graduated repo.

---

### 3. Design Red Flags Checklist

Run this checklist at EVERY stage advancement:

#### Architecture Level
- [ ] No single component doing "too much" (god object)
- [ ] Clear separation of concerns
- [ ] No circular dependencies conceptually
- [ ] Scalability paths identified
- [ ] Failure modes considered

#### Decision Quality
- [ ] No "we'll figure it out later" on critical choices
- [ ] All major decisions have documented rationale
- [ ] Trade-offs explicitly acknowledged
- [ ] Alternatives were actually considered (not rubber-stamped)

#### Completeness
- [ ] No obvious edge cases ignored
- [ ] Error scenarios identified for all major flows
- [ ] Integration points specified
- [ ] Data flows complete (not just happy paths)
- [ ] Security implications considered

#### Feasibility
- [ ] No hand-waving on technical complexity
- [ ] No "just use AI" without specifics
- [ ] External dependencies realistic
- [ ] Timeline expectations grounded

---

### 4. Progressive Deepening Template

Use this structure to ensure each refinement level builds on the previous:

```markdown
# [Aspect]: [Component/Flow/Decision]

## L1 Pass (Surface)
- What: [Basic description]
- Why: [High-level motivation]
- Key insight: [Main point]

## L2 Pass (Detailed)
- How: [Approach/mechanism]
- Interactions: [How it connects to other components]
- Alternatives: [What else was considered]
- Edge cases: [Initial list]
- Risks: [Identified concerns]

## L3 Pass (Exhaustive)
- Every variant: [All scenarios documented]
- Every failure mode: [Complete error taxonomy]
- Recovery strategies: [For each failure mode]
- Performance implications: [Scaling, bottlenecks]
- Security implications: [Threat model]
- Dependencies: [External systems, assumptions]
- Unknowns resolved: [No TBDs remaining]
```

**Usage**: Copy this into your stage documents and fill in each level as you refine.

---

### 5. Requirements Analysis Framework

Before jumping into solutions, systematically capture requirements:

```markdown
## Functional Requirements
1. The system MUST [capability]
2. The system MUST [capability]
   - Acceptance criteria: [how do we know it works?]

## Non-Functional Requirements

### Performance
- Response time: [specific targets]
- Throughput: [specific targets]
- Scalability: [user/data growth expectations]

### Security
- Authentication: [requirements]
- Authorization: [requirements]
- Data sensitivity: [classification]
- Compliance: [regulations/standards]

### Reliability
- Uptime target: [percentage]
- Data durability: [requirements]
- Disaster recovery: [RTO/RPO]

### Usability
- Target user expertise level
- Accessibility requirements
- Multi-language/localization

### Maintainability
- Team size/skill level
- Technology constraints
- Documentation needs

## Constraints
- Budget: [if applicable]
- Timeline: [if applicable]
- Technology: [required/excluded tech]
- Regulatory: [compliance requirements]
- Integration: [must work with X]

## Out of Scope
[Explicitly list what we're NOT doing]
```

**Use in Stage 2-3**: Before designing solutions, lock down requirements.

---

### 6. Edge Case Discovery Framework

Systematic approach to finding edge cases:

```markdown
## Data Boundary Cases
- Empty/null/undefined inputs
- Zero values
- Negative values (if numeric)
- Maximum values (overflow)
- Special characters (if text)
- Very large datasets
- Very small datasets

## State Transition Cases
- Multiple rapid changes
- Concurrent operations
- Partial completion (interrupted mid-flow)
- Retry after failure
- Out-of-order events

## Timing Cases
- Timeout scenarios
- Race conditions
- Clock skew/timezone issues
- Long-running operations

## Integration Cases
- External service down
- External service slow
- Invalid responses from external service
- Authentication/authorization failures
- Network partitions

## User Behavior Cases
- Unexpected navigation (back button)
- Multiple tabs/sessions
- Permission changes mid-session
- Account deletion mid-operation
```

**Use from Stage 4+**: Systematically check your design against this list.

---

## Stage-Specific Application

### Stage 2 (Brainstorm → Explore)
**Focus**: Requirements clarity
- Use Requirements Analysis Framework
- Document user needs systematically
- Establish success criteria

### Stage 3 (Explore → Refine L1)
**Focus**: Approach comparison
- Use Trade-Off Analysis Framework for each approach
- Create comparison matrix
- Document why chosen approach wins

### Stage 4 (Refine L1)
**Focus**: First complete pass
- Start ADRs for major decisions
- Apply Progressive Deepening Template (L1 level)
- Run Red Flags Checklist

### Stage 5 (Refine L2)
**Focus**: Detailed design
- Complete ADRs with full alternatives section
- Apply Progressive Deepening Template (L2 level)
- Use Edge Case Discovery Framework
- Run Red Flags Checklist

### Stage 6 (Refine L3)
**Focus**: Exhaustive coverage
- Finalize all ADRs
- Apply Progressive Deepening Template (L3 level)
- Every edge case documented
- Run Red Flags Checklist (must pass 100%)

### Stage 7 (Graduate)
**Focus**: Curated package
- Extract final ADRs
- Include trade-off analysis summaries
- Include all red flags addressed
- Clean exploration artifacts

---

## Anti-Patterns to Avoid

### ❌ Analysis Paralysis
**Symptom**: Endlessly refining without moving forward
**Fix**: Set timebox per stage. If 80% confident, advance.

### ❌ False Precision
**Symptom**: Pretending to have certainty you don't have
**Fix**: Document assumptions and validation plans

### ❌ Solution First
**Symptom**: Jumping to "we'll use X" before understanding requirements
**Fix**: Always start with Requirements Framework

### ❌ Ignoring Trade-Offs
**Symptom**: Claiming a choice has "no downsides"
**Fix**: Every decision trades something. Find it.

### ❌ Hand-Waving Complexity
**Symptom**: "We'll just use AI/microservices/blockchain"
**Fix**: Specify HOW, not just WHAT

### ❌ Rubber-Stamping
**Symptom**: "Option A is best. Option B exists but A is better."
**Fix**: Actually analyze alternatives honestly

---

## Success Metrics

You're doing this right if:
- ✅ Any team member can understand your design decisions
- ✅ You can explain WHY you chose X over Y
- ✅ You've identified edge cases before implementation
- ✅ No "we'll figure it out during coding" on critical paths
- ✅ Your graduated design enables confident implementation

---

## Templates Location

Find templates in `/docs/templates/`:
- `trade-off-analysis.md`
- `adr-template.md`
- `progressive-deepening.md`
- `requirements.md`

Copy these into your idea's stage folder and fill them in.

---

**Remember**: The goal isn't bureaucracy. It's to surface hard questions BEFORE they become expensive bugs or architectural regret. Think rigorously, document key decisions, move forward confidently.
