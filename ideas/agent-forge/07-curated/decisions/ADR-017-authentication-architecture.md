# ADR-017: Authentication Architecture

## Status

Accepted

## Context

AgentForge needs a robust authentication system that supports:
- Multiple organizations with isolated access
- Role-based permissions at org and project levels
- Session management across devices
- Multi-factor authentication for sensitive operations

We considered several approaches:
1. Custom JWT implementation
2. Firebase Authentication with custom claims
3. Auth0 or similar third-party service
4. OAuth2/OIDC with custom identity provider

## Decision

We will use **Firebase Authentication** (Google Cloud Identity Platform) with custom claims for organization and role information.

### Token Strategy

- **ID Tokens**: Short-lived (1 hour), stored in memory only
- **Refresh Tokens**: Long-lived (30 days), stored in HttpOnly secure cookies
- **Custom Claims**: Org ID, org role, and project roles embedded in token

### Session Management

- Sessions tracked in Firestore for revocation capability
- Maximum 5 concurrent sessions per user
- 24-hour idle timeout, 30-day absolute limit
- Session invalidation on password change or admin action

### Multi-Factor Authentication

- TOTP (authenticator apps) as primary method
- SMS as fallback for recovery only
- MFA required for org admins and SME curators
- Configurable enforcement for other roles

## Rationale

Firebase Authentication was chosen because:

1. **Managed Infrastructure**: No need to manage auth servers, handle security patches
2. **Built-in MFA**: Native TOTP and phone auth support
3. **Google Cloud Integration**: Seamless with Firestore, Cloud Functions, IAM
4. **Custom Claims**: Allows embedding org/role data for fast authorization
5. **Token Verification**: SDK provides efficient server-side verification

### Rejected Alternatives

**Custom JWT Implementation**:
- Higher maintenance burden
- Must handle all security edge cases ourselves
- Token revocation requires custom infrastructure

**Auth0**:
- Additional vendor dependency
- More complex pricing model
- Less integrated with GCP ecosystem

**Custom OIDC Provider**:
- Significant development effort
- Must maintain security compliance
- Overkill for our use case

## Consequences

### Positive

- Reduced development time for auth features
- Google-backed security and compliance
- Easy integration with other Google services
- Built-in protection against common attacks

### Negative

- Vendor lock-in to Google ecosystem
- Custom claims limited to 1000 bytes
- Must refresh claims on membership changes
- Limited customization of login flows

### Mitigations

- Abstract auth behind interface for potential future migration
- Use efficient claim encoding (org ID + role map)
- Implement claim refresh mechanism on membership changes
- Use Firebase UI SDK for consistent login experience

## Related

- [Authentication Architecture](../security/authentication.md)
- [ADR-011: Four-Level Project Roles](./ADR-011-four-level-project-roles.md)
