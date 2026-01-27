# Architecture Overview

## System Diagram

```mermaid
graph TB
    subgraph "Client Layer"
        Web[Web App - Next.js]
    end

    subgraph "API Layer"
        API[Go REST API]
        WS[WebSocket Server]
    end

    subgraph "Agent Layer"
        ReqAgent[Requirements Agent]
        ArchAgent[Architecture Agent]
        CodeAgent[Coding Agent]
        SecAgent[Security Agent]
    end

    subgraph "Services"
        Workflow[Workflow Engine]
        SME[SME Knowledge Service]
        Auth[Auth Service]
        Sandbox[Sandbox Service]
    end

    subgraph "Data Layer"
        Firestore[(Firestore)]
        Vector[(Vector Store)]
    end

    subgraph "External"
        LLM[LLM Provider]
        Container[gVisor Containers]
    end

    Web --> API
    Web --> WS
    API --> Workflow
    API --> Auth
    Workflow --> ReqAgent
    Workflow --> ArchAgent
    Workflow --> CodeAgent
    Workflow --> SecAgent
    ReqAgent --> SME
    ArchAgent --> SME
    CodeAgent --> SME
    CodeAgent --> Sandbox
    SecAgent --> SME
    SME --> Vector
    Sandbox --> Container
    ReqAgent --> LLM
    ArchAgent --> LLM
    CodeAgent --> LLM
    SecAgent --> LLM
    Workflow --> Firestore
    SME --> Firestore
    Auth --> Firestore
```

---

## Component Responsibilities

### API Layer

| Component | Responsibility |
|-----------|----------------|
| Go REST API | Request handling, authorization, business logic orchestration |
| WebSocket Server | Real-time updates for agent progress, collaboration |

### Agent Layer

| Component | Responsibility |
|-----------|----------------|
| Requirements Agent | Gather requirements through conversation, produce user stories |
| Architecture Agent | Design system structure, data models, API contracts |
| Coding Agent | Generate code following architecture, validate in sandbox |
| Security Agent | Review code for vulnerabilities, propose fixes |

### Service Layer

| Component | Responsibility |
|-----------|----------------|
| Workflow Engine | Phase transitions, escalations, change management, locks |
| SME Knowledge Service | Guidelines, templates, examples, constraints + RAG retrieval |
| Auth Service | Session management, org membership, project permissions |
| Sandbox Service | Container lifecycle, resource limits, execution capture |

### Data Layer

| Component | Responsibility |
|-----------|----------------|
| Firestore | Persistent storage for all domain objects, event sourcing |
| Vector Store | Embeddings for SME example retrieval (RAG) |

---

## Request Flow: Agent Task Execution

```mermaid
sequenceDiagram
    participant User
    participant API
    participant Workflow
    participant Agent
    participant SME
    participant LLM
    participant Firestore

    User->>API: Send message
    API->>Workflow: Route to current phase
    Workflow->>Agent: Assign task
    Agent->>SME: Get relevant knowledge
    SME-->>Agent: Guidelines, examples
    Agent->>LLM: Generate with tools
    LLM-->>Agent: Response
    Agent->>Agent: Self-critique
    Agent->>Workflow: Return artifacts
    Workflow->>Firestore: Persist artifacts
    Workflow-->>User: Update via WebSocket
```

---

## Request Flow: Constraint Validation

```mermaid
sequenceDiagram
    participant Agent
    participant LLMJudge
    participant Workflow
    participant User

    Agent->>Agent: Generate output
    Agent->>LLMJudge: Validate against constraints
    alt Pass
        LLMJudge-->>Agent: Approved
        Agent->>Workflow: Return artifacts
    else Fail (retry < 3)
        LLMJudge-->>Agent: Violation + feedback
        Agent->>Agent: Revise output
        Agent->>LLMJudge: Re-validate
    else Fail (retry exhausted)
        LLMJudge-->>Agent: Escalate
        Agent->>Workflow: Create escalation
        Workflow->>User: Escalation notification
    end
```

---

## Data Flow: Phase Handoff

```mermaid
graph LR
    subgraph "Requirements Phase"
        R1[User Stories]
        R2[Acceptance Criteria]
    end

    subgraph "Architecture Phase"
        A1[get_requirements tool]
        A2[System Design]
        A3[Data Model]
        A4[API Contracts]
    end

    subgraph "Code Phase"
        C1[get_architecture tool]
        C2[Generated Code]
    end

    R1 --> A1
    R2 --> A1
    A1 --> A2
    A2 --> A3
    A3 --> A4
    A2 --> C1
    A4 --> C1
    C1 --> C2
```

---

## Technology Choices

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Backend Language | Go | Type safety, performance, good concurrency |
| Database | Firestore | Flexible schema, real-time, event sourcing support |
| Container Runtime | gVisor (runsc) | Strong isolation, syscall filtering |
| Frontend | Next.js | SSR capability, React ecosystem |
| Vector DB | Firestore + pgvector | RAG for SME examples |

---

## Related Documents

- [Data Model](./data-model.md) - All domain entities and relationships
- [API Contracts](./api-contracts.md) - REST endpoint specifications
- [Components](./components/) - Detailed component designs
