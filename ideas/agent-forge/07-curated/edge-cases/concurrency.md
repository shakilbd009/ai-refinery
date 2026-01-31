# Edge Cases: Concurrency

## Multi-User Collaboration

### Simultaneous Edits to Same Item

**Trigger:** Two users edit same artifact at once

**Impact:** Lost work, confusion

**Mitigation:**
- Optimistic locking with version numbers
- On save, check version matches
- If conflict: show diff, let user merge or overwrite
- Real-time presence indicators (who's viewing)

### Simultaneous Approvals

**Trigger:** Two approvers click approve at same time

**Impact:** Duplicate processing

**Mitigation:**
- Idempotent approval (second is no-op)
- Show who approved in UI
- Last-write-wins for status
- Audit log captures both actions

### One User Rejects While Another Approves

**Trigger:** Race between approve and reject

**Impact:** Unclear item status

**Mitigation:**
- Last-write-wins
- Notify both users of conflict
- Show decision history on item
- Rejected state triggers re-work regardless of prior approval

---

## Locking

### Lock Held Too Long

**Trigger:** User locks item, goes AFK

**Impact:** Others blocked indefinitely

**Mitigation:**
- Lock timeout: 5 minutes of inactivity
- Heartbeat required to maintain lock
- Warning at 4 minutes: "Lock expiring"
- After timeout: auto-release with notification

### Lock Acquisition Race

**Trigger:** Two users click edit simultaneously

**Impact:** One fails unexpectedly

**Mitigation:**
- Optimistic lock attempt
- Loser gets: "Item locked by [user]. Retry in a moment."
- Show lock holder and estimated availability
- Queue notification for when released

### Stale Lock After Crash

**Trigger:** User's browser crashes while holding lock

**Impact:** Lock never released

**Mitigation:**
- Server-side heartbeat monitoring
- No heartbeat for 60s = auto-release
- Clean up locks on session end
- Admin can force-release locks

---

## Real-Time Updates

### Message Ordering

**Trigger:** WebSocket messages arrive out of order

**Impact:** UI shows stale state

**Mitigation:**
- Sequence numbers on all messages
- Client reorders by sequence
- Gap detection triggers re-sync
- Idempotent message handling

### Missed Updates During Disconnect

**Trigger:** User's connection drops briefly

**Impact:** UI out of sync with server

**Mitigation:**
- Reconnect with last-seen sequence
- Server replays missed events
- Full sync if gap too large
- "Reconnecting..." indicator

### Conflicting Real-Time State

**Trigger:** Local state differs from server update

**Impact:** UI flicker, confusion

**Mitigation:**
- Server is authoritative
- Local optimistic updates with rollback
- Conflict resolution favors server
- User notified of unexpected changes

---

## Database Transactions

### Transaction Timeout

**Trigger:** Firestore transaction exceeds limit

**Impact:** Operation fails

**Mitigation:**
- Keep transactions small and fast
- Retry with exponential backoff
- Max 3 retries
- Break large operations into smaller transactions

### Contention on Hot Documents

**Trigger:** Many users updating same document

**Impact:** High retry rate, slow operations

**Mitigation:**
- Sharded counters for high-write fields
- Batch writes where possible
- Queue writes for non-critical fields
- Monitor contention metrics

### Partial Transaction Failure

**Trigger:** Some writes succeed, transaction aborted

**Impact:** Inconsistent state (shouldn't happen with transactions)

**Mitigation:**
- Firestore transactions are atomic
- All-or-nothing guaranteed
- If partial state detected: bug, investigate
- Event sourcing enables reconstruction

---

## State Synchronization

### REST/WebSocket State Divergence

**Trigger:** WebSocket update arrives before REST response

**Impact:** UI shows stale data briefly

**Mitigation:**
- Optimistic updates with rollback capability
- Version numbers on all entities
- REST response always authoritative
- Debounce rapid updates client-side

### Event Ordering Across Channels

**Trigger:** Events arrive out of order via WebSocket

**Impact:** UI state inconsistent

**Mitigation:**
- Sequence numbers on all events
- Client maintains event buffer for reordering
- Gap detection triggers full resync
- Timestamps as secondary ordering

### Stale Read After Write

**Trigger:** Read immediately after write returns old value

**Impact:** User sees outdated data

**Mitigation:**
- Write-through to client state
- Optional read-your-writes consistency (session affinity)
- Firestore real-time listeners for critical data
- Clear loading states during writes

### Multi-Device Sync

**Trigger:** User has multiple tabs/devices open

**Impact:** Actions on one device not reflected on others

**Mitigation:**
- All devices subscribe to project WebSocket
- Events broadcast to all sessions for user
- Conflict resolution: last-write-wins with notification
- "Updated on another device" toast for conflicts
