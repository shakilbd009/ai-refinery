---
problem_type: idea_refinement
component: skills
symptoms:
  - "Skills don't remember previous runs"
  - "Context lost between sessions"
  - "User preferences not retained"
tags: [memory, skills, persistence, jsonl, context]
related_issues: []
related_solutions: []
created: 2026-01-26
---

# Designing Persistent Memory for Skills/Agents

## Problem

**What needed solving:**
Skills and agents have no memory between runs. Each invocation starts fresh with no knowledge of:
- Previous executions of the same skill
- User preferences and decisions made in past sessions
- Context that would inform better behavior

**Context:**
Feature request for ai-baseline skill system to add persistent memory that travels with ideas through their lifecycle.

**Why it matters:**
- Skills can't learn from past runs (e.g., "last validation found 2 issues")
- User repeats preferences each session
- No institutional memory builds up

## Investigation

**Key design questions explored:**

1. **What to remember?**
   - Skill execution memory (what ran, what happened)
   - Project/session memory (decisions, preferences)
   - Answer: Both

2. **Where to store it?**
   - Per-idea: `ideas/<name>/.memory/`
   - Global: `.claude/memory/`
   - Answer: Per-idea (scoped, travels with idea)

3. **What format?**
   - Single append-only log
   - Structured separate files
   - Answer: Structured (selective reading saves tokens)

4. **JSONL vs YAML for execution log?**
   - YAML: More readable, but 25% more tokens, append-risky
   - JSONL: Compact, safe append, easy to grep/filter
   - Answer: JSONL

## Root Cause

**Why memory didn't exist:**
Skills were designed as stateless functions. No pattern existed for persistence.

**Why per-idea over global:**
- Scoped context prevents cross-contamination
- Memory travels with idea through stages
- Copies cleanly on graduation
- Ideas can be archived/deleted independently

**Why structured over single log:**
- Skills can read only what they need
- `/validate-design` reads runs.jsonl, skips context.md
- Token-efficient for agents

**Why JSONL over YAML:**
- 25% fewer tokens
- Safe append (no structure to corrupt)
- Line-by-line streaming
- Easy grep/filter (`grep '"skill":"validate-design"'`)

## Solution

**Final design:**

```
ideas/<name>/.memory/
├── runs.jsonl      # Skill execution log
└── context.md      # Decisions & preferences
```

**runs.jsonl schema:**
```json
{"skill":"validate-design","ts":"2026-01-26T14:30:00Z","idea":"my-app","result":"completed","data":{"validators":["security"],"verdict":"PASS"}}
```

**context.md structure:**
```markdown
# Memory: my-app

## Preferences
- Auth: JWT with short-lived tokens

## Key Decisions
- 2026-01-26: Chose event-driven architecture

## Notes
- Deadline is end of Q1
```

**Skill behavior:**
- Read at start (selective - only skills that need it)
- Write at end (append to runs.jsonl, ask before context.md)
- Graceful degradation if .memory/ doesn't exist

**Graduation behavior:**
- Memory **copied** (not moved) to new repo
- Original stays for continued refinement

**Compaction:**
- `tools/compact-memory.sh` for manual cleanup
- Not a skill (avoids context bloat)

**Full design:** `docs/plans/2026-01-26-agent-memory-design.md`

## Prevention

**Reusable patterns for future skill enhancements:**

1. **Ask about scope first** - Per-idea vs global has big implications
2. **Prefer structured over monolithic** - Selective reading saves tokens
3. **JSONL for append-only logs** - Safer than YAML, more compact
4. **Separate machine-readable from human-readable** - runs.jsonl + context.md
5. **Keep utilities as scripts, not skills** - Avoid skill bloat

**Questions to ask when adding persistence:**
- [ ] What needs to be remembered?
- [ ] Where should it live (scope)?
- [ ] Who reads it (machine vs human)?
- [ ] How does it grow over time?
- [ ] What happens on graduation/archive?

## Cross-References

**Related documentation:**
- [docs/plans/2026-01-26-agent-memory-design.md](../plans/2026-01-26-agent-memory-design.md) - Full design spec

**Implementation files (to be created):**
- `.claude/skills/_memory.md` - Shared memory operations
- `tools/compact-memory.sh` - Compaction utility

---

**Tags for search:** #memory #skills #persistence #jsonl #design-decisions
