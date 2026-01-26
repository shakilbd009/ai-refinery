# Data Boundary Edge Cases

Validation rules for empty values, limits, special characters, and type handling.

---

## Empty Inputs (null, empty string, empty arrays)

### Cart & Checkout

| Input | Location | Handling | Test Case |
|-------|----------|----------|-----------|
| Empty cart | POST /api/reserve-inventory | 400 "Cart is empty" | `items: []` |
| Null cart_id | POST /api/reserve-inventory | 400 "cart_id required" | `cart_id: null` |
| Empty product_id | Cart item | 400 "Invalid product_id" | `product_id: ""` |
| Null quantity | Cart item | 400 "Quantity required" | `quantity: null` |
| Empty shipping address | Order creation | 400 "Shipping address required" | `address: {}` |
| Null customer_id | Session | 401 "Authentication required" | Missing session |

### Discount Codes

| Input | Location | Handling | Test Case |
|-------|----------|----------|-----------|
| Empty code | POST /api/apply-promo-code | 400 "Code required" | `code: ""` |
| Null code | POST /api/apply-promo-code | 400 "Code required" | `code: null` |
| Whitespace only | POST /api/apply-promo-code | 400 "Invalid code" | `code: "   "` |

### Reviews

| Input | Location | Handling | Test Case |
|-------|----------|----------|-----------|
| Empty review text | POST /api/reviews | 400 "Review text required" | `text: ""` |
| Null rating | POST /api/reviews | 400 "Rating required" | `rating: null` |
| Empty display name | POST /api/reviews | Use "Anonymous" default | `display_name: ""` |

```javascript
function validateRequired(field, value) {
  if (value === null || value === undefined) {
    throw new ValidationError(`${field} is required`);
  }
  if (typeof value === 'string' && value.trim() === '') {
    throw new ValidationError(`${field} cannot be empty`);
  }
  if (Array.isArray(value) && value.length === 0) {
    throw new ValidationError(`${field} cannot be empty`);
  }
}
```

---

## Maximum Values

### Quantity Limits

| Field | Max Value | Handling | Rationale |
|-------|-----------|----------|-----------|
| Cart item quantity | 100 | 400 "Max 100 per item" | Practical limit for honey orders |
| Cart items count | 50 | 400 "Max 50 items per cart" | Firestore transaction limit (500 writes) |
| Reservation quantity total | 500 | 400 "Order too large" | Prevents DoS via large reservations |

### String Length Limits

| Field | Max Length | Handling | Rationale |
|-------|------------|----------|-----------|
| Promo code | 20 chars | 400 "Code too long" | Reasonable code length |
| Review text | 2000 chars | 400 "Review too long" | Prevents spam walls |
| Customer name | 100 chars | 400 "Name too long" | Standard limit |
| Address line | 200 chars | 400 "Address too long" | Standard limit |
| Email | 254 chars | 400 "Email too long" | RFC 5321 limit |

### Numeric Limits

| Field | Max Value | Handling | Rationale |
|-------|-----------|----------|-----------|
| Price (cents) | 99999999 (999,999.99) | 400 "Price exceeds limit" | Practical max |
| Discount percent | 100 | 400 "Discount must be 1-100" | Business rule |
| Rating | 5 | 400 "Rating must be 1-5" | Star system |
| Max redemptions | 1000000 | 400 "Max redemptions too high" | Prevent accidental unlimited |

```javascript
const LIMITS = {
  CART_ITEM_QUANTITY: 100,
  CART_ITEMS_COUNT: 50,
  PROMO_CODE_LENGTH: 20,
  REVIEW_TEXT_LENGTH: 2000,
  MAX_PRICE_CENTS: 99999999,
};

function validateMaxValue(field, value, max) {
  if (value > max) {
    throw new ValidationError(`${field} exceeds maximum (${max})`);
  }
}
```

---

## Minimum Values

### Zero Values

| Field | Zero Allowed? | Handling |
|-------|---------------|----------|
| Cart quantity | No | 400 "Quantity must be at least 1" |
| Product price | No | 400 "Price must be positive" |
| Discount percent | No | 400 "Discount must be at least 1%" |
| Min order value | Yes | 0 means no minimum |
| Max redemptions | No | null means unlimited, 0 invalid |
| Rating | No | 400 "Rating must be 1-5" |

### Negative Numbers

| Field | Handling | Test Case |
|-------|----------|-----------|
| Quantity: -1 | 400 "Quantity must be positive" | `quantity: -1` |
| Price: -100 | 400 "Price must be positive" | `price: -100` |
| Discount: -10 | 400 "Discount must be 1-100" | `discount_percent: -10` |
| Rating: -1 | 400 "Rating must be 1-5" | `rating: -1` |

### Boundary Conditions

| Scenario | Value | Expected |
|----------|-------|----------|
| Rating exactly 1 | `rating: 1` | Valid (minimum) |
| Rating exactly 5 | `rating: 5` | Valid (maximum) |
| Discount exactly 1% | `discount_percent: 1` | Valid (minimum) |
| Discount exactly 100% | `discount_percent: 100` | Valid (free order) |
| Cart total exactly at minimum | `total = min_order_value` | Code valid |
| Cart total $0.01 below minimum | `total = min - 1` | Code invalid |

```javascript
function validatePositive(field, value) {
  if (typeof value !== 'number' || value <= 0) {
    throw new ValidationError(`${field} must be a positive number`);
  }
}

function validateRange(field, value, min, max) {
  if (value < min || value > max) {
    throw new ValidationError(`${field} must be between ${min} and ${max}`);
  }
}
```

---

## Special Characters

### Unicode & Emoji Handling

| Field | Allowed? | Handling | Example |
|-------|----------|----------|---------|
| Customer name | Yes (Unicode) | Store as-is | "Jose Garcia" |
| Review text | Yes (Unicode + emoji) | Store as-is | "Great honey!" |
| Promo code | No (alphanumeric only) | 400 "Invalid characters" | "SAVE10" only |
| Address | Yes (Unicode) | Store as-is | International addresses |
| Email | Limited charset | Standard email validation | RFC 5322 compliant |

### XSS Prevention

| Field | Risk | Mitigation |
|-------|------|------------|
| Review text (display) | High | HTML escape on render |
| Customer name (display) | Medium | HTML escape on render |
| Promo code (display) | Low | Alphanumeric only |
| Admin notes | Medium | HTML escape on render |

```javascript
function validatePromoCodeFormat(code) {
  if (!/^[A-Z0-9]+$/i.test(code)) {
    throw new ValidationError('Code must be alphanumeric only');
  }
}

function sanitizeForDisplay(text) {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
```

**Firestore Safety:** NoSQL database doesn't use SQL queries. All operations use parameterized document references. SQL injection not applicable.

---

## Type Mismatches

| Field | Expected | Invalid Input | Handling |
|-------|----------|---------------|----------|
| quantity | number | `"5"` (string) | Coerce to number or 400 |
| quantity | number | `"five"` | 400 "Quantity must be a number" |
| price | number | `"19.99"` | Coerce to number (cents) |
| active | boolean | `"true"` | Coerce to boolean |
| active | boolean | `1` | Coerce to boolean |
| expires_at | timestamp | `"tomorrow"` | 400 "Invalid date format" |
| items | array | `{}` | 400 "Items must be an array" |
| items | array | `null` | 400 "Items required" |

```javascript
function coerceNumber(value, field) {
  if (typeof value === 'number') return value;
  if (typeof value === 'string') {
    const parsed = Number(value);
    if (isNaN(parsed)) {
      throw new ValidationError(`${field} must be a valid number`);
    }
    return parsed;
  }
  throw new ValidationError(`${field} must be a number`);
}

function validateType(value, expectedType, field) {
  const actualType = Array.isArray(value) ? 'array' : typeof value;
  if (actualType !== expectedType) {
    throw new ValidationError(`${field} must be ${expectedType}, got ${actualType}`);
  }
}
```
