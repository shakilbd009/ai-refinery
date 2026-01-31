# Agent Framework Implementation - Overview

> **Navigation:** [Overview](00-overview.md) | [Agent Interface](01-agent-interface.md) | [LLM Provider](02-llm-provider.md) | [Executor](03-executor.md) | [Prompt & Memory](04-prompt-memory.md) | [Agents](05-agents.md) | [Tools & API](06-tools-api.md)

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the agent execution framework that powers Requirements, Architecture, Coding, and Security agents with tool access, layered prompts, memory management, self-critique, and constraint enforcement.

**Architecture:** Clean layered design with Agent interface -> Executor -> Tools -> LLM Provider. Agents are tool-using reasoners with read-only access. Prompts built in 4 layers (base + task + SME knowledge + conversation). Self-critique loop before output, constraint validation via LLM-judge with retry/escalation.

**Tech Stack:** Go 1.25, Chi v5 (existing), Anthropic Claude SDK (primary LLM), interface-based LLM abstraction for multi-provider support.

---

## Implementation Overview

```
internal/
├── agents/
│   ├── agent.go              # Task 1-3: Interface & base types
│   ├── executor.go           # Task 8-11: Core execution loop
│   ├── requirements.go       # Task 16-17: Requirements Agent
│   ├── architecture.go       # Task 18-19: Architecture Agent
│   ├── coding.go             # Task 20-21: Coding Agent
│   └── security.go           # Task 22-23: Security Agent
├── llm/
│   ├── provider.go           # Task 4-5: LLM provider interface
│   └── claude.go             # Task 6-7: Claude implementation
├── prompt/
│   └── builder.go            # Task 12-13: 4-layer prompt builder
├── memory/
│   └── manager.go            # Task 14-15: Conversation memory
└── tools/
    ├── registry.go           # Task 24-25: Tool registry
    └── sme.go                # Task 26-27: SME knowledge tools
```

---

## Document Index

| Document | Tasks | Description |
|----------|-------|-------------|
| [01-agent-interface.md](01-agent-interface.md) | 1-3 | Agent interface, config types, plan types |
| [02-llm-provider.md](02-llm-provider.md) | 4-7 | LLM provider interface, tool schema, Claude provider |
| [03-executor.md](03-executor.md) | 8-11 | Executor structure, planning, execution, self-critique |
| [04-prompt-memory.md](04-prompt-memory.md) | 12-15 | Prompt builder, SME injection, memory manager |
| [05-agents.md](05-agents.md) | 16-23 | Requirements agent and other agents |
| [06-tools-api.md](06-tools-api.md) | 24-30 | Tool registry, SME tools, API integration |

---

## Execution Checklist

- [ ] Tasks 1-3: Agent interface and types
- [ ] Tasks 4-7: LLM provider abstraction
- [ ] Tasks 8-11: Executor with planning and self-critique
- [ ] Tasks 12-15: Prompt builder and memory manager
- [ ] Tasks 16-23: All four agent implementations
- [ ] Tasks 24-30: Tools, API wiring, and integration tests
