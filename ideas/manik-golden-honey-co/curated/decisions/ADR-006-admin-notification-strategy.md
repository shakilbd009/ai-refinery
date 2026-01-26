# ADR-006: Dashboard Badges + Email for Admin Notifications

## Status

Accepted

## Context

Admin needs timely notifications for events requiring action:
- New reviews awaiting moderation
- Customer cancellation requests
- Low inventory alerts (< 10 units)
- System errors or issues

**Key factors:**
- Single admin user for MVP (small business owner)
- Admin may not check dashboard constantly
- Time-sensitive events need attention within 24 hours (not instant)
- Budget constraints (no expensive notification services)
- Admin likely checking email regularly throughout day
- Mobile-responsive admin dashboard (can check from phone)

## Decision

Implement **dashboard badges + email notifications** hybrid approach.

**Dashboard badges:**
- Visual indicators on admin sidebar for pending items
- Badge count shows: pending reviews, cancellation requests, low inventory items
- Clicking badge navigates to relevant queue
- Visible immediately when admin logs in
- Poll `/api/admin/notification-counts` every 30 seconds when dashboard open

**Email notifications:**
- Sent immediately when action-requiring event occurs
- Include: summary, direct link to admin dashboard, action needed
- Admin can click email link and land directly on relevant queue
- Low inventory alerts throttled to max 1 email per product per day

**No SMS or push notifications** for MVP (overkill for 24-hour SLA).

## Consequences

### Positive

- **Dual awareness**: Admin notified even if not checking dashboard
- **No missed events**: Email backup ensures visibility
- **Actionable emails**: Direct links to admin dashboard
- **Cost-effective**: Email included in existing email service cost
- **Mobile-friendly**: Works on admin's phone (email + responsive dashboard)
- **Audit trail**: Email history provides record of notifications

### Negative

- **Email fatigue**: Multiple events create multiple emails (potential inbox clutter)
- **Not instant**: Relies on admin checking email (no push notification urgency)
- **Dashboard check required**: Email drives admin to dashboard (not self-contained)
- **Spam risk**: Transactional emails could be filtered or ignored

### Trade-offs

| Factor | Dashboard + Email | Email Only | SMS | Push Notifications |
|--------|-------------------|------------|-----|-------------------|
| Visibility | High | Medium | High | Medium |
| Cost | Low | Low | $0.01-0.05/msg | Free |
| Urgency | Medium | Low | High | High |
| Mobile support | Good | Good | Excellent | Browser-dependent |
| Complexity | Medium | Low | Medium | High |

## Alternatives Rejected

**Email Only:** No visual priority in inbox, easy to miss, no at-a-glance workload view, action friction for each event.

**SMS Alerts:** Cost adds up quickly, overkill for 24-hour SLA, requires admin phone number, additional Twilio dependency.

**Push Notifications (PWA):** Browser-dependent, requires permission, not reliable on mobile browsers, complex implementation for low notification volume (~3-5 events/week).

**Dashboard Only:** Risk of missed events if admin doesn't log in, no backup notification channel.

## Future Enhancements

- Email digest mode (daily summary instead of per-event)
- Notification preferences (admin can disable specific types)
- SMS for critical-only events (system down)

## References

- ADR-002: Review Timing (review moderation workflow)
- ADR-003: Cancellation Workflow (cancellation request handling)
