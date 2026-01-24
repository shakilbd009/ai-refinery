# Testing Strategy

**Project:** Manik Golden Honey Co
**Document:** Comprehensive Testing Approach

---

## 1. Testing Pyramid

```
         /\
        /  \  E2E Tests (5%)
       /____\
      /      \  Integration Tests (20%)
     /________\
    /          \  Unit Tests (75%)
   /____________\
```

**Distribution:**
- **Unit Tests (75%)**: Fast, isolated tests of functions and components
- **Integration Tests (20%)**: Test API endpoints with database emulator
- **E2E Tests (5%)**: Full user journeys with real browser

---

## 2. Backend Testing (Go)

### Unit Tests

**Target Coverage:** 80%+ on business logic

**What to Test:**

1. **Repository Implementations** (with Firestore emulator or mocks)
   - CRUD operations
   - Query filters (active products, orders by customer)
   - Transaction logic (inventory decrements)

2. **Business Logic Handlers**
   - Order creation flow (mock repositories)
   - Payment processing logic
   - Inventory validation
   - Authentication token generation

3. **Utility Functions**
   - JWT creation and validation
   - Email formatting
   - Price calculations
   - Date/time utilities

**Example: Testing Inventory Decrement**

```go
func TestDecrementInventory_Success(t *testing.T) {
    // Arrange
    mockRepo := mocks.NewMockProductRepository()
    mockRepo.Products["prod_001"] = &repository.Product{
        ID: "prod_001",
        Inventory: 10,
    }

    // Act
    err := mockRepo.DecrementInventory(context.Background(), "prod_001", 3)

    // Assert
    assert.Nil(t, err)
    assert.Equal(t, 7, mockRepo.Products["prod_001"].Inventory)
}

func TestDecrementInventory_InsufficientStock(t *testing.T) {
    // Arrange
    mockRepo := mocks.NewMockProductRepository()
    mockRepo.Products["prod_001"] = &repository.Product{
        ID: "prod_001",
        Inventory: 2,
    }

    // Act
    err := mockRepo.DecrementInventory(context.Background(), "prod_001", 5)

    // Assert
    assert.NotNil(t, err)
    assert.Contains(t, err.Error(), "insufficient inventory")
    assert.Equal(t, 2, mockRepo.Products["prod_001"].Inventory) // Unchanged
}
```

**Example: Testing JWT Validation**

```go
func TestValidateJWT_ValidToken(t *testing.T) {
    token := GenerateJWT("cust_123", "customer@example.com", "customer")
    claims, err := ValidateJWT(token)

    assert.Nil(t, err)
    assert.Equal(t, "cust_123", claims.CustomerID)
    assert.Equal(t, "customer", claims.Role)
}

func TestValidateJWT_ExpiredToken(t *testing.T) {
    token := GenerateExpiredJWT("cust_123", "customer@example.com")
    _, err := ValidateJWT(token)

    assert.NotNil(t, err)
    assert.Contains(t, err.Error(), "expired")
}
```

### Integration Tests

**Setup:** Use Firestore emulator for local testing

**What to Test:**

1. **Full API Endpoints**
   - `POST /api/orders` with actual Firestore writes
   - `GET /api/products` with real queries
   - `POST /api/auth/verify` with token lookup

2. **Payment Flow with Stripe Test Mode**
   - Use Stripe test API keys
   - Test cards: `4242 4242 4242 4242` (success), `4000 0000 0000 0002` (declined)
   - Verify order creation after successful payment

3. **Concurrent Inventory Decrements**
   - Simulate race conditions
   - Verify only one order succeeds when last item purchased

**Example: Testing Order Creation (Integration)**

```go
func TestCreateOrder_IntegrationSuccess(t *testing.T) {
    // Setup Firestore emulator
    ctx := context.Background()
    client, _ := firestore.NewClient(ctx, "test-project")
    defer client.Close()

    // Seed test data
    productRepo := firestore.NewProductRepository(client)
    productRepo.Create(ctx, &repository.Product{
        ID: "prod_001",
        Name: "Test Honey",
        Price: 1000,
        Inventory: 10,
    })

    // Test order creation
    orderRepo := firestore.NewOrderRepository(client)
    orderHandler := handlers.NewOrderHandler(productRepo, orderRepo, nil)

    order := &repository.Order{
        CustomerID: "cust_001",
        Items: []repository.OrderItem{
            {ProductID: "prod_001", Quantity: 2},
        },
    }

    err := orderHandler.CreateOrder(ctx, order)

    // Assert
    assert.Nil(t, err)

    // Verify inventory decremented
    product, _ := productRepo.GetByID(ctx, "prod_001")
    assert.Equal(t, 8, product.Inventory)
}
```

### Key Test Scenarios (Backend)

**Must Cover:**

1. ✅ Order placement with successful payment
2. ✅ Order placement with failed payment (inventory not decremented)
3. ✅ Concurrent orders for last item (one succeeds, one fails)
4. ✅ Auth token validation (expired, used, invalid codes)
5. ✅ Admin authorization checks (non-admin rejected)
6. ✅ Inventory conflict at checkout
7. ✅ Email sending with mock SMTP server

---

## 3. Frontend Testing (Next.js)

### Component Tests (React Testing Library)

**What to Test:**

1. **Product Components**
   - Product card renders correctly
   - Product detail shows all information
   - "Add to Cart" button disabled when out of stock

2. **Cart Functionality**
   - Add item to cart updates localStorage
   - Update quantity recalculates total
   - Remove item clears from cart
   - Empty cart shows placeholder message

3. **Forms**
   - Shipping address validation (required fields)
   - Email format validation
   - Error messages display correctly
   - Submit disabled when invalid

4. **Admin Components**
   - Product form validation
   - Order status update UI
   - Inventory quick adjust buttons

**Example: Testing Product Card**

```typescript
import { render, screen } from '@testing-library/react'
import ProductCard from '@/components/ProductCard'

test('renders product card with correct information', () => {
  const product = {
    id: 'prod_001',
    name: 'Wildflower Honey',
    variety: 'Wildflower',
    size: '1lb',
    price: 1299,
    imageUrl: '/images/wildflower.jpg',
    inventory: 10,
  }

  render(<ProductCard product={product} />)

  expect(screen.getByText('Wildflower Honey')).toBeInTheDocument()
  expect(screen.getByText('Wildflower • 1lb')).toBeInTheDocument()
  expect(screen.getByText('$12.99')).toBeInTheDocument()
  expect(screen.getByText('In Stock')).toBeInTheDocument()
})

test('shows out of stock when inventory is 0', () => {
  const product = { ...mockProduct, inventory: 0 }

  render(<ProductCard product={product} />)

  expect(screen.getByText('Out of Stock')).toBeInTheDocument()
  expect(screen.queryByText('Add to Cart')).not.toBeInTheDocument()
})
```

**Example: Testing Cart Operations**

```typescript
import { render, screen, fireEvent } from '@testing-library/react'
import Cart from '@/components/Cart'

test('updates quantity and recalculates total', () => {
  const initialCart = {
    items: [
      { productId: 'prod_001', name: 'Wildflower Honey', price: 1299, quantity: 1 }
    ]
  }

  render(<Cart initialCart={initialCart} />)

  expect(screen.getByText('$12.99')).toBeInTheDocument()

  const quantityInput = screen.getByRole('spinbutton')
  fireEvent.change(quantityInput, { target: { value: '3' } })

  expect(screen.getByText('$38.97')).toBeInTheDocument()
})
```

---

## 4. End-to-End Tests (Playwright)

**Browser Coverage (MVP):** Chromium only (expand to Firefox/Safari later)

**Key User Journeys:**

### Customer Journey: Browse to Purchase

```typescript
test('customer can browse products, add to cart, and checkout', async ({ page }) => {
  // 1. Browse products
  await page.goto('http://localhost:3000')
  await expect(page.locator('h1')).toContainText('Manik Golden Honey Co')
  await page.click('text=Shop All Products')

  // 2. View product detail
  await page.click('text=Wildflower Honey')
  await expect(page).toHaveURL(/\/products\/prod_/)
  await expect(page.locator('h1')).toContainText('Wildflower Honey')

  // 3. Add to cart
  await page.fill('input[name="quantity"]', '2')
  await page.click('text=Add to Cart')
  await expect(page.locator('.toast')).toContainText('Added to cart')

  // 4. Go to cart
  await page.click('text=View Cart')
  await expect(page).toHaveURL('/cart')
  await expect(page.locator('.cart-item')).toContainText('Wildflower Honey')
  await expect(page.locator('.subtotal')).toContainText('$25.98')

  // 5. Start checkout
  await page.click('text=Checkout')

  // 6. Login with magic link
  await page.fill('input[name="email"]', 'test@example.com')
  await page.click('text=Continue')
  await expect(page.locator('.success')).toContainText('Check your email')

  // (In test environment, retrieve code from database and fill manually)
  const code = await getTestAuthCode('test@example.com')
  await page.fill('input[name="code"]', code)
  await page.click('text=Verify')

  // 7. Complete checkout
  await page.selectOption('select[name="shipping"]', 'standard')
  await page.fill('input[name="street"]', '123 Main St')
  await page.fill('input[name="city"]', 'Springfield')
  await page.selectOption('select[name="state"]', 'IL')
  await page.fill('input[name="zip"]', '62701')

  // 8. Enter payment (Stripe test card)
  await page.fill('input[name="cardNumber"]', '4242424242424242')
  await page.fill('input[name="expiry"]', '12/28')
  await page.fill('input[name="cvc"]', '123')
  await page.fill('input[name="zip"]', '62701')

  await page.click('text=Place Order')

  // 9. Verify confirmation
  await expect(page).toHaveURL(/\/orders\//)
  await expect(page.locator('h1')).toContainText('Order Confirmed')
  await expect(page.locator('.order-number')).toContainText(/MGH-\d+/)
})
```

### Admin Journey: Manage Products and Orders

```typescript
test('admin can add product and view orders', async ({ page }) => {
  // 1. Admin login
  await page.goto('http://localhost:3000/admin/login')
  await page.fill('input[name="email"]', 'admin@manikgoldenhoney.com')
  await page.click('text=Continue')

  const code = await getTestAuthCode('admin@manikgoldenhoney.com')
  await page.fill('input[name="code"]', code)
  await page.click('text=Verify')

  // 2. Navigate to products
  await expect(page).toHaveURL('/admin/dashboard')
  await page.click('text=Products')
  await expect(page).toHaveURL('/admin/products')

  // 3. Add new product
  await page.click('text=Add New Product')
  await page.fill('input[name="name"]', 'Clover Honey')
  await page.fill('textarea[name="description"]', 'Pure clover honey')
  await page.fill('input[name="variety"]', 'Clover')
  await page.fill('input[name="size"]', '1lb')
  await page.fill('input[name="price"]', '11.99')
  await page.setInputFiles('input[type="file"]', './test-images/clover.jpg')
  await page.fill('input[name="inventory"]', '20')
  await page.fill('input[name="threshold"]', '5')
  await page.click('text=Save Product')

  // 4. Verify product added
  await expect(page.locator('.success')).toContainText('Product created')
  await expect(page.locator('table')).toContainText('Clover Honey')

  // 5. View orders
  await page.click('text=Orders')
  await expect(page).toHaveURL('/admin/orders')
  await expect(page.locator('table')).toBeVisible()
})
```

---

## 5. Testing Infrastructure

### Local Development

**Firestore Emulator:**
```bash
# Start emulator
firebase emulators:start --only firestore

# Run tests against emulator
FIRESTORE_EMULATOR_HOST=localhost:8080 go test ./...
```

**Stripe Test Mode:**
- Use test API keys: `sk_test_...`
- Test cards in Stripe docs
- No real charges processed

**Email Testing:**
- Use Mailhog or similar SMTP testing tool
- Captures emails locally
- View emails in web UI (localhost:8025)

### CI/CD (GitHub Actions)

**Workflow:**
```yaml
name: Tests

on: [push, pull_request]

jobs:
  backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-go@v3
        with:
          go-version: 1.21
      - name: Start Firestore Emulator
        run: |
          npm install -g firebase-tools
          firebase emulators:start --only firestore &
      - name: Run Go Tests
        run: go test -v -cover ./...

  frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - run: npm install
      - run: npm run test

  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v3
      - run: npm install
      - run: npx playwright install chromium
      - run: npm run test:e2e
```

---

## 6. Manual Testing Checklist (Pre-Launch)

**Before Production Deployment:**

### Customer Flow
- [ ] Browse products on mobile and desktop
- [ ] Add items to cart, verify localStorage persistence
- [ ] Complete checkout with Stripe test card (4242...)
- [ ] Verify order confirmation email arrives
- [ ] View order history in account
- [ ] Test payment decline (card 4000...)
- [ ] Test out-of-stock product handling
- [ ] Test session expiry and re-login

### Admin Flow
- [ ] Login to admin dashboard
- [ ] Add new product with image upload
- [ ] Edit existing product
- [ ] Toggle product active/inactive status
- [ ] View orders and filter by status
- [ ] Update order status (triggers customer email)
- [ ] Adjust inventory (quick buttons and manual input)
- [ ] View customer list and order history

### Error Scenarios
- [ ] Invalid email format (shows error)
- [ ] Expired auth code (shows error)
- [ ] Insufficient inventory at checkout (shows error)
- [ ] Payment failure (shows error, inventory not decremented)
- [ ] Network timeout during checkout (retry works)

### Responsive Design
- [ ] Test on iPhone (Safari)
- [ ] Test on Android (Chrome)
- [ ] Test on tablet (iPad)
- [ ] Verify mobile menu navigation

---

## 7. Test Data Management

**Test Fixtures:**

```go
// fixtures/products.go
var TestProducts = []*repository.Product{
    {
        ID: "test_prod_001",
        Name: "Test Wildflower Honey",
        Price: 1299,
        Inventory: 100,
        IsActive: true,
    },
    // More test products...
}
```

**Seed Script for Testing:**
```bash
#!/bin/bash
# seed-test-data.sh

# Add test products
curl -X POST http://localhost:8080/api/admin/products \
  -H "Authorization: Bearer $ADMIN_JWT" \
  -d @fixtures/products.json

# Add test customers
curl -X POST http://localhost:8080/api/customers \
  -d @fixtures/customers.json
```

---

## Related Documents

- [repository-pattern.md](./repository-pattern.md) - Repository testing patterns
- [error-handling.md](./error-handling.md) - Error scenarios to test
- [customer-flows.md](./customer-flows.md) - User journeys to cover in E2E tests
