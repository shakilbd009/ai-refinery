# Accessibility Standards (WCAG 2.1 AA)

WCAG 2.1 AA compliance is required for legal compliance (ADA) and to ensure all customers can use the site.

## Key E-Commerce Requirements

### Perceivable

| Criterion | Requirement | Priority |
|-----------|-------------|----------|
| 1.1.1 Non-text Content | All images have alt text | Critical |
| 1.3.1 Info and Relationships | Form labels, headings | Critical |
| 1.3.5 Identify Input Purpose | Autocomplete attributes | Medium |
| 1.4.1 Use of Color | Color not sole indicator | Critical |
| 1.4.3 Contrast (Minimum) | 4.5:1 text, 3:1 large text | Critical |
| 1.4.4 Resize Text | Content readable at 200% zoom | High |
| 1.4.10 Reflow | No horizontal scroll at 320px | High |
| 1.4.11 Non-text Contrast | 3:1 for UI components | High |

### Operable

| Criterion | Requirement | Priority |
|-----------|-------------|----------|
| 2.1.1 Keyboard | All functions keyboard accessible | Critical |
| 2.1.2 No Keyboard Trap | Focus can always move | Critical |
| 2.4.1 Bypass Blocks | Skip to main content link | High |
| 2.4.3 Focus Order | Logical tab order | Critical |
| 2.4.4 Link Purpose | Descriptive link text | High |
| 2.4.6 Headings and Labels | Descriptive headings | High |
| 2.4.7 Focus Visible | Visible focus indicator | Critical |

### Understandable

| Criterion | Requirement | Priority |
|-----------|-------------|----------|
| 3.1.1 Language of Page | `lang="en"` attribute | High |
| 3.2.1 On Focus | No unexpected changes | Critical |
| 3.2.2 On Input | No unexpected changes | Critical |
| 3.3.1 Error Identification | Describe errors in text | Critical |
| 3.3.2 Labels or Instructions | Clear form labels | Critical |
| 3.3.3 Error Suggestion | Suggest corrections | High |
| 3.3.4 Error Prevention | Confirm before submit | High |

### Robust

| Criterion | Requirement | Priority |
|-----------|-------------|----------|
| 4.1.1 Parsing | Valid HTML | Medium |
| 4.1.2 Name, Role, Value | ARIA labels correct | Critical |

## Form Accessibility

### Label Requirements

```html
<!-- Explicit label association -->
<label for="email">Email Address</label>
<input type="email" id="email" name="email" autocomplete="email" required>

<!-- Required field indication -->
<label for="name">
  Full Name <span aria-label="required">*</span>
</label>
<input type="text" id="name" name="name" autocomplete="name" required
       aria-required="true">
```

### Error Message Requirements

```html
<label for="email">Email Address *</label>
<input type="email" id="email" name="email"
       aria-invalid="true"
       aria-describedby="email-error">
<p id="email-error" class="error" role="alert">
  Please enter a valid email address (example: name@example.com)
</p>
```

### Checkout Form Structure

```html
<form aria-label="Checkout form">
  <fieldset>
    <legend>Shipping Address</legend>
    <!-- Address fields with proper labels -->
  </fieldset>
  <fieldset>
    <legend>Payment Information</legend>
    <!-- Stripe Elements (inherently accessible) -->
  </fieldset>
  <fieldset>
    <legend>Order Review</legend>
    <!-- Order summary table with proper headers -->
  </fieldset>
</form>
```

### Autocomplete Attributes

| Field | Autocomplete Value |
|-------|-------------------|
| Full name | `name` |
| Email | `email` |
| Phone | `tel` |
| Street address | `street-address` |
| City | `address-level2` |
| State | `address-level1` |
| ZIP code | `postal-code` |

## Image Alt Text

### Product Images

```html
<!-- Informative -->
<img src="wildflower-honey-12oz.jpg"
     alt="12oz jar of Wildflower Honey with golden amber color">

<!-- Decorative -->
<img src="decorative-bee.png" alt="">

<!-- Complex -->
<img src="product-comparison.jpg"
     alt="Honey variety comparison chart"
     aria-describedby="comparison-desc">
<p id="comparison-desc" class="sr-only">
  Chart comparing Wildflower, Clover, and Buckwheat honey by color,
  taste profile, and best uses.
</p>
```

### Alt Text Guidelines

| Image Type | Guideline |
|------------|-----------|
| Product images | Include product name, size, key visual features |
| Icons | Describe function, not appearance |
| Decorative | Use `alt=""` |
| Charts/infographics | Provide text alternative |
| Logos | Company name only |

## Keyboard Navigation

### Tab Order

1. Skip to main content link (first focusable)
2. Main navigation
3. Search (if present)
4. Main content area (reading order)
5. Sidebar (if present)
6. Footer

### Focus Management

```javascript
// After adding to cart, focus the cart summary
cartButton.addEventListener('click', () => {
  addToCart(product);
  cartSummary.focus();
});

// Modal focus trap
modal.addEventListener('keydown', (e) => {
  if (e.key === 'Tab') {
    trapFocus(modal, e);
  }
  if (e.key === 'Escape') {
    closeModal();
    triggerButton.focus();
  }
});
```

### Skip Link Implementation

```html
<body>
  <a href="#main-content" class="skip-link">Skip to main content</a>
  <header>...</header>
  <main id="main-content" tabindex="-1">...</main>
</body>

<style>
.skip-link { position: absolute; left: -9999px; }
.skip-link:focus { position: static; left: auto; }
</style>
```

## Color Contrast

### WCAG 2.1 AA Minimums

| Element Type | Minimum Ratio |
|--------------|---------------|
| Normal text (<18pt) | 4.5:1 |
| Large text (>=18pt or 14pt bold) | 3:1 |
| UI components | 3:1 |
| Graphical objects | 3:1 |

### Recommended Brand Colors

| Use | Foreground | Background | Ratio |
|-----|------------|------------|-------|
| Body text | #333333 | #FFFFFF | 12.6:1 |
| Headings | #1A1A1A | #FFFFFF | 16.1:1 |
| Primary button | #FFFFFF | #B8860B | 4.5:1 |
| Link text | #0066CC | #FFFFFF | 5.9:1 |
| Error text | #D32F2F | #FFFFFF | 5.5:1 |
| Success text | #2E7D32 | #FFFFFF | 4.8:1 |

### Color Not Sole Indicator

```html
<!-- Use color + icon + text -->
<input style="border-color: red;" aria-invalid="true">
<span class="error-icon" aria-hidden="true">!</span>
<p class="error-text">Please enter a valid email</p>
```

## Testing

### Automated Tools

| Tool | Purpose | Integration |
|------|---------|-------------|
| axe-core | Accessibility testing | CI/CD pipeline |
| Lighthouse | Performance + accessibility | Pre-deploy check |
| WAVE | Visual evaluation | Manual review |
| Pa11y | CLI testing | CI/CD pipeline |

### CI/CD Integration

```yaml
- name: Run axe-core tests
  run: npm run test:a11y

- name: Run Lighthouse CI
  run: lhci autorun --collect.preset=desktop

- name: Fail if accessibility score < 90
  run: |
    score=$(cat lighthouse-results.json | jq '.categories.accessibility.score')
    if (( $(echo "$score < 0.90" | bc -l) )); then
      exit 1
    fi
```

### Manual Testing Schedule

| Test Type | Frequency | Performed By |
|-----------|-----------|--------------|
| Keyboard-only navigation | Each release | Developer |
| Screen reader testing | Monthly | QA or specialist |
| Color contrast spot-check | Each release | Developer |
| Full WCAG audit | Quarterly | External auditor |

### Screen Reader Testing

**Tools:** NVDA (Windows), VoiceOver (macOS/iOS)

**Critical Flows:**
1. Browse products
2. Add to cart
3. Complete checkout
4. Write product review
5. Account management

### Release Checklist

- [ ] All pages pass axe-core with 0 violations
- [ ] Lighthouse accessibility score >= 90
- [ ] Complete checkout flow keyboard-only
- [ ] All form errors announced by screen reader
- [ ] No focus traps detected
- [ ] Color contrast verified for new components
- [ ] Alt text provided for all new images
