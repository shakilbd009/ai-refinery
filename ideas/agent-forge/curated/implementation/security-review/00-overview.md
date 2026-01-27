# Security Review Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement a Security Agent that reviews code for vulnerabilities and proposes fixes before project completion.

**Architecture:** Four-phase pipeline (Requirements → Architecture → Code → Security Review). The Security Agent scans code artifacts for OWASP vulnerabilities and org-specific security rules, then proposes patches. No override path - issues must be fixed or user must provide alternative.

**Tech Stack:** Go backend (domain/service/repository/handlers), Next.js frontend (React + TypeScript + Tailwind + Radix UI)

---

## Plan Structure

This implementation is split into focused modules:

| File | Description | Dependencies |
|------|-------------|--------------|
| [01-data-models.md](./01-data-models.md) | Domain types: SecurityFinding, SecurityReview | None |
| [02-repository.md](./02-repository.md) | Repository interface for security data | 01-data-models |
| [03-service.md](./03-service.md) | Service layer orchestration | 01, 02 |
| [04-security-agent.md](./04-security-agent.md) | Security Agent implementation | 01, 02, 03 |
| [05-api-handlers.md](./05-api-handlers.md) | HTTP endpoints | 01, 02, 03 |
| [06-frontend.md](./06-frontend.md) | UI components | None (can parallel) |

## Execution Order

**Backend (sequential):** 01 → 02 → 03 → 04 → 05

**Frontend (parallel with backend):** 06 can start immediately

## Existing Infrastructure

Already in place:
- `PhaseSecurityReview` defined in `internal/domain/workflow.go`
- `AgentSecurity` type defined in `internal/domain/knowledge.go`
- `TypeSecurity` agent type defined in `internal/agents/agent.go`
- Escalation model for constraint violations
- ApprovalChecklist UI component
- Security Review tab in project page UI

## Design Reference

Full design specification: `docs/plans/security-review-design.md`
