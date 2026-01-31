# ADR-021: LLM Provider Resilience

## Status

Accepted

## Context

AgentForge depends on external LLM providers (Anthropic Claude) for all agent reasoning. Provider failures can completely halt the system. We need resilience patterns to handle:
- Transient failures (timeouts, rate limits)
- Partial degradation (slow responses)
- Complete outages (provider down)

We considered:
1. Simple retry logic
2. Full circuit breaker pattern
3. Multi-provider failover
4. Queue-based processing with retries

## Decision

We will implement a **multi-layer resilience stack**:

1. **Timeout Layer**: Request-level timeouts based on task complexity
2. **Retry Layer**: Exponential backoff with jitter
3. **Circuit Breaker**: Prevent cascade failures during outages
4. **Rate Limiter**: Stay within provider token budgets
5. **Fallback Handler**: Graceful degradation and user notification

### SLA Targets

| Metric | Target |
|--------|--------|
| Request success rate | 99.5% (after retries) |
| P95 latency | <30s |
| Circuit breaker opens | <1/day |

### Timeout Strategy

| Task Type | Timeout |
|-----------|---------|
| Simple query | 30s |
| Code generation | 60s |
| Tool-heavy task | 120s |
| Absolute max | 180s |

### Circuit Breaker Config

- Open after 5 failures in 60s window
- Stay open for 30s cooldown
- Close after 3 successful probes

## Rationale

Multi-layer resilience was chosen because:

1. **Defense in Depth**: No single point of failure
2. **Graceful Degradation**: System remains responsive during partial failures
3. **Cost Control**: Prevents runaway retries from burning token budget
4. **User Experience**: Users are notified quickly rather than waiting indefinitely
5. **Observability**: Each layer provides metrics for monitoring

### Rejected Alternatives

**Simple retry only**:
- Doesn't prevent cascade failures
- No protection during extended outages
- No visibility into failure patterns

**Multi-provider failover**:
- Different providers have different capabilities
- Prompts may need adjustment per provider
- Adds significant complexity
- May revisit in future

**Queue-based processing**:
- Adds latency for interactive use cases
- More infrastructure to maintain
- Overkill for current scale

## Consequences

### Positive

- System remains responsive during provider issues
- Clear SLAs for users to understand expected behavior
- Rich metrics for monitoring and alerting
- Circuit breaker prevents wasting resources on known failures

### Negative

- Added complexity in request path
- Multiple timeouts to configure and tune
- Circuit breaker can reject valid requests during recovery
- Must carefully balance retry attempts vs user wait time

### Mitigations

- Start with conservative settings, tune based on production data
- Half-open state allows gradual recovery
- Fallback to user notification provides clear communication
- Comprehensive logging for debugging

## Implementation Notes

### Resilient Provider Wrapper

```go
type ResilientProvider struct {
    provider     Provider
    circuitBreaker *CircuitBreaker
    retrier      *Retrier
    rateLimiter  *TokenBudget
    metrics      *Metrics
}

func (rp *ResilientProvider) Complete(ctx context.Context, req *Request) (*Response, error) {
    // Check circuit breaker
    if !rp.circuitBreaker.Allow() {
        return nil, ErrCircuitOpen
    }

    // Check rate limit
    if err := rp.rateLimiter.Reserve(estimateTokens(req)); err != nil {
        return nil, err
    }

    // Execute with retry
    resp, err := rp.retrier.Do(ctx, func() (*Response, error) {
        return rp.provider.Complete(ctx, req)
    })

    // Record result
    if err != nil {
        rp.circuitBreaker.RecordFailure()
    } else {
        rp.circuitBreaker.RecordSuccess()
    }

    return resp, err
}
```

### Metrics to Track

- `llm_request_duration_seconds` (histogram)
- `llm_request_total` by status and retry count
- `llm_circuit_breaker_state` (gauge)
- `llm_tokens_total` by direction

## Related

- [LLM Provider Resilience](../architecture/llm-resilience.md)
- [Edge Cases: Agent Execution](../edge-cases/agent-execution.md)
- [Agent Framework Implementation](../implementation/agent-framework/02-llm-provider.md)
