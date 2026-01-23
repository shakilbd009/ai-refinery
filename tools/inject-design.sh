#!/bin/bash

# inject-design.sh
# Merges curated design documents into project templates

set -e  # Exit on error

# Usage: inject-design.sh <target-path> <curated-docs-path>
TARGET_PATH="$1"
CURATED_DOCS_PATH="$2"

if [ -z "$TARGET_PATH" ] || [ -z "$CURATED_DOCS_PATH" ]; then
  echo "Error: Both target path and curated docs path required"
  echo "Usage: inject-design.sh <target-path> <curated-docs-path>"
  exit 1
fi

if [ ! -d "$TARGET_PATH" ]; then
  echo "Error: Target path does not exist: $TARGET_PATH"
  exit 1
fi

if [ ! -d "$CURATED_DOCS_PATH" ]; then
  echo "Error: Curated docs path does not exist: $CURATED_DOCS_PATH"
  exit 1
fi

echo "Injecting design from: $CURATED_DOCS_PATH"
echo "Into project at: $TARGET_PATH"

# Find all markdown files in curated docs
for doc in "$CURATED_DOCS_PATH"/*.md; do
  if [ -f "$doc" ]; then
    filename=$(basename "$doc")
    echo "Processing: $filename"

    case "$filename" in
      design.md)
        # Main design document goes to docs/architecture.md
        cp "$doc" "$TARGET_PATH/docs/architecture.md"
        echo "  → docs/architecture.md"
        ;;
      decisions.md)
        # Decision rationale goes to docs/decisions.md
        cp "$doc" "$TARGET_PATH/docs/decisions.md"
        echo "  → docs/decisions.md"
        ;;
      overview.md)
        # Overview can update README introduction
        # For now, just copy to docs
        cp "$doc" "$TARGET_PATH/docs/overview.md"
        echo "  → docs/overview.md"
        ;;
      *)
        # Other docs go to docs/ as-is
        cp "$doc" "$TARGET_PATH/docs/$filename"
        echo "  → docs/$filename"
        ;;
    esac
  fi
done

# TODO: More sophisticated injection
# - Parse templates for placeholders like {{DESIGN_CONTENT}}
# - Extract relevant sections from curated docs
# - Merge into README.md, claude.md, etc.
# For now, this simple copy approach works

echo "✓ Design documents injected successfully"

exit 0
