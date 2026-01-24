# Data Model (Firestore)

**Project:** Manik Golden Honey Co
**Database:** Firestore (NoSQL)

---

## Collection: `products`

**Purpose:** Store honey product catalog

**Schema:**
```json
{
  "id": "string (auto-generated)",
  "name": "string (e.g., 'Wildflower Honey')",
  "description": "string",
  "variety": "string (e.g., 'Wildflower', 'Clover', 'Buckwheat')",
  "price": "number (in cents, e.g., 1299 for $12.99)",
  "size": "string (e.g., '12oz', '1lb', '2lb')",
  "imageUrl": "string (Cloud Storage URL)",
  "inventory": "number (current stock level)",
  "lowStockThreshold": "number (alert admin when below this)",
  "isActive": "boolean (show on storefront)",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Key Fields:**
- `price` stored in cents to avoid floating-point issues
- `isActive` controls visibility on customer storefront
- `inventory` decremented atomically during order placement
- `lowStockThreshold` triggers admin dashboard alerts

**Example Document:**
```json
{
  "id": "prod_001",
  "name": "Wildflower Honey",
  "description": "Pure, raw wildflower honey from local hives",
  "variety": "Wildflower",
  "price": 1299,
  "size": "1lb",
  "imageUrl": "gs://bucket/products/wildflower-1lb.jpg",
  "inventory": 50,
  "lowStockThreshold": 10,
  "isActive": true,
  "createdAt": "2026-01-24T10:00:00Z",
  "updatedAt": "2026-01-24T10:00:00Z"
}
```

---

## Collection: `customers`

**Purpose:** Store customer profiles

**Schema:**
```json
{
  "id": "string (Firebase Auth UID)",
  "email": "string",
  "name": "string",
  "phone": "string (optional)",
  "defaultShippingAddress": {
    "street": "string",
    "city": "string",
    "state": "string",
    "zip": "string"
  },
  "createdAt": "timestamp"
}
```

**Key Fields:**
- `id` matches Firebase Auth UID for easy correlation
- `defaultShippingAddress` pre-fills checkout form
- Minimal personal data (privacy-focused MVP)

**Example Document:**
```json
{
  "id": "cust_abc123",
  "email": "customer@example.com",
  "name": "Jane Doe",
  "phone": "+1-555-0100",
  "defaultShippingAddress": {
    "street": "123 Main St",
    "city": "Springfield",
    "state": "IL",
    "zip": "62701"
  },
  "createdAt": "2026-01-20T14:30:00Z"
}
```

---

## Collection: `orders`

**Purpose:** Store customer orders and order history

**Schema:**
```json
{
  "id": "string (auto-generated)",
  "customerId": "string (ref to customers)",
  "orderNumber": "string (friendly ID like 'MGH-1001')",
  "status": "string (pending|processing|shipped|delivered|cancelled)",
  "items": [
    {
      "productId": "string",
      "productName": "string (denormalized for history)",
      "quantity": "number",
      "priceAtPurchase": "number (capture price at order time)"
    }
  ],
  "subtotal": "number (in cents)",
  "shippingCost": "number",
  "total": "number",
  "shippingMethod": "string (standard|express|local_pickup)",
  "shippingAddress": {
    "street": "string",
    "city": "string",
    "state": "string",
    "zip": "string"
  },
  "paymentIntentId": "string (Stripe reference)",
  "paymentStatus": "string (pending|completed|failed|refunded)",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "shippedAt": "timestamp (optional)",
  "deliveredAt": "timestamp (optional)"
}
```

**Key Fields:**
- `items` denormalizes product name and price (historical record)
- `orderNumber` is human-friendly (MGH prefix + sequential number)
- `paymentIntentId` links to Stripe for reconciliation
- Status timestamps (`shippedAt`, `deliveredAt`) track order lifecycle

**Denormalization Rationale:**
- Product name/price captured at order time (survives product edits)
- Enables accurate order history even if product is deleted/changed

**Example Document:**
```json
{
  "id": "order_xyz789",
  "customerId": "cust_abc123",
  "orderNumber": "MGH-1001",
  "status": "shipped",
  "items": [
    {
      "productId": "prod_001",
      "productName": "Wildflower Honey 1lb",
      "quantity": 2,
      "priceAtPurchase": 1299
    }
  ],
  "subtotal": 2598,
  "shippingCost": 500,
  "total": 3098,
  "shippingMethod": "standard",
  "shippingAddress": {
    "street": "123 Main St",
    "city": "Springfield",
    "state": "IL",
    "zip": "62701"
  },
  "paymentIntentId": "pi_stripe123",
  "paymentStatus": "completed",
  "createdAt": "2026-01-24T15:00:00Z",
  "updatedAt": "2026-01-25T09:00:00Z",
  "shippedAt": "2026-01-25T09:00:00Z"
}
```

---

## Collection: `admins`

**Purpose:** Store admin user credentials

**Schema:**
```json
{
  "id": "string (Firebase Auth UID)",
  "email": "string",
  "role": "string (admin)",
  "createdAt": "timestamp"
}
```

**Key Fields:**
- `role` checked during JWT validation for admin endpoints
- Minimal collection (only essential fields)

---

## Collection: `auth_tokens`

**Purpose:** Store passwordless authentication codes

**Schema:**
```json
{
  "id": "string (auto-generated doc ID)",
  "code": "string (6-digit numeric, e.g., '742591')",
  "email": "string",
  "expiresAt": "timestamp (current time + 48 hours)",
  "usedAt": "timestamp (optional, set when code is consumed)",
  "createdAt": "timestamp"
}
```

**Key Fields:**
- `code` is 6-digit numeric string (user-friendly, easy to type)
- `expiresAt` enforces time-bound validity
- `usedAt` prevents code reuse

**Lifecycle:**
1. Created when user requests login code
2. Validated during verification (checks email match, not expired, not used)
3. Marked as used after successful validation
4. Cleaned up periodically (background job deletes expired/used tokens)

---

## Indexes Required

**Critical for Performance:**

1. **`orders` - Customer Order History**
   - Composite index: `customerId ASC + createdAt DESC`
   - Query: List orders for a customer, newest first
   - Used by: Customer account page, admin customer view

2. **`products` - Active Products**
   - Single index: `isActive ASC`
   - Query: Filter products shown on storefront
   - Used by: Product listing page

3. **`orders` - Admin Order Filtering**
   - Single index: `status ASC`
   - Query: Filter orders by status (pending, shipped, etc.)
   - Used by: Admin order management page

4. **`auth_tokens` - Code Lookup**
   - Composite index: `code ASC + email ASC`
   - Query: Find token by code and email during verification
   - Used by: Authentication flow

**Index Creation:**
- Firestore auto-creates single-field indexes
- Composite indexes must be created manually or via suggested index links
- Indexes defined in `firestore.indexes.json` for deployment automation

---

## Data Migration Strategy

**Current (Firestore):**
- Document-based, flexible schema
- No migrations needed for schema changes (NoSQL flexibility)

**Future (Postgres):**
- See [repository-pattern.md](./repository-pattern.md) for migration approach
- Schema mapping: Firestore docs → Postgres tables
- Composite fields (addresses) → JSONB or separate tables

---

## Related Documents

- [repository-pattern.md](./repository-pattern.md) - Database abstraction layer
- [architecture.md](./architecture.md) - System architecture
- [error-handling.md](./error-handling.md) - Inventory management and transactions
