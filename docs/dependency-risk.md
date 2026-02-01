# Dependency Risk Assessment

## Purpose

Identify and mitigate risks from external dependencies before they become outages.

## Why This Matters

**Without dependency analysis:**
- Third-party API changes break your product
- Single point of failure takes you down
- Pricing changes destroy unit economics
- Compliance violations you didn't anticipate

**With dependency analysis:**
- Backup plans for critical dependencies
- Risk-weighted architecture decisions
- Early warning when dependencies change
- Negotiating leverage (you know alternatives)

## Assessment Template

**Location:** `ideas/<name>/07-curated/dependency-risk.md`

```markdown
# Dependency Risk Assessment: [Project Name]

## Critical Dependencies (System won't function without)

### 1. [Dependency Name]
| Attribute | Value |
|-----------|-------|
| **Type** | API / Library / Service / Infrastructure |
| **Provider** | Company Name |
| **Version/Lock** | v2.3.1 (pinned) / Latest (floating) |
| **Cost** | $500/month at 1000 users |
| **SLA** | 99.9% uptime |
| **Data Location** | US-East / EU / etc. |

**Usage:**
- What we use it for
- How deeply integrated (shallow/deep)
- Data we send/store there

**Risk Analysis:**
- **Likelihood of failure:** Low/Med/High (why?)
- **Impact of failure:** Critical/High/Med/Low (why?)
- **Risk Score:** [Likelihood × Impact]

**Mitigation:**
- [ ] Circuit breaker pattern implemented
- [ ] Fallback behavior defined
- [ ] Graceful degradation tested
- [ ] Alternative identified: [Alternative Name]
- [ ] Migration path documented

**Monitoring:**
- Health check endpoint: [URL]
- Alert threshold: [e.g., 3 failures in 5 min]
- Owner: [Who monitors this?]

**Contract/Compliance:**
- Data processing agreement: [Yes/No/Needed]
- SOC2 compliant: [Yes/No]
- GDPR compliant: [Yes/No]
- Pricing lock: [Duration or "None"]

---

## Important Dependencies (Major impact if failed)

[Same format, lower stakes]

---

## Nice-to-Have Dependencies (Can live without)

[Same format, minimal risk]

---

## Combined Risk Summary

| Metric | Value |
|--------|-------|
| Total dependencies | 12 |
| Critical | 3 |
| Important | 5 |
| Nice-to-have | 4 |
| Single points of failure | 2 |
| Dependencies without alternatives | 1 |

## Architecture Risk

**Combined availability:**
- If all critical dependencies meet SLA: 99.7% uptime
- If one critical fails: 0% (hard dependency)
- Target availability: 99.9%
- **Gap:** Need redundancy or degradation strategy

## Mitigation Priority

| Priority | Dependency | Action | Owner | Due Date |
|----------|------------|--------|-------|----------|
| P0 | Stripe | Implement offline queue | [Name] | [Date] |
| P1 | Firestore | Add read replica | [Name] | [Date] |
| P2 | SendGrid | Add Mailgun backup | [Name] | [Date] |
```

## Common Dependencies to Assess

### Infrastructure
- [ ] Cloud provider (AWS/GCP/Azure)
- [ ] Database (managed vs self-hosted)
- [ ] CDN (CloudFlare, Fastly)
- [ ] Container orchestration (K8s, Cloud Run)
- [ ] Monitoring (Datadog, New Relic)

### APIs & Services
- [ ] Authentication (Auth0, Firebase Auth)
- [ ] Payments (Stripe, PayPal)
- [ ] Email (SendGrid, Mailgun)
- [ ] SMS (Twilio)
- [ ] Search (Algolia, Elasticsearch)
- [ ] File storage (S3, Cloud Storage)
- [ ] AI/LLM (OpenAI, Anthropic)

### Libraries & Frameworks
- [ ] Web framework (Next.js, Django)
- [ ] Database ORM
- [ ] UI component library
- [ ] Authentication library
- [ ] Testing frameworks

### Development Tools
- [ ] Version control (GitHub, GitLab)
- [ ] CI/CD (GitHub Actions, CircleCI)
- [ ] Package registries (npm, PyPI)

## Risk Scoring Matrix

### Likelihood
| Level | Criteria |
|-------|----------|
| **High** | Startup (<2 years), frequent outages, financial instability, deprecated product |
| **Medium** | Growing company, occasional issues, competitive market |
| **Low** | Established (>5 years), excellent track record, market leader |

### Impact
| Level | Criteria |
|-------|----------|
| **Critical** | System completely down, data loss, revenue stops, legal violation |
| **High** | Major features broken, significant revenue impact, data breach risk |
| **Medium** | Degraded experience, workarounds exist, minor revenue impact |
| **Low** | Nuisance only, easily replaceable, no business impact |

### Risk Score
| Likelihood ↓ Impact → | Critical | High | Medium | Low |
|-----------------------|----------|------|--------|-----|
| **High** | CRITICAL | HIGH | MEDIUM | LOW |
| **Medium** | HIGH | MEDIUM | MEDIUM | LOW |
| **Low** | MEDIUM | MEDIUM | LOW | LOW |

## Mitigation Strategies

### For APIs
- [ ] **Circuit breaker** - Stop calling when failing
- [ ] **Retry with backoff** - Exponential backoff, max retries
- [ ] **Fallback** - Degraded mode when unavailable
- [ ] **Queue and retry** - Store requests, process later
- [ ] **Alternative provider** - Hot standby or quick switch

### For Databases
- [ ] **Read replicas** - Distribute load, failover option
- [ ] **Multi-region** - Geographic redundancy
- [ ] **Backup strategy** - Point-in-time recovery
- [ ] **Migration path** - Can move to different DB if needed

### For Libraries
- [ ] **Version pinning** - Don't auto-update
- [ ] **Fork/maintain** - For critical, abandoned libraries
- [ ] **Abstraction layer** - Easy to swap implementations
- [ ] **Vendor escrow** - For commercial libraries

### For Cloud Services
- [ ] **Multi-cloud strategy** - Can migrate if needed
- [ ] **Reserved capacity** - Protect against availability
- [ ] **Pricing lock** - Contract protects against increases
- [ ] **Exit planning** - Know how to leave

## Red Flags

🚩 **Single point of failure** - One dependency takes down entire system
🚩 **No alternative identified** - Can't pivot if provider fails
🚩 **Deep integration, shallow understanding** - Don't know how it works
🚩 **No SLA or SLA too low** - Provider doesn't guarantee availability
🚩 **Critical path, no fallback** - Can't function without it
🚩 **Pricing uncertainty** - "Contact sales" for scale pricing
🚩 **Data lock-in** - Can't export your data easily

## Integration with Other Stages

**Informed by:**
- 04-design-l1/l2/l3 (technical dependencies)
- 03.5-market-validation (business dependencies)

**Informs:**
- 06.5-pre-mortem (failure modes)
- 07-curated (architecture decisions)
- Implementation (monitoring, fallback code)

## Review Cadence

- **At graduation:** Complete assessment
- **Quarterly:** Review for changes (pricing, SLAs, alternatives)
- **On incident:** Post-mortem includes dependency analysis
- **Before scaling:** Reassess at 10x user milestones

## Success Metrics

- [ ] Zero critical dependencies without alternatives
- [ ] All critical dependencies have monitoring
- [ ] Fallback tested quarterly
- [ ] Dependency changes logged and reviewed
- [ ] Pricing changes don't surprise you

**The goal: No single external factor can kill your product.**
