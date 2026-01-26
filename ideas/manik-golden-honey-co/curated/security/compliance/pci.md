# PCI DSS Compliance

PCI DSS compliance is required for any business handling payment card data. Using Stripe reduces scope significantly but does not eliminate all obligations.

## Stripe Responsibilities (PCI Level 1)

Stripe handles all payment card data as a PCI Level 1 Service Provider.

**Stripe handles:**
- Card number collection (Stripe Elements/Checkout)
- Card validation and processing
- Card storage (tokenization)
- 3D Secure authentication
- Fraud detection (Radar)
- PCI DSS compliance for payment data

**We never receive:**
- Full card numbers
- CVV/CVC codes
- Card expiration dates
- Cardholder authentication data

## Our PCI Responsibilities

### SAQ A Eligibility

This setup qualifies for SAQ A (simplest self-assessment) because:
- All payment processing outsourced to Stripe
- No electronic card data storage
- Only iframe/redirect payment pages (Stripe Elements)
- No direct card data handling on our servers

### Secure Transmission

**Requirements:**
- HTTPS required on all pages
- TLS 1.2+ minimum (TLS 1.3 preferred)
- HSTS header enabled
- No mixed content warnings

**Implementation:**
```nginx
server {
    listen 443 ssl http2;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
}
```

### No Card Data Logging

Never log, store, or transmit card data.

```go
// BAD:
log.Printf("Payment from card %s", req.CardNumber)

// GOOD:
log.Printf("Payment intent created: %s", paymentIntent.ID)
```

**Code review checklist:**
- No card fields in request logging
- No card data in error messages
- No card data in debug output
- No card data in analytics events

### Stripe Integration Security

**Use Stripe Elements:**
- Client-side tokenization (card never touches our servers)
- PCI-compliant iframe integration
- Automatic security updates

**Verify webhook signatures:**
```go
func handleWebhook(w http.ResponseWriter, r *http.Request) {
    payload, _ := io.ReadAll(r.Body)
    sigHeader := r.Header.Get("Stripe-Signature")

    event, err := webhook.ConstructEvent(payload, sigHeader, webhookSecret)
    if err != nil {
        log.Printf("Webhook signature verification failed: %v", err)
        w.WriteHeader(http.StatusBadRequest)
        return
    }
    // Process verified event
}
```

**API key management:**
- Create keys with minimum required permissions
- Separate keys for test and production
- Never commit keys to source control
- Store in Secret Manager

### Access Control

**Stripe Dashboard:**
- Limit access to authorized admins only
- Enable 2FA on all Stripe accounts
- Review access logs quarterly
- Remove access immediately on role change

**API Key Rotation:**
- Rotate keys annually
- Rotate immediately if compromised
- Rotate after personnel changes
- Use environment variables (never hardcode)

## SAQ A Requirements Checklist

Complete annually for PCI compliance verification.

### Network Security
- [ ] All pages served over HTTPS
- [ ] TLS 1.2+ enforced
- [ ] Valid SSL certificate from trusted CA
- [ ] No card data transmitted to our servers
- [ ] HSTS header enabled

### Access Control
- [ ] Stripe dashboard access limited to need-to-know
- [ ] 2FA enabled on Stripe account
- [ ] API keys rotated annually
- [ ] Restricted API keys used (not full access)
- [ ] Access reviewed quarterly

### Vulnerability Management
- [ ] Stripe Elements/Checkout used (no custom card forms)
- [ ] No card data stored in our database
- [ ] No card data in logs, error messages, or debug output
- [ ] Dependencies updated regularly
- [ ] Security patches applied promptly

### Monitoring
- [ ] Stripe webhook signature verification enabled
- [ ] Failed payment alerts configured
- [ ] Suspicious activity monitoring via Stripe Radar
- [ ] Webhook delivery failures alerted

### Documentation
- [ ] SAQ A completed and stored
- [ ] Compliance attestation signed
- [ ] Incident response plan documented
- [ ] Data flow diagram maintained

## Annual Verification Timeline

| Task | Frequency | Due Date |
|------|-----------|----------|
| Complete SAQ A | Annually | January |
| Review Stripe access | Quarterly | Jan, Apr, Jul, Oct |
| Rotate API keys | Annually | January (or after personnel change) |
| Security awareness training | Annually | Upon hire, then yearly |
| Review webhook security | Quarterly | With access review |

## Incident Response

### If Card Data Exposure Suspected

1. **Contain:** Stop affected systems immediately
2. **Notify:** Contact Stripe support
3. **Investigate:** Determine scope of exposure
4. **Document:** Record timeline and actions taken
5. **Remediate:** Fix vulnerability, rotate keys
6. **Report:** Notify payment brands if required

### Contact Information
- Stripe Support: support.stripe.com
- PCI Security Standards Council: pcisecuritystandards.org

## Compliance Verification

### Self-Assessment
- Complete SAQ A questionnaire
- Sign Attestation of Compliance (AOC)
- Store documentation securely
- Review annually

### Evidence to Maintain
- SAQ A completed questionnaire
- Signed AOC
- Stripe PCI compliance certificate
- Access review logs
- Key rotation records
