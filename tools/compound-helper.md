# Compound Process Helper

Since /compound isn't registered as a Claude Code skill, follow this process manually:

## Quick Compound Workflow

### 1. Identify What to Document
- Recent problem that was solved
- Non-trivial, reusable solution
- Component: ideas/skills/tools/templates/docs

### 2. Choose Category
- `idea-refinement/` - Design decisions during stages
- `workflow-issues/` - Problems with skills/tools/automation
- `standards-application/` - How to apply docs/ correctly
- `graduation-blockers/` - Issues preventing advancement
- `template-fixes/` - Template improvements
- `tooling-problems/` - Registry/validation/script issues

### 3. Create Solution File

```bash
cd /Users/shakilakram/projects/ai-baseline
./tools/create-solution.sh <category> <problem-slug>
```

Example:
```bash
./tools/create-solution.sh workflow-issues skill-invocation-fix
```

### 4. Fill in Content

The script creates a template. Fill in:
- Problem description
- Investigation steps
- Root cause
- Solution with code examples
- Prevention strategy
- Related docs

### 5. Update Index

Add to `docs/solutions/README.md` under the appropriate category.

## Example

```bash
# Document a workflow issue
./tools/create-solution.sh workflow-issues compound-skill-registration

# Edit the created file
# Add to docs/solutions/README.md index
```

## Future: Make /compound Work

To enable `/compound` as a real skill:

```bash
mkdir -p ~/.claude/skills/compound
cp skills/compound.md ~/.claude/skills/compound/SKILL.md
```

Then `/compound` will work in all your projects.
