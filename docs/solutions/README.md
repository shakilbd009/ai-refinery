# Solutions Index

Searchable documentation of problems solved during ai-baseline development and usage.

## Purpose

Each documented solution compounds your knowledge. The first time you solve a problem takes research. Document it with `/compound`, and the next occurrence takes minutes.

**Knowledge compounds.**

## Organization

Solutions are categorized by problem type:

### idea-refinement/
Design decisions and tradeoffs made during stage progression. Captures architectural choices, component design patterns, and data flow decisions.

### workflow-issues/
Problems with skills, tools, or automation. Includes skill integration issues, parallel agent coordination, and workflow optimization.

### standards-application/
How to correctly apply standards from `docs/`. Edge cases in folder naming, file naming, CLAUDE.md structure, and other conventions.

### graduation-blockers/
Issues that prevent idea advancement or graduation. Stage validation problems, incomplete checklist detection, and readiness criteria.

### template-fixes/
Template improvements and corrections. README formatting, config file templates, and other starter files.

### tooling-problems/
Registry management, validation scripts, and helper tool issues. JSON schema problems, script errors, and automation failures.

## Solution Document Structure

Every solution follows this format:

```yaml
---
problem_type: [category]
component: [ideas|skills|tools|templates|docs]
symptoms: ["observable behavior", "error messages"]
tags: [searchable, keywords]
related_issues: []
created: YYYY-MM-DD
---

## Problem
What went wrong or needed solving

## Investigation
What was tried and why it didn't work

## Root Cause
Technical explanation of the underlying issue

## Solution
Step-by-step fix with code examples

## Prevention
How to avoid this in future

## Cross-References
Links to related docs and solutions
```

## Getting Started

**New to the compound system?**
1. Read [SETUP.md](SETUP.md) - Complete setup guide
2. Check [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - One-page reference
3. See [../compound-guide.md](../compound-guide.md) - Full usage guide

**Ready to document?** Just run `/compound` after solving a problem.

## Usage

### Document a Solution
```bash
/compound                    # After solving a problem
/compound [brief context]    # With context hint
```

### Search Solutions
```bash
grep -r "keyword" docs/solutions/        # Simple search
rg "error pattern" docs/solutions/       # Faster search
```

### Browse by Category
Navigate to category folders to see all solutions of that type.

## The Compounding Effect

**First time:** 30 minutes research → solution → document
**Second time:** 2 minutes lookup → apply → done
**Third time:** Pattern recognized → prevented automatically

Each solution makes your team smarter.

## Index

<!-- Auto-generated index will appear here -->
<!-- Update with: /update-solutions-index -->

### idea-refinement/
_No solutions yet_

### workflow-issues/
_No solutions yet_

### standards-application/
_No solutions yet_

### graduation-blockers/
_No solutions yet_

### template-fixes/
_No solutions yet_

### tooling-problems/
_No solutions yet_

---

**Start documenting. Each problem you solve can help future you.**
