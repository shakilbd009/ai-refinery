#!/bin/bash

# scaffold-repo.sh
# Creates a new project repository with standard folder structure and templates

set -e  # Exit on error

# Usage: scaffold-repo.sh <target-path> <project-type> <language>
TARGET_PATH="$1"
PROJECT_TYPE="${2:-web-app}"  # web-app, library, cli-tool, microservice
LANGUAGE="${3:-typescript}"    # typescript, python, go, rust

if [ -z "$TARGET_PATH" ]; then
  echo "Error: Target path required"
  echo "Usage: scaffold-repo.sh <target-path> [project-type] [language]"
  exit 1
fi

if [ -d "$TARGET_PATH" ]; then
  echo "Error: Directory already exists at $TARGET_PATH"
  exit 1
fi

echo "Creating project at: $TARGET_PATH"
echo "Project type: $PROJECT_TYPE"
echo "Language: $LANGUAGE"

# Get the ai-baseline directory (parent of tools/)
BASELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATES_DIR="$BASELINE_DIR/templates"

# Create target directory
mkdir -p "$TARGET_PATH"
cd "$TARGET_PATH"

# Initialize git
git init

# Create standard folder structure based on project type
case "$PROJECT_TYPE" in
  web-app)
    mkdir -p src/{components,pages,services,utils}
    mkdir -p tests
    mkdir -p docs/{plans,architecture}
    mkdir -p public
    ;;
  library)
    mkdir -p src/{core,utils}
    mkdir -p tests
    mkdir -p docs/{api,guides}
    mkdir -p examples
    ;;
  cli-tool)
    mkdir -p src/{commands,utils}
    mkdir -p tests
    mkdir -p docs
    mkdir -p bin
    ;;
  microservice)
    mkdir -p src/{routes,services,models,middleware}
    mkdir -p tests
    mkdir -p docs
    ;;
  *)
    echo "Unknown project type: $PROJECT_TYPE"
    echo "Using default structure"
    mkdir -p src
    mkdir -p tests
    mkdir -p docs
    ;;
esac

# Copy templates
echo "Copying templates..."
cp "$TEMPLATES_DIR/README.md" ./README.md
cp "$TEMPLATES_DIR/claude.md" ./claude.md
cp "$TEMPLATES_DIR/.gitignore" ./.gitignore

# Create empty placeholder files
touch src/index.$( [ "$LANGUAGE" = "python" ] && echo "py" || [ "$LANGUAGE" = "go" ] && echo "go" || [ "$LANGUAGE" = "rust" ] && echo "rs" || echo "ts" )

echo "✓ Repository scaffolded successfully"
echo ""
echo "Structure created:"
tree -L 2 "$TARGET_PATH" 2>/dev/null || find "$TARGET_PATH" -maxdepth 2 -type d

exit 0
