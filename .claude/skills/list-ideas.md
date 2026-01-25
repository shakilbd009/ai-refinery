---
name: list-ideas
description: Generate a report showing all ideas and their current stages
---

# List Ideas Skill

This skill reads ideas-registry.json and displays all ideas with their current status in an easy-to-read format.

## Usage

```bash
/list-ideas
```

Optional filters:
```bash
/list-ideas --stage=03-trade-offs
/list-ideas --recent
```

## Process

1. **Read ideas-registry.json**:
   - Load all ideas
   - Sort by last updated (most recent first)

2. **Generate report**:
   Display in table format:
   ```
   Ideas Pipeline Status
   =====================

   | Name              | Stage        | Created    | Last Updated |
   |-------------------|--------------|------------|--------------|
   | task-manager      | 04-design-l1 | 2026-01-15 | 2026-01-20   |
   | note-taking-app   | 02-requirements| 2026-01-18 | 2026-01-19   |
   | code-analyzer     | 01-brainstorm| 2026-01-22 | 2026-01-22   |

   Total ideas: 3
   - Raw: 1
   - Brainstorm: 1
   - Explore: 0
   - Refine L1: 1
   - Refine L2: 0
   - Refine L3: 0
   - Graduate: 0
   ```

3. **Apply filters if provided**:
   - `--stage`: Only show ideas at specific stage
   - `--recent`: Only show ideas updated in last 7 days

4. **Show summary statistics**:
   - Total ideas in pipeline
   - Count per stage
   - Average time in pipeline
   - Ideas ready for graduation

## Display Format

**Stage Names**:
- 01-brainstorm → "Brainstorm"
- 02-requirements → "Requirements"
- 03-trade-offs → "Trade-offs"
- 04-design-l1 → "Design L1"
- 05-design-l2 → "Design L2"
- 06-design-l3 → "Design L3"
- 07-graduate → "Ready to Graduate"

**Date Format**: YYYY-MM-DD

## Additional Features

**Quick links**:
- Show path to each idea's folder
- Highlight ideas that haven't been updated in > 30 days

**Empty state**:
If no ideas exist:
```
No ideas in pipeline yet.

Create your first idea:
  /new-idea <idea-name>
```

## Implementation Notes

- Read directly from ideas-registry.json
- Handle empty registry gracefully
- Consider caching for performance if many ideas
- Format output for terminal readability
