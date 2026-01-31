# ADR-018: Secrets Management

## Status

Accepted

## Context

AgentForge requires secure storage for sensitive configuration including:
- LLM provider API keys (Anthropic)
- Firebase admin credentials
- Encryption keys for data at rest
- Per-organization integration secrets

Secrets must be:
- Stored securely with encryption at rest
- Accessible only to authorized services
- Rotatable without application downtime
- Audited for all access

We considered:
1. Environment variables in Kubernetes
2. HashiCorp Vault
3. GCP Secret Manager
4. AWS Secrets Manager

## Decision

We will use **GCP Secret Manager** for all sensitive configuration.

### Storage Strategy

- Application secrets stored at project level
- Per-organization secrets namespaced by org ID
- Secrets versioned for rotation support
- No secrets in code, environment variables, or config files

### Access Pattern

- Secrets loaded via Secret Manager API
- In-memory caching with 5-minute TTL
- Background refresh to avoid cache misses
- Service account-based authentication via Workload Identity

### Key Rotation

- Automatic rotation on schedule (90-365 days depending on secret type)
- Manual rotation available for immediate response
- Old versions retained 30 days for rollback
- Cache invalidation via Pub/Sub notification

## Rationale

GCP Secret Manager was chosen because:

1. **Native GCP Integration**: Works seamlessly with GKE, Cloud Run, IAM
2. **Workload Identity**: No secret files in pods, automatic authentication
3. **Versioning**: Built-in version management for rotation
4. **Audit Logging**: All access logged to Cloud Audit Logs
5. **Replication**: Cross-region replication for disaster recovery

### Rejected Alternatives

**Environment Variables**:
- Visible in process listings
- No rotation without pod restart
- No audit trail
- Secrets in Kubernetes manifests

**HashiCorp Vault**:
- Additional infrastructure to manage
- Separate access control system
- Higher operational complexity
- Overkill for our scale

**AWS Secrets Manager**:
- Would require cross-cloud access
- Less integrated with our GCP infrastructure
- Additional latency for secret retrieval

## Consequences

### Positive

- Centralized secret management
- Automatic audit trail
- Built-in rotation support
- Strong access control via IAM
- No secrets in application code or configs

### Negative

- Slight latency on cache misses
- Requires Secret Manager API access from all services
- Additional GCP dependency
- Costs scale with secret access volume

### Mitigations

- Aggressive caching reduces API calls
- Workload Identity eliminates credential management
- Background refresh prevents cold-start delays
- Alert on unusual access patterns

## Implementation Notes

### Caching Strategy

```go
// 5-minute TTL balances freshness with API costs
cache := ttlcache.New(
    ttlcache.WithTTL(5 * time.Minute),
    ttlcache.WithCapacity(100),
)
```

### Rotation Handling

```go
// Subscribe to rotation events
sub := client.Subscription("secret-rotation-events")
sub.Receive(ctx, func(ctx context.Context, msg *pubsub.Message) {
    secretName := msg.Attributes["secretName"]
    cache.Delete(secretName)
    msg.Ack()
})
```

## Related

- [Secrets Management](../security/secrets-management.md)
- [Security Overview](../security/overview.md)
