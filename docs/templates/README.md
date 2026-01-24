# Design Refinement Templates

These templates provide systematic frameworks for documenting design decisions during idea refinement.

## Overview

All templates support the **design-refinement** skill and are applied at specific stages in the refinement pipeline.

## Templates

### 📋 requirements.md
**When to use**: Stage 2 (Brainstorm → Explore)

Systematic requirements capture:
- Functional requirements with acceptance criteria
- Non-functional requirements (performance, security, scalability, etc.)
- Constraints, assumptions, and dependencies
- Explicit out-of-scope items
- Success metrics

**Output**: Foundation for all design decisions


---

### ⚖️ trade-off-analysis.md
**When to use**: Stage 3+ (whenever comparing options)

Structured approach comparison:
- Multiple options with pros/cons
- Complexity and risk ratings
- Comparison matrix
- Decision rationale
- Trade-offs explicitly accepted
- Validation plan

**Output**: Documented design decision with clear reasoning

---

### 📝 adr-template.md
**When to use**: Stage 3+ (major architectural decisions)

Architecture Decision Records:
- Context and problem statement
- Decision with consequences (positive/negative/neutral)
- Alternatives considered with rejection rationale
- Implementation notes
- Success criteria
- Review date

**Output**: Numbered ADR (ADR-001, ADR-002, etc.)

**Where to store**: `ideas/<project>/ADRs/` during refinement, copied to graduated repo

---

### 🔄 progressive-deepening.md
**When to use**: Stages 4-6 (L1 → L2 → L3 refinement)

Multi-level refinement template:
- **L1 Pass** (Stage 4): What/Why/Key Insight
- **L2 Pass** (Stage 5): How/Interactions/Edge Cases/Risks
- **L3 Pass** (Stage 6): Complete scenarios/Failure modes/Performance/Security

**Output**: Same component refined across three levels of depth

**Benefit**: Ensures progressive deepening rather than random exploration

---

## Usage Pattern

### Stage 2: Capture Requirements
```bash
cp docs/templates/requirements.md ideas/my-project/stage-2/requirements.md
# Fill in systematically
```

### Stage 3: Analyze Approaches
```bash
# For each major decision:
cp docs/templates/trade-off-analysis.md ideas/my-project/stage-3/database-choice.md
cp docs/templates/adr-template.md ideas/my-project/ADRs/ADR-001-database.md
```

### Stages 4-6: Progressive Deepening
```bash
# For each major component:
cp docs/templates/progressive-deepening.md ideas/my-project/stage-4/auth-system.md

# Fill in:
# - L1 section in Stage 4
# - L2 section in Stage 5
# - L3 section in Stage 6
```

---

## Quality Checklist

Before advancing stages, verify:

### Stage 2 → Stage 3
- [ ] requirements.md completed
- [ ] Functional requirements have acceptance criteria
- [ ] Non-functional requirements specified
- [ ] Out of scope explicitly listed

### Stage 3 → Stage 4
- [ ] At least 2-3 trade-off analyses completed
- [ ] First ADRs created (1-2 minimum)
- [ ] All ADRs have alternatives section filled
- [ ] Decisions have clear rationale

### Stage 4 → Stage 5
- [ ] Progressive deepening templates created for major components
- [ ] L1 sections completed
- [ ] Additional ADRs for component-level decisions (3-5 total)

### Stage 5 → Stage 6
- [ ] Progressive deepening L2 sections completed
- [ ] Edge cases systematically identified
- [ ] All ADRs finalized

### Stage 6 → Stage 7
- [ ] Progressive deepening L3 sections completed
- [ ] Every edge case has handling approach
- [ ] No TBDs or unknowns remaining
- [ ] All ADRs reviewed and current

---

## Tips

### For Trade-Off Analysis
- **Actually consider alternatives** - Don't rubber-stamp your preferred option
- **Be honest about cons** - Every choice has downsides
- **Include complexity/risk ratings** - Forces realistic assessment
- **Define validation plans** - How will you know if you chose right?

### For ADRs
- **One ADR per major decision** - Don't combine unrelated decisions
- **Document WHY alternatives rejected** - Future you will thank you
- **Update status** - Mark as Deprecated/Superseded when designs change
- **Cross-reference** - Link related ADRs

### For Progressive Deepening
- **Don't skip levels** - L1→L2→L3 prevents missing things
- **Answer open questions** - Each level should resolve questions from previous
- **Check stability** - Core concepts shouldn't fundamentally change across levels
- **Collapse into prose for graduation** - Raw template stays in refinement, curated version goes to graduated repo

---

## File Organization Principles

### 📍 Artifact Locality
**All idea artifacts live in `ideas/<name>/` - never scatter across the repo.**

Correct:
```
ideas/my-project/
├── stage-2/requirements.md
├── stage-3/architecture.md
├── ADRs/ADR-001-database.md
└── components/auth.md
```

Wrong:
```
docs/plans/my-project-design.md  ❌ (outside idea folder)
templates/my-project-auth.md     ❌ (wrong location)
```

### 📏 File Size Limits
**Keep individual .md files under 300 lines for parallel agent efficiency.**

If a document grows too large:
1. **Split by concern**: `architecture.md`, `data-flows.md`, `edge-cases.md`
2. **Split by component**: `components/auth.md`, `components/storage.md`
3. **Use subdirectories**: `stage-4/components/`, `stage-5/edge-cases/`
4. **Link between files**: Use relative links to connect related documents

Example split:
```
# Before (600 lines)
ideas/my-project/stage-4/design.md

# After (3 focused files)
ideas/my-project/stage-4/architecture.md      (200 lines)
ideas/my-project/stage-4/components.md        (200 lines)
ideas/my-project/stage-4/data-flows.md        (200 lines)
```

**Why?** Smaller files enable:
- ✅ Parallel agent processing
- ✅ Focused context per file
- ✅ Faster reads and navigation
- ✅ Easier to reason about specific aspects

---

## Anti-Patterns

### ❌ Template Completion Theater
**Symptom**: Filling in templates without thinking
**Fix**: Templates are thinking tools, not bureaucracy. If a section seems irrelevant, explicitly note why.

### ❌ Skipping Templates
**Symptom**: "I'll just document this in the README"
**Fix**: Structured templates ensure consistency and completeness. Use them.

### ❌ Perfect is the Enemy of Good
**Symptom**: Endlessly refining templates
**Fix**: 80% confidence + explicit assumptions = advance. Templates aren't meant to be perfect.

### ❌ Copy-Paste Without Adaptation
**Symptom**: Identical wording across multiple templates
**Fix**: Each decision is unique. Customize the template to your specific context.

### ❌ Monolithic Documents
**Symptom**: Single 500+ line design documents
**Fix**: Split into focused files under 300 lines. Enables parallel processing and clearer organization.

---

## Related Documentation

- **Skill**: `skills/design-refinement/SKILL.md` - Complete guide to frameworks
- **Checklists**: `docs/stage-checklists-enhanced.md` - Stage-specific criteria
- **Architecture Guide**: `docs/architecture-guide.md` - Architecture documentation standards
- **Solution Doc**: `docs/solutions/workflow-issues/frameworks-from-everything-claude-code.md` - Background on where these came from

---

**Remember**: These templates exist to surface hard design questions BEFORE code. Use them rigorously but pragmatically. The goal is confident implementation, not bureaucracy.
