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

### Step 0: Read Memory

**Reference:** See [_memory.md](./_memory.md) for memory operations.

Check if memory exists and load context:

```bash
ls ideas/<idea-name>/.memory/ 2>/dev/null
```

**If memory exists:**

1. **Read runs.jsonl** - Filter for `advance-stage` runs to show progression history:
   ```bash
   grep '"skill":"advance-stage"' ideas/<idea-name>/.memory/runs.jsonl | tail -5
   ```

   Report to user:
   ```
   Reading memory...
   Stage progression:
     <date>: <from> → <to>
     <date>: <from> → <to>
     ...
   ```

2. **Read context.md** - Extract relevant preferences:
   ```bash
   cat ideas/<idea-name>/.memory/context.md
   ```

   Report relevant context:
   ```
   Context loaded:
     - <relevant preference>
     - <relevant decision>
   ```

**If no memory:** Proceed normally without memory context.

### Steps 1-5: Core Process

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
01-brainstorm → 02-requirements → 03-trade-offs → 04-design-l1 → 05-design-l2 → 06-design-l3 → 07-curate → 08-validated → 09-graduate
```

## Validation Rules

Each stage has specific criteria from docs/stage-checklists.md:
- Brainstorm: Basic idea captured, problem statement defined
- Requirements: User needs identified, success criteria established
- Trade-offs: Approaches compared, recommendation made
- Design L1: High-level architecture, main components, primary flows
- Design L2: Detailed design on all aspects
- Design L3: Exhaustive coverage, no ambiguity, operational readiness
- Curate: Curated design packaged, decision rationale included, compound learnings captured
- Validated: Multi-agent validation (security, architecture, performance, UX, devil's advocate), all critical issues addressed
- Graduate: All prior artifacts verified, repo scaffolding ready, export to production repo

## Error Handling

- If idea doesn't exist: Show error, list available ideas
- If validation fails: Show incomplete items, don't advance
- If already at final stage: Suggest using /graduate instead

### Step 6: Write Memory

**Reference:** See [_memory.md](./_memory.md) for memory operations.

1. **Create memory folder (if needed):**
   ```bash
   mkdir -p ideas/<idea-name>/.memory
   ```

2. **Append to runs.jsonl:**
   ```bash
   echo '{"skill":"advance-stage","ts":"<ISO-8601>","idea":"<idea-name>","result":"completed","data":{"from":"<previous-stage>","to":"<new-stage>"}}' >> ideas/<idea-name>/.memory/runs.jsonl
   ```

   If blocked (validation failed), log with `result: "failed"` and include blockers:
   ```bash
   echo '{"skill":"advance-stage","ts":"<ISO-8601>","idea":"<idea-name>","result":"failed","data":{"from":"<current-stage>","blockers":["<incomplete item 1>","<incomplete item 2>"]}}' >> ideas/<idea-name>/.memory/runs.jsonl
   ```

3. **Ask about context.md (if significant decisions emerged):**

   If the user made notable decisions during stage work:
   ```
   I noticed you decided <decision>.
   Want me to save this to memory for future reference? (y/n)
   ```

   If yes, append to appropriate section in context.md.

Report:
```
Updating memory...
✓ Logged run to .memory/runs.jsonl
```

## Implementation Notes

- Use tools/validate-checklist.sh for validation
- Use tools/update-registry.js for registry updates
- Make process atomic (rollback on failure)
