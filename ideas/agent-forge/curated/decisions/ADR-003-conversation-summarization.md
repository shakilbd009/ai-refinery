# ADR-003: Conversation Summarization for Memory

## Status
Accepted

## Context
Long conversations exceed context window limits. Options:
1. Truncate old messages (loses context)
2. Keep everything (exceeds limits)
3. Summarize older turns (preserves meaning, fits limits)

## Decision
Use **summarization** for conversation memory:

- Last N turns (default ~10) included verbatim for full fidelity
- Older turns compressed into structured summaries containing:
  - Key decisions made
  - Important facts established
  - Open questions identified
  - User preferences noted

Summarization triggers:
- Conversation exceeds token threshold
- User explicitly changes topic
- Agent completes a major subtask

Structured artifacts (user stories, architecture decisions) stored separately and retrieved via tools when needed.

## Consequences

### Positive
- Preserves context without token explosion
- Recent conversation maintains full nuance
- Summaries capture what matters, not verbatim text
- Artifacts don't consume conversation context

### Negative
- Summarization may lose subtle details
- Additional LLM calls for summarization (cost)
- Summary quality depends on LLM capability

### Mitigations
- Keep recent turns verbatim for nuance preservation
- Structured summary format ensures key info captured
- Artifact retrieval provides precise access when needed
