# Stage Gate Checklists

This document defines the specific criteria that must be met before advancing an idea from one stage to the next in the refinement pipeline.

## Stage 1 (01-brainstorm): Capture Raw Idea

**Purpose**: Capture the initial idea clearly enough to begin exploration.

**Criteria**:
- [ ] Basic idea is documented (what problem does it solve?)
- [ ] Problem statement is clearly defined
- [ ] Initial motivation is captured (why does this matter?)
- [ ] Any initial constraints or requirements are noted

**Artifacts**: Raw idea document with problem statement

---

## Stage 2 (02-requirements): Define Requirements

**Purpose**: Understand the user needs and what success looks like.

**Criteria**:
- [ ] Target users/audience identified
- [ ] User needs and pain points documented
- [ ] Success criteria established (what does "done" look like?)
- [ ] Key requirements gathered
- [ ] Scope boundaries defined (what's in/out of scope)

**Artifacts**: User research notes, requirements list, success criteria

---

## Stage 3 (03-trade-offs): Evaluate Approaches

**Purpose**: Evaluate different approaches and choose the best path forward.

**Criteria**:
- [ ] At least 2-3 different approaches identified
- [ ] Trade-offs for each approach analyzed (pros/cons)
- [ ] Technical feasibility assessed for each option
- [ ] Recommendation made with clear rationale
- [ ] High-level technical direction chosen

**Artifacts**: Approach comparison document, recommendation with justification

---

## Stage 3.5 (03.5-market-validation): Validate Market Viability ⭐ NEW

**Purpose**: Validate business viability before committing to technical implementation.

**Why**: Technical excellence means nothing if there's no market.

**Criteria**:
- [ ] **TAM/SAM/SOM** analyzed (market size)
- [ ] **Competitive landscape** mapped (direct, indirect, substitutes)
- [ ] **Customer validation** - interviews conducted, pain points confirmed
- [ ] **Business model** - pricing strategy, unit economics (LTV/CAC > 3)
- [ ] **Go-to-market strategy** - distribution, acquisition channels
- [ ] **Risk assessment** - market, execution, timing risks identified

**Hard Gates (blocking):**
- Market size > $10M (SOM) OR strategic value justifies smaller market
- Clear differentiation from competitors
- Customer interviews validate problem exists

**Red Flags:**
🚩 "Everyone is our customer" - No beachhead market
🚩 "We have no competitors" - Wrong, or no market exists
🚩 LTV/CAC < 3 - Unit economics don't work

**Artifacts**: Market size analysis, competitor matrix, customer validation, business model, GTM strategy

**See**: [Market Validation Guide](../stages/03.5-market-validation/README.md)

---

## Stage 4 (04-design-l1): High-Level Design

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

## Stage 5 (05-design-l2): Detailed Design

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

## Stage 6 (06-design-l3): Exhaustive Design + Operational Readiness ⭐ ENHANCED

**Purpose**: Final pass - exhaustive coverage leaving no ambiguity. **Includes operational readiness for production.**

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
- [ ] **Dependency Risk Assessment** completed (see [dependency-risk.md](../dependency-risk.md))

### Operational Readiness (NEW)
- [ ] **Incident Response** - Playbooks for critical failures
- [ ] **Monitoring Strategy** - Metrics, alerts, dashboards defined
- [ ] **Deployment & Rollback** - Rollback procedures, feature flags
- [ ] **Cost Estimation** - Infrastructure costs at 1x, 10x, 100x scale
- [ ] **Compliance** - GDPR, SOC2, HIPAA requirements identified
- [ ] **Data Retention** - Policies for data lifecycle management
- [ ] **Security Hardening** - Production security checklist
- [ ] **Performance SLAs** - Target metrics, monitoring approach

**Artifacts**: L3 design document + operational readiness docs + dependency risk assessment

---

## Stage 6.5 (06.5-pre-mortem): Failure Mode Analysis ⭐ NEW

**Purpose**: Imagine the project failed one year from now. Write the post-mortem to prevent it.

**Why**: Confirmation bias makes us optimistic. Force pessimistic analysis while you can still act.

**Criteria**:
- [ ] **Failure story** written (2-3 paragraphs of how it failed)
- [ ] **Failure modes categorized** - Technical, Market, Execution, Product, Business
- [ ] At least 5 distinct failure modes identified
- [ ] At least one failure mode in each category
- [ ] **Early warning metrics** defined (how to detect before fatal)
- [ ] **Prevention strategies** for each critical failure
- [ ] **Contingency plans** (Plan B) for top 3 risks
- [ ] Risk owners assigned
- [ ] Review cadence established

**Common Failure Modes:**
- Technical: Can't scale, API breaks, security breach
- Market: No demand, competitor wins, timing wrong
- Execution: Team leaves, run out of money, scope creep
- Product: UX too complex, missing features, quality issues
- Business: Unit economics fail, pricing wrong, churn high

**Red Flags:**
🚩 Can't identify any failure modes (not thinking critically)
🚩 All failures are external (not taking responsibility)
🚩 No prevention strategies (just accepting failure)

**Artifacts**: Failure story, failure modes analysis, early warning metrics, contingency plans

**See**: [Pre-Mortem Guide](../stages/06.5-pre-mortem/README.md)

---

## Stage 7: Curate → Package

**Purpose**: Package the curated design for validation and graduation.

**Criteria**:
- [ ] Curated design document created (clean, no exploration artifacts)
- [ ] Key decision rationale included (the "why" behind choices)
- [ ] Trade-offs and alternatives documented
- [ ] Design is complete and unambiguous
- [ ] Design is ready to guide implementation (but not prescriptive about implementation steps)
- [ ] **Compound learnings** captured (patterns, decisions, lessons)
- [ ] Target path for new repository identified

**Artifacts**: Curated design package ready for validation skill to process

---

## Stage 8 (08-validated): Multi-Agent Validation ⭐ ENHANCED

**Purpose**: Validate curated design with specialized agents before graduation.

**Criteria**:
- [ ] **Security validation** - OWASP, auth, data exposure reviewed
- [ ] **Architecture validation** - Patterns, coupling, scalability reviewed
- [ ] **Performance validation** - Bottlenecks, caching, scaling reviewed
- [ ] **UX validation** - Flows, accessibility, errors reviewed
- [ ] **Devil's advocate** - Assumptions, risks, blind spots challenged
- [ ] All critical issues addressed or accepted
- [ ] Validation summary created

**Artifacts**: Validation findings from all agents, summary with verdict

---

## Stage 9: Graduate → Export

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

---

## Supporting Documents

- **[Market Validation Guide](../stages/03.5-market-validation/README.md)** - Deep dive on business validation
- **[Pre-Mortem Guide](../stages/06.5-pre-mortem/README.md)** - Failure mode analysis process
- **[Dependency Risk](../dependency-risk.md)** - External dependency assessment template
- **[Compound Learnings](../compound-learnings.md)** - Cross-project knowledge tracking

---

## Pipeline Summary (Updated)

| Stage | Purpose | Output |
|-------|---------|--------|
| 01-Brainstorm | Capture idea | Problem statement |
| 02-Requirements | Define needs | User needs, success criteria |
| 03-Trade-offs | Evaluate approaches | Recommendation with rationale |
| **03.5-Market-Validation** ⭐ | Validate business | TAM/SAM/SOM, GTM, unit economics |
| 04-Design-L1 | High-level design | Architecture sketch, components |
| 05-Design-L2 | Detailed design | Interfaces, error handling, edge cases |
| 06-Design-L3 | Exhaustive design + Ops | Complete design + operational readiness |
| **06.5-Pre-Mortem** ⭐ | Failure analysis | Failure modes, early warnings, contingencies |
| 07-Curate | Package design | Clean, curated design docs |
| 08-Validate | Multi-agent review | Security, arch, perf, UX validation |
| **09-Graduate** | Export to repo | Production-ready project template |

**Key Improvements:**
- ✅ Business validation before architecture
- ✅ Operational readiness (monitoring, incident response, costs)
- ✅ Pre-mortem failure analysis
- ✅ Dependency risk assessment
- ✅ Compound learning tracking
- ✅ Production-grade graduation criteria
