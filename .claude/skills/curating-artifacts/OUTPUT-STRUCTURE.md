# Output Structure

All files kept under 300 lines for parallel agent efficiency.

```
ideas/<name>/07-curated/
├── overview.md                    # Executive summary (~100 lines)
├── requirements.md                # Functional + non-functional (~200 lines)
├── architecture/
│   ├── overview.md                # System architecture (~150 lines)
│   ├── data-model.md              # Database schema (~200 lines)
│   ├── api-contracts.md           # API specifications (~200 lines)
│   └── components/
│       ├── <component-a>.md       # Per-component design (~200 lines each)
│       └── ...
├── decisions/
│   ├── index.md                   # ADR index with summaries (~100 lines)
│   └── ADR-*.md                   # Individual ADRs (~100 lines each)
├── edge-cases/
│   ├── index.md                   # Edge case summary (~50 lines)
│   ├── data-boundaries.md         # Empty/null/max/special chars (~150 lines)
│   ├── state-transitions.md       # Concurrent/retry/out-of-order (~150 lines)
│   ├── timing.md                  # Timeout/race/long-running (~150 lines)
│   └── integration.md             # External service failures (~150 lines)
├── security/
│   ├── threat-model.md            # Security analysis (~200 lines)
│   └── compliance/
│       ├── overview.md            # Compliance summary (~100 lines)
│       └── <type>.md              # GDPR, PCI, etc. (~150 lines each)
├── operations/
│   ├── runbooks.md                # Operational procedures (~200 lines)
│   └── monitoring.md              # Alerts and metrics (~150 lines)
├── implementation/
│   └── tdd.md                     # TDD conventions (~100 lines)
├── performance.md                 # Scaling and bottlenecks (~200 lines)
└── trade-offs.md                  # Key trade-offs summary (~200 lines)
```

## File Size Guidelines

| File Type | Target Lines | Max Lines |
|-----------|--------------|-----------|
| Overview/summary docs | 50-100 | 150 |
| Component docs | 150-200 | 250 |
| ADRs | 50-100 | 150 |
| Edge case categories | 100-150 | 200 |
| Implementation docs | 80-120 | 150 |
| Index files | 30-50 | 100 |

If a file exceeds limits, split by sub-topic or component.

## Optional Files

Some files are only created if source material exists:

| File | Created When |
|------|--------------|
| `operations/monitoring.md` | stage-6 has monitoring docs or embedded in runbooks |
| `security/compliance/*.md` | Project has compliance requirements (GDPR, PCI, etc.) |
| `edge-cases/*.md` | Extracted from standalone docs OR component L3 files |
