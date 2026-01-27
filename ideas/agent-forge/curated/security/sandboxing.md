# Agent Sandboxing

## Execution Models

### Hybrid Approach

| Agent | Execution Model | Rationale |
|-------|-----------------|-----------|
| Requirements | API-only | No code to run; pure conversation |
| Architecture | API-only | Designs systems; no execution needed |
| Coding | API + Sandbox | Needs validation and testing |
| Security | API-only | Reviews code; no execution needed |

### API-Only Execution

Requirements, Architecture, and Security agents run within the backend:
- LLM calls with tool access
- Tools are predefined backend functions
- No user-provided or agent-generated code executes
- Runs in shared backend processes

### Sandbox Execution

Coding Agent has isolated execution environment:
- Full runtimes: Node.js, Python, Go (configurable)
- Can run tests, execute scripts, build projects
- **No network access**
- **Ephemeral filesystem** - wiped after each task

---

## Data Access & Isolation

### Need-to-Know Retrieval

Agents query for what they need, not everything:
```
Agent needs requirements → calls get_requirements(filter)
                       → only matching items enter context
```

### Project Isolation

**Strict boundary**: Agents can only access current project data.
- No cross-project queries
- No "similar project" retrieval
- Each project completely isolated

---

## Container Sandbox

### Isolation Model

Each code execution gets a fresh container:
```
Task starts → Fresh container created
           → Code copied in
           → Execution runs
           → Results captured
           → Container destroyed
```

No state persists. No container reuse.

### Container Restrictions

| Restriction | Enforcement |
|-------------|-------------|
| No network | Network namespace disabled |
| No host filesystem | No volume mounts |
| Ephemeral storage | tmpfs only |
| No privileged ops | Drop all capabilities, no root |
| Read-only base | Cannot modify runtime |

### Technology

**gVisor (runsc)** for container runtime - additional syscall filtering layer.

---

## Resource Limits

### Default Limits

| Resource | Default | Purpose |
|----------|---------|---------|
| Memory | 512 MB | Prevents exhaustion |
| CPU | 1 core | Fair scheduling |
| Timeout | 60 seconds | Catches infinite loops |
| Disk | 100 MB | Ephemeral storage cap |
| Processes | 50 | Prevents fork bombs |

### Graceful Handling

| Threshold | Action |
|-----------|--------|
| 80% of limit | Warning signal to agent |
| 80-100% | Agent attempts graceful wrap-up |
| 100% | Hard termination |

Agent response to warning: stop spawning processes, capture partial results, return with `partial_completion` status.

---

## Tool Access Control

Admins can enable/disable tools at org level:
- Air-gapped: Disable `fetch_tech_docs`, `fetch_library_docs`
- No code execution: Disable `execute_in_sandbox`

Tools enforced at backend, not prompt. Agents cannot bypass via prompt injection.

---

## Related ADRs

- [ADR-013: Container-Based Agent Isolation](../decisions/ADR-013-container-isolation.md)
