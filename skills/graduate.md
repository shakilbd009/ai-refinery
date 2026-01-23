---
name: graduate
description: Bootstrap a new project repository from a refined idea
---

# Graduate Skill

This skill takes a fully refined idea and creates a new project repository with all standards applied and curated design documentation injected.

## Usage

```bash
/graduate <idea-name> <target-path>
```

Example:
```bash
/graduate task-manager ~/projects/task-manager
```

## Process

1. **Validate prerequisites**:
   - Verify idea exists in registry
   - Verify idea is at "07-graduate" stage
   - Verify target path is valid and doesn't already exist
   - Confirm with user before proceeding

2. **Read curated design**:
   - Load all documents from `ideas/<idea-name>/07-graduate/`
   - These should include:
     - Final design document
     - Key decision rationale
     - Trade-offs documentation

3. **Create new repository**:
   - Call tools/scaffold-repo.sh:
     - Create target directory
     - Initialize git repository
     - Create standard folder structure (from docs/folder-conventions.md)

4. **Apply templates**:
   - Copy files from templates/:
     - README.md
     - claude.md
     - .gitignore
   - Call tools/inject-design.sh to merge curated docs into templates:
     - Design content goes into docs/architecture.md
     - Key decisions go into docs/decisions.md
     - Project-specific info updates README.md and claude.md

5. **Create documentation structure**:
   ```
   <target-path>/
   ├── README.md          (from template, customized)
   ├── claude.md          (from template, customized)
   ├── .gitignore         (from template)
   ├── docs/
   │   ├── architecture.md    (curated design)
   │   ├── decisions.md       (key rationale)
   │   └── plans/            (empty, ready for impl plans)
   ├── src/               (empty, ready for code)
   └── tests/             (empty, ready for tests)
   ```

6. **Create initial commit**:
   ```bash
   git add .
   git commit -m "Initial commit from ai-baseline graduation

   Graduated from idea: <idea-name>
   Refinement completed: <date>

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
   ```

7. **Update idea status**:
   - Mark idea as graduated in registry
   - Add graduation metadata:
     ```json
     {
       "graduatedAt": "<ISO date>",
       "targetPath": "<target-path>",
       "status": "graduated"
     }
     ```
   - Optionally archive idea (ask user)

8. **Provide next steps**:
   ```
   ✓ Successfully graduated task-manager

   New project created at: ~/projects/task-manager

   Next steps:
   1. cd ~/projects/task-manager
   2. Review docs/architecture.md
   3. Start implementation using the design blueprint

   The project includes:
   - Complete design documentation
   - Standard folder structure
   - Template files following ai-baseline standards
   - Initial git repository

   Ready to build!
   ```

## Validation

Before graduation, verify:
- [ ] Idea is at stage 07-graduate
- [ ] Curated design documents exist
- [ ] Design is complete (no TBDs or missing sections)
- [ ] Target path is valid
- [ ] No conflicts at target location

## Customization

The skill should ask:
```
Customize new project?

1. Project type:
   - Web application (frontend + backend)
   - Library/Package
   - CLI tool
   - Microservice

2. Primary language:
   - JavaScript/TypeScript
   - Python
   - Go
   - Rust
   - Other

This determines folder structure and template variations.
```

## Error Handling

- **Idea not at graduate stage**: Show current stage, suggest `/advance-stage`
- **Target path exists**: Warn, ask to choose different path
- **Incomplete design**: List missing sections, don't graduate
- **Scaffold failure**: Rollback, clean up partial directory

## Implementation Notes

- Use tools/scaffold-repo.sh for directory creation
- Use tools/inject-design.sh for content merging
- Make process atomic (rollback on any failure)
- Create detailed log of graduation process
- Consider creating a `.ai-baseline` metadata file in new repo:
  ```json
  {
    "graduatedFrom": "ai-baseline",
    "sourceIdea": "<idea-name>",
    "graduatedAt": "<ISO date>",
    "baselineVersion": "1.0.0"
  }
  ```
