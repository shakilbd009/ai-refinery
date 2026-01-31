# Performance Validation Findings

**Reviewed:** 2026-01-27
**Artifacts examined:**
- architecture/overview.md
- architecture/data-model.md
- architecture/api-contracts.md
- architecture/performance.md
- architecture/event-bus.md
- architecture/llm-resilience.md
- architecture/components/agent-framework.md
- architecture/components/workflow-engine.md
- architecture/components/sme-knowledge.md
- architecture/components/user-experience.md
- edge-cases/index.md
- edge-cases/agent-execution.md
- edge-cases/concurrency.md
- edge-cases/workflow-states.md
- edge-cases/integrations.md
- trade-offs.md

**Verdict:** PASS_WITH_NOTES

## Summary

The AgentForge architecture demonstrates strong awareness of performance considerations with comprehensive patterns for query optimization, caching, and resource management. The design includes dataloader patterns for N+1 prevention, multi-level caching, conversation history management, and bounded WebSocket connections. However, several areas require attention before production deployment, particularly around vector search scalability, event persistence patterns, and query projection optimization.

---

## Critical (Must Fix Before Graduation)

### [C1] Unbounded Event History Growth
**Location:** `architecture/event-bus.md` + `architecture/data-model.md` lines 149-159
**Issue:** Event sourcing pattern stores all events indefinitely without archival or partitioning strategy. As workflows accumulate thousands of events over months, queries like "get all events for workflow" will become increasingly slow and expensive.
**Risk:**
- O(n) query complexity that grows unbounded over time
- Firestore read costs scale linearly with event count
- Event replay for state reconstruction becomes prohibitively expensive
- Single workflow with 10,000+ events could cause multi-second query times

**Recommendation:**
```go
// Add time-based partitioning
type Event struct {
    ID         string         `firestore:"id"`
    WorkflowID string         `firestore:"workflowId"`
    Type       EventType      `firestore:"type"`
    YearMonth  string         `firestore:"yearMonth"` // "2026-01" for partitioning
    // ... rest of fields
}

// Query with partition awareness
func (r *EventRepository) GetRecentEvents(ctx context.Context, workflowID string, limit int) ([]*Event, error) {
    // Only query current and previous month partitions
    currentMonth := time.Now().Format("2006-01")
    query := r.client.Collection("events").
        Where("workflowId", "==", workflowID).
        Where("yearMonth", "in", []string{currentMonth, getPreviousMonth()}).
        OrderBy("timestamp", firestore.Desc).
        Limit(limit)
    // ...
}

// Archive old events to cold storage
func (r *EventRepository) ArchiveOldEvents(ctx context.Context, beforeDate time.Time) error {
    // Move events older than 90 days to GCS for long-term retention
    // Delete from Firestore to reduce query scope
}
```

### [C2] Missing Query Projections for Inbox Lists
**Location:** `architecture/api-contracts.md` lines 79-88 + `architecture/components/user-experience.md` lines 81-94
**Issue:** Inbox aggregation queries fetch entire escalation and artifact documents when only summary fields are needed for list views. No mention of field masks or projections in repository layer.
**Risk:**
- Over-fetching data wastes bandwidth and Firestore read units
- User with 50 pending approvals fetches 50 complete artifact documents instead of just {id, title, status, age}
- At scale, this could consume 10x more read operations than necessary

**Recommendation:**
```go
// Define lean summary types for list views
type EscalationSummary struct {
    ID           string    `firestore:"id"`
    ArtifactID   string    `firestore:"artifactId"`
    ConstraintID string    `firestore:"constraintId"`
    Status       string    `firestore:"status"`
    CreatedAt    time.Time `firestore:"createdAt"`
    // Omit Attempts[] and other heavy fields
}

// Repository method with explicit field selection
func (r *EscalationRepository) ListPendingSummaries(ctx context.Context, workflowID string) ([]*EscalationSummary, error) {
    query := r.client.Collection("escalations").
        Where("workflowId", "==", workflowID).
        Where("status", "==", "pending").
        Select("id", "artifactId", "constraintId", "status", "createdAt") // Firestore field mask

    // This fetches only specified fields, reducing read cost
}
```

### [C3] No Concurrency Control in Event Bus Publish
**Location:** `architecture/event-bus.md` lines 143-169
**Issue:** Event bus publish loops through all subscribers synchronously. With many subscribers (WebSocket broadcaster, workflow handler, agent handler, event persister, etc.), a single slow subscriber blocks all others. No timeout or concurrency control mentioned.
**Risk:**
- One slow subscriber (e.g., event persister experiencing Firestore contention) blocks all event delivery
- WebSocket clients could experience multi-second delays receiving real-time updates
- System-wide cascading delays during high event volume

**Recommendation:**
```go
func (bus *InProcessEventBus) Publish(ctx context.Context, event Event) error {
    bus.mu.RLock()
    subscribers := append(bus.subscribers[event.Type()], bus.allHandlers...)
    bus.mu.RUnlock()

    // Publish to subscribers concurrently with bounded parallelism
    g, ctx := errgroup.WithContext(ctx)
    g.SetLimit(10) // Limit concurrent handlers

    for _, sub := range subscribers {
        sub := sub // Capture loop variable
        g.Go(func() error {
            // Timeout per handler to prevent blocking
            handlerCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
            defer cancel()

            if err := sub.handler(handlerCtx, event); err != nil {
                log.Error("event handler error",
                    "type", event.Type(),
                    "handler", sub.name,
                    "error", err)
                // Don't fail the whole publish on individual handler errors
            }
            return nil
        })
    }

    return g.Wait()
}
```

---

## High (Should Fix)

### [H1] Vector Store Query Not Bounded
**Location:** `architecture/components/sme-knowledge.md` lines 55-59
**Issue:** RAG retrieval for SME examples mentions "top 2-3 relevant examples" but no discussion of vector query performance characteristics, index configuration, or query limits. As knowledge base grows to thousands of examples, similarity search could become expensive.
**Risk:**
- Unbounded vector search across large embedding collections
- Query latency increases with collection size if not properly indexed
- No mention of approximate nearest neighbor (ANN) optimization

**Recommendation:**
```go
type ExampleRetriever struct {
    vectorStore VectorStore
    config      RAGConfig
}

type RAGConfig struct {
    TopK            int     // Limit results (default 3)
    MinSimilarity   float64 // Similarity threshold (0.7)
    MaxQueryTime    time.Duration // Timeout
    UseANNIndex     bool    // Enable approximate search for large collections
}

func (er *ExampleRetriever) FindRelevant(ctx context.Context, query string) ([]*Example, error) {
    ctx, cancel := context.WithTimeout(ctx, er.config.MaxQueryTime)
    defer cancel()

    results, err := er.vectorStore.SimilaritySearch(ctx, VectorQuery{
        Embedding:     er.embedQuery(query),
        TopK:          er.config.TopK,
        MinScore:      er.config.MinSimilarity,
        UseANNIndex:   er.config.UseANNIndex, // pgvector supports IVFFlat index
    })
    // ...
}

// Monitor query performance
metrics.RecordVectorQueryDuration(duration)
metrics.RecordVectorResultCount(len(results))
```

### [H2] Conversation Summarization Lacks Cost Control
**Location:** `architecture/performance.md` lines 115-170 + `architecture/components/agent-framework.md`
**Issue:** Conversation summarization triggers LLM calls to condense history, but no discussion of when/how often this happens. Could trigger expensive summarization on every agent turn, even for short conversations.
**Risk:**
- Unnecessary LLM calls for summarization when history is still small
- Summarization itself consumes tokens and adds latency
- No batching or async summarization mentioned

**Recommendation:**
```go
type ConversationMemory struct {
    maxTurns          int
    maxTokens         int
    summarizationThreshold int // Only summarize after this many turns
    lastSummarizedAt  int      // Turn index of last summarization
}

func (cm *ConversationMemory) PrepareContext(turns []ConversationTurn) ([]Message, error) {
    // Only summarize if we've crossed threshold AND added significant new content
    if len(turns) < cm.summarizationThreshold {
        // No summarization needed yet, use all turns verbatim
        return cm.formatAllTurns(turns), nil
    }

    if len(turns) - cm.lastSummarizedAt < 10 {
        // Not enough new content to warrant re-summarization
        return cm.useCachedSummary(turns), nil
    }

    // Asynchronously update summary for next time
    go cm.asyncSummarize(turns)

    // Return current best context immediately
    return cm.buildContextWithCachedSummary(turns), nil
}
```

### [H3] WebSocket Connection Pool Grows Unbounded Per-Project
**Location:** `architecture/performance.md` lines 248-276
**Issue:** WebSocket hub tracks connections per-project with limit of 100, but no discussion of cleanup for inactive connections or validation that limit is enforced. Also, no per-user connection limit across all projects.
**Risk:**
- Memory leak if stale connections not cleaned up properly
- User opening many projects could create hundreds of connections
- No global connection limit could exhaust server resources

**Recommendation:**
```go
type WebSocketHub struct {
    projectConns   map[string]map[*Connection]bool
    userConns      map[string]map[*Connection]bool
    globalMaxConns int // Global connection limit (e.g., 1000)
    mu             sync.RWMutex
    cleaner        *ConnectionCleaner
}

type ConnectionCleaner struct {
    hub              *WebSocketHub
    inactiveTimeout  time.Duration // 5 minutes
    cleanupInterval  time.Duration // 1 minute
}

func (cc *ConnectionCleaner) Run(ctx context.Context) {
    ticker := time.NewTicker(cc.cleanupInterval)
    defer ticker.Stop()

    for {
        select {
        case <-ticker.C:
            cc.cleanupInactiveConnections()
        case <-ctx.Done():
            return
        }
    }
}

func (h *WebSocketHub) AddConnection(conn *Connection) error {
    h.mu.Lock()
    defer h.mu.Unlock()

    // Enforce global connection limit
    totalConns := h.countTotalConnections()
    if totalConns >= h.globalMaxConns {
        return ErrTooManyConnections
    }

    // Enforce per-user limit
    if len(h.userConns[conn.UserID]) >= 10 {
        return ErrUserConnectionLimitExceeded
    }

    // Enforce per-project limit
    if len(h.projectConns[conn.ProjectID]) >= 100 {
        return ErrProjectConnectionLimitExceeded
    }

    // Add to both indexes
    h.projectConns[conn.ProjectID][conn] = true
    h.userConns[conn.UserID][conn] = true

    return nil
}
```

### [H4] SME Knowledge Snapshot Lacks Versioning Strategy
**Location:** `architecture/components/sme-knowledge.md` lines 74-85
**Issue:** Workflows snapshot SME knowledge at start but no discussion of snapshot storage, size limits, or cleanup. If knowledge base is large (thousands of guidelines/templates/examples), each workflow stores a full copy.
**Risk:**
- Storage bloat: 100 concurrent workflows * 10MB knowledge snapshot = 1GB redundant storage
- No deduplication or compression mentioned
- Snapshots never cleaned up after workflow completion

**Recommendation:**
```go
type KnowledgeSnapshot struct {
    ID              string    `firestore:"id"`
    OrgID           string    `firestore:"orgId"`
    AgentType       string    `firestore:"agentType"`
    SnapshotHash    string    `firestore:"snapshotHash"` // SHA-256 of content
    ContentRef      string    `firestore:"contentRef"`   // GCS path for large snapshots
    CreatedAt       time.Time `firestore:"createdAt"`
    RefCount        int       `firestore:"refCount"`     // Number of workflows using this
}

// Deduplication: multiple workflows with same snapshot share storage
func (s *SMEService) CreateSnapshot(ctx context.Context, orgID, agentType string) (*KnowledgeSnapshot, error) {
    knowledge, err := s.getCurrentKnowledge(ctx, orgID, agentType)
    if err != nil {
        return nil, err
    }

    // Hash content to detect duplicates
    contentHash := s.hashKnowledge(knowledge)

    // Check if identical snapshot exists
    existing, err := s.findSnapshotByHash(ctx, contentHash)
    if err == nil {
        // Reuse existing snapshot, increment refcount
        s.incrementRefCount(ctx, existing.ID)
        return existing, nil
    }

    // Create new snapshot (store large content in GCS)
    snapshot := &KnowledgeSnapshot{
        ID:           uuid.New().String(),
        OrgID:        orgID,
        AgentType:    agentType,
        SnapshotHash: contentHash,
        ContentRef:   s.storeToGCS(ctx, knowledge), // Offload to object storage
        RefCount:     1,
        CreatedAt:    time.Now(),
    }
    return snapshot, s.repo.SaveSnapshot(ctx, snapshot)
}

// Cleanup when workflow completes
func (s *SMEService) ReleaseSnapshot(ctx context.Context, snapshotID string) error {
    if err := s.decrementRefCount(ctx, snapshotID); err != nil {
        return err
    }

    // Delete snapshot if no longer in use
    snapshot, _ := s.repo.GetSnapshot(ctx, snapshotID)
    if snapshot.RefCount <= 0 {
        s.deleteFromGCS(ctx, snapshot.ContentRef)
        return s.repo.DeleteSnapshot(ctx, snapshotID)
    }
    return nil
}
```

### [H5] Missing Index on Cross-Phase References
**Location:** `architecture/components/agent-framework.md` lines 97-109
**Issue:** Artifacts include `basedOn` references to upstream artifacts for impact analysis, but no index defined for reverse lookup (find all artifacts that depend on REQ-12). Impact analysis queries could be slow.
**Risk:**
- Change request impact analysis requires scanning all artifacts in workflow
- O(n) complexity for finding downstream dependencies
- Slow approval workflows as project size grows

**Recommendation:**
```yaml
# firestore.indexes.json - Add composite index for impact analysis
{
  "indexes": [
    {
      "collectionGroup": "artifacts",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "workflowId", "order": "ASCENDING"},
        {"fieldPath": "basedOn.requirements", "arrayConfig": "CONTAINS"}
      ]
    },
    {
      "collectionGroup": "artifacts",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "workflowId", "order": "ASCENDING"},
        {"fieldPath": "basedOn.architecture", "arrayConfig": "CONTAINS"}
      ]
    }
  ]
}
```

```go
// Optimized impact analysis with indexed query
func (r *ArtifactRepository) FindDependentArtifacts(ctx context.Context, workflowID, artifactID string) ([]*Artifact, error) {
    // Use indexed query instead of scan
    query := r.client.Collection("artifacts").
        Where("workflowId", "==", workflowID).
        Where("basedOn.requirements", "array-contains", artifactID)

    // This uses the composite index for efficient lookup
}
```

---

## Medium (Consider Fixing)

### [M1] Batch Loading Window Too Small
**Location:** `architecture/performance.md` lines 52
**Issue:** DataLoader batching window is 2ms, which may not allow sufficient requests to accumulate for effective batching in low-traffic scenarios.
**Risk:**
- Ineffective batching during normal load results in more individual queries
- Tuning too high adds latency, too low reduces batch size

**Recommendation:**
```go
// Make batching window configurable based on load
dataloader.WithWait(10*time.Millisecond),  // Allow more time for batch accumulation
dataloader.WithBatchCapacity(100),         // Batch up to 100 items
```

Monitor batch sizes and adjust dynamically based on request patterns.

### [M2] No Mention of Connection Pooling for Firestore
**Location:** `architecture/data-model.md` and repository implementations
**Issue:** Firestore client initialization not discussed. Default client may not pool connections efficiently for concurrent requests.
**Risk:**
- Connection overhead on every request
- Potential connection exhaustion under load

**Recommendation:**
```go
// Initialize Firestore client with optimal settings
func NewFirestoreClient(ctx context.Context, projectID string) (*firestore.Client, error) {
    client, err := firestore.NewClient(ctx, projectID,
        option.WithGRPCConnectionPool(4), // Pool connections for concurrency
    )
    if err != nil {
        return nil, err
    }
    return client, nil
}
```

### [M3] Cache Invalidation on Events Not Specified
**Location:** `architecture/performance.md` lines 190-197
**Issue:** Cache TTLs defined but invalidation strategy mentions "On update event" without implementation details. Cache could serve stale data if events are missed.
**Risk:**
- Stale cache reads between event dispatch and cache invalidation
- Race conditions if invalidation is async

**Recommendation:**
```go
// Event-driven cache invalidation
func NewCacheInvalidationHandler(cache *MultiLevelCache) EventHandler {
    return func(ctx context.Context, event Event) error {
        switch e := event.(type) {
        case *SMEKnowledgeUpdatedEvent:
            key := fmt.Sprintf("sme:%s:%s", e.OrgID, e.AgentType)
            return cache.Invalidate(ctx, key)
        case *ProjectUpdatedEvent:
            key := fmt.Sprintf("project:%s", e.ProjectID)
            return cache.Invalidate(ctx, key)
        case *OrgSettingsUpdatedEvent:
            key := fmt.Sprintf("org:%s", e.OrgID)
            return cache.Invalidate(ctx, key)
        }
        return nil
    }
}

// Subscribe to invalidation events
bus.Subscribe([]string{
    "SMEKnowledgeUpdated",
    "ProjectUpdated",
    "OrgSettingsUpdated",
}, invalidationHandler)
```

### [M4] LLM Request Queuing Unbounded
**Location:** `architecture/llm-resilience.md` lines 247-272
**Issue:** Request queue for rate limiting has channel but no maximum queue size specified. Could accumulate unbounded backlog during outages.
**Risk:**
- Memory exhaustion if queue grows too large
- Stale requests processed after long delays

**Recommendation:**
```go
type RequestQueue struct {
    queue    chan *queuedRequest
    maxQueue int // Maximum pending requests
    workers  int
    provider Provider
}

func (rq *RequestQueue) Submit(ctx context.Context, req *Request) (*Response, error) {
    result := make(chan *queueResult, 1)

    qr := &queuedRequest{ctx: ctx, req: req, result: result}

    select {
    case rq.queue <- qr:
        // Queued successfully
    case <-ctx.Done():
        return nil, ctx.Err()
    default:
        // Queue full, reject immediately
        return nil, ErrQueueFull
    }

    select {
    case r := <-result:
        return r.resp, r.err
    case <-ctx.Done():
        return nil, ctx.Err()
    }
}

// Initialize with bounded queue
func NewRequestQueue(provider Provider, workers, maxQueue int) *RequestQueue {
    return &RequestQueue{
        queue:    make(chan *queuedRequest, maxQueue), // Bounded buffer
        maxQueue: maxQueue,
        workers:  workers,
        provider: provider,
    }
}
```

### [M5] No Query Caching for Repeated Reads
**Location:** `architecture/performance.md` caching section
**Issue:** Caching strategy focuses on metadata but doesn't address repeated reads of immutable data like approved artifacts or historical events.
**Risk:**
- Redundant Firestore reads for data that never changes
- Wasted read operations and cost

**Recommendation:**
```go
// Cache immutable artifacts after approval
func (r *ArtifactRepository) GetArtifact(ctx context.Context, id string) (*Artifact, error) {
    // Check cache first
    cacheKey := fmt.Sprintf("artifact:%s", id)
    if cached, err := r.cache.Get(ctx, cacheKey); err == nil {
        var artifact Artifact
        json.Unmarshal(cached, &artifact)
        return &artifact, nil
    }

    // Fetch from Firestore
    artifact, err := r.fetchFromFirestore(ctx, id)
    if err != nil {
        return nil, err
    }

    // Cache approved artifacts indefinitely (they're immutable)
    if artifact.Status == "approved" {
        data, _ := json.Marshal(artifact)
        r.cache.Set(ctx, cacheKey, data, 24*time.Hour, 7*24*time.Hour)
    }

    return artifact, nil
}
```

---

## Low (Nice to Have)

### [L1] Firestore Batch Write Opportunities
**Location:** Repository implementations
**Issue:** Individual writes for related entities could be batched for better performance.
**Risk:** Minor - increased latency and write costs but not blocking

**Recommendation:**
```go
// Batch related writes
func (r *WorkflowRepository) CompletePhase(ctx context.Context, workflowID string, artifacts []*Artifact) error {
    batch := r.client.Batch()

    // Update workflow
    workflowRef := r.client.Collection("workflows").Doc(workflowID)
    batch.Update(workflowRef, []firestore.Update{
        {Path: "currentPhase", Value: "next_phase"},
        {Path: "updatedAt", Value: time.Now()},
    })

    // Create artifacts in same batch
    for _, artifact := range artifacts {
        artifactRef := r.client.Collection("artifacts").Doc(artifact.ID)
        batch.Set(artifactRef, artifact)
    }

    // Single network round-trip instead of N+1
    _, err := batch.Commit(ctx)
    return err
}
```

### [L2] Metrics Aggregation Could Be More Efficient
**Location:** `architecture/llm-resilience.md` lines 323-356
**Issue:** Prometheus metrics use HistogramVec and CounterVec with multiple labels, which can create high cardinality.
**Risk:** Minimal - may impact monitoring system performance at very high scale

**Recommendation:**
Limit label cardinality or use summary metrics instead of histograms for high-throughput operations.

### [L3] WebSocket Message Encoding Optimization
**Location:** `architecture/performance.md` lines 265
**Issue:** JSON encoding per message could be replaced with more efficient binary format for high-frequency updates.
**Risk:** Minimal - only impacts bandwidth, not correctness

**Recommendation:**
Consider Protocol Buffers or MessagePack for WebSocket messages if bandwidth becomes constrained.

---

## Notes (Observations, Not Issues)

- **Positive:** Comprehensive DataLoader pattern implementation for N+1 prevention shows strong performance awareness
- **Positive:** Multi-level caching strategy (L1/L2) is well-designed with appropriate TTLs
- **Positive:** Circuit breaker pattern for LLM resilience prevents cascading failures
- **Positive:** Conversation history management with bounded token limits prevents context explosion
- **Positive:** WebSocket targeted broadcasting avoids wasteful global broadcasts
- **Positive:** Explicit performance targets defined (P50/P95 latency, cache hit rate)
- **Positive:** Pagination implemented with cursor-based approach (more scalable than offset)
- **Positive:** Firestore composite indexes defined for common query patterns

- **Observation:** Performance testing strategy not documented - recommend load testing with realistic data volumes (1000+ projects, 10,000+ artifacts, 100+ concurrent users)
- **Observation:** No discussion of database sharding strategy for multi-tenant isolation - may need sharding by orgID for very large deployments
- **Observation:** Rate limiting is provider-focused but no mention of per-user/org rate limits to prevent abuse
- **Observation:** Cost monitoring appears limited to token usage - recommend adding Firestore read/write cost tracking
- **Observation:** Event replay performance for long-running workflows not addressed - consider incremental snapshots after N events

---

## Recommended Actions (Prioritized)

1. **Critical Priority:**
   - Implement event history partitioning and archival strategy (C1)
   - Add query projections for list views to reduce over-fetching (C2)
   - Make event bus concurrent with per-handler timeouts (C3)

2. **High Priority:**
   - Add vector query performance limits and ANN indexing (H1)
   - Implement lazy/async conversation summarization with caching (H2)
   - Add WebSocket connection cleanup and global limits (H3)
   - Implement SME knowledge snapshot deduplication and cleanup (H4)
   - Add Firestore indexes for impact analysis queries (H5)

3. **Medium Priority:**
   - Tune DataLoader batching window based on load patterns (M1)
   - Configure Firestore connection pooling (M2)
   - Implement event-driven cache invalidation (M3)
   - Add bounded queue for LLM requests (M4)
   - Cache immutable artifacts and events (M5)

4. **Before Launch:**
   - Conduct load testing with realistic data volumes
   - Document performance testing results and bottlenecks
   - Set up monitoring dashboards for all identified metrics
   - Create runbooks for performance incidents (circuit open, high latency, etc.)

---

## Performance Benchmarking Recommendations

The architecture would benefit from concrete performance validation:

```go
// Benchmark critical paths
func BenchmarkInboxQuery(b *testing.B) {
    // Setup: 100 projects, 1000 artifacts, 50 escalations
    // Measure: Time to fetch user's inbox
    // Target: <100ms P95
}

func BenchmarkEventReplay(b *testing.B) {
    // Setup: Workflow with 1000 events
    // Measure: Time to reconstruct state
    // Target: <500ms P95
}

func BenchmarkImpactAnalysis(b *testing.B) {
    // Setup: 500 artifacts with cross-references
    // Measure: Time to find all dependents
    // Target: <200ms P95
}
```

Monitor these metrics in production and establish baselines before claiming performance targets are met.
