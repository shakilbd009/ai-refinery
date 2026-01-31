# ADR-015: Agent-Type Partitioned Knowledge

## Status
Accepted

## Context
SME knowledge applies differently to different agent types. Options:
1. Shared pool - all agents see all knowledge
2. Agent-partitioned - each agent type has its own knowledge set
3. Inheritance - base knowledge plus agent-specific additions

## Decision
Use **agent-type partitioned knowledge**:

```
/organizations/{orgId}/sme-knowledge/{agentType}/
    ├── guidelines/
    ├── templates/
    ├── examples/
    └── constraints/
```

Each agent type (Requirements, Architecture, Coding, Security) has its own:
- Guidelines
- Templates
- Examples
- Constraints

No inheritance between agent types. Knowledge explicitly assigned to each agent.

## Consequences

### Positive
- Clear ownership - SMEs know which agent uses their knowledge
- No confusion about what applies where
- Agents only see relevant knowledge (smaller context)
- Simpler mental model than inheritance

### Negative
- Possible duplication if same rule applies to multiple agents
- Must remember to update multiple places
- No "org-wide" knowledge that applies everywhere

### Mitigations
- UI can show knowledge by agent type for easy management
- Bulk operations to apply same rule to multiple agents
- Clear documentation of what each agent type does
