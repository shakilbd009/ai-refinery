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
Avoid duplicating information that lives elsewhere:
- **DON'T**: List all files in a folder → **DO**: "See `folder/` for list"
- **DON'T**: Show JSON schema → **DO**: "See `config.json` for current schema"
- **DON'T**: Hardcode counts ("7 stages") → **DO**: "Progressive stages" or "See folder for stages"
- **DON'T**: Name specific tools → **DO**: "Registry tool in `tools/`"

Point to the source of truth instead of copying it.

## Structure

### Level 1: TL;DR (Required)
One-line project summary in active voice.

```markdown
# My Project

Build and deploy TypeScript microservices with zero-config CI/CD.
```

### Level 2: Quick Start (Required)
Show the 3-5 most common workflows as copy-paste examples.

```markdown
## Quick Start

**Run locally:**
\`\`\`
npm run dev
\`\`\`

**Deploy to staging:**
\`\`\`
npm run deploy:staging
\`\`\`
```

### Level 3: How It Works (Required)
Explain just enough concepts to support the workflows. Avoid implementation details.

```markdown
## How It Works

Services are deployed to isolated environments. Each environment has its own database and API keys. Configuration lives in `config/<env>.json`.
```

### Level 4: Reference (Optional)
Use `<details>` sections for deep dives, edge cases, and technical specifics.

```markdown
## Architecture Details

<details>
<summary>Folder Structure</summary>

See actual folders for current structure. Main areas:
- `src/` - Application code
- `config/` - Environment configs
- `scripts/` - Build and deploy scripts

</details>
```

## Additional Sections (If Needed)

### Domain Context
Business logic, terminology, or domain concepts Claude should understand.

### Conventions
Project-specific patterns, naming rules, or architectural decisions.

### Gotchas
Known issues, confusing behaviors, or important constraints.

---

## Writing Style

**DO**:
- Start with essentials, hide details in `<details>` tags
- Use active voice and imperative mood
- Point to source files instead of copying content
- Focus on what's unique to YOUR project
- Explain the "why" behind non-obvious decisions
- Use Mermaid format for all diagrams (flowcharts, sequences, etc.)

**DON'T**:
- Dump entire folder trees or file lists
- Copy schemas, configs, or data structures (link to them)
- Hardcode numbers that might change ("5 services", "12 routes")
- Include generic advice Claude already knows
- Write tutorials on frameworks/languages

---

## Examples

### Good Example (Progressive Disclosure + Anti-Rot)
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

### Bad Example (No Progressive Disclosure, Context Rot)
```markdown
# Task Manager API

This is an amazing task management system that revolutionizes team collaboration!

## Architecture

\`\`\`
src/
├── routes/
│   ├── tasks.js
│   ├── users.js
│   ├── projects.js
│   ├── comments.js
│   └── attachments.js
├── models/
│   ├── Task.js
│   ├── User.js
│   ├── Project.js
│   ├── Comment.js
│   └── Attachment.js
...
\`\`\`

We have 5 routes and 5 models...

## What is Node.js?

Node.js is a JavaScript runtime built on Chrome's V8 engine...

[Explains basic framework concepts]
```

**Problems:**
- Overhype in intro
- Complete file tree (will go stale when files added)
- Hardcoded counts ("5 routes")
- Explains generic framework concepts
- No quick start workflows
- All detail dumped upfront

---

## Anti-Rot Patterns

### Instead of this (will rot):
```markdown
## Services

We have 7 microservices:
1. auth-service
2. user-service
3. payment-service
...
```

### Do this (stays fresh):
```markdown
## Services

See `services/` folder for current list. Each service is independently deployable.
```

### Instead of this (will rot):
```markdown
## Configuration

\`\`\`json
{
  "database": {
    "host": "localhost",
    "port": 5432,
    "name": "mydb"
  }
}
\`\`\`
```

### Do this (stays fresh):
```markdown
## Configuration

See `config/default.json` for schema. Environment-specific overrides in `config/<env>.json`.
```

---

## Checklist

Before committing claude.md, verify:

- [ ] One-line TL;DR at the top
- [ ] Quick start section with 3-5 workflows
- [ ] No complete file trees (use "See folder for list")
- [ ] No JSON/config examples (link to actual files)
- [ ] No hardcoded counts or lists
- [ ] Details hidden in `<details>` tags
- [ ] Explains what's unique to THIS project
- [ ] No generic framework tutorials

---

## Length

Aim for scannable at every level:
- **Level 1** (TL;DR): 1 line
- **Level 2** (Quick Start): 10-20 lines
- **Level 3** (How It Works): 50-100 lines
- **Level 4** (Reference): Expandable, no limit

Total visible content before expanding details: ~100-150 lines.
