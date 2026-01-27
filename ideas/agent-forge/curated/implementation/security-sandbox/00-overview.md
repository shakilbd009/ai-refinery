# Security Sandbox Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement container-based code execution sandbox for the Coding Agent with resource limits, network isolation, and admin-configurable settings.

**Architecture:** Create a container abstraction layer (similar to LLM provider pattern), integrate with Docker/gVisor for isolation, implement resource limit enforcement via cgroups, and expose sandbox execution through the existing tool registry. The sandbox is ephemeral—fresh container per task, destroyed after execution.

**Tech Stack:** Go, Docker SDK (github.com/docker/docker), gVisor (optional for production), existing tool registry and agent executor patterns.

---

## Plan Structure

This implementation is split into multiple focused plans:

| Part | File | Description |
|------|------|-------------|
| 1 | [01-data-models.md](./01-data-models.md) | Domain models: OrgSandboxSettings, SandboxExecution |
| 2 | [02-repository.md](./02-repository.md) | Repository interface and in-memory implementation |
| 3 | [03-container-runtime.md](./03-container-runtime.md) | Docker runtime abstraction with security restrictions |
| 4 | [04-sandbox-service.md](./04-sandbox-service.md) | Sandbox service and execute_in_sandbox tool |
| 5 | [05-api-integration.md](./05-api-integration.md) | API endpoints and executor wiring |
| 6 | [06-resource-monitoring.md](./06-resource-monitoring.md) | 80% warning threshold and graceful degradation |

---

## Implementation Order

Execute plans in order (1 → 6). Each plan builds on the previous:

```
01-data-models (foundation)
    ↓
02-repository (data access)
    ↓
03-container-runtime (execution backend)
    ↓
04-sandbox-service (business logic + tool)
    ↓
05-api-integration (HTTP endpoints + executor)
    ↓
06-resource-monitoring (graceful limits)
```

---

## Design Reference

Source design document: `docs/plans/security-sandboxing-design.md`

### Key Design Decisions

- **Hybrid execution**: API-only for most agents, sandbox for Coding Agent only
- **No network access**: Containers cannot make external calls
- **Ephemeral filesystem**: Wiped after each task
- **Admin-configurable limits**: Memory, CPU, timeout, disk, processes
- **Graceful degradation**: Warn at 80%, kill at 100%
- **Tool access control**: Admin can disable sandbox per org

---

## Files to Create (Summary)

```
internal/
├── domain/
│   └── sandbox.go              # Part 1
├── repository/
│   ├── sandbox_repository.go   # Part 2
│   └── memory/
│       └── sandbox_repository.go # Part 2
├── sandbox/
│   ├── runtime.go              # Part 3
│   └── docker_runtime.go       # Part 3
├── service/
│   └── sandbox_service.go      # Part 4
├── tools/
│   └── sandbox.go              # Part 4
└── api/
    └── handlers/
        └── sandbox_handler.go  # Part 5
```

---

## Testing Strategy

- TDD approach: Write failing test → implement → verify pass
- Repository tests: CRUD operations, org isolation
- Runtime tests: Mock mode for CI, real Docker for integration
- Service tests: Business logic, disabled tool handling
- Handler tests: HTTP request/response, validation
- Executor tests: Tool invocation through agent pipeline

---

## Estimated Task Count

- Part 1: 3 tasks (data models)
- Part 2: 4 tasks (repository)
- Part 3: 4 tasks (container runtime)
- Part 4: 5 tasks (service + tool)
- Part 5: 5 tasks (API + executor)
- Part 6: 3 tasks (resource monitoring)

**Total: ~24 tasks**
