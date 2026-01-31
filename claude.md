# AI Baseline - Meta-Repository

Refine project ideas through progressive stages, then graduate them to production-ready repos with enforced standards.

## Quick Start

**Start a new idea:**
```
/new-idea my-project
# Automatically triggers: brainstorming → systematic refinement (if needed)
```

**Advance through stages:**
```
/advance-stage my-project
# Complete checklist in status.md, repeat until graduation
```

**Package and graduate:**
```
/curating-artifacts my-project
/graduate my-project path/to/my-project
```

## How It Works

Ideas progress through numbered stages. See `ideas/<name>/` folder for stage directories. Each stage has a checklist in `status.md` - complete it to advance.

Refinement stages cover the same aspects (architecture, components, data flows, errors, testing, edge cases) but go progressively deeper with each pass.

When you graduate, you get a new repo with design docs and standards applied. Implementation planning happens there, not here.

---

## Skills

See `.claude/skills/` for all available skills and detailed usage.

| Command | Purpose |
|---------|---------|
| `/new-idea` | **Start here!** Hybrid brainstorm → refinement |
| `/systematic-refinement` | Direct deep refinement (skip brainstorm) |
| `/advance-stage` | Progress to next stage |
| `/list-ideas` | View all ideas and stages |
| `/curating-artifacts` | Package artifacts (after 06-design-l3) → 07-curated |
| `/validate-design` | Optional specialist review (after 07-curated) → 08-validated |
| `/graduate` | Create production repo (after 07-curated or 08-validated) |
| `/compound` | Document solved problems |

---

## Architecture Details

<details>
<summary>Folder Structure</summary>

Key areas:
- `ideas/` - Refinement pipeline with registry and stage folders
- `templates/` - Files copied to new projects
- `docs/` - Standards and guides
- `.claude/skills/` - Claude Code skills
- `tools/` - Helper scripts

Explore actual folders to see current files.
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
<summary>Graduation Pipeline</summary>

After completing 06-design-l3:
1. `/curating-artifacts` - Package into `07-curated/` folder
2. `/validate-design` (optional) - Security/architecture review → `08-validated/`
3. `/graduate` - Create production repo from 07-curated artifacts
</details>

<details>
<summary>Compound Knowledge</summary>

After solving non-trivial problems, run `/compound` to document solutions in `docs/solutions/`.
</details>

---

<details>
<summary>Documentation Standards</summary>

**Artifact Locality**: All artifacts for an idea MUST reside in that idea's folder (`ideas/<name>/`). Never scatter idea-related files across `docs/`, `templates/`, or other locations.
</details>

<details>
<summary>Git Conventions</summary>

Create feature branches before making changes: `feature/<description>`
</details>
