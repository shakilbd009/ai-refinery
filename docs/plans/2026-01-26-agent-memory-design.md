# Agent Memory System Design

Persistent memory for skills/agents - remember what happened on previous runs and retain project context.

## Overview

Each idea gets a `.memory/` folder containing:
- **runs.jsonl** - Skill execution log (machine-readable)
- **context.md** - Decisions & preferences (human-readable)

Skills read memory at startup (when relevant) and write after completing.

## Memory Location

```
ideas/<name>/.memory/
├── runs.jsonl      # Append-only skill execution log
└── context.md      # Running context and decisions
```

## File Schemas

### runs.jsonl

One JSON object per line. Easy to append, query, and stream.

```json
{"skill":"validate-design","ts":"2026-01-26T14:30:00Z","idea":"my-app","result":"completed","data":{"validators":["security","architecture"],"verdict":"NEEDS_ATTENTION","critical":0,"high":2}}
{"skill":"advance-stage","ts":"2026-01-26T15:45:00Z","idea":"my-app","result":"completed","data":{"from":"03-trade-offs","to":"04-design-l1"}}
```

**Required fields:**
| Field | Type | Description |
|-------|------|-------------|
| `skill` | string | Skill name that ran |
| `ts` | string | ISO 8601 timestamp |
| `idea` | string | Idea name |
| `result` | string | "completed" \| "failed" \| "skipped" |

**Optional fields:**
| Field | Type | Description |
|-------|------|-------------|
| `data` | object | Skill-specific payload |

### context.md

Human-readable markdown with structured sections:

```markdown
# Memory: my-app

## Preferences
- Auth: JWT with short-lived tokens + refresh tokens
- Database: PostgreSQL over SQLite (needs concurrent access)

## Key Decisions
- 2026-01-26: Chose event-driven architecture for notifications
- 2026-01-25: Will not support offline mode in v1

## Notes
- User mentioned deadline is end of Q1
```

## Skill Memory Behavior

### Which Skills Use Memory

| Skill | Read runs.jsonl | Read context.md | Write runs.jsonl | Write context.md |
|-------|-----------------|-----------------|------------------|------------------|
| `/validate-design` | Yes | Yes | Yes | Ask user |
| `/advance-stage` | Yes | Yes | Yes | Ask user |
| `/curating-artifacts` | No | Yes | Yes | Ask user |
| `/graduate` | Yes | Yes | Yes | No |
| `/new-idea` | No | No | No | No |
| `/compound` | No | No | No | No |
| `/list-ideas` | No | No | No | No |

### Reading Memory

Skills read memory **at the start** of execution (Step 0).

**runs.jsonl:** Filter for current skill name, read recent entries to report previous runs.

**context.md:** Read fully, extract relevant preferences/decisions.

**Graceful degradation:** If `.memory/` doesn't exist, proceed normally. Memory is optional.

### Writing Memory

Skills write memory **at the end** of execution, after completing work.

**runs.jsonl:** Append one JSON line with execution summary.

**context.md:** Only when significant decisions emerge. Always ask user first:
```
I noticed you decided on PostgreSQL for concurrent access.
Want me to save this to memory for future reference? (y/n)
```

### Creating Memory

First skill to write creates the folder:
```bash
mkdir -p ideas/<name>/.memory
```

## Data Logged Per Skill

| Skill | Data Fields |
|-------|-------------|
| `/validate-design` | validators run, verdict, issue counts by severity |
| `/advance-stage` | from stage, to stage, blockers encountered |
| `/curating-artifacts` | artifacts curated, files created |
| `/graduate` | target path, templates applied, memory_copied flag |

## Memory Lifecycle

### Creation

First memory-writing skill creates `.memory/` folder. Typically `/advance-stage` or `/validate-design`.

### During Graduation

Memory is **copied** (not moved) to the graduated repo:

```
# Source (stays intact in ai-baseline)
ideas/my-app/.memory/
├── runs.jsonl
└── context.md

# Copied to graduated repo
~/projects/my-app/docs/design-history/
├── refinement-runs.jsonl
└── design-context.md
```

Ideas continue refining in ai-baseline after graduation. Both copies evolve independently.

### Archiving

When archiving (`/archive-idea`), memory stays with idea in `ideas/archived/<name>/.memory/`.

### Deletion

Manual only: `rm -rf ideas/<name>/.memory/`

No skill auto-deletes memory.

### Compaction

Use `tools/compact-memory.sh` for manual cleanup:

```bash
tools/compact-memory.sh my-app           # Compact runs.jsonl
tools/compact-memory.sh my-app --dry-run # Preview changes
```

**Compaction behavior:**
1. Keep last 20 runs verbatim
2. Summarize older runs into single `_compacted` entry:

```json
{"skill":"_compacted","ts":"2026-01-26T17:00:00Z","idea":"my-app","data":{"period":"2026-01-01 to 2026-01-20","runs":45,"summary":{"validate-design":12,"advance-stage":8},"notable":["First validation: 2026-01-01","Graduated v1: 2026-01-15"]}}
```

**Preserved in compaction:**
- Total run counts per skill
- Date range covered
- Notable events (firsts, failures, graduations)
- Any runs with `result: "failed"`

## Implementation

### New Files

| File | Purpose |
|------|---------|
| `.claude/skills/_memory.md` | Shared memory operations partial |
| `tools/compact-memory.sh` | Manual compaction script |

### Skills to Modify

Add memory read/write steps to:
- `.claude/skills/validate-design/SKILL.md`
- `.claude/skills/advance-stage.md`
- `.claude/skills/curating-artifacts/SKILL.md`
- `.claude/skills/graduate.md`

### Shared Memory Partial

`.claude/skills/_memory.md` contains reusable instructions for:
- Reading runs.jsonl (filter by skill, recent entries)
- Reading context.md
- Writing to runs.jsonl (append JSON line)
- Writing to context.md (ask user, append to section)
- Creating .memory/ folder

Skills reference this partial rather than duplicating instructions.

## Example Session

```
$ /validate-design my-app --security --architecture

Reading memory...
Last validation: 2026-01-25 (security, architecture)
  Verdict: NEEDS_ATTENTION
  Issues: 2 high (auth token expiration, missing index)

Context loaded:
  - Auth preference: JWT with refresh tokens
  - Database: PostgreSQL

Running validators...
[validators execute]

Validation complete.
Verdict: PASS (previous issues resolved)

Updating memory...
✓ Logged run to .memory/runs.jsonl
```

## Design Decisions

**Why JSONL over YAML?**
- 25% fewer tokens
- Safe append (no structure to corrupt)
- Line-by-line streaming
- Easy grep/filter

**Why per-idea memory over global?**
- Scoped context (no cross-contamination)
- Travels with idea through lifecycle
- Copies cleanly on graduation

**Why selective reading over always-read?**
- Saves tokens for skills that don't need history
- `/list-ideas` shouldn't load memory
- Skills opt-in to memory, not opt-out

**Why ask before writing context.md?**
- User controls what's remembered
- Prevents noise accumulation
- Context stays meaningful
