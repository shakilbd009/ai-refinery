# ADR-009: Event Sourcing for Audit Trail

## Status
Accepted

## Context
The workflow engine needs to track state and support recovery from failures. Options:
1. Current state only - simple but no history
2. Changelog - append changes to log
3. Event sourcing - all state derived from immutable events

## Decision
Use **event sourcing** as the foundation for workflow state:

Every action logged as an immutable event:
```
EVENT: artifact_created
  workflow_id: WF-123
  phase: architecture
  artifact_id: ARCH-5
  timestamp: 2026-01-15T10:32:15Z
  data: { ... }

EVENT: artifact_approved
  workflow_id: WF-123
  artifact_id: ARCH-5
  user_id: sarah@acme.com
  timestamp: 2026-01-15T10:45:22Z
```

Complemented by:
- **Checkpoints**: Workflow state snapshotted at key points
- **Transactional steps**: Each operation atomic (completes or rolls back)

## Consequences

### Positive
- Complete audit trail of all actions
- Workflow state can be rebuilt from events
- Supports debugging and analytics
- Enables point-in-time recovery
- Natural fit for compliance requirements

### Negative
- Storage overhead for event log
- Complexity in state reconstruction
- Must manage event schema evolution

### Mitigations
- Checkpoints enable fast recovery without full replay
- Events can be archived/compacted over time
- Event versioning strategy for schema changes
- **Time-based partitioning** prevents unbounded growth (see below)

---

## Event Partitioning Strategy

Without partitioning, event history grows unbounded and degrades query performance. We implement **time-based partitioning** with automatic archival.

### Partition Scheme

```
events/
  └── {workflow_id}/
      └── {year-month}/
          └── {event_id}
```

| Partition | Retention | Access Pattern |
|-----------|-----------|----------------|
| Current month | Hot storage | Direct queries |
| 1-6 months | Warm storage | On-demand load |
| 6+ months | Cold archive | Batch export only |

### Implementation

```go
type PartitionedEventStore struct {
    hotStore    *firestore.Client     // Current month
    warmStore   *firestore.Client     // Recent months (could be same)
    coldArchive *storage.BucketHandle // GCS for archives
}

func (s *PartitionedEventStore) AppendEvent(ctx context.Context, event Event) error {
    partition := event.Timestamp.Format("2006-01")
    docPath := fmt.Sprintf("events/%s/%s/%s", event.WorkflowID, partition, event.ID)

    _, err := s.hotStore.Doc(docPath).Set(ctx, event)
    return err
}

func (s *PartitionedEventStore) GetEventsForReplay(ctx context.Context, workflowID string, since time.Time) ([]Event, error) {
    // Start from most recent checkpoint if available
    checkpoint, err := s.getLatestCheckpoint(ctx, workflowID, since)
    if err == nil && checkpoint != nil {
        since = checkpoint.Timestamp
    }

    // Query only necessary partitions
    partitions := s.getPartitionsSince(since)
    var events []Event

    for _, partition := range partitions {
        partitionEvents, err := s.queryPartition(ctx, workflowID, partition, since)
        if err != nil {
            return nil, err
        }
        events = append(events, partitionEvents...)
    }

    return events, nil
}
```

### Automatic Archival

Background job archives old partitions:

```go
func (a *EventArchiver) ArchiveOldPartitions(ctx context.Context) error {
    cutoff := time.Now().AddDate(0, -6, 0) // 6 months ago

    partitions, _ := a.store.ListPartitionsOlderThan(ctx, cutoff)
    for _, partition := range partitions {
        // Export to GCS
        if err := a.exportToArchive(ctx, partition); err != nil {
            return err
        }

        // Delete from Firestore after successful export
        if err := a.store.DeletePartition(ctx, partition); err != nil {
            return err
        }

        log.Info("Archived partition", "partition", partition)
    }
    return nil
}
```

### Checkpoint Strategy

Checkpoints capture workflow state at key points to enable fast recovery:

```go
type Checkpoint struct {
    WorkflowID string    `firestore:"workflowId"`
    Timestamp  time.Time `firestore:"timestamp"`
    Phase      string    `firestore:"phase"`
    State      []byte    `firestore:"state"` // Serialized workflow state
    EventCount int       `firestore:"eventCount"`
}

// Checkpoint frequency: after every 100 events or phase transition
const checkpointFrequency = 100
```

### Query Optimization

| Query Type | Strategy |
|------------|----------|
| Recent events | Hot storage only |
| Workflow replay | Start from checkpoint |
| Audit trail | Query specific partition |
| Analytics | Pre-aggregated views |
