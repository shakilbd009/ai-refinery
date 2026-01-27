# New Project Flow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the minimal project creation wizard with name and description fields, plus a skippable onboarding tour for first-time users.

**Architecture:** Two-step flow: (1) minimal wizard dialog, (2) onboarding slides (first-time only), then redirect to project workspace.

**Tech Stack:** React 18, Next.js App Router, Tailwind CSS, lucide-react

---

## Task 1: Create Project Wizard Dialog

**Files:**
- Create: `web/src/components/projects/new-project-wizard.tsx`

**Step 1: Create the wizard component**

```typescript
"use client"

import { useState } from "react"
import { Loader2 } from "lucide-react"

import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"

interface NewProjectWizardProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onComplete: (project: { name: string; description: string }) => void
}

export function NewProjectWizard({
  open,
  onOpenChange,
  onComplete,
}: NewProjectWizardProps) {
  const [name, setName] = useState("")
  const [description, setDescription] = useState("")
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [errors, setErrors] = useState<{ name?: string; description?: string }>({})

  const validate = () => {
    const newErrors: { name?: string; description?: string } = {}

    if (!name.trim()) {
      newErrors.name = "Project name is required"
    } else if (name.length < 3) {
      newErrors.name = "Project name must be at least 3 characters"
    }

    if (!description.trim()) {
      newErrors.description = "Description is required"
    } else if (description.length < 10) {
      newErrors.description = "Please provide a bit more detail (at least 10 characters)"
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async () => {
    if (!validate()) return

    setIsSubmitting(true)

    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 500))

    onComplete({ name: name.trim(), description: description.trim() })

    // Reset form
    setName("")
    setDescription("")
    setErrors({})
    setIsSubmitting(false)
  }

  const handleOpenChange = (newOpen: boolean) => {
    if (!newOpen) {
      // Reset form when closing
      setName("")
      setDescription("")
      setErrors({})
    }
    onOpenChange(newOpen)
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>Create New Project</DialogTitle>
          <DialogDescription>
            Tell us what you want to build. Our Requirements Agent will help you
            flesh out the details.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="name">Project Name</Label>
            <Input
              id="name"
              placeholder="e.g., E-commerce Platform"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className={errors.name ? "border-red-500" : ""}
            />
            {errors.name && (
              <p className="text-sm text-red-500">{errors.name}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="description">What do you want to build?</Label>
            <Textarea
              id="description"
              placeholder="Describe your project in a few sentences..."
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={4}
              className={errors.description ? "border-red-500" : ""}
            />
            {errors.description && (
              <p className="text-sm text-red-500">{errors.description}</p>
            )}
            <p className="text-xs text-muted-foreground">
              Don't worry about being comprehensive—the agent will ask follow-up
              questions.
            </p>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => handleOpenChange(false)}>
            Cancel
          </Button>
          <Button onClick={handleSubmit} disabled={isSubmitting}>
            {isSubmitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            Start Project
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
```

**Step 2: Commit**

```bash
git add web/src/components/projects/new-project-wizard.tsx
git commit -m "feat(projects): add NewProjectWizard dialog component"
```

---

## Task 2: Create Onboarding Tour Component

**Files:**
- Create: `web/src/components/onboarding/onboarding-tour.tsx`

**Step 1: Create the onboarding component**

```typescript
"use client"

import { useState } from "react"
import { ArrowRight, Bot, CheckCircle2, Users, X } from "lucide-react"

import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
} from "@/components/ui/dialog"

interface OnboardingTourProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onComplete: () => void
}

const slides = [
  {
    id: 1,
    title: "Here's how AgentForge works",
    description:
      "Your project flows through specialized AI agents, each focusing on a specific phase of development.",
    icon: Bot,
    content: (
      <div className="my-6 flex items-center justify-center gap-4">
        <div className="flex flex-col items-center">
          <div className="flex h-12 w-12 items-center justify-center rounded-full bg-blue-100 dark:bg-blue-900">
            <span className="text-lg font-bold text-blue-600 dark:text-blue-400">1</span>
          </div>
          <span className="mt-2 text-sm">Requirements</span>
        </div>
        <ArrowRight className="h-4 w-4 text-muted-foreground" />
        <div className="flex flex-col items-center">
          <div className="flex h-12 w-12 items-center justify-center rounded-full bg-purple-100 dark:bg-purple-900">
            <span className="text-lg font-bold text-purple-600 dark:text-purple-400">2</span>
          </div>
          <span className="mt-2 text-sm">Architecture</span>
        </div>
        <ArrowRight className="h-4 w-4 text-muted-foreground" />
        <div className="flex flex-col items-center">
          <div className="flex h-12 w-12 items-center justify-center rounded-full bg-emerald-100 dark:bg-emerald-900">
            <span className="text-lg font-bold text-emerald-600 dark:text-emerald-400">3</span>
          </div>
          <span className="mt-2 text-sm">Code</span>
        </div>
      </div>
    ),
  },
  {
    id: 2,
    title: "You're in control",
    description:
      "Before moving to the next phase, you review and approve each artifact. Nothing happens without your sign-off.",
    icon: CheckCircle2,
    content: (
      <div className="my-6 flex flex-col items-center gap-4">
        <div className="flex items-center gap-3 rounded-lg border bg-muted/50 p-4">
          <CheckCircle2 className="h-8 w-8 text-green-500" />
          <div>
            <p className="font-medium">Approval Gates</p>
            <p className="text-sm text-muted-foreground">
              Review requirements, architecture, and code at each step
            </p>
          </div>
        </div>
      </div>
    ),
  },
  {
    id: 3,
    title: "Your experts guide the AI",
    description:
      "SME Knowledge—guidelines, templates, and constraints—ensures the agents follow your organization's standards.",
    icon: Users,
    content: (
      <div className="my-6 flex flex-col items-center gap-2">
        {["Guidelines", "Templates", "Examples", "Constraints"].map((item) => (
          <div
            key={item}
            className="flex w-full max-w-xs items-center gap-2 rounded-lg border bg-muted/30 px-4 py-2"
          >
            <div className="h-2 w-2 rounded-full bg-primary" />
            <span className="text-sm">{item}</span>
          </div>
        ))}
      </div>
    ),
  },
]

export function OnboardingTour({
  open,
  onOpenChange,
  onComplete,
}: OnboardingTourProps) {
  const [currentSlide, setCurrentSlide] = useState(0)

  const handleNext = () => {
    if (currentSlide < slides.length - 1) {
      setCurrentSlide(currentSlide + 1)
    } else {
      onComplete()
    }
  }

  const handleSkip = () => {
    onComplete()
  }

  const slide = slides[currentSlide]
  const Icon = slide.icon

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <button
          onClick={handleSkip}
          className="absolute right-4 top-4 rounded-sm opacity-70 ring-offset-background transition-opacity hover:opacity-100"
        >
          <X className="h-4 w-4" />
          <span className="sr-only">Skip tour</span>
        </button>

        <div className="flex flex-col items-center py-6 text-center">
          <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-primary/10">
            <Icon className="h-8 w-8 text-primary" />
          </div>

          <h2 className="mb-2 text-xl font-semibold">{slide.title}</h2>
          <p className="text-muted-foreground">{slide.description}</p>

          {slide.content}

          {/* Progress dots */}
          <div className="mb-6 flex gap-2">
            {slides.map((_, index) => (
              <div
                key={index}
                className={`h-2 w-2 rounded-full transition-colors ${
                  index === currentSlide ? "bg-primary" : "bg-muted"
                }`}
              />
            ))}
          </div>

          <div className="flex gap-3">
            <Button variant="ghost" onClick={handleSkip}>
              Skip tour
            </Button>
            <Button onClick={handleNext}>
              {currentSlide < slides.length - 1 ? (
                <>
                  Next
                  <ArrowRight className="ml-2 h-4 w-4" />
                </>
              ) : (
                "Let's start!"
              )}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
```

**Step 2: Commit**

```bash
git add web/src/components/onboarding/onboarding-tour.tsx
git commit -m "feat(onboarding): add OnboardingTour dialog component"
```

---

## Task 3: Create Component Barrel Exports

**Files:**
- Create: `web/src/components/projects/index.ts`
- Create: `web/src/components/onboarding/index.ts`

**Step 1: Create projects barrel export**

```typescript
export * from "./new-project-wizard"
```

**Step 2: Create onboarding barrel export**

```typescript
export * from "./onboarding-tour"
```

**Step 3: Commit**

```bash
git add web/src/components/projects/index.ts web/src/components/onboarding/index.ts
git commit -m "feat: add barrel exports for projects and onboarding components"
```

---

## Task 4: Create New Project Page

**Files:**
- Create: `web/src/app/(dashboard)/projects/new/page.tsx`

**Step 1: Create the new project page**

This page handles the full flow: wizard → onboarding (if first time) → redirect to project.

```typescript
"use client"

import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"

import { NewProjectWizard } from "@/components/projects"
import { OnboardingTour } from "@/components/onboarding"

// TODO: Replace with actual user state management
function useIsFirstTimeUser() {
  const [isFirstTime, setIsFirstTime] = useState<boolean | null>(null)

  useEffect(() => {
    // Check localStorage for first-time flag
    const hasSeenOnboarding = localStorage.getItem("agentforge_onboarding_complete")
    setIsFirstTime(!hasSeenOnboarding)
  }, [])

  const markOnboardingComplete = () => {
    localStorage.setItem("agentforge_onboarding_complete", "true")
    setIsFirstTime(false)
  }

  return { isFirstTime, markOnboardingComplete }
}

export default function NewProjectPage() {
  const router = useRouter()
  const { isFirstTime, markOnboardingComplete } = useIsFirstTimeUser()

  const [showWizard, setShowWizard] = useState(true)
  const [showOnboarding, setShowOnboarding] = useState(false)
  const [pendingProject, setPendingProject] = useState<{
    name: string
    description: string
  } | null>(null)

  // Wait for first-time check to complete
  if (isFirstTime === null) {
    return null
  }

  const handleWizardComplete = (project: { name: string; description: string }) => {
    setPendingProject(project)
    setShowWizard(false)

    if (isFirstTime) {
      setShowOnboarding(true)
    } else {
      // Go directly to project
      createProjectAndRedirect(project)
    }
  }

  const handleOnboardingComplete = () => {
    markOnboardingComplete()
    setShowOnboarding(false)

    if (pendingProject) {
      createProjectAndRedirect(pendingProject)
    }
  }

  const handleWizardCancel = () => {
    router.push("/")
  }

  const createProjectAndRedirect = (project: { name: string; description: string }) => {
    // TODO: Create project via API
    // For now, generate a mock ID and redirect
    const mockProjectId = `proj_${Date.now()}`
    console.log("Creating project:", project)
    router.push(`/projects/${mockProjectId}`)
  }

  return (
    <>
      <NewProjectWizard
        open={showWizard}
        onOpenChange={(open) => {
          if (!open) handleWizardCancel()
        }}
        onComplete={handleWizardComplete}
      />

      <OnboardingTour
        open={showOnboarding}
        onOpenChange={setShowOnboarding}
        onComplete={handleOnboardingComplete}
      />
    </>
  )
}
```

**Step 2: Commit**

✅ **COMPLETE** - Committed in `c81be864`

```bash
git add web/src/app/\(dashboard\)/projects/new/page.tsx
git commit -m "feat(projects): add new project page with wizard and onboarding flow"
```

---

## Task 5: Create Project Workspace Page Shell

**Files:**
- Create: `web/src/app/(dashboard)/projects/[id]/page.tsx`

**Step 1: Create the dynamic project page**

This is a shell that will be expanded by the Agent Chat workstream.

```typescript
"use client"

import { useParams } from "next/navigation"
import { Bot, FileText, Code, Shield, Check } from "lucide-react"

import { Header } from "@/components/layout/header"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"

// Mock project data
const mockProject = {
  id: "proj_1",
  name: "E-commerce Platform",
  description: "Full-stack e-commerce solution with inventory management",
  currentPhase: "requirements",
  phases: {
    requirements: { status: "active", progress: 45 },
    architecture: { status: "locked", progress: 0 },
    code: { status: "locked", progress: 0 },
    review: { status: "locked", progress: 0 },
  },
}

const phases = [
  { id: "requirements", label: "Requirements", icon: FileText },
  { id: "architecture", label: "Architecture", icon: Bot },
  { id: "code", label: "Code", icon: Code },
  { id: "review", label: "Security Review", icon: Shield },
]

function getPhaseStatus(phase: { status: string; progress: number }) {
  if (phase.status === "completed") {
    return <Check className="h-4 w-4 text-green-500" />
  }
  if (phase.status === "active") {
    return <Badge variant="default" className="text-xs">Active</Badge>
  }
  return null
}

export default function ProjectPage() {
  const params = useParams()
  const projectId = params.id as string

  // TODO: Fetch project data based on projectId
  const project = mockProject

  return (
    <div className="flex h-full flex-col">
      <Header
        title={project.name}
        description={project.description}
      />

      <div className="flex-1 overflow-hidden">
        <Tabs defaultValue={project.currentPhase} className="flex h-full flex-col">
          {/* Phase tabs */}
          <div className="border-b px-6">
            <TabsList className="h-12 w-full justify-start gap-2 bg-transparent p-0">
              {phases.map((phase) => {
                const phaseData = project.phases[phase.id as keyof typeof project.phases]
                const isDisabled = phaseData.status === "locked"
                const Icon = phase.icon

                return (
                  <TabsTrigger
                    key={phase.id}
                    value={phase.id}
                    disabled={isDisabled}
                    className="flex items-center gap-2 data-[state=active]:border-b-2 data-[state=active]:border-primary rounded-none"
                  >
                    <Icon className="h-4 w-4" />
                    {phase.label}
                    {getPhaseStatus(phaseData)}
                  </TabsTrigger>
                )
              })}
            </TabsList>
          </div>

          {/* Phase content */}
          <div className="flex-1 overflow-auto p-6">
            <TabsContent value="requirements" className="m-0 h-full">
              <Card>
                <CardHeader>
                  <CardTitle>Requirements Phase</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-sm text-muted-foreground">
                    Agent chat interface will be implemented in workstream #6.
                  </p>
                  <p className="mt-4 text-sm">
                    The Requirements Agent has pre-loaded context: "I see you want to build{" "}
                    <strong>{project.name}</strong>: {project.description}. Let me ask a few questions..."
                  </p>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="architecture" className="m-0 h-full">
              <Card>
                <CardHeader>
                  <CardTitle>Architecture Phase</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-muted-foreground">
                    Complete the Requirements phase to unlock Architecture.
                  </p>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="code" className="m-0 h-full">
              <Card>
                <CardHeader>
                  <CardTitle>Code Phase</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-muted-foreground">
                    Complete the Architecture phase to unlock Code.
                  </p>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="review" className="m-0 h-full">
              <Card>
                <CardHeader>
                  <CardTitle>Security Review Phase</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-muted-foreground">
                    Complete the Code phase to unlock Security Review.
                  </p>
                </CardContent>
              </Card>
            </TabsContent>
          </div>
        </Tabs>
      </div>
    </div>
  )
}
```

**Step 2: Commit**

✅ **COMPLETE** - Committed in `0d60d741`

```bash
git add web/src/app/\(dashboard\)/projects/\[id\]/page.tsx
git commit -m "feat(projects): add project workspace page with phase tabs"
```

---

## Task 6: Update Dashboard to Use New Project Flow

**Files:**
- Modify: `web/src/app/(dashboard)/page.tsx`

**Step 1: Read current dashboard**

✅ **COMPLETE** - Dashboard page read. It uses `router.push("/projects/new")` which correctly navigates to the new project flow.

**Step 2: Ensure NewProjectCard navigates to /projects/new**

✅ **COMPLETE** - The dashboard already uses `router.push("/projects/new")` which correctly works with our new page. The `NewProjectCard` component receives `onCreateProject` callback which calls `router.push("/projects/new")`.

**Step 3: Verify flow works end-to-end**

✅ **VERIFIED** - Flow is correctly set up:
1. Click "New Project" on dashboard → navigates to `/projects/new`
2. `/projects/new` page shows wizard dialog automatically
3. User fills in name and description
4. Click "Start Project" → wizard completes
5. (First time) Shows onboarding tour, then redirects to project workspace
6. (Returning user) Directly redirects to project workspace

**Step 4: No commit needed if no changes**

✅ **COMPLETE** - Dashboard already navigates correctly, no changes needed. No commit required.

---

## Completion Checklist

- [x] NewProjectWizard dialog created with validation
- [x] OnboardingTour component created with 3 slides
- [x] Barrel exports created for projects and onboarding
- [x] /projects/new page handles full flow
- [x] Project workspace page shell created with phase tabs
- [x] First-time user detection via localStorage
- [x] Flow works: Dashboard → Wizard → Onboarding → Project
- [x] All changes committed

**Status:** Tasks 1-6 complete. All components implemented and committed. Dashboard integration verified.
