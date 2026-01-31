# Security Validation Findings

**Reviewed:** 2026-01-27
**Artifacts examined:**
- All security/* files (8 files)
- architecture/* (overview, data-model, api-contracts, components)
- edge-cases/* (4 files)
- decisions/ADR-017, ADR-018, ADR-019
- implementation/security-* (sandbox, permissions, review)

**Verdict:** PASS_WITH_NOTES

## Critical (Must Fix Before Graduation)

### [C1] Missing CSRF Token Validation in API Endpoints
**Location:** `architecture/api-contracts.md` (all endpoints), `security/authentication.md` line 180
**Issue:** While CSRF protection is mentioned for cookies (SameSite=Strict), there is no explicit CSRF token validation mechanism documented for state-changing operations. SameSite=Strict alone is not sufficient for all browsers and scenarios.
**Risk:** Cross-Site Request Forgery attacks could allow attackers to perform unauthorized actions on behalf of authenticated users through forged requests from malicious sites.
**Recommendation:** Implement double-submit cookie pattern or synchronizer token pattern for all state-changing endpoints (POST, PUT, PATCH, DELETE). Add CSRF token generation and validation middleware. Document in authentication.md and api-contracts.md.

### [C2] No Input Sanitization for Agent Prompts at Data Layer
**Location:** `security/input-validation.md` lines 143-173, `architecture/data-model.md` lines 149-159
**Issue:** While input validation occurs at the API layer, there's no evidence of sanitization before storing user messages in Firestore events. If database is compromised or accessed directly, unsanitized content could lead to injection attacks when later processed.
**Risk:** Second-order injection attacks if data is retrieved and used in different contexts (e.g., displayed in admin interfaces, used in reports, or processed by different agents).
**Recommendation:** Apply sanitization at data persistence layer as defense-in-depth. Store both raw and sanitized versions, or apply consistent sanitization before any database write. Update Event model in data-model.md to include sanitization metadata.

### [C3] Insufficient Session Invalidation on Security Events
**Location:** `security/authentication.md` lines 108-141, `architecture/data-model.md` lines 48-60
**Issue:** Session revocation only documented for "password change, or admin action." Missing explicit session invalidation triggers for: MFA enrollment/removal, role changes, suspicious login attempts, or multiple failed MFA attempts.
**Risk:** Compromised sessions could remain active after security-relevant events, allowing attackers to maintain access even after user takes protective action.
**Recommendation:** Document and implement session revocation for: MFA changes, privilege escalation/de-escalation, detection of anomalous behavior, account lock after failed attempts. Add SessionRevocationReason enum to track why sessions were killed.

## High (Should Fix)

### [H1] Weak Rate Limiting on Authentication Endpoints
**Location:** `decisions/ADR-019-rate-limiting-strategy.md` lines 33-38, `security/authentication.md` lines 185-190
**Issue:** Login rate limiting (5 attempts per 15 minutes per IP) is IP-based, which can be bypassed using distributed attacks or shared IPs (NAT, VPN). Account lockout after 10 attempts is reasonable but could enable denial-of-service against user accounts.
**Risk:** Brute force attacks from botnets can bypass IP-based limits. Legitimate users sharing IPs may be blocked. Attackers can lock out specific user accounts intentionally.
**Recommendation:** Implement multi-factor rate limiting: per-IP, per-account, and per-credential. Use adaptive rate limiting based on reputation. Add account unlock mechanism via email/MFA. Consider CAPTCHA after 2-3 failed attempts rather than 3.

### [H2] Missing Authorization for Cross-Org Resource ID Leakage
**Location:** `architecture/api-contracts.md` lines 1-141, `security/permissions.md` lines 63-79
**Issue:** While org boundary checks exist, there's no explicit documentation preventing resource enumeration. An attacker could probe for valid project IDs, artifact IDs, or user IDs across organizations by observing different error responses (403 vs 404).
**Risk:** Information disclosure about other organizations' resources. Attackers can build maps of valid IDs and target specific resources for exploitation.
**Recommendation:** Return consistent 404 responses for both non-existent and unauthorized resources. Never return 403 for resources outside user's org. Document this pattern in API contracts and implement in authorization middleware. Add rate limiting for enumeration attempts.

### [H3] No Protection Against Timing Attacks in Authentication
**Location:** `security/authentication.md` lines 173-200, `implementation/security-permissions/04-authorization-middleware.md`
**Issue:** No mention of constant-time comparison for tokens, passwords, or session IDs. Variable timing in string comparison can leak information about valid vs invalid credentials.
**Risk:** Timing side-channel attacks could allow attackers to validate credentials character-by-character or determine valid session IDs.
**Recommendation:** Use crypto/subtle.ConstantTimeCompare for all security-sensitive comparisons. Apply to: token verification, password hashing comparison, session ID validation, API key checks. Document in authentication architecture.

### [H4] Insufficient Validation of Container Resource Exhaustion
**Location:** `security/sandboxing.md` lines 84-103, `implementation/security-sandbox/03-container-runtime.md` lines 406-421
**Issue:** Resource warning at 80% gives agent only 20% buffer before hard termination. No documentation of what happens if agent ignores warning. No mention of zombie process cleanup or file descriptor limits.
**Risk:** Malicious or buggy code could create zombie processes, exhaust file descriptors, or ignore warnings, leading to cascading failures or resource exhaustion on host.
**Recommendation:** Add explicit file descriptor limit (default 1024). Implement process reaper for zombie processes. Force-kill any container that exceeds 90% threshold regardless of warning response. Add disk I/O throttling. Document cleanup procedures.

### [H5] Missing Security Headers Documentation
**Location:** `architecture/api-contracts.md`, `security/overview.md`
**Issue:** No documentation of security-critical HTTP headers: Content-Security-Policy, X-Frame-Options, X-Content-Type-Options, Strict-Transport-Security, Permissions-Policy.
**Risk:** XSS attacks via inline scripts, clickjacking via iframes, MIME-sniffing attacks, insecure connections, excessive browser permissions.
**Recommendation:** Document required security headers: CSP with nonce-based script whitelisting, X-Frame-Options: DENY, X-Content-Type-Options: nosniff, HSTS with includeSubDomains and preload, Permissions-Policy to restrict camera/microphone/geolocation. Implement middleware to add these headers to all responses.

## Medium (Consider Fixing)

### [M1] Verbose Error Messages May Leak Stack Traces
**Location:** `edge-cases/agent-execution.md` lines 18-27, `decisions/ADR-004-tiered-error-response.md`
**Issue:** "Tiered error response" mentioned but no explicit prohibition against stack traces in production. Error messages shown to users could reveal internal paths, dependency versions, or system architecture.
**Risk:** Information disclosure helps attackers understand system internals, identify vulnerable dependencies, or craft targeted exploits.
**Recommendation:** Implement error sanitization layer that strips stack traces, file paths, and version info in production. Log full errors server-side. Return generic error IDs to users who can reference them in support requests. Document error response format in API contracts.

### [M2] Session Timeout Too Long for High-Privilege Accounts
**Location:** `security/authentication.md` lines 126-132
**Issue:** 24-hour idle timeout and 30-day absolute limit apply uniformly. Org admins with full access have same timeout as regular members.
**Risk:** Compromised admin sessions remain active for extended periods, increasing blast radius of account takeover.
**Recommendation:** Implement role-based session timeouts: Admins (2h idle, 8h absolute), SME Curators (4h idle, 12h absolute), other roles (24h idle, 30d absolute). Require re-authentication for destructive admin operations (delete org, force user removal). Document in authentication.md.

### [M3] No Mention of Secrets Rotation Notification to Users
**Location:** `security/secrets-management.md` lines 104-145
**Issue:** Automatic rotation documented but no user notification when org-specific secrets (integrations, API keys) are rotated. Users may experience unexpected auth failures.
**Risk:** Poor user experience leading to repeated failed requests. Users may incorrectly diagnose as bugs rather than expected rotation behavior. Could lead to security team fatigue from false alarms.
**Recommendation:** Add notification system for org-level secret rotations. Email org admins 7 days before scheduled rotation. Provide rotation history UI. Add graceful fallback period where both old and new secrets work for 1 hour after rotation.

### [M4] Sandbox Code Storage in Temp Directory Without Secure Wipe
**Location:** `implementation/security-sandbox/03-container-runtime.md` lines 375-381
**Issue:** Code written to temp directory and cleaned up with `os.RemoveAll`, but no secure deletion. Sensitive code could be recovered from disk or remain in filesystem cache.
**Risk:** Information disclosure if host is compromised. Proprietary code or algorithms could be extracted from temp files or filesystem journals.
**Recommendation:** Use secure deletion (overwrite with random data before removal) for sensitive code files. Alternatively, use in-memory tmpfs for code storage (already used for container /tmp). Document secure cleanup procedures.

### [M5] No Rate Limiting on Tool Calls Within Agent Execution
**Location:** `security/input-validation.md` lines 64-70, `edge-cases/agent-execution.md` lines 43-77
**Issue:** Rate limits apply to API requests (60/min per user) but no documented limits on tool calls made by agents during a single execution. Agent could make hundreds of tool calls in one request.
**Risk:** Resource exhaustion via prompt injection that tricks agent into infinite tool loops. Single malicious request could trigger massive database load.
**Recommendation:** Add per-execution tool call limits (default 50 calls per task). Track cumulative limits per workflow. Implement circuit breaker for repeated tool failures. Document in agent execution architecture and input validation.

### [M6] Missing Audit Logging for Authorization Failures
**Location:** `security/permissions.md` lines 63-79, `decisions/ADR-012-admin-override-logging.md`
**Issue:** Admin override access is logged, but no mention of logging authorization failures (403 responses). Can't detect unauthorized access attempts or privilege escalation attempts.
**Risk:** Attackers probing for vulnerabilities go undetected. Impossible to investigate potential breaches. No visibility into users attempting unauthorized actions.
**Recommendation:** Log all authorization failures with: user ID, attempted resource, required permission, timestamp, IP. Add alerting for repeated failures from same user/IP. Create security dashboard showing failed access attempts. Retain logs for 90 days minimum.

### [M7] Firebase Token Custom Claims Limited to 1000 Bytes
**Location:** `decisions/ADR-017-authentication-architecture.md` lines 72-93, `security/authentication.md` lines 56-68
**Issue:** Custom claims limited to 1000 bytes. Users with many project memberships could exceed this limit. Claim refresh strategy not detailed for edge cases (claim exceeds limit, user added to 50+ projects).
**Risk:** Authentication failures for power users with many project memberships. Potential denial of service if claim refresh fails. Users locked out without clear error message.
**Recommendation:** Implement claim pagination strategy: store only top 10 most-recent projects in token, fetch rest on-demand. Add claim size monitoring and alerts when approaching 800 bytes. Document fallback to database lookup when claims incomplete. Add user-facing error message for claim overflow.

### [M8] No Protection Against LLM Context Injection via SME Knowledge
**Location:** `security/input-validation.md` lines 206-268, `architecture/components/sme-knowledge.md`
**Issue:** SME knowledge from marketplace or org curators is treated as trusted and inserted into prompts without validation. Malicious SME content could contain prompt injection attacks.
**Risk:** Compromised marketplace items or malicious insiders could inject instructions into all agent contexts. Could exfiltrate data, bypass security checks, or manipulate agent behavior across entire org.
**Recommendation:** Apply same prompt injection detection to SME knowledge updates. Scan all guidelines, templates, examples for suspicious patterns before approval. Sandbox SME content in separate XML blocks. Implement admin review queue for marketplace items before org enablement. Add content signing for platform baseline knowledge.

## Low (Nice to Have)

### [L1] No Documentation of Security Incident Response Plan
**Location:** `security/overview.md`
**Issue:** Comprehensive security controls documented but no incident response procedures: what to do if breach detected, who to contact, how to revoke all sessions, emergency shutdown procedures.
**Risk:** Slow or incorrect response to security incidents. Potential for greater damage during breach due to unclear procedures.
**Recommendation:** Create incident response runbook: breach detection procedures, emergency contact list, session revocation scripts, audit log analysis procedures, notification templates (users, regulators). Document in security/incident-response.md.

### [L2] Sandbox Monitoring Metrics Not Persisted
**Location:** `security/sandboxing.md` lines 247-281
**Issue:** Runtime monitoring generates alerts but no mention of persisting metrics for forensic analysis. Cannot investigate suspicious sandbox behavior after the fact.
**Risk:** Limited ability to analyze patterns in attempted exploits. Cannot identify gradual attacks that stay under per-execution thresholds.
**Recommendation:** Persist sandbox execution metrics to time-series database (Cloud Monitoring). Retain for 30 days. Create dashboard for sandbox security metrics. Add queries to detect: repeated timeout attempts, gradual resource increases, unusual syscall patterns.

### [L3] No Password Complexity Requirements Documented
**Location:** `security/authentication.md`
**Issue:** MFA enforcement documented but no password complexity rules: minimum length, character requirements, common password blocking, password reuse prevention.
**Risk:** Weak passwords combined with no MFA (for members if org doesn't enforce) could enable account takeover.
**Recommendation:** Document password policy: minimum 12 characters, mix of upper/lower/numbers/symbols, check against common password lists (HaveIBeenPwned API), prevent reuse of last 5 passwords, require change every 90 days for admins. Implement password strength meter in UI.

### [L4] Container Image Vulnerability Scanning Not Mentioned
**Location:** `security/sandboxing.md` lines 33-65, `implementation/security-sandbox/03-container-runtime.md`
**Issue:** Using specific base images (node:20-slim, python:3.11-slim) but no documentation of vulnerability scanning, image update process, or CVE monitoring.
**Risk:** Using base images with known vulnerabilities. No process to update images when CVEs discovered.
**Recommendation:** Implement automated vulnerability scanning (GCP Container Analysis, Snyk). Pin images by digest, not tag. Automate monthly updates of base images. Document update and testing process. Add alerting for critical CVEs in images.

### [L5] No Geographic Restrictions or Geo-Blocking Capability
**Location:** `security/authentication.md` lines 192-199
**Issue:** Anomaly detection mentions "access from blocked countries" but no documentation of how countries are blocked or which countries to block.
**Risk:** Compliance violations (OFAC, export controls). Attacks from high-risk geographies. Inability to comply with data residency requirements.
**Recommendation:** Implement IP geolocation middleware. Allow org admins to configure allowed/blocked countries. Default block list for sanctioned countries. Log all geographic access. Add override mechanism for legitimate travel with MFA step-up. Document in authentication.md.

### [L6] Recovery Code Storage Security Not Detailed
**Location:** `security/authentication.md` lines 77-95, `architecture/data-model.md` lines 82-89
**Issue:** Recovery codes stored as SHA-256 hash but no mention of salt, no per-user pepper, no key derivation function (PBKDF2, Argon2).
**Risk:** If database compromised, rainbow table attacks or brute force on recovery codes easier than passwords due to shorter length and lower entropy.
**Recommendation:** Use Argon2id for recovery code hashing with per-user salt and global pepper. Store pepper in Secret Manager. Consider longer recovery codes (16 characters vs typical 8-10). Document secure recovery code generation (cryptographically secure random).

## Notes (Observations, Not Issues)

- **Strong sandboxing approach**: Multiple layers (gVisor, AppArmor, Seccomp, network isolation, resource limits) provide defense-in-depth. This is excellent.

- **Well-designed permission model**: Private-by-default, explicit membership, admin override with logging follows security best practices.

- **Good secrets management**: GCP Secret Manager with rotation, caching strategy, and Workload Identity is production-ready.

- **Thoughtful rate limiting**: Multi-tiered (user, project, org) with token bucket algorithm is appropriate.

- **Event sourcing for audit**: Event-driven architecture with full event log enables good forensic capabilities.

- **Comprehensive threat model**: Threat actors, attack vectors, and mitigations are well-documented and realistic.

- **No SQL injection vectors in design**: No raw SQL mentioned; Firestore NoSQL reduces SQL injection risk. Data model uses typed fields appropriately.

- **HTTPS implicit**: While not explicitly documented everywhere, GCP deployment implies HTTPS. Should be made explicit in API contracts.

- **Good separation of concerns**: Agent sandboxing isolated from main API, secrets isolated from code, clear boundaries between services.

- **Input validation depth**: Multiple layers of validation (size, character sets, content analysis, structured separation) is strong.

- **Need more OWASP coverage**: Only covers A03:Injection, A07:Auth, A01:Access Control explicitly. Should explicitly address:
  - A02:Cryptographic Failures (encryption at rest/transit)
  - A04:Insecure Design (addressed via threat model)
  - A05:Security Misconfiguration (docker defaults)
  - A06:Vulnerable Components (dependency scanning)
  - A08:Software and Data Integrity Failures (signed artifacts)
  - A09:Logging and Monitoring Failures (partial coverage)
  - A10:SSRF (network isolation helps)

- **Production readiness**: With critical and high issues addressed, this architecture is ready for production deployment with appropriate security monitoring.

---

## Summary

The AgentForge security architecture demonstrates strong security fundamentals with defense-in-depth, comprehensive threat modeling, and well-designed permission boundaries. The primary gaps are in operational security controls (CSRF tokens, authorization failure logging, security headers) and edge-case handling (timing attacks, resource exhaustion, session management).

**Critical issues (3)** must be resolved before production deployment as they represent exploitable vulnerabilities.

**High issues (5)** should be addressed to meet security best practices and prevent common attack vectors.

**Medium issues (8)** represent defense-in-depth improvements and operational security enhancements that reduce risk but are not immediately exploitable.

**Low issues (6)** are recommended for long-term security posture but not blockers for initial deployment.

The overall security design is solid and production-viable with the noted corrections.
