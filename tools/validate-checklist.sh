#!/bin/bash

# validate-checklist.sh
# Validates that stage gate criteria are met before advancement

set -e  # Exit on error

# Usage: validate-checklist.sh <idea-path> <current-stage>
IDEA_PATH="$1"
CURRENT_STAGE="$2"

if [ -z "$IDEA_PATH" ] || [ -z "$CURRENT_STAGE" ]; then
  echo "Error: Both idea path and current stage required"
  echo "Usage: validate-checklist.sh <idea-path> <current-stage>"
  exit 1
fi

STATUS_FILE="$IDEA_PATH/status.md"

if [ ! -f "$STATUS_FILE" ]; then
  echo "Error: status.md not found at $STATUS_FILE"
  exit 1
fi

echo "Validating checklist for stage: $CURRENT_STAGE"

# Check for unchecked items in current stage section
# Look for lines like "- [ ]" (unchecked) in the status file

UNCHECKED=$(grep -c "^- \[ \]" "$STATUS_FILE" || true)

if [ "$UNCHECKED" -gt 0 ]; then
  echo "❌ Validation failed: $UNCHECKED checklist items incomplete"
  echo ""
  echo "Incomplete items:"
  grep "^- \[ \]" "$STATUS_FILE"
  echo ""
  echo "Complete all items before advancing to next stage."
  exit 1
fi

# Check that at least some items were checked
CHECKED=$(grep -c "^- \[x\]" "$STATUS_FILE" || true)

if [ "$CHECKED" -eq 0 ]; then
  echo "⚠️  Warning: No checklist items found or checked"
  echo "Ensure status.md has proper checklist items."
  exit 1
fi

echo "✓ All checklist items completed ($CHECKED items)"
echo "Ready to advance to next stage."

exit 0
