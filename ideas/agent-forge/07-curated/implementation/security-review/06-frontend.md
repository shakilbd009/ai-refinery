# Security Review: Frontend Components

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build UI components for the Security Review phase.

**Prerequisites:** None (can run in parallel with backend)

**Files:**
- Create: `web/src/types/security.ts`
- Create: `web/src/components/security/security-finding-card.tsx`
- Create: `web/src/components/security/security-review-panel.tsx`
- Create: `web/src/components/security/index.ts`
- Modify: `web/src/app/(dashboard)/projects/[id]/page.tsx`

---

## Task 1: Add Security Types

**Files:**
- Create: `web/src/types/security.ts`
- Modify: `web/src/types/index.ts`

**Step 1: Write the type definitions**

Create `web/src/types/security.ts`:

```typescript
export type FindingSeverity = "critical" | "high" | "medium" | "low";

export type FindingCategory =
  | "injection"
  | "authentication"
  | "data_exposure"
  | "access_control"
  | "configuration"
  | "dependencies";

export type FindingStatus = "pending" | "accepted" | "user_alternative";

export type ReviewStatus = "in_progress" | "awaiting_approval" | "completed";

export interface SecurityFinding {
  id: string;
  projectId: string;
  artifactId: string;
  category: FindingCategory;
  severity: FindingSeverity;
  location: string;
  description: string;
  proposedPatch: string;
  status: FindingStatus;
  resolvedBy?: string;
  resolvedAt?: string;
  alternativePatch?: string;
  createdAt: string;
}

export interface SecurityReview {
  id: string;
  projectId: string;
  workflowId: string;
  findingsCount: number;
  criticalCount: number;
  highCount: number;
  mediumCount: number;
  lowCount: number;
  status: ReviewStatus;
  startedAt: string;
  completedAt?: string;
}
```

**Step 2: Export from index**

Add to `web/src/types/index.ts`:

```typescript
export * from "./security";
```

**Step 3: Verify types compile**

Run: `cd /Users/shakilakram/projects/agentic-platform/web && npm run build`

Expected: Build succeeds

**Step 4: Commit**

```bash
git add web/src/types/security.ts web/src/types/index.ts
git commit -m "$(cat <<'EOF'
feat(types): add security review types

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Create SecurityFindingCard Component

**Files:**
- Create: `web/src/components/security/security-finding-card.tsx`

**Step 1: Create the component**

```tsx
"use client";

import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Textarea } from "@/components/ui/textarea";
import {
  AlertTriangle,
  Shield,
  CheckCircle,
  ChevronDown,
  ChevronUp,
} from "lucide-react";
import { cn } from "@/lib/utils";
import type { SecurityFinding, FindingSeverity } from "@/types";

interface SecurityFindingCardProps {
  finding: SecurityFinding;
  onAccept: (findingId: string) => void;
  onProvideAlternative: (findingId: string, patch: string) => void;
}

const severityConfig: Record<
  FindingSeverity,
  { color: string; bgColor: string; icon: typeof AlertTriangle }
> = {
  critical: {
    color: "text-red-500",
    bgColor: "bg-red-500/10",
    icon: AlertTriangle,
  },
  high: {
    color: "text-orange-500",
    bgColor: "bg-orange-500/10",
    icon: AlertTriangle,
  },
  medium: {
    color: "text-yellow-500",
    bgColor: "bg-yellow-500/10",
    icon: Shield,
  },
  low: {
    color: "text-blue-500",
    bgColor: "bg-blue-500/10",
    icon: Shield,
  },
};

const categoryLabels: Record<string, string> = {
  injection: "Injection",
  authentication: "Authentication",
  data_exposure: "Data Exposure",
  access_control: "Access Control",
  configuration: "Configuration",
  dependencies: "Dependencies",
};

export function SecurityFindingCard({
  finding,
  onAccept,
  onProvideAlternative,
}: SecurityFindingCardProps) {
  const [expanded, setExpanded] = useState(false);
  const [showAlternative, setShowAlternative] = useState(false);
  const [alternativePatch, setAlternativePatch] = useState("");

  const config = severityConfig[finding.severity];
  const Icon = config.icon;
  const isResolved = finding.status !== "pending";

  const handleAccept = () => {
    onAccept(finding.id);
  };

  const handleSubmitAlternative = () => {
    if (alternativePatch.trim()) {
      onProvideAlternative(finding.id, alternativePatch);
      setShowAlternative(false);
      setAlternativePatch("");
    }
  };

  return (
    <Card
      className={cn(
        "transition-all",
        isResolved && "opacity-60",
        !isResolved && config.bgColor
      )}
    >
      <CardHeader className="pb-2">
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-2">
            <Icon className={cn("h-5 w-5", config.color)} />
            <div>
              <CardTitle className="text-sm font-medium">
                {finding.description}
              </CardTitle>
              <p className="text-xs text-muted-foreground mt-1">
                {finding.location}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Badge variant="outline" className={config.color}>
              {finding.severity.toUpperCase()}
            </Badge>
            <Badge variant="secondary">
              {categoryLabels[finding.category] || finding.category}
            </Badge>
            {isResolved && (
              <Badge variant="default" className="bg-green-500">
                <CheckCircle className="h-3 w-3 mr-1" />
                {finding.status === "accepted" ? "Accepted" : "Alternative"}
              </Badge>
            )}
          </div>
        </div>
      </CardHeader>

      <CardContent>
        <Button
          variant="ghost"
          size="sm"
          onClick={() => setExpanded(!expanded)}
          className="w-full justify-between"
        >
          <span>View proposed fix</span>
          {expanded ? (
            <ChevronUp className="h-4 w-4" />
          ) : (
            <ChevronDown className="h-4 w-4" />
          )}
        </Button>

        {expanded && (
          <div className="mt-3 space-y-3">
            <div className="bg-muted p-3 rounded-md">
              <p className="text-xs font-medium text-muted-foreground mb-1">
                Proposed Fix:
              </p>
              <pre className="text-sm whitespace-pre-wrap">
                {finding.proposedPatch}
              </pre>
            </div>

            {!isResolved && (
              <div className="flex gap-2">
                <Button size="sm" onClick={handleAccept}>
                  Accept Fix
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => setShowAlternative(!showAlternative)}
                >
                  Provide Alternative
                </Button>
              </div>
            )}

            {showAlternative && !isResolved && (
              <div className="space-y-2">
                <Textarea
                  placeholder="Enter your alternative fix..."
                  value={alternativePatch}
                  onChange={(e) => setAlternativePatch(e.target.value)}
                  rows={4}
                />
                <div className="flex gap-2">
                  <Button size="sm" onClick={handleSubmitAlternative}>
                    Submit Alternative
                  </Button>
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={() => setShowAlternative(false)}
                  >
                    Cancel
                  </Button>
                </div>
              </div>
            )}

            {finding.alternativePatch && (
              <div className="bg-muted p-3 rounded-md">
                <p className="text-xs font-medium text-muted-foreground mb-1">
                  User Alternative:
                </p>
                <pre className="text-sm whitespace-pre-wrap">
                  {finding.alternativePatch}
                </pre>
              </div>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
```

**Step 2: Verify component compiles**

Run: `cd /Users/shakilakram/projects/agentic-platform/web && npm run build`

Expected: Build succeeds

**Step 3: Commit**

```bash
git add web/src/components/security/security-finding-card.tsx
git commit -m "$(cat <<'EOF'
feat(security): add SecurityFindingCard component

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Create SecurityReviewPanel Component

**Files:**
- Create: `web/src/components/security/security-review-panel.tsx`

**Step 1: Create the component**

```tsx
"use client";

import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Shield, CheckCircle, AlertTriangle, Clock } from "lucide-react";
import { SecurityFindingCard } from "./security-finding-card";
import type { SecurityReview, SecurityFinding } from "@/types";

interface SecurityReviewPanelProps {
  review: SecurityReview | null;
  findings: SecurityFinding[];
  onAcceptFinding: (findingId: string) => void;
  onProvideAlternative: (findingId: string, patch: string) => void;
  onCompleteReview: () => void;
}

export function SecurityReviewPanel({
  review,
  findings,
  onAcceptFinding,
  onProvideAlternative,
  onCompleteReview,
}: SecurityReviewPanelProps) {
  const pendingFindings = findings.filter((f) => f.status === "pending");
  const resolvedFindings = findings.filter((f) => f.status !== "pending");
  const progress =
    findings.length > 0
      ? Math.round((resolvedFindings.length / findings.length) * 100)
      : 100;
  const canComplete = pendingFindings.length === 0;

  if (!review) {
    return (
      <Card>
        <CardContent className="flex flex-col items-center justify-center py-12 text-center">
          <Shield className="h-12 w-12 text-muted-foreground mb-4" />
          <h3 className="text-lg font-medium mb-2">
            Security Review Not Started
          </h3>
          <p className="text-sm text-muted-foreground max-w-md">
            The security review will begin automatically after the Code phase is
            approved.
          </p>
        </CardContent>
      </Card>
    );
  }

  if (review.status === "completed") {
    return (
      <Card>
        <CardContent className="flex flex-col items-center justify-center py-12 text-center">
          <CheckCircle className="h-12 w-12 text-green-500 mb-4" />
          <h3 className="text-lg font-medium mb-2">Security Review Complete</h3>
          <p className="text-sm text-muted-foreground">
            {review.findingsCount === 0
              ? "No security issues were found."
              : `All ${review.findingsCount} finding(s) have been resolved.`}
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {/* Summary Card */}
      <Card>
        <CardHeader className="pb-2">
          <div className="flex items-center justify-between">
            <CardTitle className="text-lg">Security Review Summary</CardTitle>
            <Badge
              variant={review.status === "in_progress" ? "secondary" : "default"}
            >
              {review.status === "in_progress" ? (
                <>
                  <Clock className="h-3 w-3 mr-1" />
                  In Progress
                </>
              ) : (
                <>
                  <AlertTriangle className="h-3 w-3 mr-1" />
                  Awaiting Approval
                </>
              )}
            </Badge>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Progress */}
          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span>Resolution Progress</span>
              <span>
                {resolvedFindings.length} / {findings.length} resolved
              </span>
            </div>
            <Progress value={progress} />
          </div>

          {/* Severity Breakdown */}
          <div className="flex gap-4 text-sm">
            {review.criticalCount > 0 && (
              <div className="flex items-center gap-1">
                <div className="w-3 h-3 rounded-full bg-red-500" />
                <span>{review.criticalCount} Critical</span>
              </div>
            )}
            {review.highCount > 0 && (
              <div className="flex items-center gap-1">
                <div className="w-3 h-3 rounded-full bg-orange-500" />
                <span>{review.highCount} High</span>
              </div>
            )}
            {review.mediumCount > 0 && (
              <div className="flex items-center gap-1">
                <div className="w-3 h-3 rounded-full bg-yellow-500" />
                <span>{review.mediumCount} Medium</span>
              </div>
            )}
            {review.lowCount > 0 && (
              <div className="flex items-center gap-1">
                <div className="w-3 h-3 rounded-full bg-blue-500" />
                <span>{review.lowCount} Low</span>
              </div>
            )}
          </div>

          {/* Complete Button */}
          <Button
            className="w-full"
            disabled={!canComplete}
            onClick={onCompleteReview}
          >
            {canComplete
              ? "Complete Security Review"
              : `Resolve ${pendingFindings.length} remaining issue(s)`}
          </Button>
        </CardContent>
      </Card>

      {/* Findings List */}
      {findings.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Security Findings</CardTitle>
          </CardHeader>
          <CardContent>
            <ScrollArea className="h-[500px] pr-4">
              <div className="space-y-3">
                {/* Show pending first, sorted by severity */}
                {[...findings]
                  .sort((a, b) => {
                    const statusOrder = { pending: 0, accepted: 1, user_alternative: 2 };
                    const severityOrder = { critical: 0, high: 1, medium: 2, low: 3 };
                    const statusDiff = statusOrder[a.status] - statusOrder[b.status];
                    if (statusDiff !== 0) return statusDiff;
                    return severityOrder[a.severity] - severityOrder[b.severity];
                  })
                  .map((finding) => (
                    <SecurityFindingCard
                      key={finding.id}
                      finding={finding}
                      onAccept={onAcceptFinding}
                      onProvideAlternative={onProvideAlternative}
                    />
                  ))}
              </div>
            </ScrollArea>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
```

**Step 2: Verify component compiles**

Run: `cd /Users/shakilakram/projects/agentic-platform/web && npm run build`

Expected: Build succeeds

**Step 3: Commit**

```bash
git add web/src/components/security/security-review-panel.tsx
git commit -m "$(cat <<'EOF'
feat(security): add SecurityReviewPanel component

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Create Barrel Export

**Files:**
- Create: `web/src/components/security/index.ts`

**Step 1: Create the barrel export**

```typescript
export { SecurityFindingCard } from "./security-finding-card";
export { SecurityReviewPanel } from "./security-review-panel";
```

**Step 2: Verify export works**

Run: `cd /Users/shakilakram/projects/agentic-platform/web && npm run build`

Expected: Build succeeds

**Step 3: Commit**

```bash
git add web/src/components/security/index.ts
git commit -m "$(cat <<'EOF'
feat(security): add barrel export for security components

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Integrate into Project Page

**Files:**
- Modify: `web/src/app/(dashboard)/projects/[id]/page.tsx`

**Step 1: Add mock data and imports**

Add to imports:

```typescript
import { SecurityReviewPanel } from "@/components/security";
import type { SecurityReview, SecurityFinding } from "@/types";
```

Add mock data (near other mock data):

```typescript
const mockSecurityReview: SecurityReview = {
  id: "review-1",
  projectId: "1",
  workflowId: "workflow-1",
  findingsCount: 3,
  criticalCount: 1,
  highCount: 1,
  mediumCount: 1,
  lowCount: 0,
  status: "awaiting_approval",
  startedAt: new Date().toISOString(),
};

const mockSecurityFindings: SecurityFinding[] = [
  {
    id: "finding-1",
    projectId: "1",
    artifactId: "artifact-1",
    category: "injection",
    severity: "critical",
    location: "src/api/users.ts:45",
    description: "SQL injection vulnerability in user query",
    proposedPatch: "Use parameterized queries:\ndb.query('SELECT * FROM users WHERE id = $1', [userId])",
    status: "pending",
    createdAt: new Date().toISOString(),
  },
  {
    id: "finding-2",
    projectId: "1",
    artifactId: "artifact-1",
    category: "authentication",
    severity: "high",
    location: "src/config/auth.ts:12",
    description: "Hardcoded API key detected",
    proposedPatch: "Use environment variables:\nconst apiKey = process.env.API_KEY",
    status: "pending",
    createdAt: new Date().toISOString(),
  },
  {
    id: "finding-3",
    projectId: "1",
    artifactId: "artifact-1",
    category: "data_exposure",
    severity: "medium",
    location: "src/utils/logger.ts:28",
    description: "Sensitive data may be exposed in logs",
    proposedPatch: "Remove sensitive data from log statements or use log redaction",
    status: "accepted",
    resolvedBy: "user-1",
    resolvedAt: new Date().toISOString(),
    createdAt: new Date().toISOString(),
  },
];
```

**Step 2: Add state and handlers**

Add state (after other useState calls):

```typescript
const [securityReview, setSecurityReview] = useState<SecurityReview | null>(mockSecurityReview);
const [securityFindings, setSecurityFindings] = useState<SecurityFinding[]>(mockSecurityFindings);
```

Add handlers:

```typescript
const handleAcceptFinding = (findingId: string) => {
  setSecurityFindings((prev) =>
    prev.map((f) =>
      f.id === findingId
        ? { ...f, status: "accepted" as const, resolvedBy: "user-1", resolvedAt: new Date().toISOString() }
        : f
    )
  );
};

const handleProvideAlternative = (findingId: string, patch: string) => {
  setSecurityFindings((prev) =>
    prev.map((f) =>
      f.id === findingId
        ? {
            ...f,
            status: "user_alternative" as const,
            alternativePatch: patch,
            resolvedBy: "user-1",
            resolvedAt: new Date().toISOString(),
          }
        : f
    )
  );
};

const handleCompleteSecurityReview = () => {
  setSecurityReview((prev) =>
    prev ? { ...prev, status: "completed", completedAt: new Date().toISOString() } : null
  );
};
```

**Step 3: Update Security Review tab content**

Find the Security Review TabsContent and replace with:

```tsx
<TabsContent value="security" className="mt-6">
  <SecurityReviewPanel
    review={securityReview}
    findings={securityFindings}
    onAcceptFinding={handleAcceptFinding}
    onProvideAlternative={handleProvideAlternative}
    onCompleteReview={handleCompleteSecurityReview}
  />
</TabsContent>
```

**Step 4: Verify integration works**

Run: `cd /Users/shakilakram/projects/agentic-platform/web && npm run build && npm run dev`

Expected: Build succeeds, dev server starts, Security Review tab shows findings

**Step 5: Commit**

```bash
git add web/src/app/\(dashboard\)/projects/\[id\]/page.tsx
git commit -m "$(cat <<'EOF'
feat(projects): integrate SecurityReviewPanel into project page

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Summary

After completing this module, the frontend will have:

- TypeScript types for SecurityFinding and SecurityReview
- SecurityFindingCard component showing individual findings with accept/alternative actions
- SecurityReviewPanel component with progress tracking and completion
- Integration into the project page Security Review tab
- Mock data for development testing

**Plan Complete!** All 6 modules are now defined.
