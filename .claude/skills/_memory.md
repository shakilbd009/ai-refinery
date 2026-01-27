# Memory Operations (Shared Partial)

Reusable memory operations for skills. Skills reference this partial rather than duplicating instructions.

## Memory Location

```
ideas/<name>/.memory/
├── runs.jsonl      # Append-only skill execution log
└── context.md      # Running context and decisions
```

## Reading Memory (Step 0 - At Skill Start)

### Check If Memory Exists

```bash
# Graceful degradation - memory is optional
ls ideas/<idea-name>/.memory/ 2>/dev/null
```

If `.memory/` doesn't exist, proceed normally without memory context.

### Read runs.jsonl

Filter for current skill, read recent entries:

```bash
# Get last 5 runs of this skill
grep '"skill":"<skill-name>"' ideas/<idea-name>/.memory/runs.jsonl | tail -5
```

Report to user:
```
Reading memory...
Last <skill-name>: <date>
  <key details from data field>
```

### Read context.md

Read fully, extract relevant preferences/decisions:

```bash
cat ideas/<idea-name>/.memory/context.md
```

Report relevant context to user:
```
Context loaded:
  - <relevant preference 1>
  - <relevant decision 2>
```

## Writing Memory (Final Step - After Skill Completes)

### Create Memory Folder (If Needed)

```bash
mkdir -p ideas/<idea-name>/.memory
```

### Write to runs.jsonl

Append one JSON line with execution summary:

```bash
echo '{"skill":"<skill-name>","ts":"<ISO-8601>","idea":"<idea-name>","result":"<completed|failed|skipped>","data":{<skill-specific-payload>}}' >> ideas/<idea-name>/.memory/runs.jsonl
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

### Write to context.md (Ask User First)

Only when significant decisions emerge during the skill run. **Always ask user first:**

```
I noticed you decided on <decision>.
Want me to save this to memory for future reference? (y/n)
```

If yes, append to appropriate section:

```bash
# If context.md doesn't exist, create with header
if [ ! -f ideas/<idea-name>/.memory/context.md ]; then
  echo "# Memory: <idea-name>" > ideas/<idea-name>/.memory/context.md
  echo "" >> ideas/<idea-name>/.memory/context.md
  echo "## Preferences" >> ideas/<idea-name>/.memory/context.md
  echo "" >> ideas/<idea-name>/.memory/context.md
  echo "## Key Decisions" >> ideas/<idea-name>/.memory/context.md
  echo "" >> ideas/<idea-name>/.memory/context.md
  echo "## Notes" >> ideas/<idea-name>/.memory/context.md
fi
```

Then append to the appropriate section:
- **Preferences** - User preferences on tech choices, patterns, approaches
- **Key Decisions** - Dated architectural/design decisions
- **Notes** - Miscellaneous context (deadlines, constraints, etc.)

## Data Logged Per Skill

| Skill | Data Fields |
|-------|-------------|
| `/validate-design` | validators run, verdict, issue counts by severity |
| `/advance-stage` | from stage, to stage, blockers encountered |
| `/curating-artifacts` | artifacts curated, files created |
| `/graduate` | target path, templates applied, memory_copied flag |

## Example runs.jsonl Entries

```json
{"skill":"validate-design","ts":"2026-01-26T14:30:00Z","idea":"my-app","result":"completed","data":{"validators":["security","architecture"],"verdict":"NEEDS_ATTENTION","critical":0,"high":2}}
{"skill":"advance-stage","ts":"2026-01-26T15:45:00Z","idea":"my-app","result":"completed","data":{"from":"03-trade-offs","to":"04-design-l1"}}
{"skill":"curating-artifacts","ts":"2026-01-26T16:00:00Z","idea":"my-app","result":"completed","data":{"files_created":15,"categories":["architecture","decisions","edge-cases"]}}
{"skill":"graduate","ts":"2026-01-26T17:00:00Z","idea":"my-app","result":"completed","data":{"target":"~/projects/my-app","templates":["README.md","CLAUDE.md",".gitignore"],"memory_copied":true}}
```

## Example context.md

```markdown
# Memory: my-app

## Preferences
- Auth: JWT with short-lived tokens + refresh tokens
- Database: PostgreSQL over SQLite (needs concurrent access)
- Testing: Prefer integration tests over unit tests for this project

## Key Decisions
- 2026-01-26: Chose event-driven architecture for notifications
- 2026-01-25: Will not support offline mode in v1
- 2026-01-24: API versioning via URL path (/v1/, /v2/)

## Notes
- User mentioned deadline is end of Q1
- Team is familiar with React but not Vue
```
