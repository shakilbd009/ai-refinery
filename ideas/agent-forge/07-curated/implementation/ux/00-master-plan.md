# User Experience Implementation - Master Plan

> **For Claude:** This is the master plan coordinating 6 parallel implementation tracks. Each track has its own plan file that can be executed by separate agents.

**Goal:** Implement the AgentForge UX design from `2026-01-15-user-experience-design.md`

**Architecture:** Six independent workstreams that can run in parallel, with minimal dependencies.

---

## Parallel Workstreams

| # | Workstream | Plan File | Dependencies | Priority |
|---|------------|-----------|--------------|----------|
| 1 | UI Components | `01-ui-components.md` | None | P0 - Foundation |
| 2 | Navigation & Layout | `02-navigation-layout.md` | #1 (Dialog) | P0 |
| 3 | Home Screen | `03-home-screen.md` | #1, #2 | P1 |
| 4 | New Project Flow | `04-new-project-flow.md` | #1 | P1 |
| 5 | Inbox System | `05-inbox-system.md` | #1, #2 | P1 |
| 6 | Agent Chat & Approval | `06-agent-approval.md` | #1 | P1 |

---

## Dependency Graph

```
┌─────────────────┐
│ 01-UI Components│ ◄── Foundation (start first or in parallel)
└────────┬────────┘
         │
    ┌────┴────┬──────────┬──────────┐
    ▼         ▼          ▼          ▼
┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐
│  02   │ │  04   │ │  05   │ │  06   │
│ Nav   │ │NewProj│ │ Inbox │ │ Agent │
└───┬───┘ └───────┘ └───────┘ └───────┘
    │
    ▼
┌───────┐
│  03   │
│ Home  │
└───────┘
```

**Parallel Execution Strategy:**
- Start all 6 workstreams simultaneously
- #1 is foundation but small enough to complete quickly
- #2-#6 can begin immediately; they implement their own minimal versions of needed components if #1 isn't done
- Each workstream creates feature branches: `feat/ux-{workstream-name}`

---

## Shared Conventions

### File Naming
- Components: `kebab-case.tsx`
- Pages: `page.tsx` in route directories
- Types: Colocated in component files or `types.ts`

### Component Patterns
```typescript
"use client"

import { ComponentProps } from "@/types"
import { cn } from "@/lib/utils"

interface Props extends ComponentProps {
  // Props
}

export function ComponentName({ className, ...props }: Props) {
  return (
    <div className={cn("base-styles", className)} {...props}>
      {/* Content */}
    </div>
  )
}
```

### Branch Strategy
Each workstream creates its own branch:
```bash
git checkout -b feat/ux-ui-components      # Workstream 1
git checkout -b feat/ux-navigation         # Workstream 2
git checkout -b feat/ux-home-screen        # Workstream 3
git checkout -b feat/ux-new-project        # Workstream 4
git checkout -b feat/ux-inbox              # Workstream 5
git checkout -b feat/ux-agent-approval     # Workstream 6
```

### Testing
No test framework configured yet. Each workstream should:
1. Manually verify components render
2. Test responsive layouts
3. Verify dark mode
4. Check accessibility (keyboard navigation, focus states)

---

## Accessibility Requirements (WCAG 2.1 AA)

All UI components must meet WCAG 2.1 Level AA compliance.

### Keyboard Navigation

| Requirement | Implementation |
|-------------|----------------|
| All interactive elements focusable | Use semantic HTML (button, a, input) |
| Visible focus indicator | Custom focus ring with sufficient contrast |
| Logical tab order | Natural DOM order, tabindex only when necessary |
| Skip links | "Skip to main content" on every page |
| Keyboard shortcuts | Escape to close modals, Enter to submit |

### Screen Reader Support

| Requirement | Implementation |
|-------------|----------------|
| Meaningful alt text | All images have descriptive alt |
| ARIA labels | Custom components use aria-label/labelledby |
| Live regions | Agent status updates use aria-live |
| Heading hierarchy | h1 → h2 → h3, no skipping levels |
| Form labels | Every input has associated label |

### Visual Design

| Requirement | Implementation |
|-------------|----------------|
| Color contrast | 4.5:1 for text, 3:1 for large text/icons |
| Don't rely on color alone | Icons/text accompany color indicators |
| Text resizing | UI usable at 200% zoom |
| Reduced motion | Respect prefers-reduced-motion |
| Focus visible | 2px solid ring with offset |

### Component Checklist

Every new component must include:
```typescript
// Accessibility checklist for components:
// - [ ] Keyboard navigable
// - [ ] Screen reader tested (VoiceOver/NVDA)
// - [ ] Focus states visible
// - [ ] Color contrast verified
// - [ ] ARIA attributes where needed
// - [ ] Works at 200% zoom
```

### Testing Tools

- **axe DevTools**: Automated accessibility testing
- **Lighthouse**: Accessibility audit in CI
- **VoiceOver/NVDA**: Manual screen reader testing
- **Keyboard-only**: Navigate without mouse

---

## Coordination Points

### After All Workstreams Complete
1. Integration testing across all new features
2. Navigation flow testing (home → new project → chat → approval → inbox)
3. Merge branches in order: #1 → #2 → (#3, #4, #5, #6)

### Potential Conflicts
- `sidebar.tsx` - Modified by #2
- `(dashboard)/page.tsx` - Modified by #3
- `agents/page.tsx` - Modified by #6
- New shared components may need deduplication

---

## Out of Scope (Future Work)

- Backend API integration
- Real-time updates / WebSocket
- Multi-user collaboration
- Project archiving
- Change request workflow (cross-phase edits)
- Smart defaults / user preference learning

---

## Quick Start for Agents

**To execute a workstream:**
1. Read this master plan for context
2. Read your assigned workstream plan (e.g., `01-ui-components.md`)
3. Create feature branch
4. Execute tasks sequentially, committing after each
5. Mark plan complete when done

**REQUIRED SUB-SKILL:** Use `superpowers:executing-plans` to implement each workstream.
