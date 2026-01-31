# Implementation Plans Overview

This folder contains implementation plans for building AgentForge. Each subfolder contains task-by-task implementation guides.

## Structure

```
implementation/
├── overview.md                    # This file
├── agent-framework/               # Agent execution framework
│   ├── 00-overview.md
│   ├── 01-agent-interface.md      # Tasks 1-3
│   ├── 02-llm-provider.md         # Tasks 4-7
│   ├── 03-executor.md             # Tasks 8-11
│   ├── 04-prompt-memory.md        # Tasks 12-15
│   ├── 05-agents.md               # Tasks 16-23
│   └── 06-tools-api.md            # Tasks 24-30
├── workflow-orchestration/        # Workflow engine
│   ├── 00-overview.md
│   ├── 01-domain-models.md        # Tasks 1-5
│   ├── 02-repository.md           # Tasks 6-9
│   ├── 03-service.md              # Tasks 10-13
│   └── 04-api-handlers.md         # Tasks 14-17
├── sme-knowledge/                 # SME Knowledge Store
│   ├── 00-overview.md
│   ├── 01-setup-router.md         # Tasks 1-2
│   ├── 02-domain-repository.md    # Tasks 3-5
│   └── 03-service-api.md          # Tasks 6-10
├── security-permissions/          # Existing split folder (moved)
├── security-review/               # Existing split folder (moved)
├── security-sandbox/              # Existing split folder (moved)
└── ux/                            # Existing split folder (moved)
```

## Implementation Approach

Each plan follows TDD (Test-Driven Development):
1. Write failing test
2. Run test to verify failure
3. Write minimal implementation
4. Run test to verify pass
5. Commit

## Tech Stack

- **Backend:** Go 1.21+, Chi router
- **Database:** Firestore (with in-memory repository for testing)
- **LLM:** Anthropic Claude SDK (interface-based for multi-provider)
- **Testing:** Go standard library testing

## Execution

Use `superpowers:executing-plans` skill to implement task-by-task with review checkpoints.
