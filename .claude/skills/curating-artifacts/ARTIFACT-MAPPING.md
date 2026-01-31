# Artifact Mapping

Source files from stages 1-6 map to curated output as follows:

| Source (stages 1-6) | Target (07-curated/) |
|---------------------|-------------------|
| 01-brainstorm/idea.md | overview.md (partial) |
| 02-requirements/requirements.md | requirements.md |
| 03-trade-offs/*trade-off*.md | trade-offs.md |
| 03-trade-offs/*recommendation*.md | trade-offs.md |
| 04-design-l1/architecture*.md | architecture/overview.md |
| 04-design-l1/database-schema.md | architecture/data-model.md |
| 04-design-l1/api-contracts.md | architecture/api-contracts.md |
| 04-design-l1/*-L1.md | architecture/components/*.md (merged) |
| 05-design-l2/*-L2.md | architecture/components/*.md (merged) |
| 06-design-l3/*-L3.md | architecture/components/*.md (merged) |
| 06-design-l3/edge-cases*.md | edge-cases/*.md (split by category) |
| 06-design-l3/security-threat-model.md | security/threat-model.md |
| 06-design-l3/compliance-*.md | security/compliance/*.md |
| 06-design-l3/operational-runbooks.md | operations/runbooks.md |
| 06-design-l3/monitoring*.md | operations/monitoring.md |
| 06-design-l3/performance-analysis.md | performance.md |
| 03-trade-offs/ADR-*.md (or */ADR-*.md) | decisions/ADR-*.md |

## Mapping Rules

1. **One-to-one**: Direct copy with cleanup (remove exploration notes)
2. **Many-to-one**: Merge related files (L1+L2+L3 → single component doc)
3. **One-to-many**: Split by category (edge-cases → data-boundaries, timing, etc.)

## Source Location Notes

- **ADRs**: Typically in `03-trade-offs/` but may appear in any stage. Scan all `*/ADR-*.md` files.
- **Monitoring**: May be in `06-design-l3/monitoring*.md` or embedded in `operational-runbooks.md`. Extract if present.
- **Edge cases**: May be standalone `06-design-l3/edge-cases*.md` or embedded in component L3 docs. Extract from either location.

## Component Merging

For each component, merge progressive deepening:

```
04-design-l1/<component>-L1.md  ─┐
05-design-l2/<component>-L2.md  ─┼──► architecture/components/<component>.md
06-design-l3/<component>-L3.md  ─┘
```

**Naming flexibility**: Component files may use different patterns:
- `<component>-L1.md` (suffix style)
- `L1-<component>.md` (prefix style)
- `<component>.md` in `stage-4/L1/` subdirectory

Match on component name, not exact pattern.

## Edge Case Splitting

Split comprehensive edge case docs by category:

```
06-design-l3/edge-cases*.md ──► edge-cases/data-boundaries.md
                            ──► edge-cases/state-transitions.md
                            ──► edge-cases/timing.md
                            ──► edge-cases/integration.md
```
