---
name: advance-stage
description: Move an idea to the next stage in the refinement pipeline
---

# Advance Stage Skill

This skill validates that the current stage checklist is complete and advances the idea to the next stage.

## Usage

```bash
/advance-stage <idea-name>
```

## Process

1. **Validate idea exists**:
   - Check that idea folder exists
   - Check that idea is in registry

2. **Get current stage**:
   - Read from ideas-registry.json
   - Determine next stage

3. **Validate current stage completion**:
   - Run tools/validate-checklist.sh
   - Check that all required criteria are met from docs/stage-checklists.md
   - If validation fails, show which items are incomplete

4. **Advance to next stage**:
   - Update ideas-registry.json:
     ```json
     {
       "currentStage": "<next-stage>",
       "lastUpdated": "<ISO date>"
     }
     ```
   - Update ideas/<idea-name>/status.md:
     - Change "Current Stage" header
     - Add new stage checklist items
     - Archive previous stage progress

5. **Provide guidance**:
   - Show what the new stage focuses on
   - Display checklist from docs/stage-checklists.md
   - Suggest next steps

## Stage Progression

```
01-brainstorm → 02-requirements → 03-trade-offs → 04-design-l1 → 05-design-l2 → 06-design-l3 → 07-graduate
```

## Validation Rules

Each stage has specific criteria from docs/stage-checklists.md:
- Brainstorm: Basic idea captured, problem statement defined
- Requirements: User needs identified, success criteria established
- Trade-offs: Approaches compared, recommendation made
- Design L1: High-level architecture, main components, primary flows
- Design L2: Detailed design on all aspects
- Design L3: Exhaustive coverage, no ambiguity
- Graduate: Curated docs packaged, ready for export

## Error Handling

- If idea doesn't exist: Show error, list available ideas
- If validation fails: Show incomplete items, don't advance
- If already at final stage: Suggest using /graduate instead

## Implementation Notes

- Use tools/validate-checklist.sh for validation
- Use tools/update-registry.js for registry updates
- Make process atomic (rollback on failure)
