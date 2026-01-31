# User Experience Component

## Overview

Design for AgentForge's user experience, supporting both technical and non-technical users through a single adaptive interface with progressive disclosure.

## Design Principles

- **Creation-first**: Home screen prioritizes starting new projects
- **Progressive disclosure**: Simple by default, power features when needed
- **Approval gates**: Users stay in control with explicit review points
- **Visual accessibility**: Technical artifacts include diagrams and summaries
- **Adaptive behavior**: Interface learns from usage

---

## Home Screen & Navigation

### Home Screen Layout
1. **New Project** (prominent) - Quick-start wizard
2. **Action Required** (inbox) - Pending approvals, escalations
3. **Continue Working** - Recent projects with status
4. **All Projects** - Link to full list

### Global Navigation
- Dashboard (home)
- Projects
- Inbox (with badge count)
- SME Knowledge (admin only)
- Settings

### Project Navigation
Phase-based tabs: **Requirements | Architecture | Code | Security Review**
- Current phase highlighted
- Completed phases show checkmarks
- Future phases dimmed

---

## New Project Flow

### Step 1: Minimal Wizard
Two fields only:
- **Project name** - Short identifier
- **Description** - Few sentences about what to build

No category dropdowns or tech preferences. Requirements Agent extracts details.

### Step 2: Guided Onboarding (first-time)
Brief visual tour (3-4 slides, skippable):
1. How AgentForge works
2. You're in control (approval gates)
3. Your experts guide the AI (SME knowledge)
4. Let's start with requirements

---

## Working With Agents

### Conversation Phase
Chat UI with collapsible **Draft Artifacts** panel. Agent incrementally builds outputs visible in real-time.

### Triggering Review
Agent prompts: "Ready to review?" User can also trigger via button.

### Interactive Checklist (Approval Mode)
Each item as a card with:
- Item content (with visuals)
- **Approve** button
- **Reject** button (opens options)
- Status indicator

### Rejection Options
- **"Revise this"** - Agent immediately reworks
- **"Let me explain"** - Inline mini-chat for that item

---

## Inbox & Action Required

### Categories
| Category | Description |
|----------|-------------|
| Pending Approvals | Phase reviews waiting for sign-off |
| Revision Ready | Reworked items ready for re-review |
| Escalations | Constraint violations needing attention |
| Questions | Agent needs clarification |

Each item shows: Project, phase, description, age, one-click action.

### Escalation Handling
Shows: agent output, violated constraint, summary of 3 attempts
Options: **Override & Approve** | **Provide Guidance** | **Edit Directly**

---

## Visual Representations

### Architecture Phase
- System diagram (auto-generated, interactive)
- Data model (ERD)
- User flow diagrams
- Technical details in collapsible accordion

### Code Phase
- File tree (collapsible)
- Component previews (rendered mockups)
- Plain language summary per file
- Diff highlighting for revisions

---

## Adaptive Interface

### Progressive Disclosure
- Default: Plain language, visuals, technical collapsed
- User preference: "Show technical details" toggle
- Contextual: Individual sections expandable

### Smart Defaults
System learns from usage:
- Frequent code expansion → auto-expand future code
- Never expand technical → reduce visual noise

---

## Related ADRs

- [ADR-016: Inbox-Centric Approval Model](../../decisions/ADR-016-inbox-centric-approval.md)
