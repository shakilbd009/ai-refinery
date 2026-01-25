# CLAUDE.md Audit Criteria

Complete scoring rubric for evaluating CLAUDE.md files.

## Scoring System

Each principle scored 0-10:
- **10**: Exemplary, no improvements needed
- **7-9**: Good, minor improvements possible
- **4-6**: Needs work, multiple issues
- **1-3**: Poor, major violations
- **0**: Missing or completely broken

## Progressive Disclosure (0-10)

### What We're Measuring

Can a new user accomplish something valuable in the first 30 seconds?

### Scoring Criteria

**10 Points:**
- Quick Start in first 20 lines
- One clear action with expected outcome
- Advanced details in `<details>` sections
- Perfect information hierarchy

**7-9 Points:**
- Quick Start exists but not prominent
- Multiple competing entry points
- Some details should be collapsed
- Generally scannable structure

**4-6 Points:**
- No clear Quick Start
- Wall of text in first 100 lines
- Details mixed with overview
- Hard to scan

**1-3 Points:**
- Overwhelming wall of text
- No clear entry point
- Everything visible at once
- Random organization

**0 Points:**
- Completely inaccessible
- No structure

### Examples

**10/10:**
```markdown
# Project Name

**Quick Start:**
```bash
npm install && npm run dev
# Visit http://localhost:3000
```

<details>
<summary>Architecture</summary>
[Details here]
</details>
```

**4/10:**
```markdown
# Project Name

This project is built using React, TypeScript, Vite, Tailwind CSS, and uses a custom build system with webpack loaders for handling various file types. The architecture is based on a modular pattern where each feature lives in its own directory with co-located tests, styles, and types. We use a barrel export pattern for clean imports and maintain strict TypeScript configuration...

[20 more paragraphs before any actionable content]
```

## DRY Compliance (0-10)

### What We're Measuring

Is each concept explained exactly once? Do we link to definitions instead of repeating them?

### Scoring Criteria

**10 Points:**
- Zero duplicate explanations
- Consistent terminology
- Links to single source of truth
- Templates for repeated patterns

**7-9 Points:**
- Minor terminology inconsistencies
- One or two duplicated concepts
- Most references use links
- Generally DRY

**4-6 Points:**
- Multiple duplicate explanations
- Inconsistent terminology
- Copy-pasted instructions
- No shared templates

**1-3 Points:**
- Widespread duplication
- Contradictory explanations
- No linking strategy
- Random terminology

**0 Points:**
- Complete chaos
- Everything repeated everywhere

### Examples

**10/10:**
```markdown
# Setup

Install dependencies:
```bash
npm install
```

# Development

See [Setup](#setup), then run:
```bash
npm run dev
```

# Testing

See [Setup](#setup), then run:
```bash
npm test
```
```

**4/10:**
```markdown
# Setup

Run `npm install` to install all project dependencies.

# Development

First, you need to install dependencies with `npm install`. Then run the dev server.

# Testing

Make sure you've run `npm install` to get all dependencies, then run tests.
```

## Context Rot Prevention (0-10)

### What We're Measuring

Will this documentation remain accurate in 6+ months? Does it work in any environment?

### Scoring Criteria

**10 Points:**
- No absolute paths
- No timestamps or "currently"
- No environment assumptions
- Evergreen examples
- Version-agnostic where possible

**7-9 Points:**
- Occasional absolute path
- Rare time-sensitive language
- Minor environment assumptions
- Mostly evergreen

**4-6 Points:**
- Multiple absolute paths
- Frequent "currently we use"
- Hardcoded environment details
- Examples tied to specific versions

**1-3 Points:**
- Absolute paths everywhere
- Time-sensitive throughout
- Assumes specific machine setup
- Will break soon

**0 Points:**
- Already broken
- Impossible to use

### Examples

**10/10:**
```markdown
# Configuration

Create `.env` in project root:
```env
DATABASE_URL=postgresql://localhost/mydb
API_KEY=your_key_here
```

**Requirements:** PostgreSQL 14+
```

**4/10:**
```markdown
# Configuration

Database is currently running on /usr/local/pgsql/bin/postgres on port 5432.

We're using PostgreSQL 14.2 installed on 2023-01-15.

Set your API key to the value in John's email from last Tuesday.
```

## Entropy Fighting (0-10)

### What We're Measuring

Is the documentation getting better or worse over time? Are we fighting decay?

### Scoring Criteria

**10 Points:**
- Every section has clear purpose
- No orphaned content
- Obsolete patterns archived
- Contradictions resolved
- Regular pruning evident

**7-9 Points:**
- Mostly purposeful sections
- Minor orphaned content
- Some obsolete content removed
- Generally clean

**4-6 Points:**
- Bloated sections
- Orphaned paragraphs
- Old patterns not archived
- Some contradictions

**1-3 Points:**
- Severe bloat
- Many orphaned sections
- Contradictory instructions
- No evidence of maintenance

**0 Points:**
- Complete decay
- Unusable

### Examples

**10/10:**
```markdown
# Deployment

Deploy to production:
```bash
npm run build
npm run deploy
```

<details>
<summary>Old Deployment Method (pre-2024)</summary>

Previously we used manual FTP uploads. This is no longer supported.

[Historical context preserved but clearly marked obsolete]
</details>
```

**4/10:**
```markdown
# Deployment

You can deploy using the new CLI tool or the old FTP method. Or use the build script. We also have a Docker setup but it might be outdated. John wrote some deploy scripts in the scripts/ folder (or was it tools/?). Try running npm run deploy or npm run build:prod or maybe npm run production. We used to use Heroku but switched to AWS, except for staging which is still on Heroku unless Dave migrated it.
```

## Red Flags

### Critical Issues (Auto-fail to <5)

These issues immediately drop score below 5 regardless of other criteria:

- **No Quick Start**: Can't get started quickly
- **Dead links**: Documentation references non-existent files
- **Contradictory instructions**: Steps that conflict
- **Security issues**: Exposed credentials or keys
- **Impossible instructions**: Steps that can't work

### Warning Signs

These suggest deeper problems:

- Paragraphs >10 lines
- Sections >50 lines without subsections
- 3+ similar examples
- Nested `<details>` sections
- Walls of code without explanation
- Explanations without code examples

## Improvement Priorities

When issues found across multiple categories:

1. **Fix Progressive Disclosure first**: Biggest UX impact
2. **Fix DRY violations second**: Reduces maintenance burden
3. **Fix Context Rot third**: Prevents future breakage
4. **Fight Entropy last**: Polish and refinement

## Measurement Tips

### Progressive Disclosure
- Time yourself: Can you complete first task in <60 seconds?
- Count lines before first actionable content
- Count visible sections vs collapsed sections

### DRY
- Search for repeated phrases
- List all terms for same concept
- Count duplicate examples

### Context Rot
- Grep for absolute paths (`/Users/`, `/home/`, `C:\`)
- Search for time words ("currently", "now", "recently")
- Check if examples work on fresh clone

### Entropy
- Look for orphaned sections
- Search for "TODO", "FIXME", "UPDATE THIS"
- Check for multiple ways to do same thing
- Count contradictory statements

## Holistic Assessment

Good CLAUDE.md files feel:
- **Welcoming**: Easy to start
- **Trustworthy**: Consistent and accurate
- **Timeless**: Won't need updates soon
- **Clean**: Every word earns its place

Bad CLAUDE.md files feel:
- **Overwhelming**: Too much too soon
- **Confusing**: Inconsistent or contradictory
- **Dated**: Obviously obsolete
- **Bloated**: Accumulated cruft
