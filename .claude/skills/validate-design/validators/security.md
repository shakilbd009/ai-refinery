---
name: validate-security
description: Use when reviewing designs for security vulnerabilities, OWASP Top 10, auth flaws, data exposure, injection risks, or secrets handling. Triggers on security review, security audit, vulnerability check.
---

# Validate Security

Reviews curated design artifacts for security vulnerabilities and risks.

## Usage

```bash
/validate-security <idea-name>
```

## Prerequisites

Curated folder must exist: `ideas/<name>/07-curated/`

If not curated, abort with: "Run /curating-artifacts first"

## Focus Areas

- **OWASP Top 10** - Injection, broken auth, sensitive data exposure, XXE, broken access control, security misconfiguration, XSS, insecure deserialization, known vulnerabilities, insufficient logging
- **Auth/AuthZ** - Token handling, session management, permission checks, privilege escalation
- **Data Protection** - Encryption at rest/transit, PII handling, data retention, anonymization
- **Injection Risks** - SQL, NoSQL, command, LDAP, XPath injection vectors
- **Secrets Management** - API keys, credentials, tokens, certificates
- **Compliance Gaps** - GDPR, CCPA, PCI-DSS, HIPAA considerations

## Artifacts to Examine

Primary:
- `07-curated/security/` - Security-specific docs
- `07-curated/architecture/api-contracts.md` - API attack surface
- `07-curated/edge-cases/` - Error handling that may leak info

Secondary:
- `07-curated/architecture/components/` - Component security boundaries
- `07-curated/architecture/data-model.md` - Sensitive data fields

## Execution

Use the `security-sentinel` agent via Task tool:

```
Task (security-sentinel):
  Prompt: Review ideas/<name>/07-curated/ for security vulnerabilities.

  Focus on:
  - OWASP Top 10 vulnerabilities
  - Authentication/authorization flaws
  - Data exposure risks
  - Injection vectors
  - Secrets handling
  - Compliance gaps

  Examine these files:
  - 07-curated/security/*
  - 07-curated/architecture/api-contracts.md
  - 07-curated/edge-cases/*
  - 07-curated/architecture/components/*
  - 07-curated/architecture/data-model.md

  Output findings to: ideas/<name>/08-validated/security-findings.md

  Use format from: [_output-format.md](_output-format.md)
```

## Output

Creates: `ideas/<name>/08-validated/security-findings.md`

## Severity Guide

| Severity | Examples |
|----------|----------|
| Critical | SQL injection possible, auth bypass, unencrypted PII storage |
| High | Missing rate limiting on auth, overly permissive CORS, weak password policy |
| Medium | Verbose error messages, missing security headers, session timeout too long |
| Low | Minor logging gaps, optional security hardening |
