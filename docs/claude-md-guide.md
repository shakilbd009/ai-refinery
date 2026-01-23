# claude.md Writing Guide

## Purpose

The `claude.md` file is Claude's primary instruction manual for your project. It should provide clear context about what the project does, how it's structured, and how to work with it effectively.

## Structure

### 1. Project Overview (Required)
- What the project does (1-2 sentences)
- Core purpose and use case
- Key technologies/frameworks used

### 2. Architecture (Required)
- High-level architecture overview
- Key components and their relationships
- Important patterns or conventions used
- Where things live (folder structure highlights)

### 3. Development Guidelines (Required)
- How to run the project locally
- How to run tests
- Code style and conventions specific to this project
- Common workflows (how to add a feature, fix a bug, etc.)

### 4. Domain Context (If Applicable)
- Business logic explanation
- Domain-specific terminology
- Key concepts Claude should understand

### 5. Gotchas and Constraints (If Applicable)
- Known issues or limitations
- Things that might be confusing
- Important dos and don'ts

## Tone and Style

**DO**:
- Be direct and concise
- Use active voice
- Focus on what's unique to YOUR project
- Include practical examples
- Explain the "why" behind non-obvious decisions

**DON'T**:
- Include generic advice Claude already knows
- Write a tutorial on the framework/language
- Include setup instructions better suited for README
- Use overly formal or verbose language
- Add fluff or unnecessary superlatives

## Examples

### Good Example
```markdown
# Task Manager API

A REST API for task management built with Node.js/Express and PostgreSQL.

## Architecture

- `src/routes/`: API endpoints (RESTful design)
- `src/models/`: Sequelize models (one file per table)
- `src/services/`: Business logic (keep controllers thin)
- `src/middleware/`: Auth, validation, error handling

Key pattern: Service layer handles all business logic. Controllers just map HTTP requests to service calls.

## Development

Run locally: `npm run dev`
Run tests: `npm test`
Database migrations: `npm run migrate`

## Conventions

- All IDs are UUIDs (not auto-incrementing integers)
- Use async/await (no callbacks or raw promises)
- Validation happens in middleware, not in routes or services
- All timestamps are UTC

## Authentication

Uses JWT tokens. The `requireAuth` middleware extracts the user from the token and attaches it to `req.user`. All protected routes should use this middleware.
```

### Bad Example
```markdown
# Task Manager API

This is an amazing task management system that revolutionizes how teams collaborate! Built with cutting-edge technologies to provide the best experience.

## Introduction

Node.js is a JavaScript runtime built on Chrome's V8 engine. Express is a web framework for Node.js. PostgreSQL is a relational database...

[continues with generic explanations of technologies]

## Getting Started

First, make sure you have Node.js installed. Then clone the repository. Then run npm install...

[continues with generic setup instructions better suited for README]
```

## Tips

1. **Assume Claude knows the basics**: Don't explain what Express is or how REST works
2. **Focus on your specific project**: What makes YOUR codebase unique?
3. **Be practical**: Include the specific commands and patterns developers actually use
4. **Keep it updated**: When you make architectural changes, update claude.md
5. **Think "onboarding"**: What would a new developer (or Claude) need to know to be effective immediately?

## Length

Aim for 200-500 lines. Long enough to be comprehensive, short enough to remain maintainable. If it's getting longer, you might be including too much detail better suited for other documentation.
