# AI Baseline

Your meta-repository for AI/Claude project standards and idea refinement.

## What is This?

AI Baseline serves two purposes:

1. **Standards Repository**: Single source of truth for how all your AI/Claude projects should be structured, documented, and built
2. **Idea Laboratory**: Where new project ideas are brainstormed, explored, and refined through a rigorous 7-stage pipeline before graduation

## Quick Start

### Refine a New Idea

```bash
# Create a new idea
/new-idea my-project

# Work through the refinement stages
# Edit files in ideas/my-project/01-raw/, 02-brainstorm/, etc.

# Advance when ready
/advance-stage my-project

# Continue through all stages:
# Raw → Brainstorm → Explore → Refine L1 → Refine L2 → Refine L3 → Graduate
```

### Graduate an Idea to a New Project

```bash
# Once at graduate stage
/graduate my-project ~/projects/my-project

# New repo created with:
# - All standards applied
# - Templates populated
# - Design documentation included
# - Ready to implement
```

### Manage Ideas

```bash
# List all ideas and their stages
/list-ideas

# Archive completed or abandoned ideas
/archive-idea my-project graduated
```

## Repository Structure

```
ai-baseline/
├── ideas/                    # Refinement pipeline
│   ├── ideas-registry.json   # Tracks all ideas
│   └── [idea-folders]/       # Individual ideas at various stages
├── templates/                # Starter files for new projects
├── docs/                     # Standards & guidelines
├── skills/                   # Claude Code skills
└── tools/                    # Helper scripts
```

## Refinement Pipeline

Every idea goes through 7 stages:

1. **Raw**: Capture the basic idea and problem statement
2. **Brainstorm**: Identify user needs and success criteria
3. **Explore**: Compare approaches, analyze trade-offs, make recommendation
4. **Refine L1**: First pass - high-level architecture, main components
5. **Refine L2**: Second pass - detailed design on all aspects
6. **Refine L3**: Final pass - exhaustive coverage, no ambiguity
7. **Graduate**: Package curated docs, ready for export

Each stage has specific criteria (see docs/stage-checklists.md) that must be met before advancing.

## Available Skills

- `/new-idea <name>` - Create new idea in pipeline
- `/advance-stage <name>` - Move to next refinement stage
- `/list-ideas` - Show all ideas and their status
- `/archive-idea <name> [reason]` - Archive completed/abandoned idea
- `/graduate <name> <path>` - Bootstrap new project from refined idea

## Standards Documentation

All your opinionated standards live in `docs/`:

- **Documentation**: How to write claude.md, README, architecture docs
- **Project Structure**: Folder conventions, file naming, configs
- **Code & Tooling**: Code style, tooling choices, testing standards
- **Stage Gates**: Criteria for advancing through refinement pipeline

## Philosophy

- **Separation of Concerns**: Ideas refined HERE, implementation happens in graduated repos
- **Standards Enforcement**: Every graduated project follows the same patterns
- **Iterative Deepening**: Three refinement passes ensure nothing is overlooked
- **Curated Knowledge Transfer**: New repos get clean designs, not messy exploration

## Tools

Helper scripts in `tools/` (called by skills):

- `scaffold-repo.sh` - Creates folder structure
- `inject-design.sh` - Merges curated docs into templates
- `validate-checklist.sh` - Verifies stage completion
- `update-registry.js` - Manages ideas registry

## Next Steps

1. Review standards in `docs/` and customize to your preferences
2. Create your first idea with `/new-idea`
3. Refine it through the pipeline
4. Graduate it to a new project
5. Iterate and improve your standards as you learn

## License

MIT
