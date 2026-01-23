#!/usr/bin/env bash
# create-solution.sh - Helper script for /compound skill
# Creates a new solution document with proper structure and frontmatter

set -euo pipefail

# Configuration
SOLUTIONS_DIR="docs/solutions"
TEMPLATE_FILE="$SOLUTIONS_DIR/.template.md"
DATE=$(date +%Y-%m-%d)

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Usage message
usage() {
    cat <<EOF
Usage: $(basename "$0") <category> <slug> [options]

Create a new solution document in docs/solutions/

ARGUMENTS:
  category    Solution category (required)
              Options: idea-refinement, workflow-issues, standards-application,
                      graduation-blockers, template-fixes, tooling-problems

  slug        URL-friendly problem identifier (required)
              Example: nested-checklist-validation

OPTIONS:
  -t, --type TYPE        Problem type (default: matches category)
  -c, --component COMP   Component affected (ideas|skills|tools|templates|docs)
  -s, --symptom TEXT     Add symptom (can be used multiple times)
  --tag TAG              Add tag (can be used multiple times)
  -h, --help             Show this help message

EXAMPLES:
  # Basic usage
  $(basename "$0") tooling-problems nested-checklist-validation

  # With metadata
  $(basename "$0") workflow-issues skill-integration \\
    --component skills \\
    --symptom "Skill fails to invoke tool" \\
    --tag automation --tag debugging

  # Interactive mode (no args)
  $(basename "$0")
EOF
}

# Validate category
validate_category() {
    local category="$1"
    local valid_categories=(
        "idea-refinement"
        "workflow-issues"
        "standards-application"
        "graduation-blockers"
        "template-fixes"
        "tooling-problems"
    )

    for valid in "${valid_categories[@]}"; do
        if [[ "$category" == "$valid" ]]; then
            return 0
        fi
    done

    echo -e "${RED}Error: Invalid category '$category'${NC}" >&2
    echo "Valid categories: ${valid_categories[*]}" >&2
    return 1
}

# Convert category to problem_type
category_to_type() {
    local category="$1"
    echo "$category" | tr '-' '_'
}

# Interactive mode
interactive_mode() {
    echo -e "${GREEN}=== Create Solution Document ===${NC}\n"

    echo "Available categories:"
    echo "  1) idea-refinement"
    echo "  2) workflow-issues"
    echo "  3) standards-application"
    echo "  4) graduation-blockers"
    echo "  5) template-fixes"
    echo "  6) tooling-problems"
    echo
    read -p "Select category (1-6): " cat_num

    case $cat_num in
        1) CATEGORY="idea-refinement" ;;
        2) CATEGORY="workflow-issues" ;;
        3) CATEGORY="standards-application" ;;
        4) CATEGORY="graduation-blockers" ;;
        5) CATEGORY="template-fixes" ;;
        6) CATEGORY="tooling-problems" ;;
        *) echo -e "${RED}Invalid selection${NC}"; exit 1 ;;
    esac

    read -p "Solution slug (e.g., my-problem-fix): " SLUG
    read -p "Component (ideas/skills/tools/templates/docs): " COMPONENT
    read -p "Brief symptom: " SYMPTOM
    read -p "Tags (space-separated): " TAGS_INPUT

    PROBLEM_TYPE=$(category_to_type "$CATEGORY")
    SYMPTOMS=("$SYMPTOM")
    IFS=' ' read -ra TAGS <<< "$TAGS_INPUT"
}

# Create solution file
create_solution() {
    local category="$1"
    local slug="$2"
    local problem_type="${3:-$(category_to_type "$category")}"
    local component="${4:-other}"

    local filename="$SOLUTIONS_DIR/$category/${slug}.md"

    # Check if file already exists
    if [[ -f "$filename" ]]; then
        echo -e "${YELLOW}Warning: File already exists: $filename${NC}" >&2
        read -p "Overwrite? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 0
        fi
    fi

    # Ensure category directory exists
    mkdir -p "$SOLUTIONS_DIR/$category"

    # Create file from template
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        echo -e "${RED}Error: Template not found: $TEMPLATE_FILE${NC}" >&2
        exit 1
    fi

    # Copy template and update frontmatter
    cp "$TEMPLATE_FILE" "$filename"

    # Update YAML frontmatter
    sed -i.bak "s/problem_type: \[.*\]/problem_type: $problem_type/" "$filename"
    sed -i.bak "s/component: \[.*\]/component: $component/" "$filename"
    sed -i.bak "s/created: YYYY-MM-DD/created: $DATE/" "$filename"

    # Add symptoms if provided
    if [[ ${#SYMPTOMS[@]} -gt 0 ]]; then
        local symptoms_yaml="symptoms:\n"
        for symptom in "${SYMPTOMS[@]}"; do
            symptoms_yaml+="  - \"$symptom\"\n"
        done
        # Note: This is a simplified approach; in practice, use a YAML parser
    fi

    # Add tags if provided
    if [[ ${#TAGS[@]} -gt 0 ]]; then
        local tags_str=$(printf ", %s" "${TAGS[@]}")
        tags_str=${tags_str:2}  # Remove leading ", "
        sed -i.bak "s/tags: \[.*\]/tags: [$tags_str]/" "$filename"
    fi

    # Remove backup file
    rm -f "${filename}.bak"

    echo -e "${GREEN}✓ Created solution document${NC}"
    echo -e "  File: $filename"
    echo -e "  Category: $category"
    echo -e "  Type: $problem_type"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Edit the file to add problem details"
    echo "  2. Fill in investigation steps"
    echo "  3. Document the solution"
    echo "  4. Add prevention strategies"
    echo
    echo "  Open with: ${GREEN}claude code edit $filename${NC}"
}

# Main script
main() {
    # Parse arguments
    CATEGORY=""
    SLUG=""
    PROBLEM_TYPE=""
    COMPONENT="other"
    SYMPTOMS=()
    TAGS=()

    if [[ $# -eq 0 ]]; then
        interactive_mode
        create_solution "$CATEGORY" "$SLUG" "$PROBLEM_TYPE" "$COMPONENT"
        exit 0
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -t|--type)
                PROBLEM_TYPE="$2"
                shift 2
                ;;
            -c|--component)
                COMPONENT="$2"
                shift 2
                ;;
            -s|--symptom)
                SYMPTOMS+=("$2")
                shift 2
                ;;
            --tag)
                TAGS+=("$2")
                shift 2
                ;;
            -*)
                echo -e "${RED}Error: Unknown option $1${NC}" >&2
                usage
                exit 1
                ;;
            *)
                if [[ -z "$CATEGORY" ]]; then
                    CATEGORY="$1"
                elif [[ -z "$SLUG" ]]; then
                    SLUG="$1"
                else
                    echo -e "${RED}Error: Too many arguments${NC}" >&2
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$CATEGORY" ]] || [[ -z "$SLUG" ]]; then
        echo -e "${RED}Error: Missing required arguments${NC}" >&2
        usage
        exit 1
    fi

    # Validate category
    validate_category "$CATEGORY"

    # Create solution
    if [[ -z "$PROBLEM_TYPE" ]]; then
        PROBLEM_TYPE=$(category_to_type "$CATEGORY")
    fi

    create_solution "$CATEGORY" "$SLUG" "$PROBLEM_TYPE" "$COMPONENT"
}

main "$@"
