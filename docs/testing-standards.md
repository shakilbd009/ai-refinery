# Testing Standards

## Testing Philosophy

1. **Tests are documentation**: They show how code is meant to be used
2. **Fast feedback loop**: Tests should run quickly during development
3. **Confidence over coverage**: 100% coverage doesn't mean bug-free code
4. **Test behavior, not implementation**: Tests should survive refactoring

## What to Test

### ✅ Do Test

**Business logic**:
```javascript
// ✅ Test this
function calculateDiscount(price, userType) {
  if (userType === 'premium') return price * 0.8;
  if (userType === 'regular') return price * 0.9;
  return price;
}
```

**Edge cases**:
```javascript
// ✅ Test these scenarios
- Empty arrays
- Null/undefined inputs
- Boundary values (0, -1, MAX_INT)
- Off-by-one errors
```

**Error conditions**:
```javascript
// ✅ Test error handling
- Invalid inputs
- Network failures
- Database errors
- Permission denied
```

**Public APIs**:
```javascript
// ✅ Test exposed interfaces
- Function parameters and return values
- API endpoints (request/response)
- Component props
```

### ❌ Don't Test

**Framework code**:
```javascript
// ❌ Don't test React itself
expect(useState).toBeDefined(); // React team already tests this
```

**Third-party libraries**:
```javascript
// ❌ Don't test express
expect(app.use).toBeDefined(); // Express team tests their code
```

**Trivial code**:
```javascript
// ❌ Don't test getters/setters
class User {
  get name() { return this._name; }
  set name(value) { this._name = value; }
}
```

**Implementation details**:
```javascript
// ❌ Don't test private methods
// Test the public interface that uses them instead
```

## Testing Levels

### Unit Tests (70% of tests)

**Purpose**: Test individual functions/methods in isolation

**Characteristics**:
- Fast (milliseconds)
- No external dependencies (DB, API, filesystem)
- Use mocks/stubs for dependencies
- Test one thing at a time

**Example**:
```javascript
// unit: validate-email.test.js
import { validateEmail } from './validate-email';

describe('validateEmail', () => {
  it('returns true for valid emails', () => {
    expect(validateEmail('user@example.com')).toBe(true);
  });

  it('returns false for invalid emails', () => {
    expect(validateEmail('invalid')).toBe(false);
    expect(validateEmail('no@domain')).toBe(false);
    expect(validateEmail('')).toBe(false);
  });

  it('handles null/undefined', () => {
    expect(validateEmail(null)).toBe(false);
    expect(validateEmail(undefined)).toBe(false);
  });
});
```

### Integration Tests (20% of tests)

**Purpose**: Test how components work together

**Characteristics**:
- Slower than unit tests (seconds)
- May use real dependencies (test database)
- Test interactions between modules
- More realistic scenarios

**Example**:
```javascript
// integration: user-service.test.js
import { UserService } from './user-service';
import { testDb } from './test-helpers';

describe('UserService', () => {
  beforeEach(async () => {
    await testDb.reset(); // Reset test database
  });

  it('creates user and sends welcome email', async () => {
    const userService = new UserService(testDb, mockEmailService);

    const user = await userService.createUser({
      name: 'Test User',
      email: 'test@example.com'
    });

    expect(user.id).toBeDefined();
    expect(mockEmailService.send).toHaveBeenCalledWith(
      'test@example.com',
      'Welcome!'
    );
  });
});
```

### End-to-End Tests (10% of tests)

**Purpose**: Test complete user workflows

**Characteristics**:
- Slowest (minutes)
- Use real system (or staging environment)
- Test from user's perspective
- Catch integration issues

**Example**:
```javascript
// e2e: user-registration.test.js
import { test, expect } from '@playwright/test';

test('user can register and login', async ({ page }) => {
  await page.goto('/register');

  await page.fill('[name="email"]', 'newuser@example.com');
  await page.fill('[name="password"]', 'SecurePass123');
  await page.click('button[type="submit"]');

  await expect(page).toHaveURL('/dashboard');
  await expect(page.locator('h1')).toContainText('Welcome');
});
```

## Test Structure

### AAA Pattern (Arrange, Act, Assert)

```javascript
test('calculateTotal adds prices and tax', () => {
  // Arrange - Set up test data
  const items = [
    { price: 10 },
    { price: 20 }
  ];

  // Act - Execute the code under test
  const total = calculateTotal(items, 0.08);

  // Assert - Verify the result
  expect(total).toBe(32.4); // 30 + 8% tax
});
```

### Descriptive Test Names

```javascript
// ✅ Good - describes what and expected outcome
it('returns 404 when user does not exist', () => { });
it('sends email after successful payment', () => { });
it('throws error for negative prices', () => { });

// ❌ Bad - vague or technical jargon
it('works correctly', () => { });
it('test case 1', () => { });
it('should return value', () => { });
```

### One Assertion per Test (Guideline)

```javascript
// ✅ Preferred - focused test
it('validates email format', () => {
  expect(validateEmail('user@example.com')).toBe(true);
});

it('rejects invalid email format', () => {
  expect(validateEmail('invalid')).toBe(false);
});

// ⚠️ Acceptable if testing related behavior
it('user object has required fields', () => {
  expect(user.id).toBeDefined();
  expect(user.name).toBe('Test');
  expect(user.email).toBe('test@example.com');
});

// ❌ Bad - testing unrelated things
it('user service methods', () => {
  expect(createUser()).toBeDefined();
  expect(deleteUser()).toBe(true);
  expect(validateUser()).toBe(true);
});
```

## Mocking & Stubbing

### When to Mock

- External APIs (HTTP requests)
- Database calls (for unit tests)
- File system operations
- Time-dependent code (Date.now())
- Random values (Math.random())

### Example with Mocks

```javascript
// ✅ Good mocking
import { getUserById } from './user-service';
import { db } from './database';

jest.mock('./database');

test('getUserById returns user data', async () => {
  db.query.mockResolvedValue({
    id: 1,
    name: 'Test User'
  });

  const user = await getUserById(1);

  expect(user.name).toBe('Test User');
  expect(db.query).toHaveBeenCalledWith(
    'SELECT * FROM users WHERE id = ?',
    [1]
  );
});
```

### Don't Over-Mock

```javascript
// ❌ Bad - mocking everything defeats the purpose
jest.mock('./calculate-discount');
jest.mock('./validate-user');
jest.mock('./format-price');

// At this point, you're testing mocks, not real code
```

## Test Coverage

### Coverage Goals

- **Aim for 80% coverage** as a baseline
- **Critical paths should be 100%**: auth, payments, data integrity
- **Don't chase 100% everywhere**: Diminishing returns

### Coverage ≠ Quality

```javascript
// This has 100% coverage but tests nothing useful
function add(a, b) {
  return a + b;
}

test('add is a function', () => {
  expect(typeof add).toBe('function'); // ❌ Useless test
});

// Better
test('add returns sum of two numbers', () => {
  expect(add(2, 3)).toBe(5); // ✅ Tests behavior
  expect(add(-1, 1)).toBe(0);
  expect(add(0, 0)).toBe(0);
});
```

## Testing Best Practices

### 1. Fast Tests

```javascript
// ✅ Fast - runs in milliseconds
test('validates email', () => {
  expect(validateEmail('test@example.com')).toBe(true);
});

// ❌ Slow - makes real HTTP request
test('fetches user from API', async () => {
  const user = await fetch('https://api.example.com/users/1');
  expect(user).toBeDefined();
});

// ✅ Better - mocked
test('fetches user from API', async () => {
  global.fetch = jest.fn().mockResolvedValue({ id: 1 });
  const user = await getUser(1);
  expect(user).toBeDefined();
});
```

### 2. Independent Tests

```javascript
// ❌ Bad - tests depend on each other
let userId;

test('creates user', async () => {
  userId = await createUser({ name: 'Test' });
});

test('finds user', async () => {
  const user = await findUser(userId); // Breaks if first test fails
});

// ✅ Good - tests are independent
test('creates user', async () => {
  const userId = await createUser({ name: 'Test' });
  expect(userId).toBeDefined();
});

test('finds user', async () => {
  const userId = await createUser({ name: 'Test' });
  const user = await findUser(userId);
  expect(user.name).toBe('Test');
});
```

### 3. Deterministic Tests

```javascript
// ❌ Bad - test result varies
test('generates random ID', () => {
  expect(generateId()).toBe('abc123'); // Fails randomly
});

// ✅ Good - mock randomness
test('generates random ID', () => {
  jest.spyOn(Math, 'random').mockReturnValue(0.5);
  expect(generateId()).toBe('abc123');
});
```

### 4. Clean Up After Tests

```javascript
// ✅ Good - cleanup
afterEach(() => {
  jest.clearAllMocks();
  testDb.reset();
});

afterAll(() => {
  testDb.close();
});
```

## Testing Tools

### JavaScript/TypeScript

**Unit/Integration**:
- **Jest**: Most popular, built-in mocking
- **Vitest**: Faster, Vite-native alternative

**E2E**:
- **Playwright**: Modern, fast, multi-browser
- **Cypress**: Popular, good DX

### Python

**Unit/Integration**:
- **pytest**: Industry standard
- **unittest**: Built-in alternative

**E2E**:
- **Selenium**: Browser automation

### Go

**Built-in testing**: `go test`
- Simple, effective
- Table-driven tests pattern

## CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm test
      - run: npm run test:e2e
```

## Common Testing Mistakes

### ❌ Testing Implementation Details
```javascript
// ❌ Bad - tests internal state
expect(component.state.count).toBe(1);

// ✅ Good - tests observable behavior
expect(screen.getByText('Count: 1')).toBeInTheDocument();
```

### ❌ Flaky Tests
- Tests that randomly fail
- Often due to timing issues, randomness, or shared state
- Fix immediately - they erode trust in test suite

### ❌ Slow Test Suite
- Tests taking minutes to run
- Developers won't run them locally
- Consider parallel execution, better mocking

### ❌ No Tests for Bug Fixes
When fixing a bug:
1. Write a failing test that reproduces the bug
2. Fix the bug
3. Verify the test passes
4. Now the bug can't return unnoticed

## Test Checklist

- [ ] Tests are fast (unit tests < 100ms each)
- [ ] Tests are independent (can run in any order)
- [ ] Tests are deterministic (same result every time)
- [ ] Tests clean up after themselves
- [ ] Test names describe what and why
- [ ] Mocks are used appropriately
- [ ] Coverage is tracked but not obsessed over
- [ ] Tests run in CI/CD
- [ ] Failing tests block deployment
- [ ] Tests serve as documentation

## Remember

**Good tests**:
- Give you confidence to refactor
- Catch bugs before production
- Document how code should behave
- Run fast enough to use them constantly

**Bad tests**:
- Break when you refactor (brittle)
- Take too long to run (ignored)
- Test the wrong things (false confidence)
- Are hard to understand (poor documentation)

Write tests that you'll actually run and maintain.
