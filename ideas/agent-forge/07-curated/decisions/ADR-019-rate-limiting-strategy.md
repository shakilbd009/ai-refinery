# ADR-019: Rate Limiting Strategy

## Status

Accepted

## Context

AgentForge needs rate limiting to:
- Protect against abuse and DoS attacks
- Ensure fair resource distribution across users
- Control LLM API costs
- Prevent prompt injection via high-volume attacks

Rate limiting must be:
- Applied at multiple levels (user, project, org)
- Configurable per organization
- Fast enough to not add significant latency
- Resilient to limiter infrastructure failures

We considered:
1. In-memory rate limiting per instance
2. Redis-based distributed rate limiting
3. GCP Cloud Armor
4. Custom token bucket in Firestore

## Decision

We will use **Redis-based distributed rate limiting** with token bucket algorithm, implemented via the go-redis/redis_rate library.

### Rate Limit Tiers

| Scope | Default Limit | Window | Configurable |
|-------|---------------|--------|--------------|
| Per user | 60 requests | 1 minute | No |
| Per project | 120 requests | 1 minute | No |
| Per org | 1000 requests | 1 minute | Yes |
| LLM calls/user | 20 | 1 minute | Yes |

### Implementation

- Token bucket algorithm for smooth rate limiting
- Redis cluster for high availability
- Graceful degradation if Redis unavailable
- Rate limit headers in responses

### Input Validation

Combined with rate limiting, we implement:
- Message size limits (32KB max)
- Character validation and sanitization
- Prompt injection pattern detection
- Content analysis for suspicious patterns

## Rationale

Redis-based rate limiting was chosen because:

1. **Distributed Consistency**: Single source of truth across instances
2. **Speed**: Sub-millisecond operations with pipelining
3. **Proven Algorithms**: Token bucket via redis_rate library
4. **Graceful Degradation**: Can fall back to per-instance limiting
5. **Flexibility**: Easy to adjust limits without restarts

### Rejected Alternatives

**In-memory per instance**:
- Limits not consistent across instances
- Users can game by hitting different instances
- No global org-level limiting

**Cloud Armor**:
- L7 only, doesn't understand application context
- Cannot rate limit by user or project
- Expensive at high traffic volumes

**Firestore-based**:
- Too slow for per-request checks
- High read/write costs
- Not designed for counter workloads

## Consequences

### Positive

- Consistent rate limiting across all instances
- Low latency (< 1ms typical)
- Easy to adjust limits dynamically
- Built-in handling of edge cases (clock skew, etc.)

### Negative

- Additional infrastructure dependency (Redis)
- Slightly more complex deployment
- Must handle Redis failures gracefully
- Memory usage for token buckets

### Mitigations

- Redis Cluster for high availability
- Fall back to local rate limiting if Redis down
- Monitor Redis memory and latency
- Alert on rate limit errors

## Implementation Notes

### Middleware

```go
func RateLimitMiddleware(limiter *redis_rate.Limiter) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            userID := getUserID(r)

            res, err := limiter.Allow(r.Context(),
                fmt.Sprintf("user:%s", userID),
                redis_rate.PerMinute(60))

            // Set rate limit headers
            w.Header().Set("X-RateLimit-Remaining", strconv.Itoa(int(res.Remaining)))
            w.Header().Set("X-RateLimit-Reset", strconv.FormatInt(res.ResetAfter.Milliseconds(), 10))

            if res.Remaining == 0 {
                w.Header().Set("Retry-After", strconv.Itoa(int(res.RetryAfter.Seconds())))
                http.Error(w, "Rate limit exceeded", http.StatusTooManyRequests)
                return
            }

            next.ServeHTTP(w, r)
        })
    }
}
```

### Graceful Degradation

```go
func (rl *RateLimiter) Allow(ctx context.Context, key string) bool {
    res, err := rl.redis.Allow(ctx, key, rl.limit)
    if err != nil {
        // Log error, fall back to permissive mode
        log.Warn("redis rate limit error, allowing request", "error", err)
        return true
    }
    return res.Remaining > 0
}
```

## Related

- [Input Validation](../security/input-validation.md)
- [Security Overview](../security/overview.md)
