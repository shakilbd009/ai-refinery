# Compound Learnings Tracking

## Purpose

Track insights, patterns, and reusable components across all projects.
Build organizational knowledge, not just project knowledge.

## Why This Matters

**Without compound learnings:**
- Every project starts from zero
- Same mistakes made repeatedly
- No reusable components
- Knowledge walks out the door with people

**With compound learnings:**
- New projects leverage past work
- Decisions improve over time
- Library of proven patterns
- Knowledge survives team changes

## File Structure

```
ai-refinery/
└── compound/
    ├── patterns/              # Reusable technical patterns
    ├── decisions/             # Decision records that changed
    ├── components/            # Extracted, reusable modules
    ├── anti-patterns/         # Things that didn't work
    ├── metrics/               # Benchmarks and performance data
    └── lessons/               # General lessons learned
```

## Pattern Library

### Location: `compound/patterns/<category>/<pattern-name>.md`

**Example:**
```markdown
# Pattern: Passwordless Auth with Email Codes

## Context
Web applications needing simple, secure authentication without 
password management overhead.

## Pattern
1. User enters email
2. System generates 6-digit code
3. Code expires in 10 minutes
4. User enters code to authenticate
5. JWT issued with 7-day refresh

## Implementation
- Storage: Redis (TTL = 10 min)
- Code generation: crypto.randomInt(100000, 999999)
- Rate limit: 3 attempts per code, 5 codes per hour per email

## When to Use
✅ Consumer apps, low security requirements
✅ Want minimal friction
✅ No sensitive data (health, financial)

## When NOT to Use
❌ High-security applications (banking, healthcare)
❌ Enterprise SSO requirements
❌ Compliance needs (SOC2, HIPAA)

## Projects Using This
- Manik Golden Honey Co (2026-01)
- [Future projects...]

## Variations
- SMS instead of email (higher cost, better delivery)
- Magic links instead of codes (easier UX, email client issues)

## Lessons
- 10 min expiration is sweet spot (15 min too long, 5 min frustrating)
- Email deliverability is biggest failure mode
- Always have "resend code" with rate limiting

## Version History
- v1.0 (2026-01): Initial implementation
```

## Decision Evolution

### Location: `compound/decisions/<topic>.md`

**Track how decisions change over time:**

```markdown
# Decision Evolution: Database Selection

## 2025-06: Initial Position
**Decision:** Use PostgreSQL for everything
**Rationale:** ACID compliance, proven, team knows it

## 2025-12: First Change
**Decision:** Use Firestore for rapid prototyping
**Rationale:** Faster MVP, auto-scaling
**Changed because:** Time to market mattered more than query flexibility

## 2026-01: Current Position
**Decision:** Firestore for MVP, migrate to PostgreSQL at scale
**Rationale:** Start fast, migrate when schema stabilizes
**Repository pattern enables swap without business logic changes

## Key Insight
No database is perfect for all stages. Plan for migration, 
not permanence.

## When to Use Each
| Stage | Database | Why |
|-------|----------|-----|
| 0-1000 users | Firestore | Speed of development |
| 1000-100K | PostgreSQL | Query complexity |
| 100K+ | Specialized | Read replicas, sharding |
```

## Reusable Components

### Location: `compound/components/<name>/`

**Extracted, documented, tested modules:**

```
compound/components/
├── stripe-payment-wrapper/
│   ├── README.md
│   ├── interface.go (or .ts, .py)
│   ├── implementation/
│   ├── tests/
│   └── examples/
├── firestore-repository/
├── jwt-auth-middleware/
└── email-service/
```

**Each component includes:**
- Clear interface (what it does)
- Implementation (how it does it)
- Tests (proof it works)
- Examples (how to use it)
- Projects using it (social proof)

## Anti-Patterns

### Location: `compound/anti-patterns/<name>.md`

**Document what NOT to do:**

```markdown
# Anti-Pattern: Microservices for MVPs

## The Mistake
Splitting a 3-month MVP into 5 microservices because 
"that's how big companies do it."

## What Happened
- 2 months spent on infrastructure
- Debugging required checking 5 logs
- Deployments became coordination nightmare
- Team of 3 couldn't maintain it

## The Realization
Microservices solve organizational problems, not technical ones.
Start monolithic, extract when teams conflict, not before.

## Recovery
Merged back to monolith in week 8. MVP shipped week 12.

## Detection
⚠️ You have <5 engineers and are discussing service mesh
⚠️ "We'll need Kubernetes" before first user
⚠️ More time on infra than features

## Alternative
Modular monolith:
- Clear boundaries (easy to extract later)
- Single deploy (easy to iterate)
- One database (easy to query)
- Extract services when org needs, not tech needs
```

## Performance Benchmarks

### Location: `compound/metrics/<category>.md`

**Real-world performance data:**

```markdown
# Performance: Cloud Run Cold Start

## Test Setup
- Region: us-central1
- Memory: 1Gi
- CPU: 1
- Runtime: Go 1.21

## Results
| Scenario | Latency | Notes |
|----------|---------|-------|
| Cold start | 2.3s | First request after idle |
| Warm start | 45ms | Subsequent requests |
| After 15 min idle | 2.1s | Cloud Run keeps warm ~15 min |

## Optimization Strategies
1. **Minimize startup** - Lazy load, don't init everything
2. **Keep warm** - Ping every 10 min (costs ~$5/month)
3. **Provisioned instances** - For consistent traffic (+$30/month)

## Real-World Impact
- E-commerce checkout: Cold start killed 15% of carts
- Fix: Provisioned min instances = 1
- Result: <100ms consistently, conversion +12%

## Projects
- Manik Golden Honey Co (cold start issue, fixed with keep-warm)
```

## General Lessons

### Location: `compound/lessons/<topic>.md`

**Broad insights that don't fit elsewhere:**

```markdown
# Lesson: Scope Creep is Invisible

## The Pattern
"Just one more feature" feels small in the moment.
Four months later, you're 2x over timeline with half the features working.

## Detection
- "We'll add that in v2" → never happens
- Feature count grows faster than completion %
- Scope meetings happen weekly
- Team feels busy but ship rate drops

## Prevention
1. **Ship incomplete** - Launch with 3 features that work vs 10 that don't
2. **Kill list** - For every feature added, remove one
3. **Time-box exploration** - 2 weeks max on "what if"
4. **Public commitments** - Tell users launch date, creates urgency

## Recovery
When behind: Cut scope, not timeline. Half a product that ships 
beats a full product that doesn't.

## Evidence
- AgentForge: Cut from 6 agents to 4, shipped 2 months earlier
- Manik Honey: Removed reviews feature, launched on time
```

## Integration with Ideas

**Each idea folder should reference compound learnings:**

```markdown
# In: ideas/my-project/04-design-l1/architecture.md

## Authentication

**Decision:** Passwordless email codes
**Rationale:** See [compound/patterns/auth/passwordless-email.md](../../compound/patterns/auth/passwordless-email.md)

**Adaptations for this project:**
- Extend expiration to 15 min (older user base)
- Add SMS backup (higher security needs)
```

## Maintenance

**Who updates:** Anyone who learns something
**When to update:** 
- After project completes (retrospective insights)
- When patterns emerge (2+ projects use same approach)
- When decisions change (document evolution)

**Review cadence:** Quarterly review of compound/ directory

## Success Metrics

- [ ] New projects start with 3+ compound references
- [ ] Zero repeated anti-patterns
- [ ] Components extracted and reused
- [ ] Decision time decreases over time
- [ ] New team members ramp up faster

**The goal: Every project makes the next one easier.**
