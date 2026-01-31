# SME Knowledge Store Component

## Overview

Enable internal experts at customer organizations to encode their standards, practices, and constraints so AI agents follow company-specific rules when building software.

## Key Characteristics

- **Organization-scoped**: One knowledge base per organization
- **Agent-specific**: Each agent type has its own knowledge set
- **Structured input**: SMEs populate knowledge through forms, not document uploads
- **Multi-mechanism influence**: Different knowledge types affect agents differently

---

## Knowledge Types

| Type | What SMEs Provide | How It's Used |
|------|-------------------|---------------|
| **Guidelines** | Prose standards and principles | Injected into agent prompts as context |
| **Templates** | Boilerplate structures, starter code | Provided to agents as starting points |
| **Examples** | Good/bad reference implementations | Retrieved via RAG when relevant |
| **Constraints** | Hard rules that must be enforced | Validated by LLM-judge after generation |

---

## Data Model

```
/organizations/{orgId}/sme-knowledge/{agentType}/
    ├── guidelines/     # title, category, content, priority (must/should/may)
    ├── templates/      # name, type, content, variables
    ├── examples/       # scenario, goodExample, badExample, explanation
    └── constraints/    # name, category, rule, severity, violation examples
```

---

## Runtime Flow

### 1. Agent Initialization
```
Agent receives task → Loads knowledge for its type from org's store
```

### 2. Prompt Construction
```
Base system prompt
  + Relevant guidelines (filtered by category)
  + Applicable templates (if creating new structures)
  = Final prompt
```

### 3. RAG for Examples
```
Agent embeds current task
  → Searches examples by semantic similarity
  → Top 2-3 relevant examples injected into prompt
```

### 4. Constraint Validation
```
Agent output → LLM-judge evaluates → Pass/Fail
  ↓ Fail
Feedback to agent → Retry (max 3)
  ↓ Retries exhausted
Escalation created
```

---

## Versioning & Updates

### Version Control
- Each item has auto-incremented version number
- Full edit history preserved
- Admins can view history and rollback

### Active Workflow Protection
```
Workflow starts → Snapshots current knowledge version
              → Uses that snapshot for entire workflow
```

New workflows pick up latest knowledge. In-flight workflows unaffected by edits.

---

## Platform Marketplace

- Platform operator publishes curated knowledge items
- Orgs browse and enable items they want
- Enabled items appear alongside org-created knowledge
- Orgs cannot modify marketplace items - use as-is only
- Platform updates apply automatically

---

## Org-Level Enforcement

Admins can mark knowledge items as **mandatory** - they apply to all projects automatically:
- "All projects must follow our API naming convention"
- "Security constraints apply everywhere"

Project Leads cannot disable mandatory items.

---

## Related ADRs

- [ADR-014: LLM-Judge Constraint Validation](../../decisions/ADR-014-llm-judge-validation.md)
- [ADR-015: Agent-Type Partitioned Knowledge](../../decisions/ADR-015-agent-partitioned-knowledge.md)
