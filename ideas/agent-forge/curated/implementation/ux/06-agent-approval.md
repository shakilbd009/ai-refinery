# Agent Chat & Approval System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enhance the agent chat interface with a collapsible draft artifacts panel, "Ready to Review" functionality, and interactive checklist approval mode with rejection handling.

**Architecture:** Split-pane layout with chat on left and draft artifacts on right. Approval mode replaces main content with full-screen checklist. Rejection handling with inline mini-chat per item.

**Tech Stack:** React 18, Next.js App Router, Tailwind CSS, lucide-react

---

## Task 1: Create Chat Message Component

**Files:**
- Create: `web/src/components/chat/chat-message.tsx`

**Step 1: Create the component**

```typescript
"use client"

import { Bot, User } from "lucide-react"

import { cn } from "@/lib/utils"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"

export type MessageRole = "user" | "agent"

export interface ChatMessageProps {
  role: MessageRole
  content: string
  timestamp?: string
  agentName?: string
}

export function ChatMessage({
  role,
  content,
  timestamp,
  agentName = "Agent",
}: ChatMessageProps) {
  const isAgent = role === "agent"

  return (
    <div
      className={cn(
        "flex gap-3",
        isAgent ? "flex-row" : "flex-row-reverse"
      )}
    >
      <Avatar className="h-8 w-8 shrink-0">
        <AvatarFallback
          className={cn(
            isAgent
              ? "bg-primary text-primary-foreground"
              : "bg-muted text-muted-foreground"
          )}
        >
          {isAgent ? <Bot className="h-4 w-4" /> : <User className="h-4 w-4" />}
        </AvatarFallback>
      </Avatar>

      <div
        className={cn(
          "flex max-w-[80%] flex-col gap-1",
          isAgent ? "items-start" : "items-end"
        )}
      >
        <div className="flex items-center gap-2 text-xs text-muted-foreground">
          <span className="font-medium">
            {isAgent ? agentName : "You"}
          </span>
          {timestamp && <span>{timestamp}</span>}
        </div>
        <div
          className={cn(
            "rounded-lg px-4 py-2 text-sm",
            isAgent
              ? "bg-muted text-foreground"
              : "bg-primary text-primary-foreground"
          )}
        >
          {content}
        </div>
      </div>
    </div>
  )
}
```

**Step 2: Commit**

```bash
git add web/src/components/chat/chat-message.tsx
git commit -m "feat(chat): add ChatMessage component"
```

---

## Task 2: Create Chat Input Component

**Files:**
- Create: `web/src/components/chat/chat-input.tsx`

**Step 1: Create the component**

```typescript
"use client"

import { useState, useRef, useEffect } from "react"
import { Send, Paperclip } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Textarea } from "@/components/ui/textarea"

interface ChatInputProps {
  onSend: (message: string) => void
  disabled?: boolean
  placeholder?: string
}

export function ChatInput({
  onSend,
  disabled = false,
  placeholder = "Type a message...",
}: ChatInputProps) {
  const [message, setMessage] = useState("")
  const textareaRef = useRef<HTMLTextAreaElement>(null)

  // Auto-resize textarea
  useEffect(() => {
    const textarea = textareaRef.current
    if (textarea) {
      textarea.style.height = "auto"
      textarea.style.height = `${Math.min(textarea.scrollHeight, 200)}px`
    }
  }, [message])

  const handleSend = () => {
    if (message.trim() && !disabled) {
      onSend(message.trim())
      setMessage("")
    }
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  return (
    <div className="flex items-end gap-2 border-t bg-background p-4">
      <Button variant="ghost" size="icon" disabled={disabled}>
        <Paperclip className="h-5 w-5" />
        <span className="sr-only">Attach file</span>
      </Button>

      <Textarea
        ref={textareaRef}
        value={message}
        onChange={(e) => setMessage(e.target.value)}
        onKeyDown={handleKeyDown}
        placeholder={placeholder}
        disabled={disabled}
        rows={1}
        className="min-h-[44px] resize-none"
      />

      <Button
        onClick={handleSend}
        disabled={disabled || !message.trim()}
        size="icon"
      >
        <Send className="h-5 w-5" />
        <span className="sr-only">Send message</span>
      </Button>
    </div>
  )
}
```

**Step 2: Commit**

```bash
git add web/src/components/chat/chat-input.tsx
git commit -m "feat(chat): add ChatInput component"
```

---

## Task 3: Create Draft Artifacts Panel Component

**Files:**
- Create: `web/src/components/chat/draft-artifacts-panel.tsx`

**Step 1: Create the component**

```typescript
"use client"

import { useState } from "react"
import { ChevronRight, ChevronLeft, FileText, Code, Database, Workflow } from "lucide-react"

import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Badge } from "@/components/ui/badge"

export type ArtifactType = "user-story" | "api-endpoint" | "data-model" | "component"

export interface DraftArtifact {
  id: string
  type: ArtifactType
  title: string
  content: string
  status: "draft" | "ready"
}

interface DraftArtifactsPanelProps {
  artifacts: DraftArtifact[]
  isCollapsed: boolean
  onToggleCollapse: () => void
  onArtifactClick?: (artifact: DraftArtifact) => void
}

function getArtifactIcon(type: ArtifactType) {
  switch (type) {
    case "user-story":
      return FileText
    case "api-endpoint":
      return Workflow
    case "data-model":
      return Database
    case "component":
      return Code
  }
}

function getArtifactTypeLabel(type: ArtifactType) {
  switch (type) {
    case "user-story":
      return "User Story"
    case "api-endpoint":
      return "API Endpoint"
    case "data-model":
      return "Data Model"
    case "component":
      return "Component"
  }
}

export function DraftArtifactsPanel({
  artifacts,
  isCollapsed,
  onToggleCollapse,
  onArtifactClick,
}: DraftArtifactsPanelProps) {
  const [expandedId, setExpandedId] = useState<string | null>(null)

  const readyCount = artifacts.filter((a) => a.status === "ready").length
  const totalCount = artifacts.length

  if (isCollapsed) {
    return (
      <div className="flex h-full w-10 flex-col items-center border-l bg-muted/30">
        <Button
          variant="ghost"
          size="icon"
          onClick={onToggleCollapse}
          className="mt-2"
        >
          <ChevronLeft className="h-4 w-4" />
        </Button>
        <div className="mt-4 -rotate-90 whitespace-nowrap text-xs text-muted-foreground">
          Artifacts ({readyCount}/{totalCount})
        </div>
      </div>
    )
  }

  return (
    <div className="flex h-full w-80 flex-col border-l bg-muted/30">
      {/* Header */}
      <div className="flex items-center justify-between border-b px-4 py-3">
        <div>
          <h3 className="text-sm font-medium">Draft Artifacts</h3>
          <p className="text-xs text-muted-foreground">
            {readyCount} of {totalCount} ready
          </p>
        </div>
        <Button variant="ghost" size="icon" onClick={onToggleCollapse}>
          <ChevronRight className="h-4 w-4" />
        </Button>
      </div>

      {/* Artifacts list */}
      <ScrollArea className="flex-1">
        <div className="space-y-2 p-4">
          {artifacts.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">
              Artifacts will appear here as the conversation progresses.
            </p>
          ) : (
            artifacts.map((artifact) => {
              const Icon = getArtifactIcon(artifact.type)
              const isExpanded = expandedId === artifact.id

              return (
                <div
                  key={artifact.id}
                  className={cn(
                    "cursor-pointer rounded-lg border bg-background p-3 transition-colors hover:bg-muted/50",
                    isExpanded && "ring-2 ring-primary"
                  )}
                  onClick={() => {
                    setExpandedId(isExpanded ? null : artifact.id)
                    onArtifactClick?.(artifact)
                  }}
                >
                  <div className="flex items-start gap-2">
                    <Icon className="mt-0.5 h-4 w-4 text-muted-foreground" />
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2">
                        <span className="truncate text-sm font-medium">
                          {artifact.title}
                        </span>
                        <Badge
                          variant={artifact.status === "ready" ? "success" : "secondary"}
                          className="text-xs"
                        >
                          {artifact.status}
                        </Badge>
                      </div>
                      <p className="text-xs text-muted-foreground">
                        {getArtifactTypeLabel(artifact.type)}
                      </p>
                    </div>
                  </div>

                  {isExpanded && (
                    <div className="mt-3 rounded border bg-muted/50 p-2">
                      <pre className="whitespace-pre-wrap text-xs">
                        {artifact.content}
                      </pre>
                    </div>
                  )}
                </div>
              )
            })
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
```

**Step 2: Commit**

```bash
git add web/src/components/chat/draft-artifacts-panel.tsx
git commit -m "feat(chat): add DraftArtifactsPanel component"
```

---

## Task 4: Create Approval Checklist Component

**Files:**
- Create: `web/src/components/approval/approval-checklist.tsx`

**Step 1: Create the component**

```typescript
"use client"

import { useState } from "react"
import { ArrowLeft, Check, X, MessageSquare, RotateCcw, Send } from "lucide-react"

import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Progress } from "@/components/ui/progress"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Textarea } from "@/components/ui/textarea"
import { Card, CardContent } from "@/components/ui/card"

export type ApprovalItemStatus = "pending" | "approved" | "rejected" | "needs-revision"

export interface ApprovalItem {
  id: string
  title: string
  content: string
  type: string
  status: ApprovalItemStatus
}

interface ApprovalChecklistProps {
  items: ApprovalItem[]
  onApprove: (id: string) => void
  onReject: (id: string, action: "revise" | "explain", feedback?: string) => void
  onComplete: () => void
  onBack: () => void
  phaseName: string
}

function getStatusBadge(status: ApprovalItemStatus) {
  switch (status) {
    case "pending":
      return <Badge variant="secondary">Pending</Badge>
    case "approved":
      return <Badge variant="success">Approved</Badge>
    case "rejected":
      return <Badge variant="destructive">Rejected</Badge>
    case "needs-revision":
      return <Badge variant="warning">Needs Revision</Badge>
  }
}

export function ApprovalChecklist({
  items,
  onApprove,
  onReject,
  onComplete,
  onBack,
  phaseName,
}: ApprovalChecklistProps) {
  const [expandedItemId, setExpandedItemId] = useState<string | null>(null)
  const [feedbackItemId, setFeedbackItemId] = useState<string | null>(null)
  const [feedback, setFeedback] = useState("")

  const approvedCount = items.filter((i) => i.status === "approved").length
  const progress = (approvedCount / items.length) * 100
  const allApproved = approvedCount === items.length

  const handleRejectAction = (id: string, action: "revise" | "explain") => {
    if (action === "explain") {
      setFeedbackItemId(id)
    } else {
      onReject(id, action)
    }
  }

  const handleSendFeedback = (id: string) => {
    if (feedback.trim()) {
      onReject(id, "explain", feedback.trim())
      setFeedback("")
      setFeedbackItemId(null)
    }
  }

  return (
    <div className="flex h-full flex-col bg-background">
      {/* Header */}
      <div className="flex items-center justify-between border-b px-6 py-4">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="icon" onClick={onBack}>
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <div>
            <h2 className="text-lg font-semibold">{phaseName} Review</h2>
            <p className="text-sm text-muted-foreground">
              Approve or reject each item to continue
            </p>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="text-right">
            <p className="text-sm font-medium">
              {approvedCount} of {items.length} approved
            </p>
            <Progress value={progress} className="mt-1 h-2 w-32" />
          </div>
          <Button onClick={onComplete} disabled={!allApproved}>
            {allApproved ? "Complete Phase" : "Review All Items"}
          </Button>
        </div>
      </div>

      {/* Checklist */}
      <ScrollArea className="flex-1">
        <div className="space-y-4 p-6">
          {items.map((item) => {
            const isExpanded = expandedItemId === item.id
            const showFeedback = feedbackItemId === item.id

            return (
              <Card
                key={item.id}
                className={cn(
                  "transition-all",
                  item.status === "approved" && "border-green-500/50 bg-green-500/5",
                  item.status === "rejected" && "border-red-500/50 bg-red-500/5",
                  item.status === "needs-revision" && "border-amber-500/50 bg-amber-500/5"
                )}
              >
                <CardContent className="p-4">
                  <div className="flex items-start gap-4">
                    {/* Status indicator */}
                    <div
                      className={cn(
                        "mt-1 flex h-6 w-6 shrink-0 items-center justify-center rounded-full border-2",
                        item.status === "approved" && "border-green-500 bg-green-500",
                        item.status === "rejected" && "border-red-500 bg-red-500",
                        item.status === "needs-revision" && "border-amber-500",
                        item.status === "pending" && "border-muted-foreground"
                      )}
                    >
                      {item.status === "approved" && (
                        <Check className="h-4 w-4 text-white" />
                      )}
                      {item.status === "rejected" && (
                        <X className="h-4 w-4 text-white" />
                      )}
                    </div>

                    {/* Content */}
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2">
                        <h3 className="font-medium">{item.title}</h3>
                        {getStatusBadge(item.status)}
                        <Badge variant="outline" className="text-xs">
                          {item.type}
                        </Badge>
                      </div>

                      <div
                        className={cn(
                          "mt-2 text-sm text-muted-foreground",
                          !isExpanded && "line-clamp-2"
                        )}
                      >
                        {item.content}
                      </div>

                      {item.content.length > 150 && (
                        <Button
                          variant="link"
                          size="sm"
                          className="mt-1 h-auto p-0"
                          onClick={() =>
                            setExpandedItemId(isExpanded ? null : item.id)
                          }
                        >
                          {isExpanded ? "Show less" : "Show more"}
                        </Button>
                      )}

                      {/* Feedback input */}
                      {showFeedback && (
                        <div className="mt-4 space-y-2">
                          <Textarea
                            placeholder="Explain what needs to change..."
                            value={feedback}
                            onChange={(e) => setFeedback(e.target.value)}
                            rows={3}
                          />
                          <div className="flex gap-2">
                            <Button
                              size="sm"
                              onClick={() => handleSendFeedback(item.id)}
                              disabled={!feedback.trim()}
                            >
                              <Send className="mr-1 h-4 w-4" />
                              Send Feedback
                            </Button>
                            <Button
                              size="sm"
                              variant="ghost"
                              onClick={() => {
                                setFeedbackItemId(null)
                                setFeedback("")
                              }}
                            >
                              Cancel
                            </Button>
                          </div>
                        </div>
                      )}
                    </div>

                    {/* Actions */}
                    {item.status === "pending" && !showFeedback && (
                      <div className="flex shrink-0 gap-2">
                        <Button
                          size="sm"
                          variant="outline"
                          className="text-green-600 hover:bg-green-50 hover:text-green-700 dark:hover:bg-green-950"
                          onClick={() => onApprove(item.id)}
                        >
                          <Check className="mr-1 h-4 w-4" />
                          Approve
                        </Button>
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => handleRejectAction(item.id, "revise")}
                        >
                          <RotateCcw className="mr-1 h-4 w-4" />
                          Revise
                        </Button>
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => handleRejectAction(item.id, "explain")}
                        >
                          <MessageSquare className="mr-1 h-4 w-4" />
                          Explain
                        </Button>
                      </div>
                    )}
                  </div>
                </CardContent>
              </Card>
            )
          })}
        </div>
      </ScrollArea>
    </div>
  )
}
```

**Step 2: Commit**

```bash
git add web/src/components/approval/approval-checklist.tsx
git commit -m "feat(approval): add ApprovalChecklist component"
```

---

## Task 5: Create Component Barrel Exports

**Files:**
- Create: `web/src/components/chat/index.ts`
- Create: `web/src/components/approval/index.ts`

**Step 1: Create chat barrel export**

```typescript
export * from "./chat-message"
export * from "./chat-input"
export * from "./draft-artifacts-panel"
```

**Step 2: Create approval barrel export**

```typescript
export * from "./approval-checklist"
```

**Step 3: Commit**

```bash
git add web/src/components/chat/index.ts web/src/components/approval/index.ts
git commit -m "feat: add barrel exports for chat and approval components"
```

---

## Task 6: Update Project Workspace with Agent Chat

**Files:**
- Modify: `web/src/app/(dashboard)/projects/[id]/page.tsx`

**Step 1: Read current project page**

Read to understand current structure.

**Step 2: Replace with full agent chat implementation**

```typescript
"use client"

import { useState } from "react"
import { useParams, useRouter } from "next/navigation"
import { Bot, FileText, Code, Shield, Check, ClipboardCheck } from "lucide-react"

import { Header } from "@/components/layout/header"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { ScrollArea } from "@/components/ui/scroll-area"
import {
  ChatMessage,
  ChatInput,
  DraftArtifactsPanel,
  type DraftArtifact,
  type MessageRole,
} from "@/components/chat"
import { ApprovalChecklist, type ApprovalItem } from "@/components/approval"

interface Message {
  id: string
  role: MessageRole
  content: string
  timestamp: string
}

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

// Mock conversation
const mockMessages: Message[] = [
  {
    id: "1",
    role: "agent",
    content: `I see you want to build **${mockProject.name}**: ${mockProject.description}. Let me ask a few questions to understand your requirements better.

First, who are the primary users of this platform?`,
    timestamp: "10:00 AM",
  },
  {
    id: "2",
    role: "user",
    content: "The main users will be customers shopping online and store administrators managing inventory.",
    timestamp: "10:02 AM",
  },
  {
    id: "3",
    role: "agent",
    content: "Great! So we have two main user types: customers and administrators. Let me capture that as our first user stories.\n\nWhat payment methods do you need to support?",
    timestamp: "10:03 AM",
  },
]

// Mock artifacts
const mockArtifacts: DraftArtifact[] = [
  {
    id: "1",
    type: "user-story",
    title: "Customer Registration",
    content: "As a customer, I want to create an account so that I can track my orders and save my preferences.",
    status: "ready",
  },
  {
    id: "2",
    type: "user-story",
    title: "Product Browsing",
    content: "As a customer, I want to browse products by category so that I can find what I'm looking for.",
    status: "ready",
  },
  {
    id: "3",
    type: "user-story",
    title: "Inventory Management",
    content: "As an administrator, I want to manage product inventory so that stock levels are accurate.",
    status: "draft",
  },
]

// Mock approval items
const mockApprovalItems: ApprovalItem[] = [
  {
    id: "1",
    title: "Customer Registration",
    content: "As a customer, I want to create an account so that I can track my orders and save my preferences.\n\nAcceptance Criteria:\n- Email validation\n- Password requirements\n- Email verification",
    type: "User Story",
    status: "pending",
  },
  {
    id: "2",
    title: "Product Browsing",
    content: "As a customer, I want to browse products by category so that I can find what I'm looking for.\n\nAcceptance Criteria:\n- Category navigation\n- Search functionality\n- Filtering options",
    type: "User Story",
    status: "pending",
  },
  {
    id: "3",
    title: "Shopping Cart",
    content: "As a customer, I want to add products to a cart so that I can purchase multiple items at once.\n\nAcceptance Criteria:\n- Add/remove items\n- Update quantities\n- Persistent cart",
    type: "User Story",
    status: "pending",
  },
  {
    id: "4",
    title: "Inventory Management",
    content: "As an administrator, I want to manage product inventory so that stock levels are accurate.\n\nAcceptance Criteria:\n- Stock level updates\n- Low stock alerts\n- Bulk import/export",
    type: "User Story",
    status: "pending",
  },
]

const phases = [
  { id: "requirements", label: "Requirements", icon: FileText },
  { id: "architecture", label: "Architecture", icon: Bot },
  { id: "code", label: "Code", icon: Code },
  { id: "review", label: "Security Review", icon: Shield },
]

const agentNames: Record<string, string> = {
  requirements: "Requirements Agent",
  architecture: "Architecture Agent",
  code: "Coding Agent",
  review: "Security Agent",
}

export default function ProjectPage() {
  const params = useParams()
  const router = useRouter()
  const projectId = params.id as string

  const [messages, setMessages] = useState(mockMessages)
  const [artifacts, setArtifacts] = useState(mockArtifacts)
  const [approvalItems, setApprovalItems] = useState(mockApprovalItems)
  const [isArtifactsPanelCollapsed, setIsArtifactsPanelCollapsed] = useState(false)
  const [isApprovalMode, setIsApprovalMode] = useState(false)
  const [currentPhase, setCurrentPhase] = useState(mockProject.currentPhase)

  const project = mockProject
  const currentAgentName = agentNames[currentPhase]

  const handleSendMessage = (content: string) => {
    const newMessage: Message = {
      id: Date.now().toString(),
      role: "user",
      content,
      timestamp: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
    }
    setMessages([...messages, newMessage])

    // Simulate agent response
    setTimeout(() => {
      const agentMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: "agent",
        content: "Thank you for that information. I've updated the requirements. Is there anything else you'd like to add?",
        timestamp: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
      }
      setMessages((prev) => [...prev, agentMessage])
    }, 1000)
  }

  const handleReadyToReview = () => {
    setIsApprovalMode(true)
  }

  const handleApproveItem = (id: string) => {
    setApprovalItems((items) =>
      items.map((item) =>
        item.id === id ? { ...item, status: "approved" as const } : item
      )
    )
  }

  const handleRejectItem = (id: string, action: "revise" | "explain", feedback?: string) => {
    setApprovalItems((items) =>
      items.map((item) =>
        item.id === id ? { ...item, status: "needs-revision" as const } : item
      )
    )
    // In real implementation, send feedback to agent
    console.log("Rejection:", { id, action, feedback })
  }

  const handleCompletePhase = () => {
    setIsApprovalMode(false)
    // Move to next phase
    const phaseOrder = ["requirements", "architecture", "code", "review"]
    const currentIndex = phaseOrder.indexOf(currentPhase)
    if (currentIndex < phaseOrder.length - 1) {
      setCurrentPhase(phaseOrder[currentIndex + 1])
    }
  }

  const handleBackFromApproval = () => {
    setIsApprovalMode(false)
  }

  if (isApprovalMode) {
    return (
      <ApprovalChecklist
        items={approvalItems}
        onApprove={handleApproveItem}
        onReject={handleRejectItem}
        onComplete={handleCompletePhase}
        onBack={handleBackFromApproval}
        phaseName={currentPhase.charAt(0).toUpperCase() + currentPhase.slice(1)}
      />
    )
  }

  return (
    <div className="flex h-full flex-col">
      <Header title={project.name} description={project.description} />

      <div className="flex-1 overflow-hidden">
        <Tabs value={currentPhase} className="flex h-full flex-col">
          {/* Phase tabs */}
          <div className="flex items-center justify-between border-b px-6">
            <TabsList className="h-12 gap-2 bg-transparent p-0">
              {phases.map((phase) => {
                const phaseData = project.phases[phase.id as keyof typeof project.phases]
                const isDisabled = phaseData.status === "locked"
                const isCompleted = phaseData.status === "completed"
                const Icon = phase.icon

                return (
                  <TabsTrigger
                    key={phase.id}
                    value={phase.id}
                    disabled={isDisabled}
                    className="flex items-center gap-2 rounded-none data-[state=active]:border-b-2 data-[state=active]:border-primary"
                  >
                    <Icon className="h-4 w-4" />
                    {phase.label}
                    {isCompleted && <Check className="h-4 w-4 text-green-500" />}
                  </TabsTrigger>
                )
              })}
            </TabsList>

            <Button onClick={handleReadyToReview}>
              <ClipboardCheck className="mr-2 h-4 w-4" />
              Ready to Review
            </Button>
          </div>

          {/* Chat + Artifacts */}
          <TabsContent value={currentPhase} className="m-0 flex flex-1 overflow-hidden">
            {/* Chat area */}
            <div className="flex flex-1 flex-col">
              {/* Agent header */}
              <div className="flex items-center gap-2 border-b px-4 py-2">
                <Bot className="h-5 w-5 text-primary" />
                <span className="font-medium">{currentAgentName}</span>
                <Badge variant="success" className="text-xs">
                  Online
                </Badge>
              </div>

              {/* Messages */}
              <ScrollArea className="flex-1 p-4">
                <div className="space-y-4">
                  {messages.map((message) => (
                    <ChatMessage
                      key={message.id}
                      role={message.role}
                      content={message.content}
                      timestamp={message.timestamp}
                      agentName={currentAgentName}
                    />
                  ))}
                </div>
              </ScrollArea>

              {/* Input */}
              <ChatInput
                onSend={handleSendMessage}
                placeholder={`Message ${currentAgentName}...`}
              />
            </div>

            {/* Draft artifacts panel */}
            <DraftArtifactsPanel
              artifacts={artifacts}
              isCollapsed={isArtifactsPanelCollapsed}
              onToggleCollapse={() =>
                setIsArtifactsPanelCollapsed(!isArtifactsPanelCollapsed)
              }
            />
          </TabsContent>
        </Tabs>
      </div>
    </div>
  )
}
```

**Step 3: Verify page renders**

Run `npm run dev` and navigate to `/projects/1`. Verify:
- Chat messages display
- Can send messages
- Artifacts panel shows/collapses
- "Ready to Review" opens approval checklist
- Can approve/reject items

**Step 4: Commit**

```bash
git add web/src/app/\(dashboard\)/projects/\[id\]/page.tsx
git commit -m "feat(projects): implement full agent chat interface with approval mode"
```

---

## Completion Checklist

- [ ] ChatMessage component created
- [ ] ChatInput component created with auto-resize
- [ ] DraftArtifactsPanel component created (collapsible)
- [ ] ApprovalChecklist component created with rejection handling
- [ ] Barrel exports created for chat and approval
- [ ] Project workspace updated with full chat UI
- [ ] "Ready to Review" triggers approval mode
- [ ] Approval/rejection workflow working
- [ ] Phase tabs show status correctly
- [ ] All changes committed
