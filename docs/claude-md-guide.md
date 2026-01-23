# claude.md Writing Guide

Claude's primary instruction manual for your project. Make it scannable, rot-proof, and focused on what makes YOUR project unique.

## Key Principles

### Progressive Disclosure
Structure information from essential to optional:
1. **One-line summary** - What this project does
2. **Quick start** - The 3-5 most common workflows
3. **How it works** - Concepts needed to use it effectively
4. **Reference details** - Expandable sections for deep dives

Users should get value at each level without needing to read further.

### Anti-Rot (Single Source of Truth)
Point to the source of truth instead of copying it:
- **DON'T**: List all files → **DO**: "See `folder/` for list"
- **DON'T**: Show schemas → **DO**: "See `config.json` for schema"
- **DON'T**: Hardcode counts → **DO**: "Multiple stages" or "See folder/"
- **DON'T**: Name specific items → **DO**: "Tools in `tools/`"

---

## Structure Template

### Level 1: TL;DR (Required)
One-line project summary in active voice.

### Level 2: Quick Start (Required)
Show the 3-5 most common workflows as copy-paste examples.

### Level 3: How It Works (Required)
Explain just enough concepts to support the workflows. Avoid implementation details.

### Level 4: Reference (Optional)
Use `<details>` sections for deep dives, edge cases, and technical specifics.

### Additional Sections (If Needed)
- **Domain Context** - Business logic, terminology, or domain concepts
- **Conventions** - Project-specific patterns, naming rules, or architectural decisions
- **Gotchas** - Known issues, confusing behaviors, or important constraints

---

## Writing Style

**DO**:
- Start with essentials, hide details in `<details>` tags
- Use active voice and imperative mood
- Point to source files instead of copying content
- Focus on what's unique to YOUR project
- Explain the "why" behind non-obvious decisions
- Use Mermaid format for all diagrams

**DON'T**:
- Dump folder trees or file lists (link to them)
- Copy schemas, configs, or data structures (link to them)
- Hardcode numbers that might change
- Include generic advice Claude already knows
- Write tutorials on frameworks/languages

---

## Example

<details>
<summary>Good claude.md example</summary>

```markdown
# Task Manager API

REST API for task management with JWT auth and UUID-based resources.

## Quick Start

**Run locally:**
\`\`\`
npm run dev
\`\`\`

**Run tests:**
\`\`\`
npm test
\`\`\`

**Migrate database:**
\`\`\`
npm run migrate
\`\`\`

## How It Works

Service layer pattern: Controllers handle HTTP, services contain business logic, models map to tables.

Authentication via JWT tokens. `requireAuth` middleware extracts user from token and attaches to `req.user`.

## Conventions

- All IDs are UUIDs (not integers)
- Validation in middleware (not routes/services)
- All timestamps in UTC
- Async/await only (no callbacks)

---

## Architecture Details

<details>
<summary>Folder Structure</summary>

- `src/routes/` - API endpoints
- `src/services/` - Business logic
- `src/models/` - Database models
- `src/middleware/` - Auth, validation, errors

See folders for complete file list.
</details>
```

**What makes this good:**
- One-line summary states what it is
- Quick start shows actual commands
- How It Works explains concepts, not details
- Conventions are project-specific (not generic Node.js advice)
- Folder structure points to actual folders, doesn't list every file

</details>

<details>
<summary>Common anti-patterns to avoid</summary>

**Overhype in intro:**
```markdown
# Amazing Revolutionary Task System
This groundbreaking platform transforms how teams collaborate...
```
→ Just state what it does.

**Complete file trees:**
```markdown
src/
├── routes/
│   ├── tasks.js
│   ├── users.js
│   └── projects.js
...
```
→ Use "See `src/routes/` for endpoints"

**Hardcoded counts:**
```markdown
We have 7 microservices and 12 API routes...
```
→ Use "Multiple services (see `services/`)"

**Generic tutorials:**
```markdown
## What is Node.js?
Node.js is a JavaScript runtime...
```
→ Claude already knows this. Focus on YOUR project.

</details>
