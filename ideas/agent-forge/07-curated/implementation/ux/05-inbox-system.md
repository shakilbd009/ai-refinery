# Inbox System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the Inbox page aggregating all action items: pending approvals, revision-ready items, escalations, and agent questions.

**Architecture:** Dedicated inbox page with categorized action items, filtering, and one-click actions. Connects to project workspace for inline handling.

**Tech Stack:** React 18, Next.js App Router, Tailwind CSS, lucide-react

---

## Task 1: Create Inbox Item Types

**Files:**
- Create: `web/src/types/inbox.ts`

**Step 1: Define inbox item types**

```typescript
export type InboxItemType = "approval" | "revision" | "escalation" | "question"

export type InboxItemStatus = "pending" | "in_progress" | "resolved"

export interface InboxItem {
  id: string
  type: InboxItemType
  status: InboxItemStatus
  projectId: string
  projectName: string
  phase: "requirements" | "architecture" | "code" | "review"
  title: string
  description: string
  createdAt: string
  age: string
  // For escalations
  constraint?: string
  attempts?: number
  agentOutput?: string
}

export interface InboxCategory {
  type: InboxItemType
  label: string
  description: string
  count: number
}
```

**Step 2: Commit**

```bash
git add web/src/types/inbox.ts
git commit -m "feat(inbox): add inbox item type definitions"
```

---

## Task 2: Create Types Barrel Export

**Files:**
- Create: `web/src/types/index.ts`

**Step 1: Create types index**

```typescript
export * from "./inbox"
```

**Step 2: Commit**

```bash
git add web/src/types/index.ts
git commit -m "feat(types): add types barrel export"
```

---

## Task 3: Create Inbox Item Card Component

**Files:**
- Create: `web/src/components/inbox/inbox-item-card.tsx`

**Step 1: Create the component**

```typescript
"use client"

import Link from "next/link"
import {
  AlertCircle,
  CheckCircle2,
  Clock,
  MessageSquare,
  ChevronRight,
  ExternalLink,
} from "lucide-react"

import { cn } from "@/lib/utils"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import type { InboxItem, InboxItemType } from "@/types/inbox"

interface InboxItemCardProps {
  item: InboxItem
  onAction?: (item: InboxItem, action: string) => void
}

function getTypeIcon(type: InboxItemType) {
  switch (type) {
    case "approval":
      return <CheckCircle2 className="h-5 w-5 text-blue-500" />
    case "revision":
      return <Clock className="h-5 w-5 text-amber-500" />
    case "escalation":
      return <AlertCircle className="h-5 w-5 text-red-500" />
    case "question":
      return <MessageSquare className="h-5 w-5 text-purple-500" />
  }
}

function getTypeLabel(type: InboxItemType) {
  switch (type) {
    case "approval":
      return "Pending Approval"
    case "revision":
      return "Revision Ready"
    case "escalation":
      return "Escalation"
    case "question":
      return "Question"
  }
}

function getTypeBadgeVariant(type: InboxItemType) {
  switch (type) {
    case "approval":
      return "info"
    case "revision":
      return "warning"
    case "escalation":
      return "destructive"
    case "question":
      return "secondary"
  }
}

function getPhaseColor(phase: InboxItem["phase"]) {
  switch (phase) {
    case "requirements":
      return "bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300"
    case "architecture":
      return "bg-purple-100 text-purple-700 dark:bg-purple-900 dark:text-purple-300"
    case "code":
      return "bg-emerald-100 text-emerald-700 dark:bg-emerald-900 dark:text-emerald-300"
    case "review":
      return "bg-amber-100 text-amber-700 dark:bg-amber-900 dark:text-amber-300"
  }
}

export function InboxItemCard({ item, onAction }: InboxItemCardProps) {
  const handlePrimaryAction = () => {
    onAction?.(item, "primary")
  }

  return (
    <Card className="transition-colors hover:bg-muted/30">
      <CardContent className="p-4">
        <div className="flex items-start gap-4">
          {/* Icon */}
          <div className="shrink-0 pt-0.5">{getTypeIcon(item.type)}</div>

          {/* Content */}
          <div className="min-w-0 flex-1">
            <div className="mb-1 flex items-center gap-2">
              <Link
                href={`/projects/${item.projectId}`}
                className="font-medium hover:underline"
              >
                {item.projectName}
              </Link>
              <Badge className={cn("text-xs", getPhaseColor(item.phase))}>
                {item.phase.charAt(0).toUpperCase() + item.phase.slice(1)}
              </Badge>
              <Badge variant={getTypeBadgeVariant(item.type) as any} className="text-xs">
                {getTypeLabel(item.type)}
              </Badge>
            </div>

            <h3 className="mb-1 font-medium">{item.title}</h3>
            <p className="text-sm text-muted-foreground line-clamp-2">
              {item.description}
            </p>

            {/* Escalation details */}
            {item.type === "escalation" && item.constraint && (
              <div className="mt-3 rounded-lg border border-red-200 bg-red-50 p-3 dark:border-red-900 dark:bg-red-950">
                <p className="text-sm font-medium text-red-700 dark:text-red-400">
                  Violated Constraint: {item.constraint}
                </p>
                {item.attempts && (
                  <p className="text-xs text-red-600 dark:text-red-500">
                    Agent attempted {item.attempts} times to resolve
                  </p>
                )}
              </div>
            )}
          </div>

          {/* Actions */}
          <div className="flex shrink-0 flex-col items-end gap-2">
            <span className="text-xs text-muted-foreground">{item.age}</span>

            {item.type === "approval" && (
              <Button size="sm" onClick={handlePrimaryAction}>
                Review
                <ChevronRight className="ml-1 h-4 w-4" />
              </Button>
            )}

            {item.type === "revision" && (
              <Button size="sm" variant="outline" onClick={handlePrimaryAction}>
                Re-review
                <ChevronRight className="ml-1 h-4 w-4" />
              </Button>
            )}

            {item.type === "escalation" && (
              <Button size="sm" variant="destructive" onClick={handlePrimaryAction}>
                Resolve
                <ChevronRight className="ml-1 h-4 w-4" />
              </Button>
            )}

            {item.type === "question" && (
              <Button size="sm" variant="secondary" onClick={handlePrimaryAction}>
                Answer
                <MessageSquare className="ml-1 h-4 w-4" />
              </Button>
            )}

            <Link
              href={`/projects/${item.projectId}`}
              className="flex items-center text-xs text-muted-foreground hover:text-foreground"
            >
              Open project
              <ExternalLink className="ml-1 h-3 w-3" />
            </Link>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
```

**Step 2: Commit**

```bash
git add web/src/components/inbox/inbox-item-card.tsx
git commit -m "feat(inbox): add InboxItemCard component"
```

---

## Task 4: Create Escalation Dialog Component

**Files:**
- Create: `web/src/components/inbox/escalation-dialog.tsx`

**Step 1: Create the component**

```typescript
"use client"

import { useState } from "react"
import { AlertTriangle, Check, MessageSquare, Pencil } from "lucide-react"

import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Textarea } from "@/components/ui/textarea"
import { Badge } from "@/components/ui/badge"
import type { InboxItem } from "@/types/inbox"

interface EscalationDialogProps {
  item: InboxItem | null
  open: boolean
  onOpenChange: (open: boolean) => void
  onResolve: (item: InboxItem, resolution: "override" | "guidance" | "edit", guidance?: string) => void
}

export function EscalationDialog({
  item,
  open,
  onOpenChange,
  onResolve,
}: EscalationDialogProps) {
  const [showGuidanceInput, setShowGuidanceInput] = useState(false)
  const [guidance, setGuidance] = useState("")

  if (!item) return null

  const handleOverride = () => {
    onResolve(item, "override")
    onOpenChange(false)
  }

  const handleProvideGuidance = () => {
    if (showGuidanceInput) {
      onResolve(item, "guidance", guidance)
      setGuidance("")
      setShowGuidanceInput(false)
      onOpenChange(false)
    } else {
      setShowGuidanceInput(true)
    }
  }

  const handleEditDirectly = () => {
    onResolve(item, "edit")
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[600px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5 text-red-500" />
            Escalation: {item.title}
          </DialogTitle>
          <DialogDescription>
            The agent couldn't resolve this constraint violation after {item.attempts} attempts.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-4">
          {/* Agent output */}
          <div>
            <h4 className="mb-2 text-sm font-medium">Agent Output</h4>
            <div className="rounded-lg border bg-muted/50 p-3">
              <p className="text-sm">{item.agentOutput || item.description}</p>
            </div>
          </div>

          {/* Violated constraint */}
          <div>
            <h4 className="mb-2 text-sm font-medium">Violated Constraint</h4>
            <div className="rounded-lg border border-red-200 bg-red-50 p-3 dark:border-red-900 dark:bg-red-950">
              <p className="text-sm text-red-700 dark:text-red-400">
                {item.constraint}
              </p>
            </div>
          </div>

          {/* Attempt summary */}
          <div>
            <h4 className="mb-2 text-sm font-medium">Resolution Attempts</h4>
            <p className="text-sm text-muted-foreground">
              The agent tried {item.attempts} different approaches but couldn't satisfy the constraint.
            </p>
          </div>

          {/* Guidance input */}
          {showGuidanceInput && (
            <div>
              <h4 className="mb-2 text-sm font-medium">Your Guidance</h4>
              <Textarea
                placeholder="Provide specific guidance for the agent..."
                value={guidance}
                onChange={(e) => setGuidance(e.target.value)}
                rows={3}
              />
            </div>
          )}
        </div>

        <DialogFooter className="flex-col gap-2 sm:flex-row">
          <Button variant="outline" onClick={handleOverride}>
            <Check className="mr-2 h-4 w-4" />
            Override & Approve
          </Button>
          <Button variant="outline" onClick={handleProvideGuidance}>
            <MessageSquare className="mr-2 h-4 w-4" />
            {showGuidanceInput ? "Send Guidance" : "Provide Guidance"}
          </Button>
          <Button onClick={handleEditDirectly}>
            <Pencil className="mr-2 h-4 w-4" />
            Edit Directly
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
```

**Step 2: Commit**

```bash
git add web/src/components/inbox/escalation-dialog.tsx
git commit -m "feat(inbox): add EscalationDialog component"
```

---

## Task 5: Create Inbox Components Barrel Export

**Files:**
- Create: `web/src/components/inbox/index.ts`

**Step 1: Create barrel export**

```typescript
export * from "./inbox-item-card"
export * from "./escalation-dialog"
```

**Step 2: Commit**

```bash
git add web/src/components/inbox/index.ts
git commit -m "feat(inbox): add barrel export for inbox components"
```

---

## Task 6: Implement Full Inbox Page

**Files:**
- Modify: `web/src/app/(dashboard)/inbox/page.tsx`

**Step 1: Read current inbox page**

Read the placeholder to understand current state.

**Step 2: Replace with full implementation**

```typescript
"use client"

import { useState } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import {
  AlertCircle,
  CheckCircle2,
  Clock,
  MessageSquare,
  Filter,
  Inbox as InboxIcon,
} from "lucide-react"

import { Header } from "@/components/layout/header"
import { InboxItemCard, EscalationDialog } from "@/components/inbox"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent } from "@/components/ui/card"
import type { InboxItem, InboxItemType } from "@/types/inbox"

// Mock inbox items
const mockInboxItems: InboxItem[] = [
  {
    id: "1",
    type: "approval",
    status: "pending",
    projectId: "proj_1",
    projectName: "E-commerce Platform",
    phase: "architecture",
    title: "System Architecture Review",
    description: "Review the proposed system architecture including microservices design, database schema, and API contracts.",
    createdAt: "2026-01-18T10:00:00Z",
    age: "2 hours ago",
  },
  {
    id: "2",
    type: "escalation",
    status: "pending",
    projectId: "proj_2",
    projectName: "Mobile App Backend",
    phase: "code",
    title: "Security Constraint Violation",
    description: "Generated code stores user passwords in plain text, violating security requirements.",
    createdAt: "2026-01-18T08:00:00Z",
    age: "4 hours ago",
    constraint: "All user passwords must be hashed using bcrypt with a minimum cost factor of 12",
    attempts: 3,
    agentOutput: "const user = { email, password }; // Store directly",
  },
  {
    id: "3",
    type: "revision",
    status: "pending",
    projectId: "proj_1",
    projectName: "E-commerce Platform",
    phase: "requirements",
    title: "Updated User Stories",
    description: "Revised user stories based on your feedback about checkout flow.",
    createdAt: "2026-01-18T06:00:00Z",
    age: "6 hours ago",
  },
  {
    id: "4",
    type: "question",
    status: "pending",
    projectId: "proj_3",
    projectName: "Analytics Dashboard",
    phase: "requirements",
    title: "Data Source Clarification",
    description: "Should the dashboard pull data from the existing PostgreSQL database or do you need a new data warehouse?",
    createdAt: "2026-01-17T14:00:00Z",
    age: "1 day ago",
  },
  {
    id: "5",
    type: "approval",
    status: "pending",
    projectId: "proj_3",
    projectName: "Analytics Dashboard",
    phase: "requirements",
    title: "Requirements Document Review",
    description: "Review and approve the gathered requirements including 12 user stories and 5 technical constraints.",
    createdAt: "2026-01-17T10:00:00Z",
    age: "1 day ago",
  },
]

const categories: { type: InboxItemType | "all"; label: string; icon: React.ComponentType<{ className?: string }> }[] = [
  { type: "all", label: "All", icon: InboxIcon },
  { type: "approval", label: "Pending Approvals", icon: CheckCircle2 },
  { type: "revision", label: "Revision Ready", icon: Clock },
  { type: "escalation", label: "Escalations", icon: AlertCircle },
  { type: "question", label: "Questions", icon: MessageSquare },
]

function EmptyInbox() {
  return (
    <Card>
      <CardContent className="flex flex-col items-center justify-center py-12 text-center">
        <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-green-100 dark:bg-green-900">
          <CheckCircle2 className="h-8 w-8 text-green-600 dark:text-green-400" />
        </div>
        <h3 className="mb-2 text-lg font-medium">You're all caught up!</h3>
        <p className="text-sm text-muted-foreground">
          No pending actions at the moment. Great job staying on top of things!
        </p>
      </CardContent>
    </Card>
  )
}

export default function InboxPage() {
  const router = useRouter()
  const searchParams = useSearchParams()

  const [items, setItems] = useState(mockInboxItems)
  const [selectedEscalation, setSelectedEscalation] = useState<InboxItem | null>(null)
  const [escalationDialogOpen, setEscalationDialogOpen] = useState(false)

  // Get active tab from URL or default to "all"
  const activeTab = searchParams.get("filter") || "all"

  const handleTabChange = (value: string) => {
    const params = new URLSearchParams(searchParams)
    if (value === "all") {
      params.delete("filter")
    } else {
      params.set("filter", value)
    }
    router.push(`/inbox?${params.toString()}`)
  }

  const handleItemAction = (item: InboxItem, action: string) => {
    if (item.type === "escalation") {
      setSelectedEscalation(item)
      setEscalationDialogOpen(true)
    } else {
      // Navigate to project with context
      router.push(`/projects/${item.projectId}?action=${item.id}`)
    }
  }

  const handleEscalationResolve = (
    item: InboxItem,
    resolution: "override" | "guidance" | "edit",
    guidance?: string
  ) => {
    console.log("Resolving escalation:", { item, resolution, guidance })
    // TODO: API call to resolve escalation
    // For now, remove from list
    setItems(items.filter((i) => i.id !== item.id))
  }

  const filteredItems =
    activeTab === "all"
      ? items
      : items.filter((item) => item.type === activeTab)

  const getCategoryCount = (type: InboxItemType | "all") => {
    if (type === "all") return items.length
    return items.filter((item) => item.type === type).length
  }

  return (
    <div className="flex flex-col">
      <Header
        title="Inbox"
        description="Action items requiring your attention"
      />

      <div className="flex-1 p-6">
        <Tabs value={activeTab} onValueChange={handleTabChange}>
          <TabsList className="mb-6">
            {categories.map((category) => {
              const count = getCategoryCount(category.type)
              const Icon = category.icon
              return (
                <TabsTrigger
                  key={category.type}
                  value={category.type}
                  className="flex items-center gap-2"
                >
                  <Icon className="h-4 w-4" />
                  {category.label}
                  {count > 0 && (
                    <Badge
                      variant={category.type === "escalation" ? "destructive" : "secondary"}
                      className="ml-1 h-5 min-w-[20px] px-1.5"
                    >
                      {count}
                    </Badge>
                  )}
                </TabsTrigger>
              )
            })}
          </TabsList>

          {categories.map((category) => (
            <TabsContent key={category.type} value={category.type} className="m-0">
              {filteredItems.length === 0 ? (
                <EmptyInbox />
              ) : (
                <div className="space-y-3">
                  {filteredItems.map((item) => (
                    <InboxItemCard
                      key={item.id}
                      item={item}
                      onAction={handleItemAction}
                    />
                  ))}
                </div>
              )}
            </TabsContent>
          ))}
        </Tabs>
      </div>

      <EscalationDialog
        item={selectedEscalation}
        open={escalationDialogOpen}
        onOpenChange={setEscalationDialogOpen}
        onResolve={handleEscalationResolve}
      />
    </div>
  )
}
```

**Step 3: Verify inbox page renders**

Run `npm run dev` and navigate to `/inbox`. Verify:
- All tabs work
- Items display correctly
- Escalation dialog opens
- Empty state shows when filtering to empty category

**Step 4: Commit**

```bash
git add web/src/app/\(dashboard\)/inbox/page.tsx
git commit -m "feat(inbox): implement full inbox page with filtering and escalation handling"
```

---

## Completion Checklist

- [ ] Inbox type definitions created
- [ ] Types barrel export created
- [ ] InboxItemCard component created
- [ ] EscalationDialog component created
- [ ] Inbox components barrel export created
- [ ] Full inbox page implemented with tabs
- [ ] Escalation dialog working
- [ ] Empty state showing correctly
- [ ] All changes committed
