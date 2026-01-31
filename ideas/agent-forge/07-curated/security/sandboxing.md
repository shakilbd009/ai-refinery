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

---

## Defense-in-Depth

Multiple security layers ensure that a breach of one layer doesn't compromise the system.

### Layer 1: gVisor Syscall Filtering

gVisor (runsc) provides a user-space kernel that intercepts and filters syscalls:

```yaml
# gVisor configuration
runsc:
  platform: ptrace  # or kvm for better performance
  network: none
  rootless: true
```

**Blocked syscalls include:**
- `ptrace` - Debugging/inspection of other processes
- `mount` - Filesystem manipulation
- `setuid`/`setgid` - Privilege escalation
- `reboot` - System control
- `syslog` - Kernel log access

### Layer 2: AppArmor Profiles

AppArmor provides mandatory access control at the kernel level:

```
# /etc/apparmor.d/agentforge-sandbox
profile agentforge-sandbox flags=(attach_disconnected,mediate_deleted) {
  # Deny all network access
  deny network,

  # Deny raw socket access
  deny network raw,

  # Allow reading from specific paths only
  /usr/lib/** r,
  /lib/** r,
  /etc/passwd r,
  /etc/group r,

  # Allow execution of interpreters
  /usr/bin/node ix,
  /usr/bin/python3 ix,
  /usr/bin/go ix,

  # Deny writing outside workspace
  deny /home/** w,
  deny /root/** w,
  deny /etc/** w,

  # Allow workspace operations
  /workspace/** rw,
  /tmp/** rw,

  # Deny capability acquisition
  deny capability,

  # Deny mounting
  deny mount,
}
```

### Layer 3: Seccomp Profiles

Seccomp filters syscalls at a finer granularity:

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [
    {
      "names": [
        "read", "write", "open", "close", "stat", "fstat",
        "mmap", "mprotect", "munmap", "brk",
        "access", "pipe", "dup", "dup2",
        "clone", "fork", "vfork", "execve",
        "exit", "wait4", "kill", "getpid",
        "socket", "connect", "accept", "sendto", "recvfrom"
      ],
      "action": "SCMP_ACT_ALLOW"
    },
    {
      "names": ["ptrace", "mount", "umount", "reboot", "syslog"],
      "action": "SCMP_ACT_ERRNO",
      "errnoRet": 1
    }
  ]
}
```

### Layer 4: Network Policies

Network namespace isolation prevents all network access:

```yaml
# Kubernetes NetworkPolicy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: sandbox-deny-all
spec:
  podSelector:
    matchLabels:
      app: sandbox
  policyTypes:
    - Ingress
    - Egress
  # No ingress or egress rules = deny all
```

### Layer 5: Resource Quotas

Prevent resource exhaustion attacks:

```yaml
# Container resource limits
resources:
  limits:
    memory: "512Mi"
    cpu: "1"
    ephemeral-storage: "100Mi"
  requests:
    memory: "256Mi"
    cpu: "0.5"
```

### Layer 6: Runtime Monitoring

Detect anomalous behavior during execution:

```go
type SandboxMonitor struct {
    metricsCollector *prometheus.Registry
    alerter          Alerter
}

func (sm *SandboxMonitor) MonitorExecution(ctx context.Context, execID string) {
    ticker := time.NewTicker(time.Second)
    defer ticker.Stop()

    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            metrics := sm.collectMetrics(execID)

            // Detect anomalies
            if metrics.SyscallRate > 1000 {
                sm.alerter.Warn("High syscall rate", execID)
            }
            if metrics.MemoryDelta > 100*1024*1024 { // 100MB spike
                sm.alerter.Warn("Memory spike", execID)
            }
            if metrics.FileDescriptors > 100 {
                sm.alerter.Warn("Many file descriptors", execID)
            }
        }
    }
}
```

---

## Security Audit Logging

All sandbox operations are logged for forensic analysis:

```go
type SandboxAuditLog struct {
    ExecutionID   string    `json:"executionId"`
    ProjectID     string    `json:"projectId"`
    Action        string    `json:"action"` // start, exec, file_write, terminate
    Details       any       `json:"details"`
    Timestamp     time.Time `json:"timestamp"`
    SecurityLevel string    `json:"securityLevel"` // info, warning, alert
}
```

---

## Sandbox Escape Prevention

gVisor provides strong isolation, but no single technology is sufficient. We implement defense-in-depth with multiple independent layers.

### Additional Escape Prevention Layers

| Layer | Technology | Protects Against |
|-------|------------|------------------|
| Primary | gVisor (runsc) | Kernel exploits, syscall attacks |
| Secondary | AppArmor | File access, capability abuse |
| Tertiary | Seccomp | Syscall filtering |
| Network | NetworkPolicy | Network-based escapes |
| Host | Read-only root FS | Persistence attacks |
| Monitoring | Falco/Sysdig | Real-time anomaly detection |

### Host Hardening

```yaml
# Kubernetes pod security context
securityContext:
  runAsNonRoot: true
  runAsUser: 65534  # nobody
  runAsGroup: 65534
  fsGroup: 65534
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  seccompProfile:
    type: RuntimeDefault
```

### Anomaly Detection (Falco)

Real-time detection of escape attempts:

```yaml
# /etc/falco/rules.d/agentforge.yaml
- rule: Sandbox Escape Attempt
  desc: Detect potential sandbox escape attempts
  condition: >
    container.name startswith "sandbox-" and
    (
      evt.type in (ptrace, mount, umount, setns, unshare) or
      (evt.type = open and fd.name startswith "/proc/") or
      (evt.type = execve and proc.name in (bash, sh, curl, wget, nc)) or
      (evt.type = socket and evt.arg.domain = AF_INET)
    )
  output: "Sandbox escape attempt (user=%user.name container=%container.name evt=%evt.type)"
  priority: CRITICAL
  tags: [security, container, sandbox]

- rule: Sandbox Resource Abuse
  desc: Detect resource exhaustion attempts
  condition: >
    container.name startswith "sandbox-" and
    (
      proc.pcmdline contains "fork" or
      proc.nthreads > 100 or
      container.memory_usage > 500000000  # 500MB
    )
  output: "Sandbox resource abuse (container=%container.name threads=%proc.nthreads)"
  priority: WARNING
  tags: [security, container, sandbox]
```

### Escape Response

Automated response to detected escape attempts:

```go
type EscapeDetector struct {
    alerter     Alerter
    killer      ContainerKiller
    forensics   ForensicsCollector
}

func (ed *EscapeDetector) OnEscapeAttempt(ctx context.Context, alert FalcoAlert) error {
    // 1. Immediately kill the container
    if err := ed.killer.Kill(ctx, alert.ContainerID); err != nil {
        // If kill fails, escalate to host-level action
        ed.alerter.Critical("Container kill failed - manual intervention required")
    }

    // 2. Collect forensics before cleanup
    forensics, err := ed.forensics.Collect(ctx, alert.ContainerID)
    if err != nil {
        ed.alerter.Warn("Forensics collection failed", "error", err)
    }

    // 3. Alert security team
    ed.alerter.Critical("Sandbox escape attempt detected", map[string]interface{}{
        "containerID": alert.ContainerID,
        "projectID":   alert.Labels["projectId"],
        "eventType":   alert.EventType,
        "forensics":   forensics,
    })

    // 4. Quarantine the project for review
    return ed.quarantineProject(ctx, alert.Labels["projectId"])
}
```

---

## Security Audit Requirements

The sandbox implementation requires regular security audits to validate effectiveness.

### Pre-Launch Requirements

| Requirement | Status | Validator |
|-------------|--------|-----------|
| Third-party penetration test | Required | External security firm |
| gVisor configuration review | Required | Container security expert |
| Seccomp profile audit | Required | Security team |
| AppArmor policy review | Required | Security team |
| Escape attempt testing | Required | Red team exercise |
| Supply chain audit | Required | Container image scanning |

### Ongoing Requirements

| Activity | Frequency | Owner |
|----------|-----------|-------|
| Automated security scanning | Daily | CI/CD pipeline |
| Vulnerability patching | Within 48h of CVE | DevOps |
| gVisor version updates | Monthly | Platform team |
| Penetration testing | Quarterly | External firm |
| Red team exercises | Bi-annually | Security team |
| Configuration drift detection | Continuous | Policy-as-code |

### Penetration Test Scope

```markdown
## Sandbox Penetration Test Requirements

### In Scope
- Container escape attempts (kernel exploits, syscall bypass)
- Resource exhaustion attacks (fork bombs, memory exhaustion)
- Network isolation bypass attempts
- File system escape (symlink attacks, path traversal)
- Privilege escalation within container
- Side-channel attacks between containers
- Time-of-check-to-time-of-use (TOCTOU) attacks

### Success Criteria
- No container-to-host escape achieved
- No container-to-container data access
- Resource limits effectively enforced
- All escape attempts detected by monitoring

### Deliverables
- Detailed findings report
- Proof-of-concept for any vulnerabilities
- Remediation recommendations
- Verification of fixes
```

### Continuous Verification

```go
// Automated security test suite run in CI/CD
func TestSandboxSecurity(t *testing.T) {
    tests := []struct {
        name     string
        payload  string
        expected string
    }{
        {
            name:     "network access blocked",
            payload:  "curl -s https://example.com",
            expected: "network unreachable",
        },
        {
            name:     "host filesystem inaccessible",
            payload:  "cat /host/etc/passwd",
            expected: "permission denied",
        },
        {
            name:     "ptrace blocked",
            payload:  "strace ls",
            expected: "operation not permitted",
        },
        {
            name:     "mount blocked",
            payload:  "mount -t proc proc /mnt",
            expected: "operation not permitted",
        },
        {
            name:     "fork bomb contained",
            payload:  ":(){ :|:& };:",
            expected: "process limit exceeded",
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := runInSandbox(tt.payload)
            assert.Contains(t, result.Stderr, tt.expected)
            assert.Equal(t, result.ExitCode, 1)
        })
    }
}
```

---

## Related ADRs

- [ADR-013: Container-Based Agent Isolation](../decisions/ADR-013-container-isolation.md)
