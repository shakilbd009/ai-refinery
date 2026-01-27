# Edge Cases: Agent Execution

## LLM Provider Failures

### Timeout During Generation

**Trigger:** LLM takes >30s to respond

**Impact:** Task incomplete, user waiting

**Mitigation:**
- Checkpoint after each tool call
- Timeout at 30s with retry
- After 2 retries, surface "taking longer than expected" with options
- User can: wait, retry, or escalate

### Malformed Response

**Trigger:** LLM returns invalid JSON or unexpected format

**Impact:** Cannot parse artifacts

**Mitigation:**
- Retry once with explicit format reminder in prompt
- If still malformed, extract what's parseable
- Log for analysis
- Proceed with partial data, flag uncertainty

### Rate Limiting

**Trigger:** LLM provider returns 429

**Impact:** Cannot process requests

**Mitigation:**
- Exponential backoff (1s, 2s, 4s, 8s)
- Max 4 retries
- Queue requests if sustained
- Surface "high demand" message after 30s total wait

---

## Tool Execution Failures

### Tool Not Found

**Trigger:** Agent requests tool that doesn't exist

**Impact:** Cannot gather required information

**Mitigation:**
- Return clear error to agent
- Agent should rephrase or use alternative tool
- Log unexpected tool requests for prompt improvement

### Tool Returns Error

**Trigger:** Tool execution fails (e.g., file not found)

**Impact:** Missing information for task

**Mitigation:**
- Return error message to agent
- Agent decides: retry, alternative approach, or ask user
- Include error in agent's context for adaptation

### Tool Timeout

**Trigger:** Tool takes >10s

**Impact:** Slow task execution

**Mitigation:**
- Cancel and retry once
- If still slow, proceed without that data
- Note gap in output

---

## Context Management

### Context Window Exceeded

**Trigger:** Conversation + artifacts > model limit

**Impact:** Cannot process further

**Mitigation:**
- Proactive summarization at 70% capacity
- Aggressive summarization at 90%
- Archive old conversation turns
- Keep recent turns + all approved artifacts

### Summarization Loses Critical Detail

**Trigger:** Important nuance in old message not captured

**Impact:** Agent misses requirement

**Mitigation:**
- Summarization includes explicit "key decisions" section
- User can flag messages as "important" (never summarize)
- Approved artifacts are never summarized

---

## Self-Critique Loop

### Infinite Critique Loop

**Trigger:** Agent keeps finding issues with own output

**Impact:** Never produces result

**Mitigation:**
- Max 3 self-critique iterations
- After 3, present best attempt with caveats
- Flag uncertainty areas explicitly

### Self-Critique Misses Obvious Issue

**Trigger:** Agent approves output that violates constraint

**Impact:** LLM-judge catches it, wasted iteration

**Mitigation:**
- Self-critique prompt includes constraint checklist
- LLM-judge is authoritative (self-critique is optimization)
- Track self-critique accuracy for prompt tuning

---

## Constraint Validation

### LLM-Judge Disagrees with Agent

**Trigger:** Agent believes output is compliant, judge finds violation

**Impact:** Retry loop

**Mitigation:**
- Judge feedback includes specific violation
- Agent receives feedback for targeted fix
- Max 3 retries before escalation
- Escalation shows all attempts

### Conflicting Constraints

**Trigger:** Two constraints cannot both be satisfied

**Impact:** Cannot produce valid output

**Mitigation:**
- Detect conflict during validation
- Escalate immediately with both constraints
- User resolves by: adjusting constraint, providing exception, or editing

### Judge Produces False Positive

**Trigger:** Judge flags valid output as violation

**Impact:** Unnecessary retry, possible escalation

**Mitigation:**
- Include constraint examples in judge prompt
- User can override at escalation
- Track false positive rate for tuning
