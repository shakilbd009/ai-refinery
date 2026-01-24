# Database Abstraction Layer (Repository Pattern)

**Project:** Manik Golden Honey Co
**Document:** Database Abstraction & Migration Strategy

---

## 1. Why Repository Pattern?

**Problem:** Direct database access throughout code makes migration difficult.

**Current State (Without Abstraction):**
```go
// Handler directly calls Firestore
func CreateOrder(ctx context.Context, order *Order) error {
    _, err := firestoreClient.Collection("orders").Doc(order.ID).Set(ctx, order)
    return err
}
```

**Migration Pain:**
- To switch to Postgres: rewrite every database call in every handler
- Business logic mixed with database implementation details
- Hard to test (requires real Firestore connection)

**Solution: Repository Pattern**
- Define interfaces for all data operations
- Implement interfaces for Firestore (current)
- Swap implementations without changing business logic
- Easy to test with mock repositories

---

## 2. Repository Interfaces

### Core Interfaces

```go
package repository

import "context"

// ProductRepository handles product data operations
type ProductRepository interface {
    Create(ctx context.Context, product *Product) error
    GetByID(ctx context.Context, id string) (*Product, error)
    List(ctx context.Context, activeOnly bool) ([]*Product, error)
    Update(ctx context.Context, product *Product) error
    Delete(ctx context.Context, id string) error
    DecrementInventory(ctx context.Context, id string, quantity int) error
}

// OrderRepository handles order data operations
type OrderRepository interface {
    Create(ctx context.Context, order *Order) error
    GetByID(ctx context.Context, id string) (*Order, error)
    ListByCustomer(ctx context.Context, customerID string) ([]*Order, error)
    ListByStatus(ctx context.Context, status string) ([]*Order, error)
    UpdateStatus(ctx context.Context, id string, status string) error
}

// CustomerRepository handles customer data operations
type CustomerRepository interface {
    Create(ctx context.Context, customer *Customer) error
    GetByID(ctx context.Context, id string) (*Customer, error)
    GetByEmail(ctx context.Context, email string) (*Customer, error)
    Update(ctx context.Context, customer *Customer) error
}

// AuthTokenRepository handles authentication token operations
type AuthTokenRepository interface {
    Create(ctx context.Context, token *AuthToken) error
    GetByCodeAndEmail(ctx context.Context, code, email string) (*AuthToken, error)
    MarkAsUsed(ctx context.Context, id string) error
    DeleteExpired(ctx context.Context) error
}
```

### Key Design Principles

**Context-Aware:**
- Every method accepts `context.Context` for cancellation and timeouts

**Error Handling:**
- Methods return errors for failures
- Callers handle errors (no panic inside repository)

**Single Responsibility:**
- Each repository handles one entity type
- No cross-entity logic (that's for service layer)

**Transaction Support (Future):**
- Add `BeginTransaction()` method when needed
- Return transaction handle for multi-operation commits

---

## 3. Firestore Implementation

### Directory Structure

```
internal/
├── repository/
│   ├── interfaces.go           # Repository interfaces
│   ├── models.go               # Shared data models
│   └── firestore/
│       ├── client.go           # Firestore client initialization
│       ├── product.go          # ProductRepository implementation
│       ├── order.go            # OrderRepository implementation
│       ├── customer.go         # CustomerRepository implementation
│       └── auth_token.go       # AuthTokenRepository implementation
```

### Example: Product Repository (Firestore)

```go
package firestore

import (
    "context"
    "errors"
    "cloud.google.com/go/firestore"
    "your-project/internal/repository"
)

type productRepository struct {
    client *firestore.Client
}

// NewProductRepository creates a Firestore-backed ProductRepository
func NewProductRepository(client *firestore.Client) repository.ProductRepository {
    return &productRepository{client: client}
}

// Create adds a new product to Firestore
func (r *productRepository) Create(ctx context.Context, product *repository.Product) error {
    _, err := r.client.Collection("products").Doc(product.ID).Set(ctx, product)
    return err
}

// GetByID retrieves a product by ID
func (r *productRepository) GetByID(ctx context.Context, id string) (*repository.Product, error) {
    doc, err := r.client.Collection("products").Doc(id).Get(ctx)
    if err != nil {
        return nil, err
    }

    var product repository.Product
    if err := doc.DataTo(&product); err != nil {
        return nil, err
    }
    return &product, nil
}

// List retrieves all products, optionally filtering by active status
func (r *productRepository) List(ctx context.Context, activeOnly bool) ([]*repository.Product, error) {
    query := r.client.Collection("products")

    if activeOnly {
        query = query.Where("isActive", "==", true)
    }

    docs, err := query.Documents(ctx).GetAll()
    if err != nil {
        return nil, err
    }

    products := make([]*repository.Product, len(docs))
    for i, doc := range docs {
        var product repository.Product
        if err := doc.DataTo(&product); err != nil {
            return nil, err
        }
        products[i] = &product
    }

    return products, nil
}

// DecrementInventory atomically decrements product inventory
func (r *productRepository) DecrementInventory(ctx context.Context, id string, quantity int) error {
    return r.client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
        docRef := r.client.Collection("products").Doc(id)
        snapshot, err := tx.Get(docRef)
        if err != nil {
            return err
        }

        currentInventory := snapshot.Data()["inventory"].(int64)

        if currentInventory < int64(quantity) {
            return errors.New("insufficient inventory")
        }

        return tx.Update(docRef, []firestore.Update{
            {Path: "inventory", Value: currentInventory - int64(quantity)},
            {Path: "updatedAt", Value: firestore.ServerTimestamp},
        })
    })
}

// Other methods (Update, Delete) follow same pattern...
```

---

## 4. Dependency Injection

### Setup in main.go

```go
package main

import (
    "context"
    "log"
    "cloud.google.com/go/firestore"
    "your-project/internal/repository"
    "your-project/internal/repository/firestore"
    "your-project/internal/handlers"
)

func main() {
    ctx := context.Background()

    // Initialize Firestore client
    firestoreClient, err := firestore.NewClient(ctx, "your-gcp-project-id")
    if err != nil {
        log.Fatalf("Failed to create Firestore client: %v", err)
    }
    defer firestoreClient.Close()

    // Create repositories (Firestore implementations)
    productRepo := firestore.NewProductRepository(firestoreClient)
    orderRepo := firestore.NewOrderRepository(firestoreClient)
    customerRepo := firestore.NewCustomerRepository(firestoreClient)
    authTokenRepo := firestore.NewAuthTokenRepository(firestoreClient)

    // Inject repositories into handlers
    orderHandler := handlers.NewOrderHandler(productRepo, orderRepo, customerRepo)
    productHandler := handlers.NewProductHandler(productRepo)

    // Set up HTTP routes and start server...
}
```

**Key Benefits:**
- Repositories created at startup (single source of truth)
- Handlers receive interfaces, not concrete implementations
- Easy to swap implementations (Firestore → Postgres) at startup

---

## 5. Testing with Mocks

### Mock Implementation

```go
package mocks

import (
    "context"
    "errors"
    "your-project/internal/repository"
)

type MockProductRepository struct {
    Products map[string]*repository.Product
}

func NewMockProductRepository() *MockProductRepository {
    return &MockProductRepository{
        Products: make(map[string]*repository.Product),
    }
}

func (m *MockProductRepository) Create(ctx context.Context, product *repository.Product) error {
    m.Products[product.ID] = product
    return nil
}

func (m *MockProductRepository) GetByID(ctx context.Context, id string) (*repository.Product, error) {
    product, exists := m.Products[id]
    if !exists {
        return nil, errors.New("product not found")
    }
    return product, nil
}

// Other methods...
```

### Usage in Tests

```go
func TestCreateOrder(t *testing.T) {
    // Arrange
    mockProductRepo := mocks.NewMockProductRepository()
    mockProductRepo.Products["prod_001"] = &repository.Product{
        ID: "prod_001",
        Name: "Wildflower Honey",
        Price: 1299,
        Inventory: 10,
    }

    mockOrderRepo := mocks.NewMockOrderRepository()
    orderHandler := handlers.NewOrderHandler(mockProductRepo, mockOrderRepo, nil)

    // Act
    order := &repository.Order{
        Items: []repository.OrderItem{
            {ProductID: "prod_001", Quantity: 2},
        },
    }
    err := orderHandler.CreateOrder(context.Background(), order)

    // Assert
    if err != nil {
        t.Errorf("Expected no error, got %v", err)
    }
    if mockProductRepo.Products["prod_001"].Inventory != 8 {
        t.Errorf("Expected inventory to be 8, got %d", mockProductRepo.Products["prod_001"].Inventory)
    }
}
```

**Benefits:**
- No Firestore emulator needed for unit tests
- Fast test execution (in-memory data)
- Full control over test data and error scenarios

---

## 6. Migration to Postgres

### When to Migrate?

**Triggers:**
- Firestore costs exceed Postgres (high read/write volume)
- Need complex queries (JOINs, aggregations)
- Need relational integrity constraints
- Scaling beyond Firestore's query limitations

### Migration Steps

#### Step 1: Implement Postgres Repositories

Create new package: `internal/repository/postgres/`

```go
package postgres

import (
    "context"
    "database/sql"
    "your-project/internal/repository"
)

type productRepository struct {
    db *sql.DB
}

func NewProductRepository(db *sql.DB) repository.ProductRepository {
    return &productRepository{db: db}
}

func (r *productRepository) Create(ctx context.Context, product *repository.Product) error {
    query := `
        INSERT INTO products (id, name, description, variety, price, size, image_url, inventory, low_stock_threshold, is_active, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
    `
    _, err := r.db.ExecContext(ctx, query,
        product.ID, product.Name, product.Description, product.Variety,
        product.Price, product.Size, product.ImageURL, product.Inventory,
        product.LowStockThreshold, product.IsActive, product.CreatedAt, product.UpdatedAt,
    )
    return err
}

// Other methods follow same pattern (SQL queries)...
```

#### Step 2: Data Migration Script

```go
package main

import (
    "context"
    "log"
    "cloud.google.com/go/firestore"
    "database/sql"
    _ "github.com/lib/pq"
)

func main() {
    ctx := context.Background()

    // Connect to Firestore
    firestoreClient, _ := firestore.NewClient(ctx, "your-project-id")
    defer firestoreClient.Close()

    // Connect to Postgres
    postgresDB, _ := sql.Open("postgres", "postgres://user:pass@localhost/dbname")
    defer postgresDB.Close()

    // Fetch all products from Firestore
    docs, _ := firestoreClient.Collection("products").Documents(ctx).GetAll()

    // Insert into Postgres
    for _, doc := range docs {
        var product Product
        doc.DataTo(&product)

        query := `INSERT INTO products (...) VALUES (...)`
        postgresDB.ExecContext(ctx, query, ...)
    }

    log.Println("Migration complete!")
}
```

#### Step 3: Update Dependency Injection

```go
// main.go
import (
    "database/sql"
    _ "github.com/lib/pq"
    "your-project/internal/repository/postgres"
)

func main() {
    // Connect to Postgres instead of Firestore
    db, err := sql.Open("postgres", "postgres://user:pass@host/dbname")
    if err != nil {
        log.Fatalf("Failed to connect to Postgres: %v", err)
    }
    defer db.Close()

    // Create Postgres repositories
    productRepo := postgres.NewProductRepository(db)
    orderRepo := postgres.NewOrderRepository(db)

    // Rest of setup unchanged (handlers don't care about implementation)
    orderHandler := handlers.NewOrderHandler(productRepo, orderRepo, ...)
}
```

#### Step 4: Deploy

- Test in staging environment with migrated data
- Verify all functionality works
- Deploy to production (zero business logic changes)

---

## 7. Benefits Summary

**Flexibility:**
- Swap databases without rewriting business logic
- Try new database technologies easily

**Testability:**
- Unit tests use mocks (no database required)
- Integration tests use real implementations

**Maintainability:**
- Clear separation of concerns (data access vs business logic)
- Database queries in one place (repository implementations)

**Scalability:**
- Optimize database queries without touching handlers
- Add caching layer in repository implementations (transparent to callers)

---

## Related Documents

- [data-model.md](./data-model.md) - Current Firestore schema
- [architecture.md](./architecture.md) - System architecture overview
- [testing.md](./testing.md) - Testing strategy including repository tests
