# Home Screen Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Redesign the dashboard home screen to be creation-first with "New Project", "Action Required", "Continue Working", and "All Projects" sections.

**Architecture:** Replace current stats-focused dashboard with user-action-focused layout. Primary CTA is creating new projects.

**Tech Stack:** React 18, Next.js App Router, Tailwind CSS, lucide-react

---

## Task 1: Create New Project Card Component

**Files:**
- Create: `web/src/components/dashboard/new-project-card.tsx`

**Step 1: Create the component**

```typescript
"use client"

import { Plus, Sparkles } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"

interface NewProjectCardProps {
  onCreateProject: () => void
}

export function NewProjectCard({ onCreateProject }: NewProjectCardProps) {
  return (
    <Card className="border-2 border-dashed border-primary/50 bg-primary/5 transition-colors hover:border-primary hover:bg-primary/10">
      <CardContent className="flex flex-col items-center justify-center p-8 text-center">
        <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-primary/10">
          <Sparkles className="h-8 w-8 text-primary" />
        </div>
        <h2 className="mb-2 text-xl font-semibold">What do you want to build?</h2>
        <p className="mb-6 max-w-md text-sm text-muted-foreground">
          Start a new project and let our AI agents help you from requirements to code.
        </p>
        <Button size="lg" onClick={onCreateProject}>
          <Plus className="mr-2 h-5 w-5" />
          New Project
        </Button>
      </CardContent>
    </Card>
  )
}
```

**Step 2: Commit**

```bash
git add web/src/components/dashboard/new-project-card.tsx
git commit -m "feat(dashboard): add NewProjectCard component"
```

---

## Task 2: Create Action Required Card Component

**Files:**
- Create: `web/src/components/dashboard/action-required-card.tsx`

**Step 1: Create the component**

```typescript
"use client"

import Link from "next/link"
import { AlertCircle, CheckCircle2, MessageSquare, Clock, ChevronRight } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"

type ActionType = "approval" | "revision" | "escalation" | "question"

interface ActionItem {
  id: string
  type: ActionType
  projectName: string
  phase: string
  description: string
  age: string
}

interface ActionRequiredCardProps {
  items: ActionItem[]
}

function getActionIcon(type: ActionType) {
  switch (type) {
    case "approval":
      return <CheckCircle2 className="h-4 w-4 text-blue-500" />
    case "revision":
      return <Clock className="h-4 w-4 text-amber-500" />
    case "escalation":
      return <AlertCircle className="h-4 w-4 text-red-500" />
    case "question":
      return <MessageSquare className="h-4 w-4 text-purple-500" />
  }
}

function getActionLabel(type: ActionType) {
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

export function ActionRequiredCard({ items }: ActionRequiredCardProps) {
  if (items.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Action Required</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-6 text-center">
            <CheckCircle2 className="mb-2 h-8 w-8 text-green-500" />
            <p className="font-medium">You're all caught up!</p>
            <p className="text-sm text-muted-foreground">
              No pending actions at the moment.
            </p>
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="flex items-center gap-2 text-base">
          Action Required
          <Badge variant="destructive">{items.length}</Badge>
        </CardTitle>
        <Link href="/inbox">
          <Button variant="ghost" size="sm">
            View all
            <ChevronRight className="ml-1 h-4 w-4" />
          </Button>
        </Link>
      </CardHeader>
      <CardContent className="space-y-3">
        {items.slice(0, 3).map((item) => (
          <Link
            key={item.id}
            href={`/inbox?action=${item.id}`}
            className="block rounded-lg border p-3 transition-colors hover:bg-muted/50"
          >
            <div className="flex items-start justify-between gap-2">
              <div className="flex items-start gap-3">
                {getActionIcon(item.type)}
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-medium">{item.projectName}</span>
                    <Badge variant="outline" className="text-xs">
                      {item.phase}
                    </Badge>
                  </div>
                  <p className="text-sm text-muted-foreground">
                    {item.description}
                  </p>
                </div>
              </div>
              <span className="shrink-0 text-xs text-muted-foreground">
                {item.age}
              </span>
            </div>
          </Link>
        ))}
      </CardContent>
    </Card>
  )
}
```

**Step 2: Commit**

```bash
git add web/src/components/dashboard/action-required-card.tsx
git commit -m "feat(dashboard): add ActionRequiredCard component"
```

---

## Task 3: Create Continue Working Card Component

**Files:**
- Create: `web/src/components/dashboard/continue-working-card.tsx`

**Step 1: Create the component**

```typescript
"use client"

import Link from "next/link"
import { ChevronRight, Clock } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Progress } from "@/components/ui/progress"

interface RecentProject {
  id: string
  name: string
  description: string
  phase: "requirements" | "architecture" | "development" | "review"
  progress: number
  lastActivity: string
}

interface ContinueWorkingCardProps {
  projects: RecentProject[]
}

function getPhaseLabel(phase: RecentProject["phase"]) {
  switch (phase) {
    case "requirements":
      return "Requirements"
    case "architecture":
      return "Architecture"
    case "development":
      return "Development"
    case "review":
      return "Review"
  }
}

function getPhaseColor(phase: RecentProject["phase"]) {
  switch (phase) {
    case "requirements":
      return "bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300"
    case "architecture":
      return "bg-purple-100 text-purple-700 dark:bg-purple-900 dark:text-purple-300"
    case "development":
      return "bg-emerald-100 text-emerald-700 dark:bg-emerald-900 dark:text-emerald-300"
    case "review":
      return "bg-amber-100 text-amber-700 dark:bg-amber-900 dark:text-amber-300"
  }
}

export function ContinueWorkingCard({ projects }: ContinueWorkingCardProps) {
  if (projects.length === 0) {
    return null
  }

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="text-base">Continue Working</CardTitle>
        <Link href="/projects">
          <Button variant="ghost" size="sm">
            All projects
            <ChevronRight className="ml-1 h-4 w-4" />
          </Button>
        </Link>
      </CardHeader>
      <CardContent className="space-y-4">
        {projects.map((project) => (
          <Link
            key={project.id}
            href={`/projects/${project.id}`}
            className="block rounded-lg border p-4 transition-colors hover:bg-muted/50"
          >
            <div className="mb-2 flex items-start justify-between">
              <div>
                <h3 className="font-medium">{project.name}</h3>
                <p className="text-sm text-muted-foreground line-clamp-1">
                  {project.description}
                </p>
              </div>
              <Badge className={getPhaseColor(project.phase)}>
                {getPhaseLabel(project.phase)}
              </Badge>
            </div>
            <div className="flex items-center gap-4">
              <div className="flex-1">
                <Progress value={project.progress} className="h-2" />
              </div>
              <div className="flex items-center gap-1 text-xs text-muted-foreground">
                <Clock className="h-3 w-3" />
                {project.lastActivity}
              </div>
            </div>
          </Link>
        ))}
      </CardContent>
    </Card>
  )
}
```

**Step 2: Commit**

```bash
git add web/src/components/dashboard/continue-working-card.tsx
git commit -m "feat(dashboard): add ContinueWorkingCard component"
```

---

## Task 4: Create Dashboard Components Index

**Files:**
- Create: `web/src/components/dashboard/index.ts`

**Step 1: Create barrel export**

```typescript
export * from "./new-project-card"
export * from "./action-required-card"
export * from "./continue-working-card"
```

**Step 2: Commit**

```bash
git add web/src/components/dashboard/index.ts
git commit -m "feat(dashboard): add barrel export for dashboard components"
```

---

## Task 5: Update Dashboard Home Page

**Files:**
- Modify: `web/src/app/(dashboard)/page.tsx`

**Step 1: Read current dashboard page**

Read `web/src/app/(dashboard)/page.tsx` to understand current structure.

**Step 2: Replace with new creation-first layout**

```typescript
"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"

import { Header } from "@/components/layout/header"
import {
  NewProjectCard,
  ActionRequiredCard,
  ContinueWorkingCard,
} from "@/components/dashboard"

// Mock data for action items
const mockActionItems = [
  {
    id: "1",
    type: "approval" as const,
    projectName: "E-commerce Platform",
    phase: "Architecture",
    description: "Review system architecture diagram",
    age: "2h ago",
  },
  {
    id: "2",
    type: "escalation" as const,
    projectName: "Mobile App",
    phase: "Development",
    description: "Security constraint violation needs resolution",
    age: "5h ago",
  },
  {
    id: "3",
    type: "question" as const,
    projectName: "Analytics Dashboard",
    phase: "Requirements",
    description: "Agent needs clarification on data sources",
    age: "1d ago",
  },
]

// Mock data for recent projects
const mockRecentProjects = [
  {
    id: "1",
    name: "E-commerce Platform",
    description: "Full-stack e-commerce solution with inventory management",
    phase: "architecture" as const,
    progress: 35,
    lastActivity: "2 hours ago",
  },
  {
    id: "2",
    name: "Mobile App Backend",
    description: "REST API for mobile application",
    phase: "development" as const,
    progress: 60,
    lastActivity: "Yesterday",
  },
  {
    id: "3",
    name: "Analytics Dashboard",
    description: "Real-time analytics visualization",
    phase: "requirements" as const,
    progress: 15,
    lastActivity: "3 days ago",
  },
]

export default function DashboardPage() {
  const router = useRouter()

  const handleCreateProject = () => {
    router.push("/projects/new")
  }

  return (
    <div className="flex flex-col">
      <Header
        title="Dashboard"
        description="Welcome back! What would you like to work on?"
      />
      <div className="flex-1 space-y-6 p-6">
        {/* Primary CTA: New Project */}
        <NewProjectCard onCreateProject={handleCreateProject} />

        {/* Two-column layout for action items and recent projects */}
        <div className="grid gap-6 lg:grid-cols-2">
          {/* Action Required */}
          <ActionRequiredCard items={mockActionItems} />

          {/* Continue Working */}
          <ContinueWorkingCard projects={mockRecentProjects} />
        </div>
      </div>
    </div>
  )
}
```

**Step 3: Verify dashboard renders**

Run `npm run dev` and verify new dashboard layout shows correctly.

**Step 4: Commit**

```bash
git add web/src/app/\(dashboard\)/page.tsx
git commit -m "feat(dashboard): redesign home screen with creation-first layout"
```

---

## Task 6: Handle First-Time User Empty State

**Files:**
- Modify: `web/src/app/(dashboard)/page.tsx`

**Step 1: Add first-time user detection and empty state**

Update the page to handle when there are no projects:

```typescript
"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Rocket } from "lucide-react"

import { Header } from "@/components/layout/header"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import {
  NewProjectCard,
  ActionRequiredCard,
  ContinueWorkingCard,
} from "@/components/dashboard"

// Mock data - set to empty arrays to test first-time user experience
const mockActionItems = [
  {
    id: "1",
    type: "approval" as const,
    projectName: "E-commerce Platform",
    phase: "Architecture",
    description: "Review system architecture diagram",
    age: "2h ago",
  },
  {
    id: "2",
    type: "escalation" as const,
    projectName: "Mobile App",
    phase: "Development",
    description: "Security constraint violation needs resolution",
    age: "5h ago",
  },
  {
    id: "3",
    type: "question" as const,
    projectName: "Analytics Dashboard",
    phase: "Requirements",
    description: "Agent needs clarification on data sources",
    age: "1d ago",
  },
]

const mockRecentProjects = [
  {
    id: "1",
    name: "E-commerce Platform",
    description: "Full-stack e-commerce solution with inventory management",
    phase: "architecture" as const,
    progress: 35,
    lastActivity: "2 hours ago",
  },
  {
    id: "2",
    name: "Mobile App Backend",
    description: "REST API for mobile application",
    phase: "development" as const,
    progress: 60,
    lastActivity: "Yesterday",
  },
  {
    id: "3",
    name: "Analytics Dashboard",
    description: "Real-time analytics visualization",
    phase: "requirements" as const,
    progress: 15,
    lastActivity: "3 days ago",
  },
]

function FirstTimeUserView({ onCreateProject }: { onCreateProject: () => void }) {
  return (
    <div className="flex flex-1 items-center justify-center p-6">
      <Card className="max-w-lg border-2 border-dashed">
        <CardContent className="flex flex-col items-center p-8 text-center">
          <div className="mb-4 flex h-20 w-20 items-center justify-center rounded-full bg-primary/10">
            <Rocket className="h-10 w-10 text-primary" />
          </div>
          <h2 className="mb-2 text-2xl font-semibold">Welcome to AgentForge!</h2>
          <p className="mb-6 text-muted-foreground">
            Build software faster with AI agents that understand your requirements
            and generate production-ready code.
          </p>
          <Button size="lg" onClick={onCreateProject}>
            Create Your First Project
          </Button>
          <p className="mt-4 text-sm text-muted-foreground">
            Or explore a{" "}
            <button className="text-primary underline-offset-4 hover:underline">
              sample project
            </button>{" "}
            to see how it works.
          </p>
        </CardContent>
      </Card>
    </div>
  )
}

export default function DashboardPage() {
  const router = useRouter()

  // TODO: Replace with actual user data check
  const isFirstTimeUser = false
  const hasProjects = mockRecentProjects.length > 0

  const handleCreateProject = () => {
    router.push("/projects/new")
  }

  if (isFirstTimeUser || !hasProjects) {
    return (
      <div className="flex h-full flex-col">
        <Header
          title="Dashboard"
          description="Welcome to AgentForge"
        />
        <FirstTimeUserView onCreateProject={handleCreateProject} />
      </div>
    )
  }

  return (
    <div className="flex flex-col">
      <Header
        title="Dashboard"
        description="Welcome back! What would you like to work on?"
      />
      <div className="flex-1 space-y-6 p-6">
        {/* Primary CTA: New Project */}
        <NewProjectCard onCreateProject={handleCreateProject} />

        {/* Two-column layout for action items and recent projects */}
        <div className="grid gap-6 lg:grid-cols-2">
          {/* Action Required */}
          <ActionRequiredCard items={mockActionItems} />

          {/* Continue Working */}
          <ContinueWorkingCard projects={mockRecentProjects} />
        </div>
      </div>
    </div>
  )
}
```

**Step 2: Test both states**

- Set `isFirstTimeUser = true` to verify first-time view
- Set back to `false` to verify regular dashboard

**Step 3: Commit**

```bash
git add web/src/app/\(dashboard\)/page.tsx
git commit -m "feat(dashboard): add first-time user empty state"
```

---

## Completion Checklist

- [ ] NewProjectCard component created
- [ ] ActionRequiredCard component created
- [ ] ContinueWorkingCard component created
- [ ] Dashboard components barrel export created
- [ ] Dashboard page updated with creation-first layout
- [ ] First-time user empty state implemented
- [ ] All components render correctly
- [ ] All changes committed
