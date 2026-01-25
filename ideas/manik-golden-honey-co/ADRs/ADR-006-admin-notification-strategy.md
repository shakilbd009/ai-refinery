# ADR-006: Dashboard Badges + Email for Admin Notifications

## Status

Accepted

---

## Context

Admin needs timely notifications for events requiring action:
- New reviews awaiting moderation
- Customer cancellation requests
- Low inventory alerts (< 10 units)
- System errors or issues

The notification strategy affects admin responsiveness, workload management, and overall operational efficiency.

**Key factors:**
- Single admin user for MVP (small business owner)
- Admin may not check dashboard constantly
- Time-sensitive events need attention within 24 hours (not instant)
- Budget constraints (no expensive notification services)
- Admin likely checking email regularly throughout day
- Mobile-responsive admin dashboard (check from phone)

---

## Decision

Implement **dashboard badges + email notifications** hybrid approach:

**Dashboard badges:**
- Visual indicators on admin sidebar for pending items
- Badge count shows: pending reviews, cancellation requests, low inventory items
- Clicking badge navigates to relevant queue
- Visible immediately when admin logs in

**Email notifications:**
- Sent immediately when action-requiring event occurs
- Emails include: summary, direct link to admin dashboard, action needed
- Admin can click email link → lands directly on relevant queue

**No SMS or push notifications** for MVP (overkill for 24-hour SLA)

---

## Consequences

### Positive

- **Dual awareness**: Admin notified even if not checking dashboard
- **No missed events**: Email backup ensures visibility
- **Actionable emails**: Direct links to admin dashboard
- **Cost-effective**: Email included in email service cost (no additional service)
- **Mobile-friendly**: Works on admin's phone (email + responsive dashboard)
- **Batch-friendly**: Multiple events = multiple emails (clear what needs action)
- **Audit trail**: Email history provides record of notifications

### Negative

- **Email fatigue**: Multiple events = multiple emails (potential inbox clutter)
- **Not instant**: Relies on admin checking email (no push notification urgency)
- **Dashboard check required**: Email drives admin to dashboard (not self-contained)
- **No real-time**: If admin away from email for hours, delay in response
- **Spam risk**: Transactional emails could be filtered/ignored

### Neutral

- Can implement email digest later (daily summary instead of per-event)
- Dashboard badges require WebSocket or polling for real-time updates (polling acceptable for MVP)
- Email templates needed (notification-style, not transactional)

---

## Alternatives Considered

### Alternative 1: Email Only (No Dashboard Badges)

**Why considered:**
- **Simplest**: No dashboard UI changes needed
- **Universal**: Works even if admin never logs in
- **Mobile-friendly**: Email accessible anywhere
- **Familiar**: Everyone checks email

**Why rejected:**
- **No visual priority**: Email inbox treats all messages equally
- **Easy to miss**: Emails get buried in inbox
- **No batch view**: Can't see "5 pending reviews" at a glance
- **Action friction**: Must find and click email link each time
- **No dashboard context**: Admin loses big-picture view of workload

### Alternative 2: SMS Alerts for Critical Events

**Why considered:**
- **Instant**: SMS arrives immediately, hard to miss
- **Mobile-first**: Works on any phone
- **High open rate**: 98% SMS open rate vs 20% email
- **Urgency**: SMS feels more urgent than email

**Why rejected:**
- **Cost**: $0.01-0.05 per SMS (adds up quickly)
- **Overkill**: 24-hour SLA doesn't require instant notification
- **Privacy**: Requires admin phone number (may not want business SMS)
- **Spam perception**: SMS notifications can feel intrusive
- **Infrastructure**: Requires Twilio or similar service (additional dependency)
- **International**: SMS costs/reliability vary by country

### Alternative 3: Push Notifications (Browser/PWA)

**Why considered:**
- **Modern**: Progressive Web App approach
- **No app install**: Works in browser
- **Free**: Web Push API is free
- **Instant**: Real-time delivery

**Why rejected:**
- **Browser-dependent**: Requires admin to have dashboard open in browser
- **Permission friction**: Admin must grant notification permission
- **Desktop-only**: Not reliable on mobile browsers
- **Technical complexity**: Service worker, push subscription management
- **Overkill for MVP**: Dashboard badges + email simpler and sufficient
- **Low notification volume**: Not worth implementing for ~3-5 events/week

### Alternative 4: Dashboard Only (No Email)

**Why considered:**
- **Clean**: No email clutter
- **Encourages dashboard checking**: Admin builds habit of logging in daily
- **Simple**: Fewer notification channels to maintain

**Why rejected:**
- **Missed events risk**: If admin doesn't log in, events go unnoticed
- **No backup**: Single point of failure (dashboard unavailable = no visibility)
- **Workload planning**: Admin can't triage from email (must log in first)
- **Mobile friction**: Opening dashboard on phone is slower than reading email

---

## Implementation Notes

**Dashboard badge UI:**
```javascript
// Admin sidebar component
<NavLink to="/admin/reviews">
  Reviews
  {pendingReviewsCount > 0 && (
    <Badge variant="warning">{pendingReviewsCount}</Badge>
  )}
</NavLink>

<NavLink to="/admin/cancellations">
  Cancellations
  {pendingCancellationsCount > 0 && (
    <Badge variant="danger">{pendingCancellationsCount}</Badge>
  )}
</NavLink>
```

**Badge count API:**
```go
// GET /api/admin/notification-counts
{
  "pending_reviews": 3,
  "pending_cancellations": 1,
  "low_inventory_products": 2
}
```

**Polling strategy:**
- Admin dashboard polls `/notification-counts` every 30 seconds (when dashboard open)
- Acceptable latency for non-critical updates
- No WebSocket complexity for MVP

**Email notification triggers:**

1. **New review submitted:**
   - To: Admin email
   - Subject: "New review awaiting moderation - [Product Name]"
   - Body: Review snippet, rating, customer email, [Moderate Review] button/link
   - Link: `https://admin.example.com/reviews?filter=pending&highlight={review_id}`

2. **Cancellation request:**
   - To: Admin email
   - Subject: "Cancellation request - Order #{order_id}"
   - Body: Customer name, order total, cancellation reason, [Review Request] button/link
   - Link: `https://admin.example.com/cancellations/{request_id}`

3. **Low inventory alert:**
   - To: Admin email
   - Subject: "Low inventory alert - [Product Name] (X units left)"
   - Body: Product name, current quantity, reorder suggestion, [Update Inventory] link
   - Link: `https://admin.example.com/products/{product_id}/edit`
   - Trigger: When `quantity - reserved_quantity < 10`
   - Throttle: Max 1 email per product per day (avoid spam)

**Email template structure:**
```html
<div style="font-family: sans-serif;">
  <h2>[Event Type]</h2>
  <p>[Event summary]</p>

  <div style="background: #f5f5f5; padding: 16px; border-radius: 8px;">
    [Event details]
  </div>

  <a href="[Dashboard link]"
     style="display: inline-block; background: #4CAF50; color: white;
            padding: 12px 24px; text-decoration: none; border-radius: 4px;
            margin-top: 16px;">
    [Action Button Text]
  </a>

  <p style="color: #666; font-size: 12px; margin-top: 24px;">
    You can also view this in your
    <a href="https://admin.example.com">admin dashboard</a>.
  </p>
</div>
```

**Email sending:**
- Use Mailgun transactional API (separate from customer emails)
- From: `notifications@manikkgoldenhoney.com`
- Reply-to: `noreply@manikgoldenhoney.com`
- Template management: Store templates in code (not email service)
- Error handling: Log failed notifications, retry once

**Future enhancements:**
- Email digest mode: Admin preference to receive daily summary instead of per-event
- Notification preferences: Admin can disable specific notification types
- Mobile app push notifications (if native app built)
- SMS for critical-only events (e.g., system down)

---

## Success Criteria

**How we'll know this decision was correct:**
- Admin response time to events < 6 hours (well within 24-hour SLA)
- Zero missed events (admin acts on all notifications)
- Admin satisfaction with notification system > 4/5
- < 5% of email notifications marked as spam/unread
- Dashboard badge click-through rate > 80% (badges drive action)

**Red flags to watch for:**
- Admin response time > 24 hours (notifications not working)
- Admin complaints about email volume (need digest mode)
- Low email open rate < 50% (emails being ignored)
- Admin bypassing dashboard (email-only workflow emerging)

---

## Review Date

**Review after 3 months of production use** or if:
- Admin requests SMS notifications (urgency issue)
- Email open rate < 40% (notifications ineffective)
- Notification volume > 20/day (email fatigue)
- Admin consistently responds within 1 hour (may not need email backup)

**Potential upgrades:**
- Add SMS for critical events only
- Implement email digest mode (daily summary)
- Build Slack integration (if admin uses Slack)
- Add webhook notifications (for future integrations)

---

## References

- Functional Requirements: #12 (Review Moderation), #12a (Cancellation Management)
- Related ADRs: ADR-002 (Review Timing), ADR-003 (Cancellation Workflow)
- Mailgun API: https://documentation.mailgun.com/en/latest/

---

**Date:** 2026-01-24
**Author(s):** Claude (Systematic Refinement)
**Reviewers:** [Pending]
