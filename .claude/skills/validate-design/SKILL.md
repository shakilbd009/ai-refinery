---
name: validate-design
description: Use when validating curated design artifacts before graduation. Dispatches security, architecture, performance, UX, and devil's advocate reviewers in parallel. Triggers on design review, validation, audit requests.
---

# Validate Design (Orchestrator)

Thin orchestrator that dispatches specialized validator skills in parallel, then aggregates results.

## Usage

```bash
# Run specific validators
/validate-design <idea-name> --security --architecture

# Run all validators
/validate-design <idea-name> --all

# Quick validation (security + architecture only)
/validate-design <idea-name> --quick
```

## Available Validators

| Flag | Skill | Agent | Focus |
|------|-------|-------|-------|
| `--security` | `/validate-security` | security-sentinel | OWASP, auth, data exposure |
| `--architecture` | `/validate-architecture` | architecture-strategist | Patterns, coupling, scalability |
| `--performance` | `/validate-performance` | performance-oracle | Bottlenecks, caching, scaling |
| `--ux` | `/validate-ux` | general-purpose | Flows, accessibility, errors |
| `--devils-advocate` | `/validate-devils-advocate` | devils-advocate | Assumptions, risks, blind spots |

Shortcuts:
- `--all` = all five validators
- `--quick` = security + architecture only

## When to Use

| Scenario | Recommendation |
|----------|----------------|
| Payment/financial systems | `--all` (mandatory) |
| Auth/identity systems | `--security --architecture` |
| Public APIs | `--security --performance` |
| User-facing features | `--ux --security` |
| Infrastructure/platform | `--architecture --performance` |
| Internal tools | `--quick` or skip |
| Prototypes/experiments | Skip |

**Rule of thumb**: If a breach or outage would make the news, use `--all`.

## Process

### Step 1: Parse Arguments

Extract `<idea-name>` and flags from command.

Expand shortcuts:
- `--all` → `--security --architecture --performance --ux --devils-advocate`
- `--quick` → `--security --architecture`

### Step 2: Prerequisites Check

```bash
# Verify curated folder exists
ls ideas/<name>/curated/
```

If missing: abort with "Run /curating-artifacts first"

### Step 3: Dispatch Validators (PARALLEL)

**MANDATORY: All selected validators run in parallel via Task tool.**

For each flag, invoke the corresponding validator skill using Task:

```
# Example: If --security --architecture --performance selected

Task (security-sentinel):
  Follow /validate-security skill for ideas/<name>
  Output: ideas/<name>/validation/security-findings.md

Task (architecture-strategist):
  Follow /validate-architecture skill for ideas/<name>
  Output: ideas/<name>/validation/architecture-findings.md

Task (performance-oracle):
  Follow /validate-performance skill for ideas/<name>
  Output: ideas/<name>/validation/performance-findings.md
```

### Step 4: Aggregate Summary

After all validators complete, create `ideas/<name>/validation/summary.md`:

```markdown
# Validation Summary: <idea-name>

**Validated:** <timestamp>
**Validators run:** <list>

## Verdict

| Validator | Verdict | Critical | High | Medium | Low |
|-----------|---------|----------|------|--------|-----|
| Security | PASS | 0 | 0 | 2 | 1 |
| Architecture | NEEDS_ATTENTION | 0 | 2 | 1 | 0 |
| ... | ... | ... | ... | ... | ... |

**Overall:** <PASS | NEEDS_ATTENTION | BLOCKING>

## Critical Issues (Must Fix)

<aggregated from all files, or "None">

## High Priority Issues (Should Fix)

<aggregated from all files, or "None">

## Next Steps

- [ ] Address critical issues (if any)
- [ ] Review high priority issues
- [ ] Run `/graduate` when ready
```

### Step 5: Report to User

Display concise summary:

```
Validation complete for <idea-name>

Validators run: security, architecture, performance
Overall verdict: NEEDS_ATTENTION

Critical: 0 | High: 3 | Medium: 5 | Low: 2

High priority issues:
- [H1] Auth token lacks expiration (security-findings.md)
- [H2] Database lacks index on user_id (performance-findings.md)
- [H3] Component X tightly coupled to Y (architecture-findings.md)

Full findings: ideas/<name>/validation/
```

## Standalone Validator Usage

Each validator can be run independently:

```bash
/validate-security my-idea
/validate-architecture my-idea
/validate-performance my-idea
/validate-ux my-idea
/validate-devils-advocate my-idea
```

Useful for:
- Re-running a single validator after fixes
- Focused review on specific concern
- Lighter-weight validation

## After Validation

```bash
# If validation passes or issues addressed:
/graduate <idea-name> ~/projects/<project-name>

# If issues found:
# 1. Update curated/ artifacts
# 2. Re-run affected validators
# 3. Graduate when ready
```
