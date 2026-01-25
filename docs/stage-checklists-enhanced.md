# Enhanced Stage Gate Checklists

This document defines enhanced criteria incorporating systematic thinking frameworks from the design-refinement skill.

> **Note**: This enhances the base checklists in `stage-checklists.md` with specific framework applications.

---

## Stage 1: Raw → Brainstorm

**Purpose**: Capture the initial idea clearly enough to begin exploration.

**Base Criteria**:
- [ ] Basic idea is documented (what problem does it solve?)
- [ ] Problem statement is clearly defined
- [ ] Initial motivation is captured (why does this matter?)
- [ ] Any initial constraints or requirements are noted

**Enhanced Criteria**:
- [ ] Problem statement avoids solution bias (describes need, not implementation)
- [ ] Initial assumptions explicitly listed

**Artifacts**: Raw idea document with problem statement

**Frameworks Used**: None yet - this is pre-framework stage

---

## Stage 2: Brainstorm → Explore

**Purpose**: Understand the user needs and what success looks like.

**Base Criteria**:
- [ ] Target users/audience identified
- [ ] User needs and pain points documented
- [ ] Success criteria established (what does "done" look like?)
- [ ] Key requirements gathered
- [ ] Scope boundaries defined (what's in/out of scope)

**Enhanced Criteria**:
- [ ] **Requirements Analysis Framework** applied (use `docs/templates/requirements.md`)
  - [ ] Functional requirements with acceptance criteria
  - [ ] Non-functional requirements specified (performance, security, scalability)
  - [ ] Constraints documented
  - [ ] Out of scope explicitly listed
- [ ] Success metrics defined (not just qualitative "good")
- [ ] Assumptions documented with validation plans

**Artifacts**:
- Completed `requirements.md`
- User research notes
- Success criteria with metrics

**Frameworks Used**:
- ✅ Requirements Analysis Framework
- 🔄 Begin identifying requirements that will need trade-off analysis in Stage 3

---

## Stage 3: Explore → Refine L1

**Purpose**: Evaluate different approaches and choose the best path forward.

**Base Criteria**:
- [ ] At least 2-3 different approaches identified
- [ ] Trade-offs for each approach analyzed (pros/cons)
- [ ] Technical feasibility assessed for each option
- [ ] Recommendation made with clear rationale
- [ ] High-level technical direction chosen

**Enhanced Criteria**:
- [ ] **Trade-Off Analysis Framework** applied for each major approach decision
  - [ ] Each option documented (use `docs/templates/trade-off-analysis.md`)
  - [ ] Comparison matrix completed
  - [ ] Decision rationale clearly documented
  - [ ] Trade-offs explicitly accepted
  - [ ] Validation plan for chosen approach
- [ ] Red flags check passed:
  - [ ] Not ignoring obvious complexity
  - [ ] Not hand-waving "just use AI/microservices"
  - [ ] Alternatives actually considered (not rubber-stamped)
- [ ] **First ADRs created** for major architectural directions
  - [ ] At least 1-2 ADRs for biggest decisions (use `docs/templates/adr-template.md`)
  - [ ] Alternatives section fully completed

**Artifacts**:
- Approach comparison with trade-off analysis
- Initial ADRs (ADR-001, ADR-002, etc.)
- Recommendation document with clear rationale

**Frameworks Used**:
- ✅ Trade-Off Analysis Framework (primary)
- ✅ Architecture Decision Records (begin)
- ✅ Design Red Flags Checklist

**Anti-Patterns to Avoid**:
- ❌ Jumping to solution without comparing alternatives
- ❌ Claiming chosen approach has "no downsides"
- ❌ Vague comparisons ("A is better than B")

---

## Stage 4: Refine L1 → Refine L2

**Purpose**: First complete pass covering all design aspects at a high level.

**Base Criteria**:
- [ ] **Architecture**: High-level architecture sketch created
- [ ] **Components**: Main components/modules identified
- [ ] **Data Flows**: Primary data flows mapped (happy paths)
- [ ] **Error Handling**: Basic error scenarios identified
- [ ] **Testing Strategy**: High-level testing approach outlined
- [ ] **Edge Cases**: Obvious edge cases noted
- [ ] **Technical Decisions**: Key technology choices documented

**Enhanced Criteria**:
- [ ] **Progressive Deepening Template** applied - L1 level (use `docs/templates/progressive-deepening.md`)
  - [ ] What/Why/Key Insight documented for each major component
  - [ ] Initial questions raised
- [ ] **ADRs expanded**:
  - [ ] ADR for each major technical decision (architecture pattern, data storage, API design)
  - [ ] All ADRs have "Alternatives Considered" section filled
- [ ] **Red Flags Checklist** passed:
  - [ ] No god objects in architecture
  - [ ] Clear separation of concerns
  - [ ] No circular dependencies
  - [ ] Failure modes identified
- [ ] **Trade-off analysis** for component boundaries and data modeling approaches
- [ ] Mermaid diagrams created for architecture and major data flows

**Artifacts**:
- L1 design document
- Multiple ADRs (3-5 typical)
- Progressive deepening docs for major components (L1 level)
- Architecture diagram (Mermaid)
- Trade-off analyses for component design

**Frameworks Used**:
- ✅ Progressive Deepening Template (L1)
- ✅ Architecture Decision Records (expand)
- ✅ Trade-Off Analysis Framework (component design)
- ✅ Design Red Flags Checklist

---

## Stage 5: Refine L2 → Refine L3

**Purpose**: Second pass - detailed design on all aspects from L1.

**Base Criteria**:
- [ ] **Architecture**: Detailed architecture with component relationships, patterns, layers
- [ ] **Components**: Component interfaces, responsibilities, interactions defined
- [ ] **Data Flows**: Detailed flows including error paths and alternate scenarios
- [ ] **Error Handling**: Comprehensive error scenarios, recovery strategies, user experience during failures
- [ ] **Testing Strategy**: Specific testing approaches (unit/integration/e2e), what to test, coverage goals
- [ ] **Edge Cases**: Most edge cases identified and handling approaches defined
- [ ] **Technical Decisions**: All major technical decisions documented with rationale

**Enhanced Criteria**:
- [ ] **Progressive Deepening Template** - L2 level completed
  - [ ] How/Interactions documented for all components
  - [ ] Edge cases list started
  - [ ] Risks identified with mitigations
  - [ ] Open questions from L1 answered
- [ ] **Edge Case Discovery Framework** applied systematically
  - [ ] Data boundary cases checked
  - [ ] State transition cases checked
  - [ ] Timing cases checked
  - [ ] Integration cases checked
- [ ] **ADRs finalized** for all major decisions
  - [ ] Every ADR has consequences (positive/negative/neutral)
  - [ ] Every ADR documents why alternatives rejected
- [ ] **Red Flags Checklist** passed at higher bar:
  - [ ] No "figure it out later" on critical paths
  - [ ] All major decisions have documented rationale
  - [ ] Trade-offs explicitly acknowledged
- [ ] **Security implications** documented for each component
- [ ] **Performance implications** documented for each major flow

**Artifacts**:
- L2 design document (significantly deeper than L1)
- All progressive deepening templates at L2 level
- Complete ADR set (5-10 typical)
- Edge case catalog
- Detailed sequence diagrams for complex flows

**Frameworks Used**:
- ✅ Progressive Deepening Template (L2)
- ✅ Edge Case Discovery Framework
- ✅ Architecture Decision Records (finalize)
- ✅ Design Red Flags Checklist (stricter)

**Quality Bar**:
- Any team member should be able to understand design from docs
- No major questions left unanswered
- Clear path to implementation visible

---

## Stage 6: Refine L3 → Graduate

**Purpose**: Final pass - exhaustive coverage leaving no ambiguity.

**Base Criteria**:
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

**Enhanced Criteria**:
- [ ] **Progressive Deepening Template** - L3 level completed
  - [ ] Complete scenario coverage (all variants)
  - [ ] Complete failure mode analysis with recovery strategies
  - [ ] Performance implications documented (scaling, bottlenecks)
  - [ ] Security threat model documented
  - [ ] All dependencies and assumptions validated
  - [ ] No unknowns remaining (all TBDs resolved)
- [ ] **Edge Case Discovery Framework** - 100% coverage
  - [ ] Every category checked and documented
  - [ ] Handling approach defined for each edge case
- [ ] **Red Flags Checklist** - MUST PASS 100%
  - [ ] Zero "we'll figure it out later" items
  - [ ] Zero hand-waving on complexity
  - [ ] Every decision has clear rationale
  - [ ] All trade-offs explicitly documented
- [ ] **All ADRs reviewed and current**
  - [ ] Status field accurate (Accepted/Deprecated)
  - [ ] References between ADRs linked
  - [ ] Implementation notes complete
- [ ] **Stability check across levels**:
  - [ ] Core concepts stable from L1→L2→L3
  - [ ] No fundamental pivots needed
  - [ ] Refinements were additive, not corrective

**Artifacts**:
- L3 design document (exhaustive, production-ready)
- All progressive deepening templates at L3 level
- Final ADR set with full traceability
- Complete edge case catalog with handling
- Full failure mode analysis
- Security threat model
- Performance analysis

**Frameworks Used**:
- ✅ Progressive Deepening Template (L3 - exhaustive)
- ✅ Edge Case Discovery Framework (100% coverage)
- ✅ Design Red Flags Checklist (100% pass)
- ✅ All ADRs finalized

**Quality Bar**:
- Implementation team can start coding immediately
- No ambiguity in any design aspect
- Every "what if X happens?" question answered
- Confidence level: 95%+ in design soundness

---

## Stage 7: Graduate → Export

**Purpose**: Package the curated design for export to a new project repository.

**Base Criteria**:
- [ ] Curated design document created (clean, no exploration artifacts)
- [ ] Key decision rationale included (the "why" behind choices)
- [ ] Trade-offs and alternatives documented
- [ ] Design is complete and unambiguous
- [ ] Design is ready to guide implementation (but not prescriptive about implementation steps)
- [ ] Target path for new repository identified

**Enhanced Criteria**:
- [ ] **ADRs packaged** for graduated repo
  - [ ] All ADRs in `ADRs/` folder
  - [ ] ADR index created
  - [ ] Cross-references verified
- [ ] **Trade-off summaries** extracted into design doc
  - [ ] Key trade-offs highlighted
  - [ ] Rationale for major decisions clear
- [ ] **Red flags review** documented
  - [ ] Document confirms all red flags addressed
  - [ ] Evidence/reasoning provided
- [ ] **Exploration artifacts removed**
  - [ ] No L1/L2 drafts in final package
  - [ ] Only L3 content or curated summaries
  - [ ] Progressive deepening templates collapsed into prose
- [ ] **Requirements document** finalized and included
- [ ] **Edge case catalog** included (as appendix or reference)

**Artifacts**:
- Curated design package containing:
  - Executive summary
  - Complete requirements
  - Final architecture with ADRs
  - Component specifications
  - Data flows and edge cases
  - Testing strategy
  - Security and performance considerations
  - Known risks and mitigations

**Frameworks Used**:
- ✅ All frameworks synthesized into final design
- 🎯 Output ready for implementation planning in graduated repo

**What Gets Included**:
- ✅ Final ADRs
- ✅ Requirements document
- ✅ Architecture diagrams
- ✅ Trade-off analysis summaries
- ✅ Edge case catalog
- ✅ Key decision rationale

**What Gets Excluded**:
- ❌ Progressive deepening templates (raw form)
- ❌ L1/L2 drafts
- ❌ Exploration notes
- ❌ Dead-end approaches
- ❌ Internal debates

---

## Framework Summary by Stage

| Stage | Requirements | Trade-Off | ADRs | Progressive | Edge Cases | Red Flags |
|-------|-------------|-----------|------|-------------|------------|-----------|
| 2: Explore | ✅ Create | - | - | - | - | - |
| 3: Choose | ✅ Review | ✅ Apply | ✅ Start | - | - | ✅ Check |
| 4: L1 | - | ✅ Components | ✅ Expand | ✅ L1 | Initial | ✅ Check |
| 5: L2 | - | - | ✅ Finalize | ✅ L2 | ✅ Systematic | ✅ Check |
| 6: L3 | - | - | ✅ Review | ✅ L3 | ✅ Complete | ✅ 100% |
| 7: Graduate | - | ✅ Summary | ✅ Package | ✅ Curate | ✅ Include | ✅ Document |

---

## Tips for Success

### General
1. **Don't skip frameworks** - they catch issues early
2. **Templates are starting points** - adapt to your specific idea
3. **Red flags are mandatory** - if you can't pass, don't advance
4. **Document decisions as you make them** - don't wait until stage end

### Stage-Specific
- **Stage 2**: Nail requirements first. Bad requirements = wasted refinement.
- **Stage 3**: Actually consider alternatives. Rubber-stamping wastes everyone's time.
- **Stage 4-6**: Progressive deepening prevents missing things. Use the L1→L2→L3 structure.
- **Stage 7**: Be ruthless cutting exploration artifacts. Ship only the signal.

### Anti-Patterns
- ❌ "I'll document this later" - No. Document now.
- ❌ "We don't need ADRs for this" - If it's important enough to discuss, document it.
- ❌ "This is obvious" - Write it down anyway. It won't be obvious to others.
- ❌ "Analysis paralysis" - Frameworks don't mean perfection. 80% confidence + explicit assumptions = advance.

---

**Remember**: These frameworks exist to surface hard questions BEFORE code. Use them rigorously but pragmatically. The goal is confident implementation, not bureaucracy.
