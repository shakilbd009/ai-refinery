# Documentation Audit Criteria

Complete scoring rubric for evaluating any markdown documentation.

## Scoring System

Each principle scored 0-10:
- **10**: Exemplary, no improvements needed
- **7-9**: Good, minor improvements possible
- **4-6**: Needs work, multiple issues
- **1-3**: Poor, major violations
- **0**: Missing or completely broken

## Progressive Disclosure (0-10)

### What We're Measuring

Can a reader accomplish something valuable or understand the core purpose in 30 seconds?

### Scoring Criteria

| Score | Criteria |
|-------|----------|
| 10 | Quick Start in first 20 lines, clear action, details collapsed, perfect hierarchy |
| 7-9 | Entry point exists but not prominent, some details should be collapsed |
| 4-6 | No clear entry point, wall of text in first 100 lines, hard to scan |
| 1-3 | Overwhelming wall of text, everything visible at once, random organization |
| 0 | Completely inaccessible, no structure |

### Example: 10/10 vs 4/10

```markdown
# Good: 10/10
npm install && npm run dev

<details><summary>Architecture</summary>
[Details here]
</details>

# Bad: 4/10
This project is built using React, TypeScript, Vite...
[20 paragraphs before any actionable content]
```

## DRY Compliance (0-10)

### What We're Measuring

Is each concept explained exactly once? Do we link instead of repeating?

### Scoring Criteria

| Score | Criteria |
|-------|----------|
| 10 | Zero duplicates, consistent terminology, links to single source of truth |
| 7-9 | Minor terminology inconsistencies, one or two duplicated concepts |
| 4-6 | Multiple duplicates, inconsistent terminology, copy-pasted instructions |
| 1-3 | Widespread duplication, contradictory explanations |
| 0 | Everything repeated everywhere |

### Example: 10/10 vs 4/10

```markdown
# Good: 10/10
## Setup
npm install

## Development
See [Setup](#setup), then: npm run dev

# Bad: 4/10
## Setup
Run npm install to install dependencies.

## Development
First, run npm install to install dependencies. Then run dev.
```

## Context Rot Prevention (0-10)

### What We're Measuring

Will this documentation remain accurate in 6+ months? Does it work in any environment?

### Scoring Criteria

| Score | Criteria |
|-------|----------|
| 10 | No absolute paths, no timestamps, no environment assumptions, evergreen |
| 7-9 | Occasional absolute path, rare time-sensitive language |
| 4-6 | Multiple absolute paths, frequent "currently we use", hardcoded env details |
| 1-3 | Absolute paths everywhere, time-sensitive throughout |
| 0 | Already broken, impossible to use |

### Context Rot Markers

Search for: `/Users/`, `/home/`, `C:\`, "currently", "now", "recently", "as of", specific dates

### Example: 10/10 vs 4/10

```markdown
# Good: 10/10
Create `.env`: DATABASE_URL=postgresql://localhost/mydb
Requirements: PostgreSQL 14+

# Bad: 4/10
Database is at /usr/local/pgsql/bin/postgres port 5432.
We're using PostgreSQL 14.2 installed on 2023-01-15.
```

## Entropy Fighting (0-10)

### What We're Measuring

Is the documentation getting better or worse over time? Are we fighting decay?

### Scoring Criteria

| Score | Criteria |
|-------|----------|
| 10 | Every section has clear purpose, no orphaned content, obsolete archived |
| 7-9 | Mostly purposeful sections, minor orphaned content |
| 4-6 | Bloated sections, orphaned paragraphs, some contradictions |
| 1-3 | Severe bloat, many orphaned sections, contradictory instructions |
| 0 | Complete decay, unusable |

### Entropy Markers

Search for: "TODO", "FIXME", "UPDATE THIS", multiple ways to do same thing, contradictions

### Example: 10/10 vs 4/10

```markdown
# Good: 10/10
npm run deploy

<details><summary>Old Method (deprecated)</summary>
Previously used FTP. No longer supported.
</details>

# Bad: 4/10
You can use CLI or FTP or build script. We have Docker but
it might be outdated. Try npm run deploy or build:prod or production.
```

---

## Red Flags (Auto-fail to <5)

- No entry point
- Dead links
- Contradictory instructions
- Security issues (exposed credentials)
- Impossible instructions

## Warning Signs

- Paragraphs > 10 lines
- Sections > 50 lines without subsections
- 3+ similar examples
- Nested `<details>` sections
- Code without explanation
- Explanation without code

## Improvement Priorities

1. **Progressive Disclosure first**: Biggest UX impact
2. **DRY violations second**: Reduces maintenance burden
3. **Context Rot third**: Prevents future breakage
4. **Entropy last**: Polish and refinement

---

See [TYPE-CHECKS.md](TYPE-CHECKS.md) for document type-specific criteria.
