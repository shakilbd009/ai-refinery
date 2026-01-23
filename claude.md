# AI Baseline - Meta-Repository

This is a meta-repository that serves as both a standards repository and an idea laboratory for AI/Claude projects.

## Purpose

1. **Standards Repository**: Define and maintain standards for all AI/Claude projects (documentation, structure, code, tooling)
2. **Idea Refinement Pipeline**: Brainstorm and refine project ideas through 7 stages before graduating them to actual project repositories

## Architecture

### Folder Structure

```
ai-baseline/
├── ideas/                    # Refinement pipeline for project ideas
│   ├── ideas-registry.json   # JSON tracking all ideas and their stages
│   └── <idea-name>/          # Individual idea folders
│       ├── status.md         # Current stage, progress, checklist
│       ├── 01-raw/           # Stage folders containing work artifacts
│       ├── 02-brainstorm/
│       ├── 03-explore/
│       ├── 04-refine-l1/
│       ├── 05-refine-l2/
│       ├── 06-refine-l3/
│       └── 07-graduate/      # Curated docs ready for export
├── templates/                # Starter files copied to new projects
│   ├── README.md
│   ├── claude.md
│   └── .gitignore
├── docs/                     # Standards documentation
│   ├── stage-checklists.md   # Criteria for advancing stages
│   ├── claude-md-guide.md    # How to write claude.md
│   ├── readme-guide.md
│   ├── architecture-guide.md
│   ├── writing-guide.md
│   ├── folder-conventions.md
│   ├── file-naming.md
│   ├── config-standards.md
│   ├── code-style.md
│   ├── tooling-choices.md
│   └── testing-standards.md
├── skills/                   # Claude Code skills
│   ├── new-idea.md           # Create new idea in pipeline
│   ├── advance-stage.md      # Move to next stage
│   ├── list-ideas.md         # Show all ideas
│   ├── archive-idea.md       # Archive completed ideas
│   └── graduate.md           # Bootstrap new project repo
└── tools/                    # Helper scripts called by skills
    ├── scaffold-repo.sh      # Creates project structure
    ├── inject-design.sh      # Merges design into templates
    ├── validate-checklist.sh # Validates stage completion
    └── update-registry.js    # Manages registry updates
```

## Key Concepts

### Refinement Pipeline

Ideas progress through 7 stages:
1. **Raw** → 2. **Brainstorm** → 3. **Explore** → 4. **Refine L1** → 5. **Refine L2** → 6. **Refine L3** → 7. **Graduate**

**Iterative Deepening Model**: Refinement levels (L1, L2, L3) all cover the same aspects (architecture, components, data flows, error handling, testing, edge cases, technical decisions) but go progressively deeper with each level.

**Stage Gates**: Each stage has specific criteria in `docs/stage-checklists.md` that must be met before advancing.

### Graduation Process

When an idea reaches "graduate" stage, the `/graduate` skill:
1. Validates idea is ready (at stage 07-graduate)
2. Creates new repo at specified path
3. Applies templates and standards
4. Injects curated design documentation
5. Initializes git repository
6. Returns a ready-to-implement project

**Important**: Graduated repos receive **design documents** (what/how/why) but NOT implementation plans. Implementation planning happens in the new repo.

### Ideas Registry

`ideas/ideas-registry.json` tracks all ideas programmatically:
```json
{
  "ideas": [
    {
      "id": "project-alpha",
      "name": "Project Alpha",
      "currentStage": "04-refine-l1",
      "createdAt": "2026-01-15T00:00:00.000Z",
      "lastUpdated": "2026-01-20T00:00:00.000Z"
    }
  ],
  "archived": []
}
```

Managed by `tools/update-registry.js`.

## Common Workflows

### Creating a New Idea

1. `/new-idea <name>` - Creates folder structure, initializes registry
2. Work in `ideas/<name>/01-raw/` to capture initial idea
3. `/advance-stage <name>` when checklist complete
4. Repeat through all stages

### Checking Progress

- `/list-ideas` - See all ideas and their current stages
- Review `ideas/<name>/status.md` for specific idea

### Graduating an Idea

1. Ensure idea is at stage 07-graduate
2. Curated docs exist in `ideas/<name>/07-graduate/`
3. `/graduate <name> <target-path>` - Creates new project repo
4. Switch to new repo and start implementation

### Maintaining Standards

Standards in `docs/` should be updated as you learn:
- When you find better patterns, update the guides
- When tools change, update tooling-choices.md
- Standards evolve with experience

## Skills Reference

- **`/new-idea <name>`**: Creates idea folder structure, adds to registry
- **`/advance-stage <name>`**: Validates checklist, advances to next stage
- **`/list-ideas`**: Reports all ideas and their stages
- **`/archive-idea <name> [reason]`**: Archives graduated/abandoned ideas
- **`/graduate <name> <path>`**: Bootstraps new project from refined idea

## Important Notes

### Don't Edit Registry Manually

Use `tools/update-registry.js` to modify ideas-registry.json:
```bash
node tools/update-registry.js add <id> <name>
node tools/update-registry.js update <id> <stage>
node tools/update-registry.js list
```

### Checklist Validation

`/advance-stage` calls `tools/validate-checklist.sh` which checks `status.md` for unchecked items (`- [ ]`). All must be checked (`- [x]`) before advancing.

### Template Customization

Templates in `templates/` are minimal starting points. During graduation, `tools/inject-design.sh` merges curated docs into these templates.

## Philosophy

1. **Separation of Concerns**: Ideas are refined here, implementation happens in graduated repos
2. **Standards Enforcement**: Every graduated project follows the same high-quality patterns
3. **Iterative Deepening**: Three refinement passes ensure thorough design
4. **Programmatic Tracking**: JSON registry enables automation
5. **Curated Transfer**: New repos get clean designs, not messy exploration history
