# Security Review Workflow

## Overview

Dedicated Security Agent reviews code for vulnerabilities and proposes fixes before project completion. No code ships without security review.

## Security Focus

**What This Covers**: Security of generated output - ensuring agents produce secure code.

**What This Does NOT Cover**: Enterprise audit trails, SOC 2/GDPR compliance features.

---

## Two-Layer Approach

| Layer | Purpose |
|-------|---------|
| Generation guidance | Agents prompted to follow security best practices during generation |
| Security review phase | Dedicated Security Agent reviews and fixes before finalization |

---

## Updated Pipeline

```
Requirements → Architecture → Code → Security Review
```

Security Review is the fourth and final phase.

---

## Security Agent

### Identity
```
You are a Security Agent reviewing code for vulnerabilities.
You identify security issues and propose fixes.
You follow OWASP guidelines and secure coding best practices.
You do not change functionality - only fix security issues.
```

### What It Checks

| Category | Examples |
|----------|----------|
| Injection | SQL injection, command injection, XSS |
| Authentication | Hardcoded credentials, weak session handling |
| Data exposure | Sensitive data in logs, unencrypted storage |
| Access control | Missing authorization checks, IDOR |
| Configuration | Debug mode enabled, permissive CORS |
| Dependencies | Known-vulnerable imports |

### Tools

| Tool | Purpose |
|------|---------|
| `get_code_artifacts` | Retrieve all code from Code phase |
| `get_architecture` | Understand intended security model |
| `search_sme_security` | Find org-specific security rules |
| `propose_fix` | Submit code patch for user approval |

---

## Issue Handling

### Flow

```
Security Agent reviews code
        ↓
Issue found → Agent proposes fix
        ↓
User reviews patch
        ↓
Accept → Patch applied, continue
        ↓
Reject → User must provide alternative
        ↓
Alternative reviewed by Security Agent
        ↓
Passes? → Continue
Fails? → User tries again
```

### No Override Path

Unlike other constraint violations, security issues **cannot be overridden**:
- User must accept the fix, OR
- User must provide an alternative that passes review

All shipped code is security-reviewed.

---

## SME Security Knowledge

### Platform Baseline (enabled by default)
- OWASP Top 10 Guidelines
- Secure Coding Patterns
- Language-Specific Rules (JS, Python, Go)

### Org-Specific Rules
SME Curators can add security rules:
```
Rule: All database queries must use the ORM layer.
      Direct SQL prohibited except in data-access module.
```

Both platform and org rules inform what Security Agent checks.

---

## Related ADRs

- [ADR-014: LLM-Judge Constraint Validation](../decisions/ADR-014-llm-judge-validation.md)
