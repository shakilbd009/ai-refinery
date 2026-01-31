# Integration Edge Cases

External service failures, slow responses, rate limiting, webhook handling, and API versioning.

---

## External Service Down

### Stripe Down

| Scenario | Detection | Fallback | Customer Message |
|----------|-----------|----------|------------------|
| API unreachable | Connection timeout | None (critical path) | "Payment system unavailable" |
| Webhook endpoint down | Our side down | Stripe retries for 3 days | N/A (async) |
| Dashboard inaccessible | Admin can't refund | Wait or use API | N/A (admin) |

```javascript
async function createPaymentIntent(data) {
  try {
    return await stripe.paymentIntents.create(data);
  } catch (error) {
    if (error.type === 'StripeConnectionError') {
      logger.critical('Stripe connection failed', { error });
      alertOps('Stripe appears to be down');
      throw new ServiceUnavailableError('Payment system temporarily unavailable');
    }
    throw error;
  }
}
```

### Mailgun Down

| Scenario | Detection | Fallback | Impact |
|----------|-----------|----------|--------|
| API unreachable | Connection timeout | Queue for retry | Delayed emails |
| Rate limited | 429 response | Exponential backoff | Delayed emails |
| Quota exceeded | 402 response | Alert admin | No emails until resolved |

```javascript
async function sendEmail(email) {
  try {
    await mailgun.send(email);
    return { sent: true };
  } catch (error) {
    // Queue for retry
    await firestore.collection('email_queue').add({
      email,
      attempts: 0,
      next_retry: new Date(Date.now() + 5 * 60 * 1000),
      error: error.message,
    });
    return { sent: false, queued: true };
  }
}
```

### Firestore Down

| Scenario | Detection | Fallback | Impact |
|----------|-----------|----------|--------|
| Complete outage | All operations fail | None (critical) | Site down |
| Partial outage | Some regions affected | Multi-region config | Degraded |
| Quota exceeded | 429 errors | Alert + wait | Site slow/down |

**Note:** Firestore outage = site outage. No reasonable fallback for MVP. Monitor Firestore health.

---

## External Service Slow

### Slow Response Handling

| Service | Normal Latency | Slow Threshold | Action at Threshold |
|---------|----------------|----------------|---------------------|
| Stripe | 200-400ms | > 2s | Log warning, continue |
| Stripe | 200-400ms | > 10s | Timeout, show retry |
| Mailgun | 100-300ms | > 5s | Queue for async |
| Firestore | 20-100ms | > 1s | Log warning |
| Firestore | 20-100ms | > 5s | Alert, possible outage |

```javascript
async function timedFetch(operation, warningThreshold, errorThreshold) {
  const start = Date.now();
  try {
    const result = await operation();
    const duration = Date.now() - start;

    if (duration > errorThreshold) {
      logger.error(`Operation exceeded error threshold: ${duration}ms`);
    } else if (duration > warningThreshold) {
      logger.warn(`Operation slow: ${duration}ms`);
    }

    return result;
  } catch (error) {
    const duration = Date.now() - start;
    logger.error(`Operation failed after ${duration}ms`, { error });
    throw error;
  }
}
```

---

## External Service Rate Limiting

### Rate Limit Responses

| Service | Rate Limit | Detection | Handling |
|---------|------------|-----------|----------|
| Stripe | 100 req/sec | 429 response | Exponential backoff |
| Mailgun | 300 req/min | 429 response | Queue and throttle |
| Firestore | 10k writes/sec | 429 response | Unlikely to hit for MVP |

### Backoff Strategy

```javascript
async function withBackoff(operation, maxRetries = 5) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      if (error.status === 429 && attempt < maxRetries) {
        const delay = Math.pow(2, attempt) * 1000 + Math.random() * 1000;
        logger.warn(`Rate limited, retrying in ${delay}ms`);
        await sleep(delay);
        continue;
      }
      throw error;
    }
  }
}
```

---

## Webhook Delivery Failures

### Stripe Webhook Retry Schedule

| Attempt | Delay After Previous | Total Time |
|---------|---------------------|------------|
| 1 | Immediate | 0 |
| 2 | 1 minute | 1 min |
| 3 | 5 minutes | 6 min |
| 4 | 30 minutes | 36 min |
| 5 | 2 hours | 2.6 hours |
| ... | Continues | Up to 3 days |

### Webhook Failure Scenarios

| Failure | Stripe Behavior | Our Response |
|---------|-----------------|--------------|
| 500 error | Retry | Fix bug, wait for retry |
| 502/503 | Retry | Infra issue, auto-recover |
| Timeout (30s) | Retry | Optimize processing |
| 404 | Stop retrying | Misconfigured endpoint |
| Invalid signature | Stop retrying | Security issue, investigate |

### Idempotent Webhook Processing

```javascript
async function handleStripeWebhook(event) {
  // Check if already processed
  const existing = await firestore
    .collection('processed_webhooks')
    .doc(event.id)
    .get();

  if (existing.exists) {
    logger.info(`Webhook ${event.id} already processed`);
    return { status: 200, message: 'Already processed' };
  }

  // Process webhook
  await processPaymentSuccess(event);

  // Mark as processed
  await firestore.collection('processed_webhooks').doc(event.id).set({
    processed_at: FieldValue.serverTimestamp(),
    event_type: event.type,
  });

  return { status: 200, message: 'Processed' };
}
```

---

## API Version Mismatches

### Stripe API Versioning

| Risk | Scenario | Prevention |
|------|----------|------------|
| Breaking change | New Stripe version changes response format | Pin API version in SDK |
| Deprecated field | Field we use becomes deprecated | Monitor Stripe changelog |
| New required field | Stripe requires field we don't send | Test before upgrading |

```javascript
const stripe = require('stripe')('sk_...', {
  apiVersion: '2023-10-16', // Pin to specific version
});

// Monitor for version updates
// Set calendar reminder to review quarterly
```

### Firestore SDK Versioning

| Risk | Scenario | Prevention |
|------|----------|------------|
| Breaking change | SDK upgrade changes API | Test in staging first |
| Deprecated method | Method we use becomes deprecated | Monitor release notes |

### Best Practices

- Pin dependencies in package.json
- Review changelogs before upgrading
- Test in staging environment
- Keep upgrade window quarterly
