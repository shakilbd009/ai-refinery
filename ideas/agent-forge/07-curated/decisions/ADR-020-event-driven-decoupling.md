# ADR-020: Event-Driven Decoupling

## Status

Accepted

## Context

The Agent Framework and Workflow Engine have a circular dependency:
- Workflow Engine dispatches tasks to agents
- Agents report completion/failure back to Workflow Engine
- Both components import each other, creating tight coupling

This makes testing difficult, changes risky, and the architecture harder to understand.

We considered:
1. Accepting the circular dependency with careful interface design
2. Merging the components into one
3. Introducing an event bus for decoupling
4. Using a command/query separation pattern

## Decision

We will introduce an **in-process Event Bus** to decouple the Agent Framework from the Workflow Engine.

### Event Flow

Instead of direct calls:
```go
// Before: tight coupling
agent.Execute(task)
workflowService.HandleCompletion(result)
```

Events flow through the bus:
```go
// After: loose coupling
eventBus.Publish(AgentTaskCompletedEvent{...})
// Workflow subscribes and handles asynchronously
```

### Event Types

- **Agent Events**: TaskStarted, TaskProgress, TaskCompleted, TaskFailed
- **Workflow Events**: PhaseStarted, PhaseCompleted, EscalationCreated
- **User Events**: MessageSent, ArtifactApproved, ArtifactRejected

### Implementation

Start with an in-process event bus using Go channels and sync primitives. The interface is designed to support future migration to distributed messaging (Pub/Sub, NATS) without changing publishers or subscribers.

## Rationale

Event-driven decoupling was chosen because:

1. **Breaks Circular Dependency**: Components only depend on event types, not each other
2. **Testability**: Components can be tested in isolation with mock event bus
3. **Flexibility**: Easy to add new subscribers without modifying publishers
4. **Audit Trail**: All events can be persisted for event sourcing (ADR-009)
5. **Real-time Updates**: WebSocket broadcaster is just another subscriber

### Rejected Alternatives

**Accepting circular dependency**:
- Makes unit testing difficult
- Changes in one component ripple to the other
- Hard to reason about control flow

**Merging components**:
- Creates a monolithic component
- Loses separation of concerns
- Harder to maintain and extend

**Command/Query Separation**:
- More complex than needed
- Overkill for our use case
- Event bus provides similar benefits more simply

## Consequences

### Positive

- Clear separation of concerns
- Easy to add new event consumers
- Natural fit for WebSocket broadcasting
- Enables event sourcing
- Simplified testing

### Negative

- Adds indirection (events instead of direct calls)
- Debugging requires tracing through events
- Event ordering must be carefully managed
- Slightly more complex error handling

### Mitigations

- Strong event typing prevents mismatches
- Correlation IDs in events for tracing
- Synchronous mode for critical paths if needed
- Comprehensive logging of event flow

## Implementation Notes

### In-Process Bus (Concurrent with Timeouts)

**Critical**: Event publishing must be concurrent with timeouts to prevent slow subscribers from blocking all event delivery.

```go
type InProcessEventBus struct {
    subscribers    map[string][]EventHandler
    allHandlers    []EventHandler
    handlerTimeout time.Duration
    workerPool     *WorkerPool
    mu             sync.RWMutex
}

func NewInProcessEventBus(handlerTimeout time.Duration, poolSize int) *InProcessEventBus {
    return &InProcessEventBus{
        subscribers:    make(map[string][]EventHandler),
        allHandlers:    []EventHandler{},
        handlerTimeout: handlerTimeout,
        workerPool:     NewWorkerPool(poolSize),
    }
}

func (bus *InProcessEventBus) Publish(ctx context.Context, event Event) error {
    bus.mu.RLock()
    handlers := append(bus.subscribers[event.Type()], bus.allHandlers...)
    bus.mu.RUnlock()

    if len(handlers) == 0 {
        return nil
    }

    // Use WaitGroup to track completion, but with overall timeout
    var wg sync.WaitGroup
    errChan := make(chan error, len(handlers))

    for _, handler := range handlers {
        wg.Add(1)
        h := handler // Capture for goroutine

        bus.workerPool.Submit(func() {
            defer wg.Done()

            // Per-handler timeout
            handlerCtx, cancel := context.WithTimeout(ctx, bus.handlerTimeout)
            defer cancel()

            done := make(chan error, 1)
            go func() {
                done <- h(handlerCtx, event)
            }()

            select {
            case err := <-done:
                if err != nil {
                    errChan <- fmt.Errorf("handler error: %w", err)
                }
            case <-handlerCtx.Done():
                errChan <- fmt.Errorf("handler timeout after %v", bus.handlerTimeout)
                bus.metrics.HandlerTimeout.Inc()
            }
        })
    }

    // Wait for all handlers with overall timeout
    done := make(chan struct{})
    go func() {
        wg.Wait()
        close(done)
    }()

    overallTimeout := bus.handlerTimeout * 2 // Allow some buffer
    select {
    case <-done:
        // All handlers completed
    case <-time.After(overallTimeout):
        bus.metrics.PublishTimeout.Inc()
        // Continue - don't block caller indefinitely
    }

    close(errChan)

    // Collect errors (non-blocking)
    var errs []error
    for err := range errChan {
        errs = append(errs, err)
    }

    if len(errs) > 0 {
        return fmt.Errorf("event delivery partial failure: %d/%d handlers failed", len(errs), len(handlers))
    }
    return nil
}

// Worker pool prevents goroutine explosion
type WorkerPool struct {
    tasks chan func()
    wg    sync.WaitGroup
}

func NewWorkerPool(size int) *WorkerPool {
    pool := &WorkerPool{
        tasks: make(chan func(), size*10), // Buffered for burst handling
    }
    for i := 0; i < size; i++ {
        pool.wg.Add(1)
        go pool.worker()
    }
    return pool
}

func (p *WorkerPool) worker() {
    defer p.wg.Done()
    for task := range p.tasks {
        task()
    }
}

func (p *WorkerPool) Submit(task func()) {
    p.tasks <- task
}
```

### Handler Priority

Critical handlers (e.g., event persistence) run with higher priority:

```go
type PrioritizedHandler struct {
    Handler  EventHandler
    Priority int // Higher = more important
    Critical bool // If true, failures are logged as errors
}

func (bus *InProcessEventBus) SubscribeWithPriority(eventType string, ph PrioritizedHandler) {
    // Critical handlers get longer timeouts
    if ph.Critical {
        bus.criticalHandlers[eventType] = append(bus.criticalHandlers[eventType], ph)
    } else {
        bus.subscribers[eventType] = append(bus.subscribers[eventType], ph.Handler)
    }
}
```

### Degraded Mode

If handlers consistently timeout, circuit breaker disables them temporarily:

```go
func (bus *InProcessEventBus) wrapWithCircuitBreaker(handler EventHandler, name string) EventHandler {
    cb := NewCircuitBreaker(name, CircuitConfig{
        FailureThreshold: 5,
        Timeout:          30 * time.Second,
    })

    return func(ctx context.Context, event Event) error {
        if !cb.Allow() {
            bus.metrics.HandlerCircuitOpen.WithLabelValues(name).Inc()
            return nil // Skip this handler
        }

        err := handler(ctx, event)
        if err != nil {
            cb.RecordFailure()
        } else {
            cb.RecordSuccess()
        }
        return err
    }
}
```

### Future: Distributed Bus

The interface supports future migration:

```go
type PubSubEventBus struct {
    client *pubsub.Client
    topic  *pubsub.Topic
}

func (bus *PubSubEventBus) Publish(ctx context.Context, event Event) error {
    data, _ := json.Marshal(event)
    _, err := bus.topic.Publish(ctx, &pubsub.Message{Data: data}).Get(ctx)
    return err
}
```

## Related

- [Event Bus Architecture](../architecture/event-bus.md)
- [ADR-009: Event Sourcing](./ADR-009-event-sourcing.md)
