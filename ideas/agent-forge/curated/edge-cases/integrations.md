# Edge Cases: Integrations

## Sandbox Execution

### Code Runs Forever

**Trigger:** Infinite loop or blocking call in user code

**Impact:** Resource consumption, stuck agent

**Mitigation:**
- Hard timeout (default 60s, configurable per org)
- SIGTERM at timeout, SIGKILL after 5s
- Return timeout error to agent
- Agent notes execution failed

### Memory Exhaustion

**Trigger:** Code allocates excessive memory

**Impact:** Container crash, potential host impact

**Mitigation:**
- Memory limit (default 512MB)
- OOM killer terminates process
- Return memory exceeded error
- Warn user if hitting 80% repeatedly

### Disk Exhaustion

**Trigger:** Code writes excessive files

**Impact:** Disk full, container crash

**Mitigation:**
- Disk limit (default 100MB)
- Ephemeral storage only (tmpfs)
- Write fails at limit
- Return disk exceeded error

### Escape Attempt

**Trigger:** Malicious code tries to escape container

**Impact:** Potential system compromise

**Mitigation:**
- gVisor syscall filtering
- No network access
- No privileged operations
- Minimal filesystem visibility
- Regular security audits

### Runtime Not Available

**Trigger:** Requested runtime (e.g., Python) not installed

**Impact:** Cannot execute code

**Mitigation:**
- Check runtime before execution
- Return clear "runtime unavailable" error
- Org admin configures enabled runtimes
- Agent uses available alternative or skips execution

---

## LLM Provider

### Provider Outage

**Trigger:** Claude API completely unavailable

**Impact:** All agent work stops

**Mitigation:**
- Multi-provider support (Claude primary, fallback secondary)
- Automatic failover after 3 failed requests
- Degrade gracefully: queue tasks until recovered
- Status page integration for proactive alerts

### Model Deprecated

**Trigger:** Using model version that gets retired

**Impact:** Requests fail

**Mitigation:**
- Pin to specific model versions
- Monitor deprecation announcements
- Gradual migration path
- Test suite validates new versions

### Response Truncated

**Trigger:** Model stops mid-response (max tokens)

**Impact:** Incomplete output

**Mitigation:**
- Request sufficient max_tokens
- Detect truncation (no proper ending)
- Continue generation if truncated
- Merge continuations seamlessly

---

## Vector Store (RAG)

### Embedding Service Down

**Trigger:** Cannot generate embeddings for RAG

**Impact:** SME examples not retrieved

**Mitigation:**
- Cache recent embeddings
- Proceed without examples (degraded)
- Note: "Could not retrieve similar examples"
- Retry on next request

### No Relevant Examples Found

**Trigger:** Query returns no matches above threshold

**Impact:** No example context for agent

**Mitigation:**
- This is normal for novel tasks
- Agent proceeds without examples
- Not an error state
- Track query patterns for SME knowledge gaps

### Stale Embeddings

**Trigger:** SME example updated but embedding not refreshed

**Impact:** Wrong example retrieved

**Mitigation:**
- Re-embed on every SME knowledge update
- Version embeddings with content
- Invalidate cache on update

---

## External Services

### Firestore Quota Exceeded

**Trigger:** Too many reads/writes

**Impact:** Operations fail

**Mitigation:**
- Monitor quota usage
- Implement client-side caching
- Batch operations where possible
- Alert before hitting limits
- Scale plan if needed

### Authentication Service Down

**Trigger:** Cannot validate tokens

**Impact:** All requests rejected

**Mitigation:**
- Cache valid sessions locally (short TTL)
- Graceful degradation for existing sessions
- Block new logins until recovered
- Status page shows auth status

### Webhook Delivery Failure

**Trigger:** External integration endpoint unreachable

**Impact:** Integration misses events

**Mitigation:**
- Retry with exponential backoff
- Dead letter queue for failed deliveries
- Manual replay capability
- Webhook health monitoring
