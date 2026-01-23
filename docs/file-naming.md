# File Naming Conventions

## Core Principles

1. **Be descriptive**: File names should indicate what's inside
2. **Be consistent**: Use the same patterns across the project
3. **Be readable**: Prefer clarity over brevity
4. **Follow community standards**: Use conventions common in your ecosystem

## Casing Styles

### kebab-case (Preferred for most files)
```
user-service.ts
api-client.js
database-config.json
```
**Use for**: Configuration files, scripts, general files

### camelCase
```
userService.ts
apiClient.js
databaseConfig.json
```
**Use for**: JavaScript/TypeScript source files (common in some codebases)

### PascalCase
```
UserService.ts
ApiClient.tsx
DatabaseConfig.ts
```
**Use for**:
- React/Vue components
- TypeScript classes/interfaces
- Files exporting a single class

### snake_case
```
user_service.py
api_client.py
database_config.py
```
**Use for**: Python files (PEP 8 standard)

### SCREAMING_SNAKE_CASE
```
API_KEY
DATABASE_URL
MAX_RETRIES
```
**Use for**: Environment variables, constants

## Pick One and Stick With It

Choose based on your primary language/framework:

| Language/Framework | Recommended Style |
|-------------------|-------------------|
| JavaScript/Node.js | kebab-case or camelCase |
| TypeScript | kebab-case or PascalCase (for classes/components) |
| React/Vue | PascalCase for components, kebab-case for others |
| Python | snake_case |
| Go | lowercase (Go convention) |
| Rust | snake_case |

## File Extensions

### Use Specific Extensions
```
✅ UserService.ts          (TypeScript)
✅ config.json             (JSON)
✅ UserComponent.tsx       (React/JSX)
✅ styles.module.css       (CSS Module)

❌ UserService.js          (when it's actually TypeScript)
❌ config.txt              (when it's actually JSON)
```

### Common Extensions
- `.ts` - TypeScript
- `.tsx` - TypeScript with JSX
- `.js` - JavaScript
- `.jsx` - JavaScript with JSX
- `.mjs` - ES Module JavaScript
- `.py` - Python
- `.go` - Go
- `.rs` - Rust
- `.json` - JSON data
- `.yaml` / `.yml` - YAML
- `.md` - Markdown
- `.sh` - Shell script

## Naming Patterns

### Services/Business Logic
```
user-service.ts
auth-service.ts
email-service.ts
```
Pattern: `<domain>-service.<ext>`

### Controllers/Routes
```
user-controller.ts
auth-routes.ts
api-routes.ts
```
Pattern: `<domain>-controller.<ext>` or `<domain>-routes.<ext>`

### Models/Entities
```
User.ts
Task.ts
Comment.ts
```
Pattern: `<Entity>.<ext>` (PascalCase for classes)

### Components (React/Vue)
```
UserProfile.tsx
TaskList.tsx
Button.tsx
```
Pattern: `<ComponentName>.<ext>` (PascalCase)

### Utilities/Helpers
```
string-utils.ts
date-helpers.ts
validation.ts
```
Pattern: `<purpose>-utils.<ext>` or `<purpose>-helpers.<ext>`

### Tests
```
user-service.test.ts        # Next to source
user-service.spec.ts        # Alternative
__tests__/user-service.ts   # In __tests__ folder
```
Pattern: `<source-file>.test.<ext>` or `<source-file>.spec.<ext>`

### Configuration
```
tsconfig.json
.eslintrc.json
webpack.config.js
database.config.ts
```
Pattern: `<tool>config.<ext>` or `.<tool>rc.<ext>`

### Documentation
```
README.md
API.md
CONTRIBUTING.md
ARCHITECTURE.md
```
Pattern: `<PURPOSE>.md` (often UPPERCASE for important docs)

## Special Files

### Root-Level Files
These have conventional names - don't change them:
```
README.md               # Project intro
LICENSE                 # License file
.gitignore             # Git ignore rules
package.json           # Node.js dependencies
requirements.txt       # Python dependencies
Cargo.toml            # Rust dependencies
go.mod                # Go module file
Dockerfile            # Docker build instructions
docker-compose.yml    # Docker Compose config
```

### Index Files
```
index.ts               # Main entry point
index.html            # HTML entry
__init__.py           # Python package marker
```

## What NOT to Do

### ❌ Abbreviations
```
❌ usrSvc.ts
❌ authCtrl.ts
❌ dbCfg.json
```
Be explicit: `user-service.ts`, `auth-controller.ts`, `database-config.json`

### ❌ Numbers or Dates in Names
```
❌ user-service-v2.ts
❌ config-2026-01-22.json
❌ backup-final-final.ts
```
Use version control instead. If you must version, use semantic versioning in file metadata.

### ❌ Spaces
```
❌ user service.ts
❌ my config.json
```
Use dashes or underscores: `user-service.ts`, `my-config.json`

### ❌ Special Characters
```
❌ user@service.ts
❌ config#1.json
❌ file(1).ts
```
Stick to letters, numbers, dashes, and underscores.

### ❌ Generic Names
```
❌ utils.ts            # Utils for what?
❌ helpers.ts          # Helping with what?
❌ data.json           # What data?
❌ temp.ts             # Temp files should be deleted
```
Be specific: `string-utils.ts`, `date-helpers.ts`, `user-data.json`

### ❌ Redundant Information
```
❌ /services/user-service.service.ts
❌ /models/User.model.ts
❌ /tests/user.test.spec.ts
```
Folder already says "services", no need for `.service.` suffix.

## Framework-Specific Patterns

### React
```
Button.tsx              # Component
Button.module.css       # CSS Module
Button.test.tsx         # Test
useAuth.ts              # Custom hook (camelCase starting with "use")
```

### Next.js
```
page.tsx                # Page route
layout.tsx              # Layout component
route.ts                # API route
```

### Vue
```
UserProfile.vue
user-profile.vue        # Alternative (kebab-case)
```

### Django
```
models.py               # Django convention
views.py
urls.py
admin.py
```

### Rails
```
user.rb                 # Model
users_controller.rb     # Controller
user_mailer.rb         # Mailer
```

## Validation Checklist

Good file names should:
- [ ] Clearly indicate the file's purpose
- [ ] Follow project-wide naming conventions
- [ ] Use appropriate casing for the language/framework
- [ ] Use correct file extensions
- [ ] Avoid abbreviations and ambiguity
- [ ] Not include version numbers (use git instead)
- [ ] Not include dates (use git history instead)
- [ ] Not include spaces or special characters

## Tips

1. **New to a codebase?** Look at existing files and match their pattern
2. **Starting fresh?** Pick conventions early and document them
3. **Renaming files?** Update all imports/references - use IDE refactoring tools
4. **Inconsistent project?** Gradually migrate to standard as you touch files
5. **Team disagreement?** Pick one standard and enforce it with linters
