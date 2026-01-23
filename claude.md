# AI Baseline - Meta-Repository

Refine project ideas through progressive stages, then graduate them to production-ready repos with enforced standards.

## Quick Start

**Start a new idea:**
```
/new-idea my-project
# Work in ideas/my-project/<current-stage>/
```

**Advance through stages:**
```
/advance-stage my-project
# Complete checklist in status.md, repeat until graduation
```

**Create production repo:**
```
/graduate my-project ~/code/my-project
# New repo ready with design docs, templates, standards
```

## How It Works

Ideas progress through numbered stages. See `ideas/<name>/` folder for stage directories. Each stage has a checklist in `status.md` - complete it to advance.

Refinement stages cover the same aspects (architecture, components, data flows, errors, testing, edge cases) but go progressively deeper with each pass.

When you graduate, you get a new repo with design docs and standards applied. Implementation planning happens there, not here.

---

## Skills Reference

### `/new-idea <name>`
Creates folder structure and registry entry for new idea.

### `/advance-stage <name>`
Validates current stage checklist is complete, advances to next stage. Fails if checklist has unchecked items.

### `/list-ideas`
Shows all ideas and their current stages.

### `/archive-idea <name> [reason]`
Archives graduated or abandoned ideas.

### `/graduate <name> <target-path>`
Creates production repo at target path with templates, standards, and curated design docs from final stage folder.

### `/compound [context]`
Document a recently solved problem to build institutional knowledge. Creates searchable solutions in `docs/solutions/` with YAML frontmatter.

---

## Architecture Details

<details>
<summary>Folder Structure</summary>

```
ai-baseline/
├── ideas/                    # Refinement pipeline
│   ├── ideas-registry.json   # Tracks all ideas and stages
│   └── <idea-name>/
│       ├── status.md         # Current stage, checklist
│       └── <NN-stage-name>/  # Numbered stage folders
├── templates/                # Files copied to new projects
├── docs/                     # Standards (see folder for list)
├── skills/                   # Claude Code skills (see folder for list)
└── tools/                    # Helper scripts called by skills (see folder for list)
```

Explore actual folders to see current files. Documentation doesn't track file lists.
</details>

<details>
<summary>Ideas Registry</summary>

`ideas/ideas-registry.json` tracks all ideas programmatically. See file for current schema.

Managed by registry tool in `tools/`. Do not edit manually.
</details>

<details>
<summary>Stage Gate Validation</summary>

`/advance-stage` validates checklist completion in `status.md`:
- All checklist items must be checked
- Fails if unchecked items exist
- Advances stage and updates registry when complete

Checklist criteria defined in `docs/` standards.
</details>

<details>
<summary>Graduation Process</summary>

`/graduate` creates production repo:
1. Validates idea is at final stage
2. Creates new repo at target path
3. Copies templates
4. Merges curated design docs from final stage folder
5. Initializes git repository
6. Returns ready-to-implement project

Graduated repos receive design documents (what/how/why) but NOT implementation plans. Implementation planning happens in the new repo.
</details>

<details>
<summary>Compound Knowledge System</summary>

`/compound` documents solved problems to build institutional knowledge in `docs/solutions/`.

**The principle:** Knowledge compounds. Document problems once, solve them instantly in the future.

**Categories:**
- `idea-refinement/` - Design decisions and tradeoffs
- `workflow-issues/` - Skills, tools, automation problems
- `standards-application/` - Edge cases in applying docs/
- `graduation-blockers/` - Issues preventing advancement
- `template-fixes/` - Template improvements
- `tooling-problems/` - Registry, validation, script issues

**Usage:** After solving a non-trivial problem, run `/compound` to document it.

See `docs/compound-guide.md` for complete guide.
</details>

---

## Documentation Standards

**Diagrams**: Use Mermaid format for all flow diagrams, sequence diagrams, and visualizations. Mermaid renders natively in GitHub and most markdown viewers.

---

## Philosophy

**Separation of Concerns**: Ideas refined here, implementation happens in graduated repos.

**Iterative Deepening**: Multiple refinement passes ensure thorough design without premature detail.

**Standards Enforcement**: Every graduated project follows the same high-quality patterns defined in `docs/`.

**Programmatic Tracking**: JSON registry enables automation and tooling.

**Curated Transfer**: New repos get clean designs, not messy exploration history.
