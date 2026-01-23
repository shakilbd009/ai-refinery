# Configuration Standards

## Configuration Files Every Project Should Have

### 1. .gitignore (Required)
Prevents committing sensitive data, build artifacts, and dependencies.

**Minimum contents**:
```gitignore
# Dependencies
node_modules/
venv/
__pycache__/

# Environment variables
.env
.env.local
*.env

# Build output
dist/
build/
*.log

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
```

### 2. README.md (Required)
Project overview and quick start guide.

**Minimum contents**:
- What the project does
- How to install/run it
- Basic usage example

### 3. LICENSE (Required for Open Source)
Legal terms for using the code.

Common choices:
- **MIT**: Permissive, simple
- **Apache 2.0**: Permissive, includes patent grant
- **GPL**: Copyleft, derivative works must be open source

### 4. Environment Variables (.env)

**Never commit .env files**. Instead, commit `.env.example`:

```bash
# .env.example
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
API_KEY=your_api_key_here
PORT=3000
NODE_ENV=development
```

Users copy this to `.env` and fill in real values.

## Language/Framework-Specific Configs

### JavaScript/TypeScript/Node.js

#### package.json
```json
{
  "name": "project-name",
  "version": "1.0.0",
  "description": "Brief description",
  "main": "dist/index.js",
  "scripts": {
    "dev": "nodemon src/index.ts",
    "build": "tsc",
    "test": "jest",
    "lint": "eslint src/"
  },
  "keywords": [],
  "author": "",
  "license": "MIT",
  "dependencies": {},
  "devDependencies": {}
}
```

#### tsconfig.json (for TypeScript)
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

#### .eslintrc.json (Linting)
```json
{
  "extends": ["eslint:recommended"],
  "env": {
    "node": true,
    "es2020": true
  },
  "parserOptions": {
    "ecmaVersion": 2020
  },
  "rules": {}
}
```

#### .prettierrc (Formatting)
```json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2
}
```

### Python

#### requirements.txt or pyproject.toml
```txt
# requirements.txt
flask==2.3.0
sqlalchemy==2.0.0
pytest==7.4.0
```

Or modern approach:
```toml
# pyproject.toml
[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"

[project]
name = "project-name"
version = "1.0.0"
dependencies = [
    "flask>=2.3.0",
    "sqlalchemy>=2.0.0"
]

[project.optional-dependencies]
dev = ["pytest>=7.4.0"]
```

#### .flake8 or pyproject.toml
```ini
# .flake8
[flake8]
max-line-length = 88
extend-ignore = E203, W503
exclude = venv, __pycache__
```

### Go

#### go.mod
```go
module github.com/username/project-name

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
)
```

### Rust

#### Cargo.toml
```toml
[package]
name = "project-name"
version = "0.1.0"
edition = "2021"

[dependencies]
serde = { version = "1.0", features = ["derive"] }
```

## Docker Configuration

### Dockerfile
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["node", "dist/index.js"]
```

### docker-compose.yml
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
    depends_on:
      - db

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=mydb
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  postgres-data:
```

### .dockerignore
```
node_modules
npm-debug.log
.env
.git
.gitignore
README.md
dist
```

## CI/CD Configuration

### GitHub Actions (.github/workflows/ci.yml)
```yaml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3
    - name: Use Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
    - run: npm ci
    - run: npm test
    - run: npm run build
```

## Editor Configuration

### .editorconfig
Ensures consistent coding style across different editors.

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.{js,ts,jsx,tsx,json,yml,yaml}]
indent_style = space
indent_size = 2

[*.py]
indent_style = space
indent_size = 4

[*.md]
trim_trailing_whitespace = false
```

### .vscode/settings.json (Optional)
Project-specific VS Code settings.

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "typescript.tsdk": "node_modules/typescript/lib"
}
```

## Best Practices

### Environment Variables
1. **Never commit secrets**: Use `.env` files and gitignore them
2. **Provide examples**: Commit `.env.example` with dummy values
3. **Validate on startup**: Check required env vars exist when app starts
4. **Use descriptive names**: `DATABASE_URL` not `DB`

### Version Pinning
```json
// ❌ Too loose - breaks on updates
"dependencies": {
  "express": "*"
}

// ❌ Still risky
"dependencies": {
  "express": "^4.18.0"  // Could get 4.19.x
}

// ✅ Safer with lock file
"dependencies": {
  "express": "^4.18.0"  // With package-lock.json committed
}

// ✅ Exact for critical deps
"dependencies": {
  "express": "4.18.2"
}
```

### Configuration Priority
Load config in this order (later overrides earlier):
1. Default values in code
2. Config files (config.json, etc.)
3. Environment variables (.env)
4. Command-line arguments

### Secrets Management
**Development**:
- `.env` files (gitignored)
- Local password managers

**Production**:
- AWS Secrets Manager
- HashiCorp Vault
- Cloud provider secret stores
- Environment variables (set by platform)

## Validation Checklist

Every project should have:
- [ ] .gitignore (preventing sensitive data commits)
- [ ] README.md (basic documentation)
- [ ] Package manager file (package.json, requirements.txt, etc.)
- [ ] .env.example (if using environment variables)
- [ ] LICENSE (if open source)
- [ ] Linter config (.eslintrc, .flake8, etc.)
- [ ] Formatter config (.prettierrc, .editorconfig)
- [ ] CI config (for automated testing)

## Tips

1. **Use lock files**: Commit `package-lock.json`, `poetry.lock`, `Cargo.lock`, etc.
2. **Keep configs minimal**: Only configure what differs from defaults
3. **Document special config**: If config is non-standard, explain why in README
4. **Validate early**: Check config on app startup, fail fast with clear errors
5. **Share team settings**: Use .editorconfig and .prettierrc so everyone has the same formatting

## Common Mistakes

### ❌ Committing secrets
```bash
# .env (committed by mistake)
API_KEY=sk_live_real_secret_key_123
```

### ❌ No .gitignore
Committing `node_modules`, build artifacts, or IDE files

### ❌ Too many configs
Having 10 different config files when 3 would do. Consolidate where possible.

### ❌ Outdated dependencies
Dependencies from 5 years ago with known security issues. Keep them updated.

### ❌ No config validation
App crashes mysteriously because `DATABASE_URL` is undefined. Validate on startup!
