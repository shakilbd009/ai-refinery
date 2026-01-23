---
name: new-idea
description: Create a new idea folder structure in the refinement pipeline
---

# New Idea Skill

This skill creates a new idea in the refinement pipeline with the full folder structure and initializes it in the ideas registry.

## Usage

```bash
/new-idea <idea-name>
```

## Process

1. **Validate input**:
   - Check that idea-name is provided
   - Check that idea doesn't already exist
   - Sanitize name (convert to kebab-case)

2. **Create folder structure**:
   ```
   ideas/<idea-name>/
   ├── status.md
   ├── 01-raw/
   ├── 02-brainstorm/
   ├── 03-explore/
   ├── 04-refine-l1/
   ├── 05-refine-l2/
   ├── 06-refine-l3/
   └── 07-graduate/
   ```

3. **Initialize status.md**:
   ```markdown
   # <Idea Name> - Status

   **Current Stage**: 01-raw
   **Created**: <current date>
   **Last Updated**: <current date>

   ## Progress

   ### Stage: Raw
   - [ ] Basic idea captured
   - [ ] Problem statement defined
   - [ ] Initial motivation documented
   - [ ] Constraints/requirements noted

   ## Notes

   [Add notes here as you work through the stage]

   ## Next Steps

   1. Document the core problem this idea solves
   2. Capture initial motivation and constraints
   3. Ready to advance to Brainstorm stage
   ```

4. **Update ideas-registry.json**:
   - Read current registry
   - Add new idea entry:
     ```json
     {
       "id": "<idea-name>",
       "name": "<Idea Name>",
       "currentStage": "01-raw",
       "createdAt": "<ISO date>",
       "lastUpdated": "<ISO date>"
     }
     ```
   - Write back to registry

5. **Create initial raw document**:
   - Create `ideas/<idea-name>/01-raw/idea.md` with starter template

6. **Confirm to user**:
   - Show created structure
   - Display next steps
   - Show path to start working

## Implementation Notes

- Use tools/update-registry.js to manage registry updates
- Ensure atomic operations (don't leave partial state)
- Sanitize idea name to ensure valid folder names
