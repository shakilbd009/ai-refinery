# Architecture Decision Records

Index of all architectural decisions for AgentForge.

## Summary

| ADR | Title | Status | Category |
|-----|-------|--------|----------|
| [001](./ADR-001-read-only-agent-tools.md) | Read-Only Agent Tool Access | Accepted | Agent Framework |
| [002](./ADR-002-four-layer-prompts.md) | Four-Layer Prompt Composition | Accepted | Agent Framework |
| [003](./ADR-003-conversation-summarization.md) | Conversation Summarization for Memory | Accepted | Agent Framework |
| [004](./ADR-004-tiered-error-response.md) | Tiered Error Response Model | Accepted | Agent Framework |
| [005](./ADR-005-self-critique-validation.md) | Self-Critique Before Validation | Accepted | Agent Framework |
| [006](./ADR-006-fixed-linear-pipeline.md) | Fixed Linear Pipeline | Accepted | Workflow |
| [007](./ADR-007-automatic-phase-transitions.md) | Automatic Phase Transitions | Accepted | Workflow |
| [008](./ADR-008-blocking-escalations.md) | Blocking Escalations | Accepted | Workflow |
| [009](./ADR-009-event-sourcing.md) | Event Sourcing for Audit Trail | Accepted | Workflow |
| [010](./ADR-010-private-by-default.md) | Private-by-Default Projects | Accepted | Security |
| [011](./ADR-011-four-level-project-roles.md) | Four-Level Project Roles | Accepted | Security |
| [012](./ADR-012-admin-override-logging.md) | Admin Project Override with Logging | Accepted | Security |
| [013](./ADR-013-container-isolation.md) | Container-Based Agent Isolation | Accepted | Security |
| [014](./ADR-014-llm-judge-validation.md) | LLM-Judge Constraint Validation | Accepted | SME Knowledge |
| [015](./ADR-015-agent-partitioned-knowledge.md) | Agent-Type Partitioned Knowledge | Accepted | SME Knowledge |
| [016](./ADR-016-inbox-centric-approval.md) | Inbox-Centric Approval Model | Accepted | User Experience |
| [017](./ADR-017-authentication-architecture.md) | Authentication Architecture | Accepted | Security |
| [018](./ADR-018-secrets-management.md) | Secrets Management | Accepted | Security |
| [019](./ADR-019-rate-limiting-strategy.md) | Rate Limiting Strategy | Accepted | Security |
| [020](./ADR-020-event-driven-decoupling.md) | Event-Driven Decoupling | Accepted | Architecture |
| [021](./ADR-021-llm-provider-resilience.md) | LLM Provider Resilience | Accepted | Architecture |
| [022](./ADR-022-cost-controls.md) | Cost Controls | Accepted | Architecture |

## By Category

### Agent Framework
- **ADR-001:** Agents have read-only tool access; all changes flow through user approval
- **ADR-002:** Prompts built in four layers: base + task + SME knowledge + conversation
- **ADR-003:** Older conversation turns summarized to manage context window
- **ADR-004:** Three-tier error handling: silent retry, graceful degradation, escalation
- **ADR-005:** Agents self-critique output before formal LLM-judge validation

### Workflow
- **ADR-006:** Fixed sequence: Requirements → Architecture → Code → Security Review
- **ADR-007:** Approval triggers automatic progression to next phase
- **ADR-008:** Constraint violations block workflow until user resolves
- **ADR-009:** All actions logged as immutable events for audit and recovery

### Security
- **ADR-010:** Projects require explicit membership; no default access
- **ADR-011:** Four project roles: Owner, Editor, Approver, Viewer
- **ADR-012:** Admins can access any project; all access logged for audit
- **ADR-013:** Code execution in isolated containers with no network access
- **ADR-017:** JWT auth via Firebase with MFA and session management
- **ADR-018:** Secrets stored in GCP Secret Manager with rotation
- **ADR-019:** Redis-based rate limiting with prompt injection defense

### Architecture
- **ADR-020:** Event bus decouples agents from workflow engine
- **ADR-021:** Multi-layer LLM resilience with circuit breaker
- **ADR-022:** Tiered budget controls with usage tracking

### SME Knowledge
- **ADR-014:** LLM-as-judge validates output against natural language constraints
- **ADR-015:** Each agent type has its own knowledge set; no inheritance

### User Experience
- **ADR-016:** Inbox aggregates all action items; approval-centric workflow

## Key Trade-offs

| Decision | Trade-off Accepted |
|----------|-------------------|
| Read-only agents | Limited autonomy vs safety and user control |
| Fixed pipeline | No flexibility vs predictability and simplicity |
| Blocking escalations | Slower progress vs no unresolved violations |
| Event sourcing | Storage overhead vs complete audit trail |
| Agent-partitioned knowledge | Duplication possible vs clear ownership |
