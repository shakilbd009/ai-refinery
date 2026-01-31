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

### Step 0: Read Memory

**Reference:** See [_memory.md](../_memory.md) for memory operations.

Check if memory exists and load context:

```bash
ls ideas/<name>/.memory/ 2>/dev/null
```

**If memory exists:**

1. **Read runs.jsonl** - Filter for `validate-design` runs:
   ```bash
   grep '"skill":"validate-design"' ideas/<name>/.memory/runs.jsonl | tail -3
   ```

   Report to user:
   ```
   Reading memory...
   Last validation: <date>
     Validators: <list>
     Verdict: <verdict>
     Issues: <critical> critical, <high> high
   ```

2. **Read context.md** - Extract relevant preferences:
   ```bash
   cat ideas/<name>/.memory/context.md
   ```

   Report relevant context:
   ```
   Context loaded:
     - <relevant preference>
     - <relevant decision>
   ```

**If no memory:** Proceed normally without memory context.

### Step 1: Parse Arguments

Extract `<idea-name>` and flags from command.

Expand shortcuts:
- `--all` → `--security --architecture --performance --ux --devils-advocate`
- `--quick` → `--security --architecture`

### Step 2: Prerequisites Check

```bash
# Verify curated folder exists
ls ideas/<name>/07-curated/
```

If missing: abort with "Run /curating-artifacts first"

### Step 3: Dispatch Validators (PARALLEL)

**MANDATORY: All selected validators run in parallel via Task tool.**

For each flag, invoke the corresponding validator skill using Task:

```
# Example: If --security --architecture --performance selected

Task (security-sentinel):
  Follow /validate-security skill for ideas/<name>
  Output: ideas/<name>/08-validated/security-findings.md

Task (architecture-strategist):
  Follow /validate-architecture skill for ideas/<name>
  Output: ideas/<name>/08-validated/architecture-findings.md

Task (performance-oracle):
  Follow /validate-performance skill for ideas/<name>
  Output: ideas/<name>/08-validated/performance-findings.md
```

### Step 4: Aggregate Summary

After all validators complete, create `ideas/<name>/08-validated/summary.md`:

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

Full findings: ideas/<name>/08-validated/
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

### Step 6: Write Memory

**Reference:** See [_memory.md](../_memory.md) for memory operations.

1. **Create memory folder (if needed):**
   ```bash
   mkdir -p ideas/<name>/.memory
   ```

2. **Append to runs.jsonl:**
   ```bash
   echo '{"skill":"validate-design","ts":"<ISO-8601>","idea":"<name>","result":"completed","data":{"validators":["<list>"],"verdict":"<PASS|NEEDS_ATTENTION|BLOCKING>","critical":<n>,"high":<n>,"medium":<n>,"low":<n>}}' >> ideas/<name>/.memory/runs.jsonl
   ```

3. **Ask about context.md (if significant decisions emerged):**

   If the user made notable decisions during validation (e.g., "we'll accept this risk", "we need to prioritize X"):
   ```
   I noticed you decided <decision>.
   Want me to save this to memory for future reference? (y/n)
   ```

   If yes, append to appropriate section in context.md.

Report:
```
Updating memory...
✓ Logged run to .memory/runs.jsonl
```

## After Validation

```bash
# If validation passes or issues addressed:
/graduate <idea-name> ~/projects/<project-name>

# If issues found:
# 1. Update 07-curated/ artifacts
# 2. Re-run affected validators
# 3. Graduate when ready
```
