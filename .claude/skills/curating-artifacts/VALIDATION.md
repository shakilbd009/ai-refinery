# Validation

## Validation Checklist

Before marking curation complete:

### Completeness
- [ ] All source artifacts mapped to targets
- [ ] No file exceeds 300 lines
- [ ] overview.md has executive summary
- [ ] requirements.md has acceptance criteria
- [ ] Each component has merged L1+L2+L3 doc

### Decisions & Edge Cases
- [ ] ADRs indexed with summaries
- [ ] Edge cases split by category
- [ ] All decisions have rationale

### Security & Operations
- [ ] Security threat model included
- [ ] Compliance docs included (if applicable)
- [ ] Operations runbooks included
- [ ] Performance analysis included

### Quality
- [ ] Trade-offs summarized
- [ ] No TBDs or placeholders remain
- [ ] Internal links work

## Validation Process

**Feedback loop**: Run validation → fix errors → repeat until all checks pass.

1. **Verify completeness**
   - All curated files exist
   - No file exceeds 300 lines
   - No broken internal links
   - **If issues found**: Return to Phase 2, dispatch fix tasks in parallel

2. **Verify content quality**
   - No TBDs or placeholders
   - All decisions have rationale
   - Edge cases have handling strategies
   - **If issues found**: Return to Phase 2, dispatch fix tasks in parallel

3. **Update status** (only after all validations pass)
   - Mark idea as "curated" in registry
   - Create `07-curated/status.md` with checklist

## Error Handling

| Error | Resolution |
|-------|------------|
| Missing 06-design-l3 artifacts | Cannot curate - complete refinement first |
| File exceeds 300 lines | Split into focused sub-documents |
| Missing ADRs | Create ADRs for undocumented decisions |
| Broken links | Fix paths before completing |
| TBDs found | Resolve or document as explicit assumptions |
| No standalone edge-cases file | Extract edge cases from component L3 docs |
| No monitoring file | Extract from runbooks or create minimal placeholder |
| ADRs scattered across stages | Scan all `*/ADR-*.md`, not just 03-trade-offs |
