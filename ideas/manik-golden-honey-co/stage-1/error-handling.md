# Error Handling & Critical Flows

**Project:** Manik Golden Honey Co
**Document:** Error Handling, Edge Cases, Recovery Strategies

---

## 1. Error Handling Strategy

### Frontend (Next.js)

**Form Validation (Before API Calls):**
- Required field checks
- Email format validation (regex)
- Quantity > 0 and < 100
- ZIP code format
- Display errors inline (red text below input fields)

**API Error Display:**
- Parse JSON error responses from backend
- Show user-friendly messages via toast notifications or alert banners
- Example backend error: `{"error": "Product out of stock", "code": "INSUFFICIENT_INVENTORY"}`
- Frontend shows: "Sorry, this item is currently out of stock."

**Network Failure Handling:**
- Catch fetch errors (network timeout, offline)
- Display: "Something went wrong. Please try again."
- Include retry button
- Log error to browser console for debugging

**Checkout-Specific Errors:**
- Payment failures: "Payment declined. Please check your card details."
- Inventory issues: "Item out of stock. Please update your cart."
- Always provide actionable next steps

### Backend (Go API)

**Structured Error Responses:**
```json
{
  "error": "Human-readable message",
  "code": "ERROR_CODE",
  "details": {
    "field": "productId",
    "reason": "insufficient_inventory"
  }
}
```

**HTTP Status Codes:**
- **400 Bad Request**: Validation errors (missing fields, invalid format)
- **401 Unauthorized**: Authentication required (no JWT or expired)
- **403 Forbidden**: Insufficient permissions (customer accessing admin endpoint)
- **404 Not Found**: Resource doesn't exist (product, order, customer)
- **409 Conflict**: State conflict (insufficient inventory, order already cancelled)
- **500 Internal Server Error**: Unexpected server errors (database failure, external service down)

**Logging:**
- Log all errors with context:
  - Request ID (for tracing)
  - User ID (if authenticated)
  - Timestamp
  - Error message and stack trace
  - Request path and method
- Use structured logging (JSON format) for easy parsing
- Levels: INFO (normal), WARN (recoverable), ERROR (failures)

**Graceful Degradation:**
- If email service fails: log failure, queue for retry, order still processes
- If Stripe webhook fails: retry webhook with exponential backoff
- Critical path: payment and order creation (must succeed or rollback)
- Non-critical: emails, analytics (can retry later)

---

## 2. Payment Processing Flow (Detailed)

### Happy Path

1. **Customer submits order** with Stripe payment method ID
2. **Backend validation:**
   - Cart not empty
   - All products exist and are active
   - Inventory available for each item
   - Valid shipping address
   - Valid payment method ID from Stripe
3. **Create Stripe PaymentIntent:**
   - Amount: order total in cents
   - Currency: USD
   - Payment method: from frontend
   - Metadata: customer ID, order items
4. **Payment succeeds:**
   - Stripe returns success status
   - Backend begins transaction
5. **Firestore transaction (atomic):**
   - Decrement inventory for each product
   - Create order record with status "pending"
   - All or nothing (if any step fails, entire transaction rolls back)
6. **Post-transaction:**
   - Send order confirmation email (async, non-blocking)
   - Return success response to frontend with order ID
7. **Frontend:**
   - Display order confirmation page
   - Clear cart from localStorage

### Error Scenarios & Recovery

#### Scenario 1: Payment Fails

**Trigger:** Stripe PaymentIntent fails (card declined, insufficient funds, etc.)

**Backend Actions:**
1. Catch Stripe error
2. Do NOT create order
3. Do NOT decrement inventory
4. Return 400 error with Stripe message

**Frontend Actions:**
1. Display error: "Payment failed: {reason}"
2. User can retry with:
   - Different card
   - Update billing info
   - Contact support

**Result:** No data corruption, user can retry immediately

---

#### Scenario 2: Inventory Conflict

**Trigger:** Product goes out of stock between cart view and checkout

**Backend Actions:**
1. Validate inventory before payment
2. If insufficient: return 409 Conflict error:
   ```json
   {
     "error": "Product 'Wildflower Honey 1lb' is out of stock",
     "code": "INSUFFICIENT_INVENTORY",
     "details": {
       "productId": "prod_001",
       "requested": 2,
       "available": 0
     }
   }
   ```
3. Do NOT process payment

**Frontend Actions:**
1. Display error: "Item out of stock"
2. Highlight affected product in cart
3. Suggest: "Update cart to continue"

**Result:** User updates cart, retries checkout

---

#### Scenario 3: Concurrent Orders (Race Condition)

**Trigger:** Two customers try to buy the last item simultaneously

**Scenario:**
- Product inventory: 1 unit
- Customer A and Customer B both add to cart
- Both click "Checkout" at nearly the same time

**Backend Handling (Firestore Transaction):**
```go
func (r *ProductRepository) DecrementInventory(ctx context.Context, productID string, quantity int) error {
    return r.client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
        docRef := r.client.Collection("products").Doc(productID)
        snapshot, err := tx.Get(docRef)

        currentInventory := snapshot.Data()["inventory"].(int64)

        if currentInventory < int64(quantity) {
            return errors.New("insufficient inventory")
        }

        return tx.Update(docRef, []firestore.Update{
            {Path: "inventory", Value: currentInventory - int64(quantity)},
        })
    })
}
```

**Result:**
- **Customer A**: Transaction succeeds, inventory decremented to 0
- **Customer B**: Transaction fails with "insufficient inventory" error
- Customer B sees: "Sorry, this item just went out of stock."

**Why This Works:**
- Firestore transactions are serializable
- Second transaction sees updated inventory (0)
- No overselling possible

---

#### Scenario 4: Payment Succeeds but Inventory Update Fails

**Trigger:** Stripe payment succeeds, but Firestore transaction fails (rare: network issue, database unavailable)

**Backend Actions:**
1. Payment captured by Stripe
2. Firestore transaction throws error
3. Backend catches error, logs it
4. **Compensation:** Initiate Stripe refund
5. Return 500 error to frontend

**Frontend Actions:**
1. Display: "Order failed to process. Your card was not charged. Please try again."
2. User can retry

**Result:** Customer not charged, no order created (consistent state)

**Monitoring:**
- Alert ops team for payment success + order creation failure
- Manual review and customer follow-up if refund fails

---

## 3. Inventory Management Edge Cases

### Admin Manually Adjusts Inventory

**Scenario:** Admin sets inventory to 0 while customers have item in cart

**Handling:**
- Customers see "Out of Stock" at checkout
- Backend validates inventory before payment (as usual)
- No special handling needed (validation catches it)

### Admin Deletes Product

**Scenario:** Admin deletes product while customers have it in cart

**Handling:**
1. Backend checks product exists during checkout
2. If not found: return 404 error
3. Frontend: "Product no longer available. Please update cart."

**Best Practice:**
- Soft delete recommended (mark `isActive = false`) instead of hard delete
- Preserves historical order data

---

## 4. Email Notification Handling

### Email Service Availability

**Services Used:** SendGrid, Mailgun, or similar SMTP provider

**Primary Path:**
1. Order created successfully
2. Backend calls email API to send confirmation
3. Email delivered immediately

**Failure Handling:**

#### Email API Down or Rate Limited

**Actions:**
1. Log email failure with order ID
2. Queue email for retry (simple in-memory queue for MVP)
3. Retry logic:
   - Attempt 1: Immediate
   - Attempt 2: After 5 minutes
   - Attempt 3: After 1 hour
4. If all retries fail: log as permanent failure, alert ops

**Result:**
- Order still processed successfully
- Customer can view order in account (doesn't depend on email)
- Admin manually resends if critical

#### Invalid Email Address

**Actions:**
1. Email API returns error (invalid recipient)
2. Log error with customer ID
3. Do NOT retry (won't succeed)
4. Flag customer account for admin review

**Result:**
- Order processed, but customer didn't receive confirmation
- Admin can contact via phone or alternate method

---

## 5. Session Expiry Handling

### JWT Expiration

**Trigger:** Customer's JWT expires (48 hours after login)

**Detection:**
- API returns 401 Unauthorized on any authenticated request
- Frontend intercepts 401 response

**Frontend Actions:**
1. Clear expired JWT cookie
2. Redirect to `/auth/login` with redirect parameter:
   - Example: `/auth/login?redirect=/account`
3. Display message: "Session expired. Please log in again."

**User Experience:**
- Cart persists in localStorage (not affected by logout)
- After re-login, user returns to intended page
- Order history still accessible after re-auth

### Token Refresh (Out of Scope for MVP)

**Future Enhancement:**
- Implement refresh tokens for seamless re-authentication
- JWT expires after 1 hour, refresh token lasts 30 days
- Frontend auto-refreshes JWT before expiration

---

## 6. Stripe Webhook Handling

### Purpose

Stripe sends webhooks for payment events:
- Payment succeeded
- Payment failed
- Refund processed

### Implementation

**Endpoint:** `POST /api/webhooks/stripe`

**Verification:**
1. Validate webhook signature (Stripe secret)
2. Prevents spoofed requests

**Event Handling:**

#### `payment_intent.succeeded`
- Log success (order already created in synchronous flow)
- Optional: update order status to "processing"

#### `payment_intent.payment_failed`
- Alert ops team
- Customer already received error in synchronous flow

#### `charge.refunded`
- Update order payment status to "refunded"
- Update order status to "cancelled"
- Send refund confirmation email

**Retry Logic:**
- Stripe retries webhooks automatically (with exponential backoff)
- Endpoint returns 200 OK to acknowledge receipt
- Idempotent handling: safe to process same webhook twice

---

## Related Documents

- [architecture.md](./architecture.md) - System architecture and data flow
- [customer-flows.md](./customer-flows.md) - Customer journeys where errors occur
- [deployment-security.md](./deployment-security.md) - Monitoring and alerting
