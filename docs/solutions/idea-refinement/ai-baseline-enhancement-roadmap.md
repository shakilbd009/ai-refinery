---
problem_type: idea_refinement
component: meta-repository
symptoms:
  - "Need to track future enhancements for ai-baseline"
  - "Want to improve ai-baseline system over time"
  - "Enhancement ideas from /enhance skill analysis"
tags: [enhancements, roadmap, features, improvements]
related_issues: []
related_solutions: []
created: 2026-01-24
---

## Problem

The ai-baseline meta-repository has a solid foundation but can be significantly enhanced with additional features. Need to track all enhancement opportunities generated from the /enhance skill critique for future implementation.

## Vision

A structured, standardized meta-repository for refining ideas before building them with Claude, ensuring every graduated project follows high-quality patterns.

## Enhancement Roadmap

### Quick Wins (Implement Soon)

#### 1. Idea Templates by Project Type
- Web app template (frontend + backend considerations)
- CLI tool template (user interaction patterns)
- Library template (API design focus)
- Microservice template (deployment, monitoring)
- Choose template during `/new-idea`

**Implementation:**
- Create `templates/types/` directory
- Add type-specific templates
- Modify `/new-idea` skill to accept `--type` parameter
- Copy appropriate template to idea folder

#### 2. Auto-Generated Status Dashboard
- Visual overview of all ideas and stages
- At-a-glance progress tracking
- Automatic stale idea identification
- Add: `/dashboard` skill

**Implementation:**
- Create `/dashboard` skill
- Read ideas-registry.json
- Generate Mermaid pipeline diagram
- Show ideas at each stage
- Highlight stale ideas (not updated in N days)

#### 3. Stage-Specific Checklists in Files
- Each stage folder gets its own `checklist.md`
- Pre-populated with criteria from docs/stage-checklists.md
- Check off inline as you work
- `/advance-stage` validates from file

**Implementation:**
- Modify `/new-idea` to create `checklist.md` in each stage folder
- Copy relevant criteria from docs/stage-checklists.md
- Update `/advance-stage` to validate file-based checklists
- Better workflow: edit checklist in place

#### 4. Rich Idea Metadata
- Extend registry with: `priority`, `complexity`, `tags`, `estimatedDuration`
- Filter ideas by tags: `/list-ideas --tag cli`
- Sort by priority: `/list-ideas --sort priority`

**Implementation:**
- Update tools/update-registry.js schema
- Add metadata fields to registry
- Modify `/new-idea` to capture metadata
- Update `/list-ideas` with filter/sort options

#### 5. Design Snippet Library
- Common patterns in `docs/patterns/`
- Authentication flows
- Error handling strategies
- Testing approaches
- API design patterns
- Reference during refinement

**Implementation:**
- Create `docs/patterns/` directory
- Document common patterns as reusable snippets
- Reference from stage checklists
- Link in skills where relevant

### Strategic Enhancements

#### 6. Graduated Project Feedback Loop
- Add `.ai-baseline-link` file to graduated repos
- Track: What worked? What didn't?
- Update templates based on real learnings
- `/sync-learnings` skill pulls feedback back

**Implementation:**
- Modify `/graduate` to create `.ai-baseline-link` file
- File contains: source idea path, graduation date, feedback template
- Create `/sync-learnings` skill
- Aggregate learnings to improve templates

#### 7. Stage Progression Automation
- AI reads current stage content
- Suggests next-stage starting points
- Pre-fills next stage folder with AI-generated draft
- User refines the AI draft (faster than blank page)

**Implementation:**
- Create `/advance-stage-with-ai` skill
- Read current stage documents
- Use Claude to generate next stage starting draft
- Write to next stage folder
- User refines instead of starting from scratch

#### 8. Cross-Idea Insights
- Detect patterns across ideas
- "You've designed 3 APIs, here's the pattern you follow"
- Auto-suggest standards based on decisions
- System learns user preferences over time

**Implementation:**
- Analyze all ideas in registry
- Extract common patterns (technology choices, architectures)
- Generate insights document
- Suggest personalizing standards based on patterns

#### 9. Validation Suite
- Automated checks before `/advance-stage`
- Markdown lint
- Broken link detection
- Checklist completeness
- Design document structure validation

**Implementation:**
- Create validation scripts in `tools/`
- Check markdown formatting
- Validate internal links
- Verify checklist completion
- Run before allowing stage advancement

#### 10. Solution Discovery AI
- When hitting a problem, AI searches `docs/solutions/`
- Suggests relevant solutions automatically
- "This looks similar to [solution-name]"
- Compounds knowledge actively, not passively

**Implementation:**
- Index all solution documents
- Extract symptoms and tags
- When user describes problem, search index
- Suggest relevant solutions proactively

### Future Possibilities

#### 11. Idea Dependency Graph
- Idea B depends on idea A being graduated first
- Visualize with Mermaid diagram
- Block advancement if dependencies not met
- Unlock parallel work on independent ideas

**Implementation:**
- Add `dependencies: []` field to registry
- Store idea IDs that must graduate first
- Validate dependencies before advancement
- Generate Mermaid dependency graph

#### 12. Multi-Variant Exploration
- Branch ideas to explore multiple approaches
- `03-explore-api/` and `03-explore-graphql/` in parallel
- Merge best parts of both
- Keep exploration history

**Implementation:**
- Add `/branch-idea` skill
- Create variant stage folders
- Support variant naming (stage-variant)
- `/merge-variants` to combine best parts

#### 13. AI Pair Programming During Refinement
- Chat interface per stage
- AI asks clarifying questions
- Conversation becomes design doc
- Natural instead of checklist-driven

**Implementation:**
- Create interactive refinement mode
- AI-driven conversation about design
- Capture conversation as structured doc
- Transform Q&A into design document

#### 14. Template Evolution Tracking
- Version templates
- See how templates improve over time
- Graduated projects specify template version
- Can upgrade to newer templates

**Implementation:**
- Add versioning to templates/
- Track template changes over time
- Store template version in `.ai-baseline-link`
- Create upgrade path for older projects

#### 15. Community Template Sharing
- Share templates with others
- Import templates from community
- Fork and customize imported templates
- Build template marketplace

**Implementation:**
- Create template export format
- Host templates in GitHub
- `/import-template` skill
- Customize after import

### Synergistic Combinations

**Templates + Metadata + Filters:**
- Create web-app idea with `high` priority
- `/list-ideas --type web-app --priority high`
- Focus on what matters now

**Feedback Loop + Solution System + AI Discovery:**
- Graduated project hits issue → Document solution
- AI suggests solution when similar idea refined
- Knowledge compounds automatically

**Stage Automation + Design Patterns + User Preferences:**
- AI learns user always designs REST APIs a certain way
- Pre-fills API design sections
- User confirms/adjusts instead of writing from scratch
- Refinement gets faster over time

**Validation Suite + Stage Progression + Quality Gates:**
- Can't advance with broken links
- Can't graduate with incomplete checklists
- Automatic quality enforcement
- Standards maintained effortlessly

### Additional Missing Capabilities

#### 16. Visual Stage Pipeline
- Mermaid diagram showing idea flow
- Current stage highlighted
- Click to see ideas at each stage

#### 17. Time Tracking Per Stage
- How long did each stage take?
- Learn your own velocity
- Better estimate future ideas

#### 18. Idea Archival with Searchable History
- Archive with rich metadata (why archived, learnings)
- Search archived ideas
- Resurrect with full context

#### 19. Bulk Operations
- Archive all ideas in `01-raw` older than 30 days
- Advance all ideas meeting criteria
- Batch update metadata

#### 20. Integration with Graduated Repos
- `/sync` in graduated repo
- Pull latest templates
- Update standards
- Stay connected to meta-repo

## Implementation Strategy

### Phase 1: Foundation (Quick Wins 1-3)
**Goal:** Immediate value, better workflow

1. Idea templates by type
2. Auto-generated dashboard
3. Stage-specific checklists

**Timeline:** 1-2 weeks
**Impact:** High - immediate workflow improvement

### Phase 2: Intelligence (Strategic 6-8)
**Goal:** Learning system that gets smarter

4. Feedback loop
5. Stage automation
6. Cross-idea insights

**Timeline:** 3-4 weeks
**Impact:** High - system learns and improves

### Phase 3: Scale (Strategic 9-10 + Future 11-13)
**Goal:** Handle more ideas, faster refinement

7. Validation suite
8. Solution discovery AI
9. Dependency graph
10. Multi-variant exploration

**Timeline:** 4-6 weeks
**Impact:** Medium - enables scaling

### Phase 4: Evolution (Future 14-20)
**Goal:** Long-term sustainability

11. Template versioning
12. Community sharing
13. Visual pipeline
14. Time tracking
15. Advanced bulk operations

**Timeline:** 8-12 weeks
**Impact:** Medium - nice-to-have, not essential

## Success Metrics

Track these to measure enhancement effectiveness:

- **Refinement speed:** Time from idea creation to graduation
- **Template usage:** Which templates are most used
- **Solution reuse:** How often solutions are referenced
- **Stage velocity:** Average time per stage
- **Graduation rate:** Percentage of ideas that graduate
- **Feedback quality:** Learnings from graduated projects

## Cross-References

- [Stage Checklists](../stage-checklists.md) - Current checklist system
- [Compound Guide](../compound-guide.md) - Knowledge compounding system
- [Template README](../../templates/README.md) - Current template structure
- [Ideas Registry](../../ideas/ideas-registry.json) - Registry schema

## Notes

This roadmap created from /enhance skill analysis on 2026-01-24. Represents comprehensive enhancement opportunities while maintaining core vision of structured, standardized project refinement system.

All enhancements are additive - they build on the existing foundation rather than replacing it.
