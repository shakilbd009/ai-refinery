# ADR-022: Cost Controls

## Status

Accepted

## Context

AgentForge uses external LLM providers with per-token pricing. Without controls:
- Organizations could incur unexpected charges
- Runaway agent loops could exhaust budgets
- No visibility into cost allocation

We need:
- Budget limits at organization level
- Usage tracking for billing and allocation
- Alerts before limits are reached
- Controls to prevent runaway costs

We considered:
1. No controls (trust users)
2. Hard budget limits with blocking
3. Soft limits with warnings
4. Usage-based throttling

## Decision

We will implement **tiered budget controls** with both hard limits and progressive warnings.

### Budget Hierarchy

- **Platform level**: Overall spending cap (optional)
- **Organization level**: Monthly budget per org (required)
- **Project level**: Optional sub-allocation
- **User level**: Optional daily limits

### Enforcement

- Pre-request cost estimation
- Block requests that would exceed budget
- Progressive warnings at 50%, 80%, 90%
- Admin override for temporary increases

### Tracking

- Per-request usage records
- Aggregated by org, project, user
- Monthly rollup for billing
- Export capability for reconciliation

## Rationale

Tiered controls with hard limits were chosen because:

1. **Predictable Costs**: Organizations know their maximum exposure
2. **Fair Allocation**: Multi-tenant platform needs resource boundaries
3. **Early Warning**: Alerts prevent surprise limit hits
4. **Flexibility**: Admins can adjust limits as needed
5. **Transparency**: Dashboard shows usage breakdown

### Rejected Alternatives

**No controls**:
- Unpredictable costs for organizations
- No fairness between tenants
- Could lead to billing disputes

**Soft limits only**:
- Doesn't prevent runaway costs
- Warnings can be ignored
- Still leads to unexpected charges

**Usage-based throttling**:
- More complex to implement
- Degrades experience unpredictably
- Hard to explain to users

## Consequences

### Positive

- Organizations have cost certainty
- Platform can plan capacity
- Fair resource distribution
- Clear cost visibility

### Negative

- Adds latency for budget checks
- Blocks legitimate work when budget exceeded
- Requires accurate cost estimation
- Admin overhead for budget management

### Mitigations

- Cache budget state for fast checks
- Clear UI explaining budget status
- Conservative estimation to avoid surprises
- Easy budget increase workflow

## Implementation Notes

### Pre-Execution Cost Estimates (User-Facing)

Users need visibility into costs BEFORE agent execution begins:

```go
type CostEstimate struct {
    MinCost      float64 `json:"minCost"`
    MaxCost      float64 `json:"maxCost"`
    LikelyCost   float64 `json:"likelyCost"`
    TokenEstimate TokenEstimate `json:"tokenEstimate"`
    Warning      string  `json:"warning,omitempty"`
}

type TokenEstimate struct {
    InputTokens  int `json:"inputTokens"`
    OutputTokensMin int `json:"outputTokensMin"`
    OutputTokensMax int `json:"outputTokensMax"`
}

func EstimateWorkflowCost(workflow *Workflow, project *Project) (*CostEstimate, error) {
    // Estimate based on project complexity indicators
    complexity := analyzeComplexity(project)

    // Historical data from similar projects
    historical := getHistoricalCosts(workflow.Type, complexity)

    // Current SME knowledge size affects context
    smeTokens := estimateSMETokens(project.SMEKnowledge)

    estimate := &CostEstimate{
        MinCost:    historical.P25 * (1 + float64(smeTokens)/10000),
        MaxCost:    historical.P95 * (1 + float64(smeTokens)/10000),
        LikelyCost: historical.Median * (1 + float64(smeTokens)/10000),
    }

    // Add warning if estimate is high
    if estimate.MaxCost > project.Budget * 0.5 {
        estimate.Warning = fmt.Sprintf(
            "This workflow may use up to %.0f%% of remaining budget",
            (estimate.MaxCost / project.Budget) * 100,
        )
    }

    return estimate, nil
}
```

### Pre-Execution Confirmation UI

```typescript
interface CostConfirmation {
  estimate: CostEstimate;
  budgetRemaining: number;
  percentOfBudget: number;
  requiresApproval: boolean;  // True if > threshold
}

// Show before starting expensive workflows
async function confirmWorkflowCost(workflow: Workflow): Promise<boolean> {
  const estimate = await api.estimateWorkflowCost(workflow.id);

  if (estimate.maxCost > settings.confirmationThreshold) {
    return await showCostConfirmationDialog({
      title: "Cost Estimate",
      message: `This workflow is estimated to cost $${estimate.likelyCost.toFixed(2)} (range: $${estimate.minCost.toFixed(2)} - $${estimate.maxCost.toFixed(2)})`,
      budgetImpact: `${estimate.percentOfBudget}% of remaining monthly budget`,
      actions: [
        { label: "Proceed", action: "confirm" },
        { label: "Cancel", action: "cancel" },
      ]
    });
  }
  return true;
}
```

### Real-Time Cost Tracking

```go
type CostTracker struct {
    currentCost  atomic.Value  // float64
    budget       float64
    thresholds   []CostThreshold
    broadcaster  EventBus
}

func (ct *CostTracker) RecordUsage(usage TokenUsage) {
    cost := calculateCost(usage)
    newTotal := ct.currentCost.Load().(float64) + cost
    ct.currentCost.Store(newTotal)

    // Check thresholds and notify
    for _, threshold := range ct.thresholds {
        if newTotal >= threshold.Amount && !threshold.Triggered {
            threshold.Triggered = true
            ct.broadcaster.Publish(&CostThresholdEvent{
                Threshold: threshold,
                Current:   newTotal,
                Budget:    ct.budget,
            })
        }
    }

    // Broadcast real-time update to UI
    ct.broadcaster.Publish(&CostUpdateEvent{
        Current:    newTotal,
        Budget:     ct.budget,
        Percentage: (newTotal / ct.budget) * 100,
    })
}
```

### Usage Dashboard

```go
type UsageDashboard struct {
    Period         string       `json:"period"`  // "daily", "weekly", "monthly"
    TotalCost      float64      `json:"totalCost"`
    TotalTokens    int64        `json:"totalTokens"`
    BudgetUsed     float64      `json:"budgetUsed"`      // Percentage
    BudgetRemaining float64     `json:"budgetRemaining"` // Dollar amount
    CostByProject  []ProjectCost `json:"costByProject"`
    CostByAgent    []AgentCost   `json:"costByAgent"`
    CostTrend      []DailyCost   `json:"costTrend"`
    Projections    Projections   `json:"projections"`
}

type Projections struct {
    EndOfMonth     float64 `json:"endOfMonth"`     // Projected total
    DaysUntilLimit int     `json:"daysUntilLimit"` // At current rate
    Recommendation string  `json:"recommendation"` // e.g., "On track" or "Reduce usage by 20%"
}

func (s *DashboardService) GetUsageDashboard(ctx context.Context, orgID string) (*UsageDashboard, error) {
    usage := s.usageStore.GetCurrentPeriodUsage(ctx, orgID)
    budget := s.configStore.GetOrgBudget(ctx, orgID)

    // Calculate projections
    daysElapsed := time.Since(usage.PeriodStart).Hours() / 24
    daysRemaining := 30 - daysElapsed
    dailyRate := usage.TotalCost / daysElapsed
    projected := usage.TotalCost + (dailyRate * daysRemaining)

    return &UsageDashboard{
        Period:          "monthly",
        TotalCost:       usage.TotalCost,
        BudgetUsed:      (usage.TotalCost / budget.MonthlyLimit) * 100,
        BudgetRemaining: budget.MonthlyLimit - usage.TotalCost,
        Projections: Projections{
            EndOfMonth:     projected,
            DaysUntilLimit: int(budget.MonthlyLimit - usage.TotalCost) / int(dailyRate),
            Recommendation: getRecommendation(projected, budget.MonthlyLimit),
        },
        // ... breakdown by project, agent, etc.
    }, nil
}
```

### Budget Controls

| Control | Scope | Behavior |
|---------|-------|----------|
| Pre-confirmation | Workflow | Require approval for estimates > $X |
| Soft limit | Organization | Warn at 80%, alert at 90% |
| Hard limit | Organization | Block new workflows at 100% |
| Per-project cap | Project | Optional sub-budget allocation |
| Daily ceiling | User | Prevent individual runaway usage |

### Cost Estimation

```go
func EstimateRequestCost(req *LLMRequest) float64 {
    inputTokens := estimateTokens(req.Messages)
    outputTokens := estimateOutputTokens(req.TaskType)
    return calculateCost(req.Model, inputTokens, outputTokens)
}
```

### Budget Check

```go
func (be *BudgetEnforcer) CheckBudget(ctx context.Context, orgID string, estimatedCost float64) error {
    usage, _ := be.usageStore.GetCurrentPeriodUsage(ctx, orgID)
    budget, _ := be.configStore.GetOrgBudget(ctx, orgID)

    if usage.TotalCost + estimatedCost > budget.MonthlyLimit {
        return ErrBudgetExceeded
    }
    return nil
}
```

### Alert Thresholds

| Threshold | Notification |
|-----------|--------------|
| 50% | Info to admins |
| 80% | Warning to admins |
| 90% | Warning to all users |
| 100% | Block + critical alert |

## Related

- [Cost Management](../architecture/cost-management.md)
- [LLM Resilience](../architecture/llm-resilience.md)
