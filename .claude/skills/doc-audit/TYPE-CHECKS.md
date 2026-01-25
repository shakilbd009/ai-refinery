# Type-Specific Audit Criteria

Additional checks based on document type.

## Document Type Detection

| Type | Detection Method |
|------|------------------|
| Skill | YAML frontmatter with `name` and `description` |
| CLAUDE.md | Filename is `CLAUDE.md` |
| README | Filename is `README.md` or starts with `# Project` |
| Design Doc | Has `## Overview` + `## Architecture` |
| Generic | Default (applies core principles only) |

---

## Skill Files

### Frontmatter (Critical)

```yaml
---
name: skill-name
description: Use when [triggers]
---
```

**Checklist:**
- [ ] Only `name` and `description` fields (no others)
- [ ] Name: letters, numbers, hyphens only (no `_`, no special chars)
- [ ] Description starts with "Use when..."
- [ ] Description under 500 chars
- [ ] Description does NOT summarize workflow (triggers only)

**Why description matters:** Claude reads descriptions to decide which skills to load. If description summarizes workflow, Claude may follow description instead of reading full skill.

### CSO (Claude Search Optimization) - Critical for Discoverability

Skills are only useful if Claude finds them. Optimize for Claude's search patterns:

| CSO Element | Example |
|-------------|---------|
| Keywords Claude searches | "debugging", "test failures", "flaky" |
| Error messages | "ECONNREFUSED", "timeout exceeded" |
| Symptoms | "hangs", "slow", "intermittent failures" |
| Synonyms | timeout/hang/freeze, error/failure/crash |

**Checklist:**
- [ ] Description contains keywords Claude would search for
- [ ] Common error messages mentioned in body
- [ ] Symptoms described (not just solutions)
- [ ] Synonyms included for key concepts

### Content Checklist

- [ ] Overview: core purpose in 1-2 sentences
- [ ] "When to Use" section with clear triggers
- [ ] "When NOT to Use" guidance (helps avoid false positives)
- [ ] Examples show input AND expected output
- [ ] Quick reference table for scanning

---

## CLAUDE.md Files

### Structure Checklist

- [ ] Quick Start in first 30 lines
- [ ] Common tasks early (before details)
- [ ] Advanced details in `<details>` sections
- [ ] Table of contents if > 300 lines

### Content Checklist

- [ ] Project commands documented (`npm run dev`, etc.)
- [ ] File structure explained or linked to
- [ ] Coding conventions listed
- [ ] Testing approach described
- [ ] Environment setup instructions

### Quality Signals

- [ ] Uses relative paths (not `/Users/...`)
- [ ] No timestamps or "currently"
- [ ] Examples are copy-pasteable

---

## README Files

### Required Sections

- [ ] **Description**: What is this project?
- [ ] **Installation**: How to set up
- [ ] **Usage**: How to use (with examples)
- [ ] **Prerequisites**: What's needed before install

### Nice to Have

- [ ] Contributing guidelines
- [ ] License information
- [ ] Badges (build status, coverage)
- [ ] Links to documentation
- [ ] Screenshots or demos

### Common Issues

- Missing prerequisites (assumes user has Node, Python, etc.)
- Installation steps skip authentication/access setup
- Examples don't work on fresh clone
- Dead links to documentation

---

## Design Documents

### Required Sections

- [ ] **Overview/Summary**: What problem does this solve?
- [ ] **Problem Statement**: Why are we doing this?
- [ ] **Solution Architecture**: How does it work?
- [ ] **Trade-offs**: What did we choose and why?

### Nice to Have

- [ ] ADR (Architecture Decision Record) links
- [ ] Diagrams (Mermaid preferred for portability)
- [ ] Alternative approaches considered
- [ ] Success metrics
- [ ] Rollout plan

### Common Issues

- Missing "why" (only explains "what")
- No trade-offs documented
- Diagrams use external tools (not portable)
- References specific dates ("Q1 2024 launch")

---

## Quick Reference: Type-Specific Red Flags

| Type | Red Flags |
|------|-----------|
| Skill | Description summarizes workflow, name has special chars, no CSO keywords |
| CLAUDE.md | No Quick Start, hardcoded paths |
| README | No installation, examples don't work |
| Design Doc | No trade-offs, no "why" |
