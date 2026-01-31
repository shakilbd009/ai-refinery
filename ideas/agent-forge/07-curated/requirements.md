# AgentForge - Functional Requirements

## Core Capabilities

### Agent System
- Agents execute tasks using tool-based reasoning with read-only data access
- Four agent types: Requirements, Architecture, Coding, Security
- Hybrid planning: structured plans that adapt reactively to unexpected situations
- Self-critique before presenting output to users
- Tiered error handling with graceful degradation

### Workflow Engine
- Fixed linear pipeline: Requirements → Architecture → Code → Security Review
- Automatic phase transitions on approval
- Parallel tasks within phases (user-initiated split)
- Blocking escalations for unresolved constraint violations
- Change requests trigger automatic downstream re-work

### SME Knowledge Store
- Organization-scoped knowledge (guidelines, templates, examples, constraints)
- Agent-type partitioned (each agent has its own knowledge set)
- LLM-judge validates output against constraints
- Auto-retry on violations (max 3 attempts) before escalation
- Version snapshots protect in-flight workflows

### Security
- Multi-tenant organization isolation
- Four org roles: Admin, SME Curator, Project Lead, Member
- Four project roles: Owner, Editor, Approver, Viewer
- Private-by-default projects with explicit membership
- Container sandboxing for code execution (no network, ephemeral storage)
- Mandatory security review phase before project completion

### User Experience
- Creation-first home screen
- Inbox-centric approval workflow
- Interactive checklists for artifact review
- Progressive disclosure (technical details collapsed by default)
- Visual representations for architecture (diagrams, ERDs)

---

## Functional Requirements by Component

### FR-AGENT: Agent Framework

| ID | Requirement |
|----|-------------|
| FR-AGENT-01 | Agents receive tasks and generate execution plans |
| FR-AGENT-02 | Agents call read-only tools to gather information |
| FR-AGENT-03 | Agents cannot write files, call external APIs, or execute code (except Coding Agent in sandbox) |
| FR-AGENT-04 | Agents emit progress updates visible in UI |
| FR-AGENT-05 | Agents self-critique output before presenting to users |
| FR-AGENT-06 | Prompt construction uses four layers: base + task + SME + conversation |
| FR-AGENT-07 | Conversation history summarizes older turns to manage context |
| FR-AGENT-08 | Phase handoffs use selective retrieval (agents query what they need) |

### FR-WORKFLOW: Workflow Engine

| ID | Requirement |
|----|-------------|
| FR-WORKFLOW-01 | Projects follow fixed phase sequence (no skipping/reordering) |
| FR-WORKFLOW-02 | Approval triggers automatic transition to next phase |
| FR-WORKFLOW-03 | All parallel tasks must complete before phase transition |
| FR-WORKFLOW-04 | Escalations block workflow until user resolves |
| FR-WORKFLOW-05 | Change requests show impact analysis before confirmation |
| FR-WORKFLOW-06 | Affected downstream items automatically re-work |
| FR-WORKFLOW-07 | Event sourcing provides complete audit trail |
| FR-WORKFLOW-08 | Checkpoints enable fast recovery from failures |

### FR-SME: SME Knowledge Store

| ID | Requirement |
|----|-------------|
| FR-SME-01 | Knowledge partitioned by organization and agent type |
| FR-SME-02 | Four knowledge types: guidelines, templates, examples, constraints |
| FR-SME-03 | Constraints validated by LLM-judge after generation |
| FR-SME-04 | Three retry attempts before escalation |
| FR-SME-05 | Workflow snapshots current knowledge version at start |
| FR-SME-06 | Admins can mark knowledge as mandatory (applies to all projects) |
| FR-SME-07 | Platform marketplace provides curated default knowledge |

### FR-SEC: Security

| ID | Requirement |
|----|-------------|
| FR-SEC-01 | Organizations are fully isolated tenants |
| FR-SEC-02 | No cross-project data access |
| FR-SEC-03 | Projects private by default, explicit membership required |
| FR-SEC-04 | Org admins can access any project (logged for audit) |
| FR-SEC-05 | Sandbox containers have no network access |
| FR-SEC-06 | Sandbox containers use ephemeral storage only |
| FR-SEC-07 | Resource limits configurable per org (memory, CPU, timeout) |
| FR-SEC-08 | Security Agent reviews all code before project completion |
| FR-SEC-09 | Security issues cannot be overridden (must fix or provide alternative) |

### FR-UX: User Experience

| ID | Requirement |
|----|-------------|
| FR-UX-01 | Home screen prioritizes new project creation |
| FR-UX-02 | Inbox aggregates all action items across projects |
| FR-UX-03 | Interactive checklist for artifact approval |
| FR-UX-04 | Rejection options: revise or explain |
| FR-UX-05 | Phase tabs show completion status |
| FR-UX-06 | Change requests available from any previous phase |
| FR-UX-07 | Visual diagrams for architecture artifacts |
| FR-UX-08 | Technical details collapsed by default |
| FR-UX-09 | Multi-user collaboration with item locking |
