# Tooling & Technology Choices

## Philosophy

1. **Boring technology wins**: Proven > cutting-edge
2. **Right tool for the job**: No one-size-fits-all
3. **Team familiarity matters**: Productivity > résumé-driven development
4. **Simplicity scales**: Fewer tools = less cognitive load

## General Principles

### When Choosing Tools

**Evaluate based on**:
- **Maturity**: Battle-tested in production?
- **Community**: Active maintenance and support?
- **Documentation**: Can you find answers easily?
- **Performance**: Fast enough for your needs?
- **Developer experience**: Pleasant to work with?
- **Lock-in risk**: Can you migrate away if needed?

**Red flags**:
- "Rewrite it in X" without clear benefits
- "Everyone's using it" (popularity ≠ right for you)
- Overly complex for your use case
- Abandoned or poorly maintained
- Massive bundle size for small features

## Language Choices

### JavaScript/TypeScript
**Use for**: Web frontends, Node.js backends, full-stack apps

**Why**:
- Ubiquitous in web development
- Huge ecosystem (npm)
- TypeScript adds safety without runtime cost
- Great tooling (VS Code, ESLint, Prettier)

**Trade-offs**:
- Loose typing without TypeScript
- Callback hell if not careful
- Package ecosystem can be unstable

**Recommended setup**:
- TypeScript over plain JavaScript
- Node.js 18+ LTS
- npm or pnpm for package management

### Python
**Use for**: Data science, ML, scripting, backend APIs

**Why**:
- Readable syntax
- Rich ecosystem for data/ML
- Great for rapid prototyping
- Excellent libraries (NumPy, Pandas, FastAPI)

**Trade-offs**:
- Slower than compiled languages
- Packaging can be messy
- GIL limits true parallelism

**Recommended setup**:
- Python 3.10+
- pyenv for version management
- poetry or pip-tools for dependencies
- Type hints with mypy

### Go
**Use for**: CLI tools, microservices, system programming

**Why**:
- Fast compilation and execution
- Simple language with few features
- Built-in concurrency (goroutines)
- Single binary deployment

**Trade-offs**:
- Verbose error handling
- Limited generics (improving)
- Not ideal for rapid prototyping

### Rust
**Use for**: Performance-critical code, systems programming, WebAssembly

**Why**:
- Memory safety without garbage collection
- Blazingly fast
- Great error messages
- Strong type system

**Trade-offs**:
- Steep learning curve
- Slower development initially
- Compile times can be slow

## Web Frameworks

### Frontend

#### React
**Use for**: Complex interactive UIs, SPAs

**Strengths**:
- Huge ecosystem
- Component reusability
- React Native for mobile
- Virtual DOM performance

**When to use**: You need a full SPA framework

**Recommended with**:
- Vite for build tooling
- React Router for routing
- TanStack Query for data fetching

#### Next.js
**Use for**: Full-stack React apps, SEO-critical sites

**Strengths**:
- Server-side rendering
- File-based routing
- API routes
- Image optimization
- Built on React

**When to use**: You need SSR/SSG with React

#### Vue
**Use for**: Simpler alternative to React

**Strengths**:
- Easier learning curve
- Great documentation
- Less boilerplate than React

**When to use**: Team prefers Vue over React

#### Plain HTML/CSS/JS
**Use for**: Simple sites, landing pages, documentation

**Strengths**:
- No build step
- Fast, simple
- No dependencies

**When to use**: Project doesn't need framework complexity

### Backend

#### Express (Node.js)
**Use for**: RESTful APIs, web servers

**Strengths**:
- Minimal, unopinionated
- Huge middleware ecosystem
- Widely used

**Recommended with**:
- TypeScript
- Helmet for security
- Morgan for logging

#### FastAPI (Python)
**Use for**: Python APIs with auto-generated docs

**Strengths**:
- Fast (async support)
- Auto-generates OpenAPI docs
- Type validation with Pydantic

**When to use**: Building APIs in Python

#### Gin (Go)
**Use for**: High-performance APIs in Go

**Strengths**:
- Very fast
- Minimal overhead
- Good routing

**When to use**: Performance-critical Go APIs

## Databases

### PostgreSQL
**Use for**: Most applications needing a relational DB

**Strengths**:
- ACID compliant
- Rich feature set (JSON, full-text search, PostGIS)
- Excellent performance
- Strong community

**When to use**: Default choice for relational data

### MongoDB
**Use for**: Document-oriented data, rapid prototyping

**Strengths**:
- Flexible schema
- Horizontal scaling
- Good for evolving data models

**When to use**: Truly need schema flexibility (not just to avoid migrations)

### Redis
**Use for**: Caching, sessions, pub/sub

**Strengths**:
- Extremely fast (in-memory)
- Simple key-value model
- Rich data types

**When to use**: Need caching or real-time features

### SQLite
**Use for**: Local storage, embedded databases, prototypes

**Strengths**:
- Zero configuration
- Single file
- Fast for reads

**When to use**: Local-first apps, dev/test, small projects

## Development Tools

### Version Control
**Git**: The standard. No alternatives needed.

**Platforms**:
- **GitHub**: Default choice (Actions, Copilot, community)
- **GitLab**: Self-hosted option, built-in CI/CD
- **Bitbucket**: If already using Atlassian stack

### Code Editors/IDEs

#### VS Code
**Best for**: TypeScript, JavaScript, Python, most languages

**Why**:
- Excellent TypeScript support
- Rich extension ecosystem
- Integrated terminal
- Git integration
- Free

#### JetBrains IDEs
**Best for**: Java, Kotlin, Python (PyCharm), Go (GoLand)

**Why**:
- Deep language intelligence
- Powerful refactoring
- Database tools

**Trade-off**: Paid (except Community editions)

### Package Managers

| Language | Recommended | Alternative |
|----------|------------|-------------|
| JavaScript | npm, pnpm | yarn |
| Python | poetry | pip, pipenv |
| Go | built-in | - |
| Rust | cargo | - |
| Ruby | bundler | - |

### Testing

| Language | Unit Testing | E2E Testing |
|----------|--------------|-------------|
| JavaScript | Jest, Vitest | Playwright, Cypress |
| TypeScript | Jest, Vitest | Playwright |
| Python | pytest | Selenium |
| Go | built-in testing | - |

### CI/CD

#### GitHub Actions
**Use for**: GitHub-hosted projects

**Strengths**:
- Native GitHub integration
- Free for public repos
- Good free tier for private
- Easy YAML config

#### GitLab CI
**Use for**: GitLab-hosted projects

**Strengths**:
- Built into GitLab
- Powerful pipeline features

#### CircleCI / Travis CI
**Use for**: Multi-platform CI

**Trade-off**: Less integrated than platform-native options

## Deployment Platforms

### Vercel
**Best for**: Next.js apps, static sites, serverless

**Strengths**:
- Zero-config Next.js deployment
- Global CDN
- Preview deployments
- Generous free tier

### Netlify
**Best for**: Static sites, JAMstack apps

**Strengths**:
- Simple deployments
- Forms handling
- Identity/auth
- Free tier

### Railway / Render
**Best for**: Full-stack apps, databases

**Strengths**:
- Simple deployment
- Built-in databases
- Good free tier

### AWS / GCP / Azure
**Best for**: Enterprise, complex infrastructure

**Strengths**:
- Full control
- Every service imaginable
- Scalability

**Trade-offs**:
- Complexity
- Cost can be unpredictable
- Steep learning curve

### Docker + VPS
**Best for**: Custom deployments, cost control

**Strengths**:
- Full control
- Predictable costs
- Learn infrastructure

**Trade-offs**:
- More DevOps work
- You manage everything

## Monitoring & Logging

### Development
- **Logging**: console.log, pino, winston
- **Debugging**: VS Code debugger, Chrome DevTools

### Production
- **Error tracking**: Sentry (cross-platform)
- **Logging**: Datadog, CloudWatch, LogRocket
- **Uptime**: UptimeRobot, Pingdom
- **Analytics**: Plausible, Fathom (privacy-friendly)

## Decision Framework

When choosing tools, ask:

1. **Is this solving a real problem?** (Not just "nice to have")
2. **Is it worth the added complexity?** (Every tool has overhead)
3. **Can the team learn it quickly?** (Productivity matters)
4. **Is it maintained and supported?** (Check GitHub activity)
5. **What's the migration path?** (Can you switch later if needed?)

## Common Anti-Patterns

### ❌ Resume-Driven Development
Adding tools to learn them, not because they're best for the project.

### ❌ Not Invented Here
Building custom solutions when mature libraries exist.

### ❌ Analysis Paralysis
Spending weeks evaluating tools instead of building.

### ❌ Over-Engineering
Using microservices for a CRUD app, Kubernetes for a single server.

### ❌ Under-Engineering
Ignoring scalability, security, or performance until it's too late.

## Recommendations by Project Type

### Personal Project / MVP
**Keep it simple**:
- Language you know best
- Minimal frameworks
- Free-tier hosting
- SQLite or serverless DB

### Startup / Small Team
**Optimize for speed**:
- Proven tech stack
- Managed services (less DevOps)
- Monitoring from day one
- PostgreSQL

### Enterprise / Scale
**Optimize for reliability**:
- Battle-tested technologies
- Comprehensive monitoring
- Strong typing (TypeScript/Go/Rust)
- Scalable database (PostgreSQL with read replicas)

## Keep Learning

Technology changes. What's recommended today may not be tomorrow.

**Stay updated**:
- Follow language/framework official blogs
- Read postmortems (learn from failures)
- Experiment with new tools in side projects
- But don't rewrite production code for fun

**But remember**: Boring, stable technology wins most of the time.
