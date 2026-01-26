# State Transition Edge Cases

State machines, race conditions, persistence failures, orphaned states, and recovery patterns.

---

## Invalid State Transitions

### Order Status Transitions

```
Valid transitions:
  pending -> confirmed -> shipped -> delivered
  pending -> canceled
  confirmed -> canceled
  confirmed -> refunded (after payment)
  shipped -> delivered
  delivered -> (terminal state)
  canceled -> (terminal state)
  refunded -> (terminal state)

Invalid transitions (must reject):
  canceled -> confirmed  (can't resurrect canceled order)
  canceled -> shipped    (can't ship canceled order)
  refunded -> confirmed  (can't un-refund)
  delivered -> shipped   (can't go backwards)
  shipped -> pending     (can't go backwards)
```

| Current State | Attempted State | Handling |
|---------------|-----------------|----------|
| canceled | confirmed | 400 "Cannot modify canceled order" |
| refunded | shipped | 400 "Cannot ship refunded order" |
| delivered | any | 400 "Order already delivered" |
| pending | delivered | 400 "Order must be shipped first" |

```javascript
const VALID_TRANSITIONS = {
  pending: ['confirmed', 'canceled'],
  confirmed: ['shipped', 'canceled', 'refunded'],
  shipped: ['delivered'],
  delivered: [],
  canceled: [],
  refunded: [],
};

function validateStateTransition(currentState, newState) {
  const allowed = VALID_TRANSITIONS[currentState] || [];
  if (!allowed.includes(newState)) {
    throw new ValidationError(
      `Cannot transition from ${currentState} to ${newState}`
    );
  }
}
```

### Reservation Status Transitions

```
Valid:
  active -> completing -> completed
  active -> expired (by cleanup job)
  active -> admin_cancelled (by admin)
  completing -> completed (payment succeeded)
  completing -> active (payment failed, restore)

Invalid:
  expired -> active (can't resurrect)
  completed -> active (can't undo order)
  admin_cancelled -> active (can't restore without new reservation)
```

### Review Status Transitions

```
Valid:
  pending_moderation -> approved
  pending_moderation -> rejected
  approved -> hidden (admin action)
  approved -> edited (customer edit, re-moderation)

Invalid:
  rejected -> approved (must re-submit as new review)
  hidden -> approved (admin must explicitly unhide)
```

---

## Race Conditions on State Changes

### Concurrent Order Status Updates

| Scenario | Race Condition | Resolution |
|----------|----------------|------------|
| Admin cancels while shipping | Both try to update status | Transaction: first wins, second sees conflict |
| Two admins ship same order | Duplicate shipping label risk | Status check in transaction, second fails |
| Refund while customer requests cancel | Both valid but conflicting | First to commit wins |

```javascript
async function updateOrderStatus(orderId, newStatus, userId) {
  return firestore.runTransaction(async (transaction) => {
    const orderRef = firestore.doc(`orders/${orderId}`);
    const order = await transaction.get(orderRef);

    if (!order.exists) throw new Error('Order not found');

    const currentStatus = order.data().status;
    validateStateTransition(currentStatus, newStatus);

    transaction.update(orderRef, {
      status: newStatus,
      status_updated_at: FieldValue.serverTimestamp(),
      status_updated_by: userId,
    });

    return { previousStatus: currentStatus, newStatus };
  });
}
```

### Concurrent Inventory Updates

| Scenario | Race Condition | Resolution |
|----------|----------------|------------|
| Two customers reserve last unit | Both see available = 1 | Transaction conflict, retry, loser sees 0 |
| Admin updates while customer reserves | Quantity changes mid-reservation | Transaction ensures consistency |
| Cleanup job + payment complete | Both try to release reservation | Idempotent: status check first |

---

## State Persistence Failures

### Partial Write Scenarios

| Operation | Failure Point | State After Failure | Recovery |
|-----------|---------------|---------------------|----------|
| Create order | After payment, before order write | Payment exists, no order | Webhook retry creates order |
| Reserve inventory | After reservation, before quantity update | Reservation orphaned | Cleanup job releases |
| Apply discount | After usage record, before order | Usage exists, no order | Order creation checks existing usage |
| Ship order | After status update, before shipping label | Status = shipped, no label | Admin manually creates label |

### Transaction Guarantees

```javascript
async function createOrder(paymentIntentId) {
  return firestore.runTransaction(async (transaction) => {
    // All reads first
    const reservation = await transaction.get(reservationRef);
    const products = await Promise.all(productRefs.map(r => transaction.get(r)));

    // All writes together (atomic)
    transaction.create(orderRef, orderData);
    transaction.delete(reservationRef);
    products.forEach((prod, i) => {
      transaction.update(productRefs[i], {
        quantity: FieldValue.increment(-items[i].quantity),
        reserved_quantity: FieldValue.increment(-items[i].quantity),
      });
    });

    // If any write fails, all roll back
  });
}
```

---

## Orphaned States

### Orphan Scenarios

| Orphan Type | How Created | Detection | Cleanup |
|-------------|-------------|-----------|---------|
| Reservation without order | Customer abandons checkout | expires_at < now | Background job every 5 min |
| Payment intent without order | Webhook never delivered | Stripe dashboard check | Manual order creation |
| Usage record without order | Transaction failed mid-way | order_id = null | Cleanup job deletes orphans |
| Order without payment | Should never happen | payment_intent_id = null | Alert + investigation |
| Review without order | Order deleted after review | order_id foreign key missing | Keep review, mark order_deleted |

### Orphan Detection Queries

```javascript
// Find reservations that should be cleaned up
const orphanedReservations = await firestore
  .collection('reservations')
  .where('status', '==', 'active')
  .where('expires_at', '<', now)
  .get();

// Find usage records without orders (orphaned)
const orphanedUsage = await firestore
  .collection('promo_code_usage')
  .where('order_id', '==', null)
  .where('created_at', '<', oneHourAgo)
  .get();
```

---

## Recovery from Partial State

### Rollback Scenarios

| Scenario | Partial State | Rollback Action |
|----------|---------------|-----------------|
| Payment failed after reservation | Reservation exists, no order | Reservation expires naturally (15 min) |
| Inventory update failed | reserved_quantity inconsistent | Recalculate from reservations collection |
| Promo code update failed | used_count wrong | Recalculate from usage records |
| Email send failed | Order exists, no email | Retry queue, admin can resend |

### Reconciliation Pattern

```javascript
async function reconcileReservedQuantity(productId) {
  const activeReservations = await firestore
    .collection('reservations')
    .where('status', '==', 'active')
    .get();

  let calculatedReserved = 0;
  activeReservations.forEach(res => {
    const item = res.data().items.find(i => i.product_id === productId);
    if (item) calculatedReserved += item.quantity;
  });

  const product = await firestore.doc(`products/${productId}`).get();
  const storedReserved = product.data().reserved_quantity;

  if (calculatedReserved !== storedReserved) {
    console.warn(`Mismatch: stored=${storedReserved}, calculated=${calculatedReserved}`);
    await firestore.doc(`products/${productId}`).update({
      reserved_quantity: calculatedReserved,
      reconciled_at: FieldValue.serverTimestamp(),
    });
  }
}
```
