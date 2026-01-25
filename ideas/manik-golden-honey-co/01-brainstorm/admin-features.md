# Admin Management Features

**Project:** Manik Golden Honey Co
**Document:** Admin Dashboard & Tools

---

## 1. Admin Authentication

### Login Flow

**Same as Customer Auth (6-digit code) with Key Differences:**

- Admin login page: `/admin/login` (separate route)
- Backend checks `admins` collection instead of `customers`
- JWT includes role claim: `{"role": "admin", "adminId": "..."}`
- Admin JWT valid for 48 hours (same as customer)

### Authorization Enforcement

**Next.js Middleware:**
```typescript
// middleware.ts
export function middleware(request: NextRequest) {
  if (request.nextUrl.pathname.startsWith('/admin')) {
    const token = request.cookies.get('auth_token')
    const decoded = verifyJWT(token)

    if (!decoded || decoded.role !== 'admin') {
      return NextResponse.redirect('/admin/login')
    }
  }
}
```

**Go API Validation:**
- All `/api/admin/*` endpoints validate JWT
- Extract role claim from JWT
- Return 403 Forbidden if role !== "admin"

---

## 2. Admin Dashboard (`/admin/dashboard`)

### Overview Metrics

**Top Row (Cards):**

1. **Orders Today**
   - Count: Number of orders placed today
   - Comparison: vs. yesterday (e.g., "+5 from yesterday")
   - API: `GET /api/admin/metrics/orders-today`

2. **Pending Orders**
   - Count: Orders with status = "pending"
   - Alert if > 10
   - API: `GET /api/admin/metrics/pending-orders`

3. **Low Stock Alerts**
   - Count: Products where `inventory < lowStockThreshold`
   - Alert if > 0
   - API: `GET /api/admin/metrics/low-stock`

4. **Revenue Today**
   - Sum: Total of all orders placed today
   - Formatted: "$1,234.56"
   - API: `GET /api/admin/metrics/revenue-today`

### Quick Views

**Recent Orders (Table):**
- Latest 10 orders
- Columns: Order #, Customer, Date, Status, Total
- Click order # → navigates to order detail page
- "View All Orders" button → `/admin/orders`

**Low Stock Products (Table):**
- Products below threshold
- Columns: Image, Name, Current Stock, Threshold, Status
- Status indicator: 🔴 Out of Stock, 🟡 Low Stock
- Quick action: "Adjust Stock" button → inline form
- "View Inventory" button → `/admin/inventory`

### Quick Actions (Buttons)

- "Add New Product" → `/admin/products/new`
- "View All Orders" → `/admin/orders`
- "Manage Inventory" → `/admin/inventory`

---

## 3. Product Management (`/admin/products`)

### Product List View

**Table Columns:**
- Image (thumbnail, 60×60px)
- Name
- Variety
- Size
- Price
- Inventory (current stock)
- Status (Active/Inactive badge)
- Actions (dropdown)

**Actions Per Product:**
- **Edit** → Opens edit form
- **Duplicate** → Creates copy with "(Copy)" suffix
- **Toggle Active** → Flips `isActive` flag (shows/hides on storefront)
- **Delete** → Confirms and soft-deletes (MVP: hard delete acceptable)

**Top Actions:**
- "Add New Product" button → Opens product form

### Product Form (Create/Edit)

**Fields:**

1. **Name** (text, required)
   - Example: "Wildflower Honey"

2. **Description** (textarea, required)
   - Example: "Pure, raw wildflower honey from local hives"

3. **Variety** (text, required)
   - Example: "Wildflower"

4. **Size** (text, required)
   - Example: "1lb"

5. **Price** (number, required)
   - Input in dollars (e.g., "12.99")
   - Stored as cents (1299)

6. **Image Upload** (file input, required)
   - Accepts: .jpg, .png, .webp
   - Max size: 5MB
   - Uploads to Cloud Storage
   - Generates public URL → stored in `imageUrl`

7. **Inventory** (number, required)
   - Initial stock level
   - Editable later via inventory page

8. **Low Stock Threshold** (number, required)
   - Alert admin when inventory drops below this
   - Default: 10

9. **Active Status** (checkbox)
   - Checked: shows on storefront
   - Unchecked: hidden from customers

**Form Actions:**
- "Save Product" → Creates/updates product in Firestore
- "Cancel" → Discards changes, returns to list

**Validation:**
- All fields required (except active status defaults to checked)
- Price must be > 0
- Inventory must be >= 0
- Image required for new products

**API Calls:**
- Create: `POST /api/admin/products`
- Update: `PUT /api/admin/products/{id}`
- Delete: `DELETE /api/admin/products/{id}`

---

## 4. Order Management (`/admin/orders`)

### Order List View

**Table Columns:**
- Order # (clickable)
- Customer Name
- Date Placed
- Status (badge with color)
- Total
- Actions (dropdown)

**Status Colors:**
- Pending: 🟡 Yellow
- Processing: 🔵 Blue
- Shipped: 🟢 Green
- Delivered: ✅ Gray
- Cancelled: 🔴 Red

**Filters:**
- Status dropdown: All, Pending, Processing, Shipped, Delivered, Cancelled
- Date range picker (optional for MVP)

**Sort:**
- Default: Date placed (newest first)
- Sortable columns: Date, Total

**API Call:**
- `GET /api/admin/orders?status={filter}&sort=createdAt:desc`

### Order Detail Page (`/admin/orders/[id]`)

**Sections:**

1. **Order Header**
   - Order number
   - Current status (badge)
   - Date placed
   - Customer name (clickable → customer profile)

2. **Items List**
   - Table: Product, Quantity, Unit Price, Line Total
   - Subtotal calculation

3. **Shipping Information**
   - Method (Standard/Express/Local Pickup)
   - Address
   - Shipping cost

4. **Payment Information**
   - Payment status (Completed/Pending/Failed)
   - Total amount
   - Stripe Payment Intent ID (for reference)

5. **Status Timeline**
   - Visual timeline showing progression
   - Timestamps for each status change

**Actions:**

1. **Update Status (Dropdown)**
   - Options: Pending → Processing → Shipped → Delivered
   - Or: Cancel Order (from Pending/Processing only)
   - On update:
     - Updates order in Firestore
     - Sends customer notification email
     - API: `PATCH /api/admin/orders/{id}/status`

2. **Print Receipt**
   - Opens printable view of order
   - Includes: items, totals, shipping address

3. **Cancel Order**
   - Confirmation modal: "Are you sure?"
   - Refunds payment via Stripe (if applicable)
   - Restores inventory
   - Sends cancellation email to customer
   - API: `POST /api/admin/orders/{id}/cancel`

---

## 5. Customer Management (`/admin/customers`)

### Customer List View

**Table Columns:**
- Name
- Email
- Total Orders (count)
- Total Spent (sum of all order totals)
- Joined Date

**Search:**
- Search bar filters by email or name
- Client-side filtering for MVP (acceptable for <1000 customers)

**Click Customer → Customer Detail Page**

### Customer Detail Page (`/admin/customers/[id]`)

**Sections:**

1. **Profile Information** (read-only for MVP)
   - Email
   - Name
   - Phone (if provided)
   - Default shipping address

2. **Order History**
   - Table: Order #, Date, Status, Total
   - Click order # → order detail page
   - Sorted by date (newest first)

**No Edit/Delete for MVP (YAGNI):**
- Customers can update own info via account page
- Admin view is read-only
- Can add edit functionality later if needed

**API Call:**
- `GET /api/admin/customers/{id}`

---

## 6. Inventory Management (`/admin/inventory`)

### Inventory View

**Table Columns:**
- Image (thumbnail)
- Product Name
- Variety + Size
- Current Stock (number)
- Low Stock Threshold
- Status Indicator (OK/Low/Out)

**Status Indicators:**
- ✅ **OK**: `inventory >= lowStockThreshold`
- 🟡 **Low**: `inventory < lowStockThreshold && inventory > 0`
- 🔴 **Out**: `inventory = 0`

**Quick Adjust Actions (Per Product):**

1. **+10 Button** → Increments inventory by 10
2. **+50 Button** → Increments inventory by 50
3. **"Set to..." Button** → Opens inline input to set exact value

**Bulk Update:**
- Checkbox per product → select multiple
- "Adjust Selected" button → modal with bulk adjustment options:
  - Add N units to all selected
  - Set all selected to N units

**API Calls:**
- Quick adjust: `PATCH /api/admin/products/{id}/inventory`
- Bulk update: `PATCH /api/admin/products/inventory/bulk`

**Real-Time Updates:**
- Inventory changes reflect immediately
- Admin dashboard "Low Stock Alerts" updates automatically

---

## 7. Admin Settings (Future)

**Out of Scope for MVP, but Planned:**
- Add/remove admin users
- Configure shipping rates
- Email template customization
- Sales reports/analytics

---

## Related Documents

- [customer-flows.md](./customer-flows.md) - Customer experience
- [data-model.md](./data-model.md) - Database schema for admin entities
- [error-handling.md](./error-handling.md) - Error handling in admin operations
