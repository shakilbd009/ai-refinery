# Threat Model

## Assets to Protect

| Asset | Description |
|-------|-------------|
| Customer code | Generated code artifacts |
| SME knowledge | Organization's proprietary standards |
| Project data | Requirements, architecture, conversations |
| User credentials | Authentication tokens, sessions |
| System integrity | Platform availability and correctness |

---

## Threat Actors

| Actor | Motivation | Capabilities |
|-------|------------|--------------|
| Malicious user | Data theft, sabotage | Authenticated access, prompt crafting |
| External attacker | Data breach, service disruption | Network access, common exploits |
| Compromised agent | Unintended actions | LLM outputs, tool access |
| Malicious insider | Data exfiltration | Admin access |

---

## Attack Vectors & Mitigations

### Prompt Injection

**Threat**: User crafts prompts to make agent bypass restrictions.

**Mitigations**:
- Tools enforced at backend, not prompt level
- Agent tool access is read-only
- All outputs go through user approval
- Sandbox has no network access

### Cross-Tenant Data Access

**Threat**: User accesses another organization's data.

**Mitigations**:
- Hard org boundary at data layer
- Every query scoped to user's org
- No API endpoint accepts cross-org resource IDs
- Defense in depth (API + data layer checks)

### Cross-Project Data Access

**Threat**: Agent or user accesses unauthorized project.

**Mitigations**:
- Project membership required for access
- Agents cannot query other projects
- No "similar project" cross-references

### Code Execution Escape

**Threat**: Malicious code escapes sandbox.

**Mitigations**:
- gVisor syscall filtering
- No network access in containers
- Ephemeral storage only
- No privileged operations
- Resource limits prevent DoS

### Data Exfiltration via Agent

**Threat**: Agent leaks data through LLM responses.

**Mitigations**:
- Need-to-know data retrieval (minimal context)
- No network access from sandbox
- All outputs visible to user before persistence
- Audit logging of all agent actions

### Privilege Escalation

**Threat**: User gains unauthorized capabilities.

**Mitigations**:
- Role-based access control at every endpoint
- Permission checks at API and data layers
- Admin actions logged for audit
- No self-elevation of roles

### Security Review Bypass

**Threat**: User ships code without security review.

**Mitigations**:
- Security Review is mandatory phase
- No override path for security issues
- Phase transition requires all items approved
- Security findings must be resolved

---

## Security Boundaries

```
┌─────────────────────────────────────────────────┐
│                 Organization A                   │
│  ┌─────────────┐  ┌─────────────┐               │
│  │  Project 1  │  │  Project 2  │  (isolated)   │
│  └─────────────┘  └─────────────┘               │
│                                                  │
│  ┌─────────────────────────────────┐            │
│  │        SME Knowledge            │            │
│  └─────────────────────────────────┘            │
└─────────────────────────────────────────────────┘
         ║ HARD BOUNDARY (no data crosses)
┌─────────────────────────────────────────────────┐
│                 Organization B                   │
└─────────────────────────────────────────────────┘
```

---

## Residual Risks

| Risk | Likelihood | Impact | Acceptance |
|------|------------|--------|------------|
| LLM hallucination in security review | Medium | Medium | Mitigated by human approval |
| Novel attack on gVisor | Low | High | Accept; monitor advisories |
| Admin abuse | Low | High | Mitigated by audit logging |
