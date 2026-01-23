# Stage Gate Checklists

This document defines the specific criteria that must be met before advancing an idea from one stage to the next in the refinement pipeline.

## Stage 1: Raw → Brainstorm

**Purpose**: Capture the initial idea clearly enough to begin exploration.

**Criteria**:
- [ ] Basic idea is documented (what problem does it solve?)
- [ ] Problem statement is clearly defined
- [ ] Initial motivation is captured (why does this matter?)
- [ ] Any initial constraints or requirements are noted

**Artifacts**: Raw idea document with problem statement

---

## Stage 2: Brainstorm → Explore

**Purpose**: Understand the user needs and what success looks like.

**Criteria**:
- [ ] Target users/audience identified
- [ ] User needs and pain points documented
- [ ] Success criteria established (what does "done" look like?)
- [ ] Key requirements gathered
- [ ] Scope boundaries defined (what's in/out of scope)

**Artifacts**: User research notes, requirements list, success criteria

---

## Stage 3: Explore → Refine L1

**Purpose**: Evaluate different approaches and choose the best path forward.

**Criteria**:
- [ ] At least 2-3 different approaches identified
- [ ] Trade-offs for each approach analyzed (pros/cons)
- [ ] Technical feasibility assessed for each option
- [ ] Recommendation made with clear rationale
- [ ] High-level technical direction chosen

**Artifacts**: Approach comparison document, recommendation with justification

---

## Stage 4: Refine L1 → Refine L2

**Purpose**: First complete pass covering all design aspects at a high level.

**Criteria**:
- [ ] **Architecture**: High-level architecture sketch created
- [ ] **Components**: Main components/modules identified
- [ ] **Data Flows**: Primary data flows mapped (happy paths)
- [ ] **Error Handling**: Basic error scenarios identified
- [ ] **Testing Strategy**: High-level testing approach outlined
- [ ] **Edge Cases**: Obvious edge cases noted
- [ ] **Technical Decisions**: Key technology choices documented

**Artifacts**: L1 design document covering all aspects at surface level

---

## Stage 5: Refine L2 → Refine L3

**Purpose**: Second pass - detailed design on all aspects from L1.

**Criteria**:
- [ ] **Architecture**: Detailed architecture with component relationships, patterns, layers
- [ ] **Components**: Component interfaces, responsibilities, interactions defined
- [ ] **Data Flows**: Detailed flows including error paths and alternate scenarios
- [ ] **Error Handling**: Comprehensive error scenarios, recovery strategies, user experience during failures
- [ ] **Testing Strategy**: Specific testing approaches (unit/integration/e2e), what to test, coverage goals
- [ ] **Edge Cases**: Most edge cases identified and handling approaches defined
- [ ] **Technical Decisions**: All major technical decisions documented with rationale

**Artifacts**: L2 design document with significantly more depth than L1

---

## Stage 6: Refine L3 → Graduate

**Purpose**: Final pass - exhaustive coverage leaving no ambiguity.

**Criteria**:
- [ ] **Architecture**: Every architectural nuance resolved, no ambiguous areas
- [ ] **Components**: All component details finalized, APIs/contracts defined
- [ ] **Data Flows**: Every flow variant documented including rare scenarios
- [ ] **Error Handling**: Every failure mode addressed, rollback/recovery procedures defined
- [ ] **Testing Strategy**: Comprehensive test plan, all test scenarios identified
- [ ] **Edge Cases**: Every edge case documented with handling approach
- [ ] **Technical Decisions**: All technical questions answered, no TBDs remaining
- [ ] Design reviewed for completeness
- [ ] All assumptions explicitly stated
- [ ] Dependencies and external integrations fully specified

**Artifacts**: L3 design document - exhaustive, no stone unturned

---

## Stage 7: Graduate → Export

**Purpose**: Package the curated design for export to a new project repository.

**Criteria**:
- [ ] Curated design document created (clean, no exploration artifacts)
- [ ] Key decision rationale included (the "why" behind choices)
- [ ] Trade-offs and alternatives documented
- [ ] Design is complete and unambiguous
- [ ] Design is ready to guide implementation (but not prescriptive about implementation steps)
- [ ] Target path for new repository identified

**Artifacts**: Curated design package ready for graduation skill to process

---

## Using These Checklists

1. Copy the relevant checklist items into your idea's `status.md` when entering a new stage
2. Check off items as you complete them
3. Use `/advance-stage` skill when all criteria are met
4. The skill will validate completion before allowing advancement
