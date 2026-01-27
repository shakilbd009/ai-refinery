# ADR-013: Container-Based Agent Isolation

## Status
Accepted

## Context
The Coding Agent needs to execute code for validation and testing. Options for isolation:
1. No isolation - run in backend process (dangerous)
2. Language-level sandbox - use language features (limited)
3. Container isolation - run in isolated containers
4. VM isolation - full virtual machines (heavy)

## Decision
Use **container-based isolation** with gVisor for code execution:

Each task gets a fresh container:
```
Task starts → Fresh container created
           → Code copied in
           → Execution runs
           → Results captured
           → Container destroyed
```

Container restrictions:
| Restriction | Enforcement |
|-------------|-------------|
| No network | Network namespace disabled |
| No host filesystem | No volume mounts |
| Ephemeral storage | tmpfs only, wiped on destroy |
| No privileged ops | Drop all capabilities, no root |
| Read-only base image | Cannot modify runtime |

Technology: **gVisor (runsc)** for additional syscall filtering.

## Consequences

### Positive
- Strong isolation from host and other containers
- No persistent state between tasks
- Cannot exfiltrate data via network
- Syscall filtering adds defense layer

### Negative
- Container startup adds latency (~2 sec)
- More infrastructure complexity
- Resource overhead per execution

### Mitigations
- Container pre-warming for faster startup
- Resource limits prevent runaway containers
- gVisor provides good security/performance balance
