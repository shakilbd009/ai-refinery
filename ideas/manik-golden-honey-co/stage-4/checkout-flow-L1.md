# Progressive Deepening: Checkout Flow

**Component:** Customer Checkout & Payment Processing
**Stage:** L1 (Refine L1 - High-Level Design)
**Date:** 2026-01-24

---

## L1 Pass: Surface Level (Stage 4: Refine L1)

### What

The checkout flow is the critical path where customers complete purchases. It handles inventory reservation, discount code application, payment processing via Stripe, and order creation. The flow must prevent overselling, apply discounts correctly, and create orders only after successful payment.

**Key components:**
- Inventory reservation system (15-min window)
- Discount code validation
- Stripe PaymentIntent creation
- Order confirmation and email notification

---

### Why

**Business critical:** This is the money path. Failures here mean lost revenue and customer trust.

**High-level motivation:**
- Prevent overselling (small producer can't afford fulfillment failures)
- Secure payment processing (PCI compliance delegated to Stripe)
- Clear customer experience (know if order succeeded or failed)
- Admin operational clarity (only pay-confirmed orders in system)

---

### Key Insight

**The checkout flow uses pessimistic locking (ADR-001) to prevent race conditions.**

The key insight: Inventory is reserved BEFORE payment, not after. This means:
- ✅ Customer always gets what they paid for
- ❌ Temporarily reduces available inventory (trade-off accepted)
- ⚠️ Requires background job to clean up abandoned reservations

**Critical sequence:**
1. Reserve inventory → 2. Collect payment → 3. Confirm order → 4. Release reservation

If payment fails or customer abandons, background job releases reservation after 15 minutes.

---

### Initial Questions Raised

1. **What happens if payment succeeds but order creation fails?**
   - Customer charged but no order record → Needs investigation in L2

2. **What if Stripe webhook arrives before /confirm-order call?**
   - Race condition between frontend confirmation and webhook → L2

3. **How do we handle partial inventory (customer wants 5, only 3 available)?**
   - All-or-nothing or allow partial? → Decision needed in L2

4. **What if discount code expires during checkout?**
   - Validate at payment time, not just at application → L2

5. **What if customer has multiple tabs open, reserves inventory twice?**
   - Session management needed → L2

---

## L2 Pass: Detailed Level (Stage 5: Refine L2)

*To be completed in Stage 5*

---

**Last Updated:** 2026-01-24
**Stage:** L1
