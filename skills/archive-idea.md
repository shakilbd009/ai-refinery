---
name: archive-idea
description: Archive a graduated or abandoned idea
---

# Archive Idea Skill

This skill moves an idea from active pipeline to archive, useful for graduated projects or abandoned ideas.

## Usage

```bash
/archive-idea <idea-name> [reason]
```

Reasons:
- `graduated` (default): Idea was successfully graduated to a project
- `abandoned`: Idea was abandoned/cancelled
- `duplicate`: Idea was duplicate of another

## Process

1. **Validate idea exists**:
   - Check that idea is in registry
   - Confirm with user before archiving

2. **Create archive entry**:
   - Create `ideas/_archive/` folder if it doesn't exist
   - Move `ideas/<idea-name>/` to `ideas/_archive/<idea-name>/`
   - Add metadata file `ideas/_archive/<idea-name>/archived.json`:
     ```json
     {
       "archivedAt": "<ISO date>",
       "reason": "graduated|abandoned|duplicate",
       "originalStage": "<stage-at-archive>",
       "createdAt": "<original-creation-date>",
       "notes": "Optional notes"
     }
     ```

3. **Update ideas-registry.json**:
   - Remove idea from active ideas array
   - Add to archived section:
     ```json
     {
       "ideas": [...],
       "archived": [
         {
           "id": "<idea-name>",
           "name": "<Idea Name>",
           "archivedAt": "<ISO date>",
           "reason": "graduated",
           "finalStage": "07-graduate"
         }
       ]
     }
     ```

4. **Confirm to user**:
   - Show archive location
   - Confirm reason
   - Display summary

## Safety Features

**Confirmation prompt**:
```
Archive idea "task-manager"?

This will:
- Move ideas/task-manager/ to ideas/_archive/task-manager/
- Remove from active ideas list
- Mark as: graduated

Continue? (y/n)
```

**Prevent accidental deletion**:
- Never delete files, only move to archive
- Archive preserves all work
- Can be restored if needed

## Restoring Archived Ideas

To restore an archived idea:
1. Move folder back from `_archive/`
2. Update registry to move from archived to active
3. Remove `archived.json` metadata

(Consider creating a `/restore-idea` skill for this)

## Implementation Notes

- Use filesystem operations to move folders
- Update registry atomically
- Keep archive organized (consider date-based subfolders if archive grows large)
- Log all archive operations for audit trail
