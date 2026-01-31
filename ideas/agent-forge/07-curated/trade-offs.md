# Design Trade-offs

Consolidated design rationale and alternatives considered across all components.

---

## Agent Framework

| Decision | Choice | Alternative Considered | Trade-off Accepted |
|----------|--------|------------------------|-------------------|
| Tool access | Read-only | Read-write with approval queue | Limited autonomy for safety |
| Output format | Structured JSON | Free-form markdown | More complex parsing for validation capability |
| Memory model | Summarization | Full history / RAG-only | Summarization quality for context fit |
| Error handling | Tiered response | Always escalate / Always retry | Complexity for appropriate user involvement |
| Self-validation | Self-critique + LLM-judge | Single validation pass | Extra LLM calls for better quality |

### Why Read-Only Agents
Agents that can write create risk of unintended modifications. Read-only access with approval gates keeps users in control. The trade-off is more round-trips for changes, but safety and trust are prioritized.

### Why Summarization
Full conversation history exceeds context limits. RAG-only loses conversational flow. Summarization preserves meaning while managing tokens. Risk: subtle details may be lost.

---

## Workflow Engine

| Decision | Choice | Alternative Considered | Trade-off Accepted |
|----------|--------|------------------------|-------------------|
| Workflow structure | Fixed linear pipeline | Flexible/customizable | No flexibility for predictability |
| Phase transitions | Automatic on approval | Manual "proceed" step | No pause between phases for frictionless flow |
| Escalations | Blocking | Non-blocking queue | Workflow stops for no unresolved issues |
| Change handling | In-place with auto re-work | Manual re-work / version branches | Complexity for immediate consistency |
| Recovery model | Event sourcing + checkpoints | Current state only | Storage overhead for full audit trail |

### Why Fixed Pipeline
Flexible workflows create decision fatigue and inconsistent projects. Fixed sequence ensures every project follows proven steps. Trade-off: cannot skip phases even when simple.

### Why Blocking Escalations
Non-blocking escalations let violations slip through. Blocking ensures conscious user decision on every constraint conflict. Trade-off: single escalation can halt progress.

---

## SME Knowledge

| Decision | Choice | Alternative Considered | Trade-off Accepted |
|----------|--------|------------------------|-------------------|
| Knowledge scope | Organization-wide | Project-level granularity | Simpler management for less flexibility |
| Input method | Structured forms | Document upload / free-form | Less flexibility for quality control |
| Constraint enforcement | LLM-as-judge | Static analysis / rule engine | Non-deterministic for flexibility |
| Agent binding | Agent-specific knowledge | Shared pool / inheritance | Possible duplication for clear ownership |
| Versioning | Snapshot on workflow start | Live updates | In-flight inconsistency avoided |

### Why LLM-as-Judge
Static analysis only works for code rules. Rule engines require formal language SMEs won't learn. LLM evaluation handles natural language constraints. Trade-off: probabilistic, not deterministic.

### Why Agent-Partitioned
Shared knowledge creates confusion about what applies where. Inheritance adds complexity. Partitioned knowledge has clear ownership. Trade-off: same rule may need entry for multiple agents.

---

## Security

| Decision | Choice | Alternative Considered | Trade-off Accepted |
|----------|--------|------------------------|-------------------|
| Project access | Private by default | Public within org | Admin overhead for confidentiality |
| Project roles | 4 levels | 2 levels (Editor/Viewer) | Complexity for granular control |
| Admin power | Full access with logging | No override / silent access | Trust required for governance needs |
| Execution model | Hybrid (API + sandbox) | All sandbox / all API | Complexity for right-sized isolation |
| Sandbox isolation | Container (gVisor) | VMs / language sandbox | Infrastructure for security/efficiency balance |
| Security review | Mandatory, no override | Optional / override allowed | No flexibility for no security debt |

### Why No Security Override
Other constraint violations can be overridden with reason. Security issues cannot - this enforces security discipline. Trade-off: users cannot ship code they believe is safe without fixing flagged issues.

### Why Container vs VM
VMs provide stronger isolation but significant overhead. Language sandboxes are too weak. Containers with gVisor balance security and efficiency. Trade-off: not as isolated as VMs.

---

## User Experience

| Decision | Choice | Alternative Considered | Trade-off Accepted |
|----------|--------|------------------------|-------------------|
| User types | Single adaptive interface | Separate tech/non-tech modes | Learning complexity for unified experience |
| Home priority | New project creation | Dashboard / recent activity | Less visibility for action-oriented |
| Project start | Minimal wizard | Detailed forms | Less upfront info for low friction |
| Artifact format | Interactive checklist | Document review | More UI complexity for granular control |
| Attention model | Inbox aggregation | Per-project notifications | Central place vs contextual |

### Why Single Interface
Mode switching creates friction and "wrong mode" errors. Progressive disclosure serves both audiences. Trade-off: may feel oversimplified to power users or overwhelming to novices initially.

### Why Inbox Model
Checking each project for pending items doesn't scale. Inbox aggregates all action items. Trade-off: removes context from project, may feel disconnected.

---

## Summary: Key Trade-offs

| Area | We Prioritized | Over |
|------|---------------|------|
| Agent | Safety, user control | Agent autonomy |
| Workflow | Predictability, consistency | Flexibility |
| SME Knowledge | Simplicity, clear ownership | Fine-grained control |
| Security | Defense in depth, no exceptions | Convenience |
| UX | Low friction, unified experience | Customization |
