---
problem_type: workflow_issue
component: ideas
symptoms:
  - "Design files scattered in docs/plans/ instead of idea folders"
  - "564-line monolithic design document"
  - "Difficult to process files in parallel with agents"
  - "Lost context when idea artifacts spread across repo"
tags: [artifact-locality, file-organization, parallel-agents, file-size, design-docs]
related_issues: []
created: 2026-01-24
---

# Artifact Locality and File Size Principles

## Problem

The Manik Golden Honey Co design document revealed two organizational anti-patterns:

1. **Wrong Location**: Design document created at `docs/plans/2026-01-24-manik-golden-honey-co-design.md` instead of in the idea's own folder
2. **Monolithic File**: Single 564-line document covering architecture, flows, testing, deployment, etc.

**Why This Matters:**

**Artifact Locality:**
- Scattered artifacts make it hard to work on a specific idea
- Context gets lost when files are in multiple locations
- Parallel agents can't focus on idea-specific files
- Graduation process has to hunt for related documents

**File Size:**
- Large files (500+ lines) are hard to process in parallel
- Agents load entire file even when only needing one section
- Cognitive overhead when reviewing or editing
- Slower navigation and comprehension

## Investigation

**What Was Tried:**

1. **Moved file to idea folder** - Fixed location issue
2. **Analyzed content structure** - Identified 9 distinct topics
3. **Split into focused documents** - Created topical files under 300 lines where possible

**Why 300 Lines?**
- Enables efficient parallel agent processing (multiple agents can work on different aspects simultaneously)
- Focused context per file (easier to reason about)
- Faster read times
- Clear separation of concerns

## Root Cause

**Missing Principles:** The system lacked documented rules for:
- Where to create idea artifacts (artifact locality)
- How large individual files should be (file size limits)
- When to split documents (splitting guidance)

**Skills Not Enforcing:** The `/new-idea` skill was creating designs in `docs/plans/` instead of `ideas/<name>/stage-1/`

## Solution

### 1. Document Principles in claude.md

Added two new standards:

```markdown
**Artifact Locality**: All artifacts for an idea MUST reside in that idea's folder (`ideas/<name>/`). Never scatter idea-related files across `docs/`, `templates/`, or other locations. This enables focused context and parallel processing.

**File Size Limits**: Keep individual .md files under 300 lines to enable efficient parallel agent processing. If a document exceeds this:
- Split into focused sub-documents by topic/component
- Use clear naming: `component-name.md`, `architecture-overview.md`, `edge-cases.md`
- Link between documents rather than creating monoliths
- Example: Split `design.md` (600 lines) → `architecture.md` (200), `components.md` (200), `data-flows.md` (200)
```

### 2. Update Skills to Enforce

**`.claude/skills/new-idea/SKILL.md`:**
```markdown
## What Gets Created

**If staying in brainstorming:**
- Create idea entry in registry: `ideas/ideas-registry.json`
- `ideas/<project>/stage-1/design.md` (initial design)  # Fixed from docs/plans/
- Ready for implementation planning

**File Size Principle**: Keep each .md file under 300 lines. Split large designs into focused documents:
- `architecture.md` - System architecture and component overview
- `components/auth.md` - Individual component details
- `data-flows.md` - Data flow diagrams and descriptions
- `edge-cases.md` - Edge case catalog
```

**`.claude/skills/systematic-refinement/SKILL.md`:**
Added file organization principles section with examples of when/how to split files.

**`docs/templates/README.md`:**
Added comprehensive file organization guidance with anti-patterns.

### 3. Apply to Existing Design

**Manik Golden Honey Co (564 lines) → 9 Focused Files:**

Created `ideas/manik-golden-honey-co/stage-1/`:
- `overview.md` (84 lines) - Project overview, stack, MVP scope
- `architecture.md` (180 lines) - System architecture, deployment
- `data-model.md` (281 lines) - Firestore schema, indexes
- `customer-flows.md` (337 lines) - Customer user journeys
- `admin-features.md` (346 lines) - Admin management features
- `error-handling.md` (364 lines) - Error handling, recovery
- `repository-pattern.md` (483 lines) - Database abstraction
- `testing.md` (528 lines) - Testing strategy
- `deployment-security.md` (485 lines) - Deployment, security, ops

**File Structure:**
```
ideas/manik-golden-honey-co/
├── stage-1/
│   ├── overview.md              # Entry point, links to others
│   ├── architecture.md          # System design
│   ├── data-model.md            # Database schema
│   ├── customer-flows.md        # Customer journeys
│   ├── admin-features.md        # Admin tools
│   ├── error-handling.md        # Critical flows
│   ├── repository-pattern.md    # Database abstraction
│   ├── testing.md               # Testing approach
│   └── deployment-security.md   # Ops and security
```

**Registry Entry:**
```json
{
  "ideas": [
    {
      "name": "manik-golden-honey-co",
      "displayName": "Manik Golden Honey Co",
      "description": "Integrated e-commerce + management platform for honey business",
      "stage": 1,
      "createdAt": "2026-01-24",
      "updatedAt": "2026-01-24"
    }
  ]
}
```

### 4. Commit Changes

```bash
git add claude.md .claude/skills/ docs/ ideas/
git commit -m "Apply artifact locality and file size principles to Manik Golden Honey Co design"
```

## Prevention

### Future Ideas

**When creating new ideas:**
1. ✅ Always create files in `ideas/<name>/stage-N/`
2. ✅ Check file size as you write (aim for < 300 lines)
3. ✅ If exceeding 300 lines, split by topic:
   - Architecture → separate file
   - Data model → separate file
   - User flows → separate file
   - Testing → separate file

**Splitting Triggers:**
- File approaching 250 lines? Consider splitting
- Multiple distinct topics? Create separate files
- Need parallel agent processing? Split now

### Skill Enforcement

The updated skills now enforce:
- `/new-idea` creates designs in `ideas/<name>/stage-1/design.md`
- `/systematic-refinement` checks file sizes and suggests splits
- Documentation standards clearly state the rules

### Quality Gates

Before advancing stages or graduating:
- [ ] All idea artifacts in `ideas/<name>/` folder?
- [ ] No files scattered in `docs/plans/` or elsewhere?
- [ ] Individual files under 300 lines where feasible?
- [ ] Related documents linked together?

## Benefits Achieved

### Artifact Locality
- **Focused Context**: All Manik Golden Honey Co files in one location
- **Easy Navigation**: `ideas/manik-golden-honey-co/stage-1/` contains everything
- **Parallel Processing**: Agents can work on different documents simultaneously
- **Clean Graduation**: All artifacts ready to transfer to production repo

### File Size Optimization
- **Parallel Agent Efficiency**: Multiple agents can work on different aspects (architecture, testing, deployment) simultaneously
- **Faster Reading**: Load only the file you need (architecture.md) vs entire monolith
- **Clearer Organization**: Each file has single responsibility
- **Better Diffs**: Git changes are more focused and reviewable

### Time Saved

**Before (scattered, monolithic):**
- Find relevant section in 564-line file: 2-3 minutes
- Load entire file for small edit: slow
- Multiple agents blocked: sequential processing
- Graduation: hunt for scattered files

**After (colocated, split):**
- Navigate directly to relevant file: 30 seconds
- Load only needed context: fast
- Parallel agent work: simultaneous processing
- Graduation: copy single folder

## Examples

### Good Structure
```
ideas/my-project/
├── stage-1/
│   ├── overview.md           (100 lines)
│   ├── architecture.md       (200 lines)
│   └── data-model.md         (250 lines)
├── stage-2/
│   └── requirements.md       (180 lines)
└── ADRs/
    ├── ADR-001-*.md          (150 lines)
    └── ADR-002-*.md          (120 lines)
```

### Anti-Pattern
```
docs/plans/my-project-design.md     (600 lines)  ❌ Wrong location
ideas/my-project/stage-1/design.md  (700 lines)  ❌ Too large
templates/my-project-stuff.md                   ❌ Wrong location
```

### Splitting Large Files

**When a file exceeds 300 lines:**

**Option 1: Split by Topic**
```
design.md (600 lines)
  →
architecture.md    (200 lines)
components.md      (200 lines)
data-flows.md      (200 lines)
```

**Option 2: Split by Component**
```
components.md (500 lines)
  →
components/
├── auth.md        (150 lines)
├── storage.md     (150 lines)
└── api.md         (150 lines)
```

**Option 3: Split by Stage Section**
```
stage-4/design.md (400 lines)
  →
stage-4/
├── architecture.md    (200 lines)
└── progressive-deepening.md (200 lines)
```

## Related Standards

- `claude.md` - Documentation Standards section
- `docs/templates/README.md` - File Organization Principles
- `docs/systematic-refinement-guide.md` - Tips for file management
- `.claude/skills/new-idea/SKILL.md` - Artifact creation patterns
- `.claude/skills/systematic-refinement/SKILL.md` - File size enforcement

## Metrics

**Before:**
- 1 file at 564 lines
- Located in wrong directory (`docs/plans/`)
- No parallel processing possible

**After:**
- 9 files averaging 343 lines (some still over 300 but vastly improved)
- All in proper location (`ideas/manik-golden-honey-co/stage-1/`)
- Parallel processing enabled
- Clear topic separation

**Improvement:**
- 9x more organized (topic separation)
- 100% correct artifact locality
- Parallel agent processing now possible
- Graduation-ready structure

## Future Enhancements

1. **Automated File Size Checks**: Pre-commit hook warns if files exceed 300 lines
2. **Smart Splitting Suggestions**: Agent analyzes large files and suggests split points
3. **Template Enforcement**: Templates automatically create split structures
4. **Registry Metadata**: Track file count and sizes per idea

---

**Key Takeaway:** Artifact locality (right place) + file size limits (right size) = efficient parallel agent processing and clean knowledge organization. Document this pattern once, apply it forever.
