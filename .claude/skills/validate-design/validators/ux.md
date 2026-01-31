---
name: validate-ux
description: Use when reviewing designs for UX gaps, user flow issues, error state handling, accessibility concerns, or loading states. Triggers on UX review, usability audit, accessibility check.
---

# Validate UX

Reviews curated design artifacts for user experience concerns.

## Usage

```bash
/validate-ux <idea-name>
```

## Prerequisites

Curated folder must exist: `ideas/<name>/07-curated/`

If not curated, abort with: "Run /curating-artifacts first"

## Focus Areas

- **User Flows** - Complete happy paths, flow continuity, navigation clarity
- **Error States** - Error messaging, recovery paths, graceful degradation
- **Accessibility** - Screen reader support, keyboard navigation, color contrast
- **Loading States** - Skeleton screens, progress indicators, perceived performance
- **Edge Case UX** - Empty states, first-time experience, error boundaries
- **Mobile/Responsive** - Touch targets, viewport considerations, offline handling

## Artifacts to Examine

Primary:
- `07-curated/requirements.md` - User stories, acceptance criteria
- `07-curated/edge-cases/` - Error and edge case handling

Secondary:
- Component docs with UI aspects
- `07-curated/architecture/components/` - UI components

## Execution

Use a `general-purpose` agent via Task tool (focused on UX review):

```
Task (general-purpose):
  Prompt: Review ideas/<name>/07-curated/ for UX quality as a UX specialist.

  Focus on:
  - User flow completeness and clarity
  - Error state handling and messaging
  - Accessibility considerations
  - Loading state design
  - Edge case user experience
  - Mobile and responsive design

  Examine these files:
  - 07-curated/requirements.md
  - 07-curated/edge-cases/*
  - 07-curated/architecture/components/* (UI-related)

  Output findings to: ideas/<name>/08-validated/ux-findings.md

  Use format from: [_output-format.md](_output-format.md)
```

## Output

Creates: `ideas/<name>/08-validated/ux-findings.md`

## Severity Guide

| Severity | Examples |
|----------|----------|
| Critical | User cannot complete core task, data loss without warning, inaccessible critical feature |
| High | Confusing error message, dead-end flow, missing confirmation for destructive action |
| Medium | No loading indicator, unclear empty state, minor accessibility gap |
| Low | Polish opportunity, nice-to-have animation, minor copy improvement |
