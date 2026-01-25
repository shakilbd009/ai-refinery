# Customer User Flows

**Project:** Manik Golden Honey Co
**Document:** Customer Journey Mapping

---

## 1. Passwordless Authentication (6-Digit Code)

### Login/Signup Flow

**Step-by-Step:**

1. **Email Entry**
   - User visits `/auth/login` or `/auth/signup`
   - Enters email address in form
   - Clicks "Continue"

2. **Code Generation**
   - Backend generates random 6-digit numeric code (e.g., `742591`)
   - Creates record in `auth_tokens` collection:
     - `code`: "742591"
     - `email`: user's email
     - `expiresAt`: current time + 48 hours
     - `usedAt`: null

3. **Email Delivery**
   - Backend sends email with subject: "Your Manik Golden Honey Co login code"
   - Email body contains:
     - Plain text code: **742591**
     - Magic link: `https://manik-golden-honey-co.com/auth/verify?code=742591&email={EMAIL}`
     - Expiration notice: "Valid for 48 hours"

4. **Verification**
   - User redirected to `/auth/verify` page
   - Two verification options:
     - **Option A:** Click magic link (auto-fills code and email)
     - **Option B:** Manually type 6-digit code on verification page

5. **Backend Validation**
   - Frontend calls: `POST /api/auth/verify` with `{code, email}`
   - Backend checks:
     - Code + email combination exists
     - Token not expired (< 48 hours old)
     - Token not already used (`usedAt` is null)
   - If valid: marks token as used, proceeds to step 6
   - If invalid: returns error with reason

6. **Session Creation**
   - Backend creates/finds customer record in `customers` collection
   - Generates JWT containing:
     - `customerId`: customer's Firestore doc ID
     - `email`: customer's email
     - `exp`: expiration timestamp (48 hours from now)
   - Returns JWT in httpOnly secure cookie
   - Frontend redirects to intended destination (account dashboard or checkout)

### Security Measures

**Rate Limiting:**
- Max 5 verification attempts per email per hour
- Prevents brute-force attacks on 6-digit codes
- Backend returns 429 status after limit exceeded

**Token Management:**
- Each code is single-use (marked as used after verification)
- Expired tokens cleaned up by background job (runs daily)
- Composite index on `code + email` ensures fast lookups

**Cookie Security:**
- JWT stored in httpOnly cookie (prevents XSS access)
- Secure flag enabled (HTTPS only)
- SameSite=Strict (CSRF protection)

---

## 2. Product Browsing

### Homepage

**Layout:**
- Hero section with business tagline
- Featured products grid (3-4 products)
- Call-to-action: "Shop All Products"

**Product Card (Preview):**
- Product image (square thumbnail)
- Product name (e.g., "Wildflower Honey")
- Variety + size (e.g., "Wildflower • 1lb")
- Price (e.g., "$12.99")
- Stock indicator: "In Stock" (green) or "Out of Stock" (gray)

### Product Listing Page (`/products`)

**API Call:**
- `GET /api/products?active=true`
- Returns array of active products

**Display:**
- Grid layout (3 columns on desktop, 2 on tablet, 1 on mobile)
- Each product card clickable → navigates to product detail page
- Out-of-stock products shown but grayed out

### Product Detail Page (`/products/[id]`)

**API Call:**
- `GET /api/products/{id}`
- Returns single product with full details

**Layout:**
- Left: Large product image
- Right: Product info
  - Name + variety
  - Full description
  - Size + price
  - Stock status
  - Quantity selector (1-10)
  - "Add to Cart" button (or "Out of Stock" if unavailable)

**Interactions:**
- Quantity selector updates line total preview
- "Add to Cart" adds item to localStorage cart
- Success toast: "Added to cart"
- "View Cart" button appears briefly after adding

**SSR for SEO:**
- Product detail pages server-side rendered
- Meta tags include product name, description, image (Open Graph)
- Indexed by search engines

---

## 3. Shopping Cart

### Storage

**Client-Side Cart (localStorage):**
```json
{
  "items": [
    {
      "productId": "prod_001",
      "name": "Wildflower Honey",
      "variety": "Wildflower",
      "size": "1lb",
      "price": 1299,
      "quantity": 2,
      "imageUrl": "gs://bucket/products/wildflower-1lb.jpg"
    }
  ],
  "updatedAt": "2026-01-24T15:30:00Z"
}
```

**Why localStorage:**
- Persists across browser sessions
- No server calls needed for cart operations
- User doesn't lose cart if not logged in

### Cart Page (`/cart`)

**Display:**
- Table/list of cart items:
  - Product image (small thumbnail)
  - Name, variety, size
  - Unit price
  - Quantity selector (editable)
  - Line total (price × quantity)
  - Remove button
- Cart summary:
  - Subtotal
  - "Shipping calculated at checkout"
  - Total (subtotal for now)
- Actions:
  - "Continue Shopping" → back to products
  - "Checkout" → requires authentication

**Interactions:**
- Update quantity → recalculates line total and subtotal in real-time
- Remove item → confirms with toast: "Item removed"
- Empty cart shows: "Your cart is empty" + "Shop Products" link

### Checkout Gate

**Authentication Check:**
- "Checkout" button checks for valid JWT cookie
- If authenticated → proceed to `/checkout`
- If not authenticated → redirect to `/auth/login?redirect=/checkout`
- After login → redirects back to checkout with cart intact

---

## 4. Checkout Flow

### Step 1: Review Order

**Display:**
- Cart items summary (read-only)
- Subtotal
- Note: "Shipping will be calculated in next step"

**Actions:**
- "Edit Cart" → back to `/cart`
- "Continue to Shipping" → proceed to step 2

### Step 2: Shipping Method

**API Call:**
- `GET /api/shipping/methods`
- Returns available methods with base costs

**Options:**
- Standard Shipping ($5.00, 5-7 business days)
- Express Shipping ($12.00, 2-3 business days)
- Local Pickup (Free, available immediately)

**Selection:**
- Radio buttons for method selection
- Updates shipping cost in summary
- "Continue to Address" → proceed to step 3

### Step 3: Shipping Address

**Form Fields:**
- Street address
- City
- State (dropdown)
- ZIP code

**Pre-fill:**
- If customer has `defaultShippingAddress`, pre-fill form
- Editable (doesn't update default automatically for MVP)

**Validation:**
- All fields required (except for local pickup)
- ZIP code format validation
- "Continue to Payment" → proceed to step 4

### Step 4: Payment

**Display:**
- Order summary (items, subtotal, shipping, total)
- Stripe Elements card form embedded
- "Place Order" button

**Stripe Integration:**
- Load Stripe.js library
- Render Stripe Elements for card entry
- On "Place Order":
  1. Stripe creates payment method
  2. Frontend calls: `POST /api/orders` with:
     - Cart items
     - Shipping method
     - Shipping address
     - Stripe payment method ID
  3. Backend handles payment (see error-handling.md)
  4. Returns order confirmation or error

### Step 5: Order Confirmation

**Display:**
- Success message: "Order placed successfully!"
- Order number (e.g., "MGH-1001")
- Order summary
- Expected delivery date
- "View Order" → navigates to order detail page
- "Continue Shopping" → back to homepage

**Side Effects:**
- Cart cleared from localStorage
- Order confirmation email sent
- Inventory decremented in Firestore

**Email Confirmation:**
- Subject: "Order Confirmation - MGH-1001"
- Contains:
  - Order summary
  - Shipping address
  - Expected delivery
  - Link to track order

---

## 5. Customer Account (`/account`)

### Dashboard

**Sections:**

1. **Profile Information**
   - Email address (read-only)
   - Name (editable via inline form)
   - Phone (editable, optional)
   - Default shipping address (editable)

2. **Order History**
   - Table of all orders:
     - Order number (clickable)
     - Date placed
     - Status (with color indicator)
     - Total amount
     - Actions: "View Details"
   - Sorted by date (newest first)
   - API call: `GET /api/orders?customerId={ID}`

### Order Detail Page (`/account/orders/[id]`)

**API Call:**
- `GET /api/orders/{id}`
- Returns single order with full details

**Display:**
- Order number + status
- Status timeline (pending → processing → shipped → delivered)
- Items list with images
- Subtotal, shipping, total
- Shipping address
- Payment status
- Actions (if applicable):
  - "Track Shipment" (if shipped)
  - "Cancel Order" (if still pending)

**Status Timeline:**
```
● Pending      (Jan 24, 3:00 PM)
● Processing   (Jan 24, 4:15 PM)
○ Shipped      (Not yet)
○ Delivered    (Not yet)
```

---

## Related Documents

- [admin-features.md](./admin-features.md) - Admin management flows
- [error-handling.md](./error-handling.md) - Error scenarios in customer flows
- [architecture.md](./architecture.md) - Technical architecture
