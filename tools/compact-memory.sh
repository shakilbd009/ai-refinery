#!/bin/bash
# Compact memory runs.jsonl for an idea
# Usage: tools/compact-memory.sh <idea-name> [--dry-run]
#
# Compaction behavior:
# 1. Keep last 20 runs verbatim
# 2. Summarize older runs into single _compacted entry
#
# Preserved in compaction:
# - Total run counts per skill
# - Date range covered
# - Notable events (firsts, failures, graduations)
# - Any runs with result: "failed"

set -e

IDEA_NAME="$1"
DRY_RUN=false

if [ -z "$IDEA_NAME" ]; then
    echo "Usage: tools/compact-memory.sh <idea-name> [--dry-run]"
    exit 1
fi

if [ "$2" = "--dry-run" ]; then
    DRY_RUN=true
fi

MEMORY_DIR="ideas/$IDEA_NAME/.memory"
RUNS_FILE="$MEMORY_DIR/runs.jsonl"

if [ ! -f "$RUNS_FILE" ]; then
    echo "No runs.jsonl found at $RUNS_FILE"
    exit 1
fi

TOTAL_LINES=$(wc -l < "$RUNS_FILE" | tr -d ' ')
KEEP_LINES=20

if [ "$TOTAL_LINES" -le "$KEEP_LINES" ]; then
    echo "Only $TOTAL_LINES runs found (threshold: $KEEP_LINES). No compaction needed."
    exit 0
fi

COMPACT_LINES=$((TOTAL_LINES - KEEP_LINES))

echo "Compacting $RUNS_FILE"
echo "  Total runs: $TOTAL_LINES"
echo "  Runs to compact: $COMPACT_LINES"
echo "  Runs to keep: $KEEP_LINES"
echo ""

# Extract lines to compact
LINES_TO_COMPACT=$(head -n "$COMPACT_LINES" "$RUNS_FILE")

# Calculate summary using jq
SUMMARY=$(echo "$LINES_TO_COMPACT" | jq -s '
  # Get date range
  (map(.ts) | sort | [first, last]) as $dates |

  # Count by skill
  (group_by(.skill) | map({key: .[0].skill, value: length}) | from_entries) as $skill_counts |

  # Find notable events
  (
    # First run
    [(sort_by(.ts) | first | "First run: \(.ts[0:10]) (\(.skill))")] +

    # Any failures
    [.[] | select(.result == "failed") | "Failed: \(.ts[0:10]) (\(.skill))"] +

    # Any graduations
    [.[] | select(.skill == "graduate" and .result == "completed") | "Graduated: \(.ts[0:10])"]
  ) as $notable |

  {
    period: "\($dates[0][0:10]) to \($dates[1][0:10])",
    runs: length,
    summary: $skill_counts,
    notable: $notable
  }
')

# Get current timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build compacted entry
COMPACTED_ENTRY=$(jq -n \
  --arg skill "_compacted" \
  --arg ts "$TIMESTAMP" \
  --arg idea "$IDEA_NAME" \
  --argjson data "$SUMMARY" \
  '{skill: $skill, ts: $ts, idea: $idea, result: "completed", data: $data}')

echo "Compacted entry:"
echo "$COMPACTED_ENTRY" | jq .
echo ""

# Also preserve any failed runs from the compacted section
FAILED_RUNS=$(echo "$LINES_TO_COMPACT" | jq -c 'select(.result == "failed")' 2>/dev/null || true)

if [ -n "$FAILED_RUNS" ]; then
    FAILED_COUNT=$(echo "$FAILED_RUNS" | wc -l | tr -d ' ')
    echo "Preserving $FAILED_COUNT failed run(s)"
    echo ""
fi

if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would create new runs.jsonl with:"
    echo "  - 1 compacted entry"
    if [ -n "$FAILED_RUNS" ]; then
        echo "  - $FAILED_COUNT preserved failed run(s)"
    fi
    echo "  - $KEEP_LINES recent runs"
    exit 0
fi

# Create new file
TEMP_FILE=$(mktemp)

# Write compacted entry
echo "$COMPACTED_ENTRY" >> "$TEMP_FILE"

# Write preserved failed runs (if any)
if [ -n "$FAILED_RUNS" ]; then
    echo "$FAILED_RUNS" >> "$TEMP_FILE"
fi

# Write recent runs
tail -n "$KEEP_LINES" "$RUNS_FILE" >> "$TEMP_FILE"

# Backup and replace
cp "$RUNS_FILE" "$RUNS_FILE.bak"
mv "$TEMP_FILE" "$RUNS_FILE"

NEW_LINES=$(wc -l < "$RUNS_FILE" | tr -d ' ')
echo "Compaction complete."
echo "  Before: $TOTAL_LINES lines"
echo "  After: $NEW_LINES lines"
echo "  Backup: $RUNS_FILE.bak"
