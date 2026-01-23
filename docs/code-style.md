# Code Style Standards

## Philosophy

Code is read more often than it's written. Optimize for readability and maintainability, not clever solutions.

**Core values**:
1. **Clarity over cleverness**
2. **Consistency over personal preference**
3. **Simplicity over complexity**
4. **Explicit over implicit**

## Universal Principles (All Languages)

### 1. Naming

**Variables and Functions**: Descriptive, readable names
```javascript
// ✅ Good
const userEmail = getUserEmail(userId);
function calculateTotalPrice(items) { }

// ❌ Bad
const ue = getUE(uid);
function calc(i) { }
```

**Constants**: SCREAMING_SNAKE_CASE for true constants
```javascript
const MAX_RETRY_ATTEMPTS = 3;
const API_BASE_URL = 'https://api.example.com';
```

**Classes**: PascalCase
```javascript
class UserService { }
class EmailValidator { }
```

**Booleans**: Prefix with is/has/should/can
```javascript
const isActive = true;
const hasPermission = checkPermission();
const shouldRetry = attempts < MAX_RETRY_ATTEMPTS;
```

### 2. Functions

**Keep them small**: One function, one purpose
```javascript
// ✅ Good - focused, single responsibility
function validateEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function sendWelcomeEmail(user) {
  if (!validateEmail(user.email)) {
    throw new Error('Invalid email');
  }
  return emailService.send(user.email, 'Welcome!');
}

// ❌ Bad - doing too much
function validateAndSendEmail(user) {
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(user.email)) {
    throw new Error('Invalid email');
  }
  return emailService.send(user.email, 'Welcome!');
}
```

**Function length**: Aim for < 20 lines. If longer, consider splitting.

**Parameters**: Max 3-4 parameters. More? Use an options object.
```javascript
// ✅ Good
function createUser({ name, email, role, department }) { }

// ❌ Bad
function createUser(name, email, role, department, manager, startDate) { }
```

### 3. Comments

**Comment the "why", not the "what"**
```javascript
// ✅ Good - explains reasoning
// Using Set for O(1) lookup performance with large datasets
const uniqueIds = new Set(ids);

// ❌ Bad - states the obvious
// Create a new Set from ids array
const uniqueIds = new Set(ids);
```

**When to comment**:
- Non-obvious decisions
- Complex algorithms
- Workarounds for bugs/limitations
- TODOs with context

**When NOT to comment**:
- Obvious code
- Instead of writing clear code
- To explain bad variable names

### 4. Error Handling

**Be explicit about errors**
```javascript
// ✅ Good
try {
  const user = await getUser(id);
  if (!user) {
    throw new Error(`User ${id} not found`);
  }
  return user;
} catch (error) {
  logger.error('Failed to fetch user', { id, error });
  throw error;
}

// ❌ Bad - silent failures
try {
  const user = await getUser(id);
  return user;
} catch (error) {
  return null;
}
```

**Don't swallow errors**: Log or re-throw, never ignore

### 5. DRY (Don't Repeat Yourself)

But don't overdo it. Three uses? Consider abstracting. Two uses? Maybe wait.

```javascript
// ✅ Abstraction makes sense
function formatCurrency(amount) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD'
  }).format(amount);
}

// Used in 5 places
const price1 = formatCurrency(19.99);
const price2 = formatCurrency(49.99);

// ❌ Premature abstraction
function addOne(x) {
  return x + 1;
}

// Only used once
const result = addOne(5);
```

## Language-Specific Standards

### JavaScript/TypeScript

**Use modern syntax**:
```javascript
// ✅ Use const/let, not var
const items = [...];
let count = 0;

// ✅ Arrow functions for callbacks
items.map(item => item.id);

// ✅ Destructuring
const { name, email } = user;
const [first, ...rest] = items;

// ✅ Template literals
const message = `Hello, ${name}!`;

// ✅ Optional chaining
const street = user?.address?.street;

// ✅ Nullish coalescing
const port = process.env.PORT ?? 3000;
```

**Async/await over callbacks**:
```javascript
// ✅ Good
async function fetchUser(id) {
  const response = await fetch(`/api/users/${id}`);
  return response.json();
}

// ❌ Avoid
function fetchUser(id, callback) {
  fetch(`/api/users/${id}`)
    .then(res => res.json())
    .then(data => callback(null, data))
    .catch(err => callback(err));
}
```

**TypeScript**: Use types, avoid `any`
```typescript
// ✅ Good
interface User {
  id: string;
  name: string;
  email: string;
}

function getUser(id: string): Promise<User> {
  // ...
}

// ❌ Bad
function getUser(id: any): any {
  // ...
}
```

### Python

**Follow PEP 8**:
```python
# ✅ Good
def calculate_total_price(items: list[Item]) -> float:
    """Calculate total price of items including tax."""
    subtotal = sum(item.price for item in items)
    tax = subtotal * 0.08
    return subtotal + tax

# ❌ Bad
def CalculateTotalPrice(Items):
    Subtotal = 0
    for Item in Items:
        Subtotal = Subtotal + Item.Price
    Tax = Subtotal * 0.08
    return Subtotal + Tax
```

**Use type hints**:
```python
from typing import Optional, List

def get_user(user_id: int) -> Optional[User]:
    # ...
    pass

def process_items(items: List[Item]) -> None:
    # ...
    pass
```

**List comprehensions** over loops when clear:
```python
# ✅ Good
squares = [x**2 for x in range(10)]
active_users = [u for u in users if u.is_active]

# ✅ Also fine if clearer
squares = []
for x in range(10):
    squares.append(x**2)
```

### Go

**Follow Go conventions**:
```go
// ✅ Good - exported names start with capital
type User struct {
    ID    string
    Name  string
    Email string
}

func GetUser(id string) (*User, error) {
    // ...
}

// ✅ Error handling
user, err := GetUser(id)
if err != nil {
    return nil, fmt.Errorf("failed to get user: %w", err)
}

// ✅ Defer for cleanup
file, err := os.Open("file.txt")
if err != nil {
    return err
}
defer file.Close()
```

## Formatting

**Use auto-formatters**. Don't argue about formatting - let tools handle it.

| Language | Tool |
|----------|------|
| JavaScript/TypeScript | Prettier |
| Python | Black |
| Go | gofmt |
| Rust | rustfmt |
| Ruby | RuboCop |

**Line length**: 80-100 characters max. Exceptions allowed for long strings/URLs.

**Indentation**:
- 2 spaces: JavaScript, TypeScript, Ruby, YAML, JSON
- 4 spaces: Python
- Tabs: Go (per Go convention)

## Code Organization

### Imports/Dependencies
**Group and sort imports**:
```javascript
// ✅ Good - grouped and sorted
// Standard library
import fs from 'fs';
import path from 'path';

// Third-party
import express from 'express';
import { z } from 'zod';

// Local
import { UserService } from './services/user';
import { config } from './config';
```

### File Structure
```javascript
// ✅ Good file organization
// 1. Imports
import { ... } from '...';

// 2. Constants
const MAX_RETRIES = 3;

// 3. Types/Interfaces
interface User { ... }

// 4. Main logic
class UserService { ... }

// 5. Exports
export { UserService };
```

## Anti-Patterns to Avoid

### Magic Numbers
```javascript
// ❌ Bad
if (user.age > 18) { }

// ✅ Good
const LEGAL_ADULT_AGE = 18;
if (user.age > LEGAL_ADULT_AGE) { }
```

### Nested Ternaries
```javascript
// ❌ Bad
const status = user.isActive ? user.isPremium ? 'premium' : 'active' : 'inactive';

// ✅ Good
let status = 'inactive';
if (user.isActive) {
  status = user.isPremium ? 'premium' : 'active';
}
```

### God Objects/Functions
```javascript
// ❌ Bad - function does everything
function handleUserAction(user, action, data) {
  // 200 lines of if/else for different actions
}

// ✅ Good - separated responsibilities
function handleLogin(user, credentials) { }
function handleLogout(user) { }
function handleUpdateProfile(user, data) { }
```

### Premature Optimization
```javascript
// ❌ Bad - optimizing before measuring
const cache = new Map();
function getUser(id) {
  if (cache.has(id)) return cache.get(id);
  const user = db.users.find(u => u.id === id);
  cache.set(id, user);
  return user;
}

// ✅ Good - start simple, optimize if needed
function getUser(id) {
  return db.users.find(u => u.id === id);
}
// Add caching only if profiling shows this is slow
```

## Testing Considerations

Write testable code:
```javascript
// ❌ Hard to test
function processUser() {
  const user = getCurrentUser(); // global dependency
  const result = calculateScore(user); // can't inject test data
  saveToDatabase(result); // side effect
}

// ✅ Easy to test
function calculateUserScore(user) {
  return user.points * user.multiplier;
}

function processUser(user, saveFunction) {
  const score = calculateUserScore(user);
  return saveFunction(score);
}
```

## Enforcement

1. **Linters**: ESLint, Pylint, RuboCop, golangci-lint
2. **Formatters**: Prettier, Black, gofmt
3. **Pre-commit hooks**: Run linting before commits
4. **CI/CD**: Fail builds on linting errors
5. **Code review**: Catch what automated tools miss

## Summary Checklist

- [ ] Names are clear and descriptive
- [ ] Functions are small and focused
- [ ] Comments explain "why", not "what"
- [ ] Errors are handled explicitly
- [ ] No magic numbers or strings
- [ ] Code is formatted consistently
- [ ] No obvious anti-patterns
- [ ] Would pass linter checks
- [ ] Easy to test
- [ ] Easy for someone else to understand
