# AI Baseline: Meta-Repository Design

**Date**: 2026-01-22
**Status**: Validated Design

## Overview

**ai-baseline** is a meta-repository serving dual purposes:

1. **Standards Repository**: Single source of truth for how all AI/Claude projects should be structured, documented, and built
2. **Idea Laboratory**: Where new project ideas are brainstormed, explored, and refined through a rigorous 7-stage pipeline before graduation

## Core Workflow

When you have a new project idea:

1. Create a new idea folder in `ideas/`
2. Progress through refinement stages: **Raw → Brainstorm → Explore → Refine L1 → Refine L2 → Refine L3 → Graduate**
3. Each stage has specific criteria that must be met (defined in standards docs)
4. Once graduated, a graduation skill automatically creates a new project repository with:
   - All standards applied (folder structure, templates, configs)
   - Curated design documentation (final design + key decision rationale)
   - Ready to start implementation immediately

The new repo lives outside ai-baseline but follows all standards defined within it.

## Repository Structure

```
ai-baseline/
├── ideas/                    # Refinement pipeline
│   ├── ideas-registry.json   # Programmatic tracking of all ideas & stages
│   ├── project-alpha/        # Individual idea folders
│   │   ├── status.md         # Current stage, progress, notes
│   │   ├── 01-raw/           # Initial concept
│   │   ├── 02-brainstorm/    # Exploration notes
│   │   ├── 03-explore/       # Deep dive artifacts
│   │   ├── 04-refine-l1/     # First refinement
│   │   ├── 05-refine-l2/     # Second refinement
│   │   ├── 06-refine-l3/     # Final refinement
│   │   └── 07-graduate/      # Curated export package
│   └── project-beta/
│       └── ...
├── templates/                # Starter files for new projects
│   ├── README.md
│   ├── claude.md
│   └── .gitignore
├── docs/                     # Standards & guidelines
│   ├── stage-checklists.md   # Criteria for advancing stages
│   ├── writing-guide.md      # How to write good documentation
│   ├── architecture-patterns.md
│   └── ...
├── skills/                   # Claude Code skills
│   ├── graduate.md           # Bootstrap new repo from refined idea
│   ├── advance-stage.md      # Move idea to next stage
│   ├── list-ideas.md         # Report on all ideas
│   └── ...
└── tools/                    # Helper scripts called by skills
    ├── scaffold-repo.sh
    ├── copy-curated-docs.sh
    └── ...
```

## Refinement Pipeline & Stage Gates

### Ideas Registry

**ideas-registry.json** tracks all ideas programmatically:

```json
{
  "ideas": [
    {
      "id": "project-alpha",
      "name": "Project Alpha",
      "currentStage": "03-explore",
      "createdAt": "2026-01-15",
      "lastUpdated": "2026-01-20"
    }
  ]
}
```

### Stage Progression

Each stage folder contains work artifacts (documents, diagrams, notes) for that phase. The `status.md` in each idea folder tracks:
- Current stage
- Completed checklist items
- Blockers/questions
- Next steps

### Stage Gate Checklists

Defined in `docs/stage-checklists.md`. Each stage has specific criteria:

- **Raw**: Basic idea captured, problem statement defined
- **Brainstorm**: User needs identified, success criteria established
- **Explore**: 2-3 approaches compared, trade-offs analyzed, recommendation made
- **Refine L1**: First complete pass - high-level architecture, main components, primary flows
- **Refine L2**: Second pass - detailed design on all aspects from L1
- **Refine L3**: Final pass - exhaustive coverage, no ambiguity remaining
- **Graduate**: Curated docs packaged, ready for export

### Iterative Deepening Model

Each refinement level (L1, L2, L3) covers the **same aspects** but goes progressively deeper:

**All refinement levels address:**
- Architecture
- Components
- Data flows
- Error handling
- Testing strategy
- Edge cases
- Technical decisions

**Depth increases per level:**
- **Refine L1**: High-level view - basic architecture sketch, main components identified, happy path flows
- **Refine L2**: Medium depth - detailed architecture, component interactions, error scenarios, basic testing approach
- **Refine L3**: Exhaustive depth - every edge case, every failure mode, comprehensive test coverage, all technical nuances resolved

## Graduation & Standards Application

### Graduation Skill Usage

```bash
/graduate project-alpha /path/to/new/project-alpha-repo
```

### Graduation Process

1. Validates idea is in "07-graduate" stage
2. Reads curated docs from `ideas/project-alpha/07-graduate/`
3. Creates new repo at target path
4. Applies templates from `templates/` (README.md, claude.md, .gitignore, folder structure)
5. Injects curated design into appropriate sections
6. Marks idea as graduated in ideas-registry.json

### New Repo Contents

The graduated repo starts with:
- Standard structure and documentation following ai-baseline standards
- Complete **design document** (what, how, why - but NOT implementation steps)
- Key decision rationale and trade-offs
- No messy exploration history
- No implementation plan (created in new repo as needed)

## Skills & Automation

### Refinement Pipeline Skills

- **`/new-idea <name>`**: Creates new idea folder structure, initializes in ideas-registry.json, starts at "01-raw" stage
- **`/advance-stage <idea-name>`**: Validates current stage checklist is complete, moves to next stage, updates registry
- **`/list-ideas`**: Generates report from ideas-registry.json showing all ideas and their current stages
- **`/archive-idea <idea-name>`**: Moves graduated/abandoned ideas to archive, updates registry

### Graduation Skill

- **`/graduate <idea-name> <target-path>`**: Full repo scaffolding with standards applied and curated design injected

### Supporting Tools

Scripts called by skills:

- `scaffold-repo.sh`: Creates folder structure, copies templates
- `inject-design.sh`: Merges curated docs into template placeholders
- `validate-checklist.sh`: Verifies stage gate criteria met before advancement
- `update-registry.js`: Manages ideas-registry.json updates

## Standards Definition

The `docs/` folder contains comprehensive standards for all AI/Claude projects:

### Documentation Standards

- **claude.md-guide.md**: How to write effective claude.md files (structure, tone, what to include/exclude)
- **readme-guide.md**: README.md best practices (clarity, examples, getting started flow)
- **architecture-guide.md**: How to document architecture decisions, when to use diagrams vs prose
- **writing-guide.md**: General writing principles (clarity, conciseness, avoiding AI-generated fluff)

### Project Structure Standards

- **folder-conventions.md**: Standard directory layouts for different project types
- **file-naming.md**: Naming conventions for files and folders
- **config-standards.md**: Required configuration files and their standard settings

### Code & Tooling Standards

- **code-style.md**: Formatting, patterns, anti-patterns for preferred languages
- **tooling-choices.md**: Preferred tools, libraries, frameworks and rationale
- **testing-standards.md**: Testing philosophy, coverage expectations, test structure

### Stage Gates

- **stage-checklists.md**: Detailed criteria for each refinement stage

## Key Principles

1. **Separation of Concerns**: Ideas are refined in ai-baseline, implementation happens in graduated repos
2. **Standards Enforcement**: Every graduated project follows the same high-quality patterns
3. **Iterative Deepening**: Three refinement passes ensure nothing is overlooked
4. **Programmatic Tracking**: JSON registry enables automation and reporting
5. **Curated Knowledge Transfer**: New repos get clean designs, not messy exploration history
6. **Design Not Implementation**: Graduated repos receive blueprints (what/how/why), not task lists

## Daily Workflow Example

1. **New idea arrives**: `/new-idea task-manager` → Creates folder structure, initializes registry
2. **Work through stages**: Create documents and artifacts in each stage folder
3. **Check progress**: `/list-ideas` → See all ideas and their current stages
4. **Advance when ready**: `/advance-stage task-manager` → Validates checklist, moves to next stage
5. **Repeat** through all refinement levels, going deeper each time
6. **Graduate**: `/graduate task-manager ~/projects/task-manager` → New repo created with standards applied
7. **Build**: Switch to new repo, implement the design using the blueprint provided
