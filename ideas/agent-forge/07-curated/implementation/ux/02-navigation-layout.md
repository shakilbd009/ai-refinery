# Navigation & Layout Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update sidebar navigation and layout to match UX design with Inbox badge, reorganized navigation, and global layout improvements.

**Architecture:** Modify existing sidebar component, add badge count support, update navigation structure.

**Tech Stack:** React 18, Next.js App Router, Tailwind CSS, lucide-react

---

## Task 1: Update Sidebar Navigation Structure

**Files:**
- Modify: `web/src/components/layout/sidebar.tsx`

**Step 1: Read current sidebar implementation**

Read `web/src/components/layout/sidebar.tsx` to understand current structure.

**Step 2: Update navigation items**

Replace the navigation items to match the UX spec:
- Dashboard (home)
- Projects
- Inbox (Action Required) - with badge count
- SME Knowledge (admin only for now, but show to all)
- Settings

```typescript
"use client"

import Link from "next/link"
import { usePathname } from "next/navigation"
import {
  Home,
  FolderKanban,
  Inbox,
  BookOpen,
  Settings,
  HelpCircle,
  Bot,
} from "lucide-react"

import { cn } from "@/lib/utils"
import { Badge } from "@/components/ui/badge"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"

const mainNavItems = [
  {
    title: "Dashboard",
    href: "/",
    icon: Home,
  },
  {
    title: "Projects",
    href: "/projects",
    icon: FolderKanban,
  },
  {
    title: "Inbox",
    href: "/inbox",
    icon: Inbox,
    badge: 3, // TODO: Replace with dynamic count
  },
  {
    title: "Agents",
    href: "/agents",
    icon: Bot,
  },
  {
    title: "SME Knowledge",
    href: "/knowledge",
    icon: BookOpen,
  },
]

const secondaryNavItems = [
  {
    title: "Settings",
    href: "/settings",
    icon: Settings,
  },
  {
    title: "Help",
    href: "/help",
    icon: HelpCircle,
  },
]

export function Sidebar() {
  const pathname = usePathname()

  const isActive = (href: string) => {
    if (href === "/") {
      return pathname === "/"
    }
    return pathname.startsWith(href)
  }

  return (
    <div className="flex h-full w-64 flex-col border-r bg-card">
      {/* Logo */}
      <div className="flex h-14 items-center border-b px-4">
        <Link href="/" className="flex items-center gap-2 font-semibold">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary">
            <Bot className="h-5 w-5 text-primary-foreground" />
          </div>
          <span className="text-lg">AgentForge</span>
        </Link>
      </div>

      {/* Navigation */}
      <ScrollArea className="flex-1 px-3 py-4">
        <nav className="space-y-1">
          {mainNavItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex items-center justify-between rounded-lg px-3 py-2 text-sm font-medium transition-colors",
                isActive(item.href)
                  ? "bg-primary text-primary-foreground"
                  : "text-muted-foreground hover:bg-muted hover:text-foreground"
              )}
            >
              <div className="flex items-center gap-3">
                <item.icon className="h-4 w-4" />
                {item.title}
              </div>
              {item.badge && item.badge > 0 && (
                <Badge
                  variant={isActive(item.href) ? "secondary" : "destructive"}
                  className="h-5 min-w-[20px] px-1.5 text-xs"
                >
                  {item.badge}
                </Badge>
              )}
            </Link>
          ))}
        </nav>

        <div className="my-4 border-t" />

        <nav className="space-y-1">
          {secondaryNavItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors",
                isActive(item.href)
                  ? "bg-primary text-primary-foreground"
                  : "text-muted-foreground hover:bg-muted hover:text-foreground"
              )}
            >
              <item.icon className="h-4 w-4" />
              {item.title}
            </Link>
          ))}
        </nav>
      </ScrollArea>

      {/* User Section */}
      <div className="border-t p-4">
        <div className="flex items-center gap-3">
          <Avatar className="h-9 w-9">
            <AvatarImage src="/avatars/user.png" alt="User" />
            <AvatarFallback>JD</AvatarFallback>
          </Avatar>
          <div className="flex-1 overflow-hidden">
            <p className="truncate text-sm font-medium">John Doe</p>
            <p className="truncate text-xs text-muted-foreground">
              john@example.com
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
```

**Step 3: Verify sidebar renders correctly**

Run `npm run dev` and verify sidebar shows updated navigation with Inbox badge.

**Step 4: Commit**

```bash
git add web/src/components/layout/sidebar.tsx
git commit -m "feat(nav): update sidebar with Inbox badge and reorganized navigation"
```

---

## Task 2: Create Inbox Page Placeholder

**Files:**
- Create: `web/src/app/(dashboard)/inbox/page.tsx`

**Step 1: Create basic inbox page**

```typescript
"use client"

import { Header } from "@/components/layout/header"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Inbox } from "lucide-react"

export default function InboxPage() {
  return (
    <div className="flex flex-col">
      <Header
        title="Inbox"
        description="Action items requiring your attention"
      />
      <div className="flex-1 space-y-6 p-6">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Inbox className="h-5 w-5" />
              Action Required
            </CardTitle>
            <CardDescription>
              Pending approvals, escalations, and questions from agents
            </CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-muted-foreground">
              Full inbox implementation coming in workstream #5.
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
```

**Step 2: Verify page is accessible**

Navigate to `/inbox` and verify it renders.

**Step 3: Commit**

```bash
git add web/src/app/\(dashboard\)/inbox/page.tsx
git commit -m "feat(inbox): add placeholder inbox page"
```

---

## Task 3: Create Settings Page Placeholder

**Files:**
- Create: `web/src/app/(dashboard)/settings/page.tsx`

**Step 1: Create basic settings page**

```typescript
"use client"

import { Header } from "@/components/layout/header"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Settings, User, Bell, Palette, Shield } from "lucide-react"

const settingsSections = [
  {
    title: "Profile",
    description: "Manage your account details",
    icon: User,
  },
  {
    title: "Notifications",
    description: "Configure how you receive updates",
    icon: Bell,
  },
  {
    title: "Appearance",
    description: "Customize the interface",
    icon: Palette,
  },
  {
    title: "Security",
    description: "Password and authentication",
    icon: Shield,
  },
]

export default function SettingsPage() {
  return (
    <div className="flex flex-col">
      <Header
        title="Settings"
        description="Manage your account and preferences"
      />
      <div className="flex-1 space-y-6 p-6">
        <div className="grid gap-4 md:grid-cols-2">
          {settingsSections.map((section) => (
            <Card
              key={section.title}
              className="cursor-pointer transition-colors hover:bg-muted/50"
            >
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-base">
                  <section.icon className="h-5 w-5" />
                  {section.title}
                </CardTitle>
                <CardDescription>{section.description}</CardDescription>
              </CardHeader>
            </Card>
          ))}
        </div>
      </div>
    </div>
  )
}
```

**Step 2: Commit**

```bash
git add web/src/app/\(dashboard\)/settings/page.tsx
git commit -m "feat(settings): add placeholder settings page"
```

---

## Task 4: Create Help Page Placeholder

**Files:**
- Create: `web/src/app/(dashboard)/help/page.tsx`

**Step 1: Create basic help page**

```typescript
"use client"

import { Header } from "@/components/layout/header"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { HelpCircle, BookOpen, MessageSquare, Video } from "lucide-react"

const helpResources = [
  {
    title: "Documentation",
    description: "Learn how to use AgentForge",
    icon: BookOpen,
    href: "#",
  },
  {
    title: "Video Tutorials",
    description: "Watch step-by-step guides",
    icon: Video,
    href: "#",
  },
  {
    title: "Contact Support",
    description: "Get help from our team",
    icon: MessageSquare,
    href: "#",
  },
]

export default function HelpPage() {
  return (
    <div className="flex flex-col">
      <Header
        title="Help & Support"
        description="Find answers and get assistance"
      />
      <div className="flex-1 space-y-6 p-6">
        <div className="grid gap-4 md:grid-cols-3">
          {helpResources.map((resource) => (
            <Card
              key={resource.title}
              className="cursor-pointer transition-colors hover:bg-muted/50"
            >
              <CardHeader>
                <div className="mb-2 flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                  <resource.icon className="h-5 w-5 text-primary" />
                </div>
                <CardTitle className="text-base">{resource.title}</CardTitle>
                <CardDescription>{resource.description}</CardDescription>
              </CardHeader>
            </Card>
          ))}
        </div>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <HelpCircle className="h-5 w-5" />
              Frequently Asked Questions
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-muted-foreground">
              FAQ content coming soon.
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
```

**Step 2: Commit**

```bash
git add web/src/app/\(dashboard\)/help/page.tsx
git commit -m "feat(help): add placeholder help page"
```

---

## Task 5: Update Header Component with Inbox Link

**Files:**
- Modify: `web/src/components/layout/header.tsx`

**Step 1: Read current header**

Read `web/src/components/layout/header.tsx` to understand current structure.

**Step 2: Update header with inbox notification link**

```typescript
"use client"

import Link from "next/link"
import { Bell, Search } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"

interface HeaderProps {
  title: string
  description?: string
  action?: {
    label: string
    onClick: () => void
  }
}

export function Header({ title, description, action }: HeaderProps) {
  return (
    <div className="flex h-14 items-center justify-between border-b px-6">
      <div>
        <h1 className="text-lg font-semibold">{title}</h1>
        {description && (
          <p className="text-sm text-muted-foreground">{description}</p>
        )}
      </div>
      <div className="flex items-center gap-4">
        <div className="relative">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            type="search"
            placeholder="Search..."
            className="w-64 pl-8"
          />
        </div>
        <Link href="/inbox">
          <Button variant="ghost" size="icon" className="relative">
            <Bell className="h-5 w-5" />
            <span className="absolute -right-1 -top-1 flex h-4 w-4 items-center justify-center rounded-full bg-destructive text-[10px] font-medium text-destructive-foreground">
              3
            </span>
            <span className="sr-only">View inbox</span>
          </Button>
        </Link>
        {action && (
          <Button onClick={action.onClick}>{action.label}</Button>
        )}
      </div>
    </div>
  )
}
```

**Step 3: Commit**

```bash
git add web/src/components/layout/header.tsx
git commit -m "feat(header): add inbox notification link with badge"
```

---

## Task 6: Remove Workflows from Main Navigation

The UX design doesn't include "Workflows" as a top-level navigation item. The workflow monitoring is part of the project dashboard. We'll keep the page but remove it from primary nav (already done in Task 1).

**Files:**
- None (already handled in Task 1)

**Step 1: Verify workflows page still accessible**

Navigate to `/workflows` directly - it should still work.

**Step 2: No commit needed**

Already covered by Task 1.

---

## Completion Checklist

- [ ] Sidebar updated with new navigation structure
- [ ] Inbox badge showing on sidebar
- [ ] Inbox page placeholder created
- [ ] Settings page placeholder created
- [ ] Help page placeholder created
- [ ] Header notification links to inbox
- [ ] All navigation links working
- [ ] All changes committed
