# Technical Writing Guide

## Core Principles

### 1. Clarity Over Cleverness
Write to be understood, not to impress. Your goal is to transfer knowledge efficiently.

**Good**: "The API returns a 404 if the user doesn't exist."
**Bad**: "In the event that the specified user entity cannot be located within the persistent data store, the system shall respond with an HTTP status code of 404."

### 2. Be Concise
Every word should earn its place. Remove filler words and redundancy.

**Good**: "Use environment variables for configuration."
**Bad**: "It is generally recommended that you should probably use environment variables for the purpose of configuration."

Eliminate:
- "basically", "actually", "simply", "just"
- "It should be noted that"
- "It is important to remember that"
- "In order to" (use "to")

### 3. Active Voice
Write in active voice when possible. It's clearer who does what.

**Good**: "The service validates the token."
**Bad**: "The token is validated by the service."

**Good**: "Pass the API key in the header."
**Bad**: "The API key should be passed in the header."

### 4. Specific Over Vague
Use concrete details instead of abstract descriptions.

**Good**: "The cache expires after 5 minutes."
**Bad**: "The cache expires after a reasonable amount of time."

**Good**: "Supports files up to 10MB."
**Bad**: "Supports reasonably sized files."

## Avoiding AI-Generated Fluff

Modern AI tools produce predictable patterns. Avoid them:

### Red Flags
- Starting with "In today's..." or "In the world of..."
- Overuse of "robust", "seamless", "cutting-edge", "innovative"
- Phrases like "It's worth noting that" or "It's important to understand"
- Lists of obvious benefits without trade-offs
- Concluding with "In conclusion" or restating everything

### Write Like a Human
**Good**: "This library is fast but uses more memory."
**AI-style**: "This robust, cutting-edge library seamlessly delivers blazing-fast performance while maintaining enterprise-grade reliability."

## Structure

### Use Headings
Break up text with clear headings. Readers scan before reading.

### Use Lists
Lists are easier to scan than paragraphs.

**Good**:
```markdown
Prerequisites:
- Node.js 18 or higher
- PostgreSQL 14+
- Redis (optional, for caching)
```

**Bad**:
"Before getting started, you'll need Node.js version 18 or higher, as well as PostgreSQL 14 or above. Redis is also recommended if you want caching support."

### Code Examples
Show, don't just tell. Include working code examples.

**Good**:
```markdown
Create a new task:

```javascript
const task = await createTask({
  title: 'Write documentation',
  dueDate: '2026-01-30'
});
```
```

**Bad**:
"You can create tasks by calling the createTask function with a title and due date."

## Technical Accuracy

### Be Precise
Don't approximate technical details.

**Good**: "Requires Node.js 18.0.0 or higher"
**Bad**: "Requires a recent version of Node.js"

**Good**: "Returns a 401 if authentication fails"
**Bad**: "Returns an error if authentication fails"

### Acknowledge Limitations
Be honest about what doesn't work or what's not supported.

**Good**: "Currently doesn't support nested transactions."
**Bad**: [Silently omits this limitation]

### Explain Trade-offs
Every technical decision has pros and cons. Document both.

**Good**: "We use Redis for session storage. This is faster than database storage but requires running an additional service."
**Bad**: "We use Redis for session storage because it's the best option."

## Documentation-Specific Guidelines

### README Files
- Start with what it does (not the history of the project)
- Put installation/quick start near the top
- Keep it scannable (headings, lists, code blocks)

### API Documentation
- Show request and response examples
- Document error cases, not just success
- Include authentication requirements
- Specify required vs. optional parameters

### Code Comments
- Explain "why", not "what" (code shows what)
- Comment non-obvious decisions
- Don't comment obvious code
- Keep comments updated when code changes

**Good**:
```javascript
// Using Set for O(1) lookup performance with large lists
const uniqueIds = new Set(ids);
```

**Bad**:
```javascript
// Create a new Set from the ids array
const uniqueIds = new Set(ids);
```

## Common Mistakes

### 1. Writing for the Wrong Audience
Know who's reading. Documentation for end-users is different from documentation for developers.

### 2. Assuming Too Much Knowledge
Define acronyms on first use. Don't assume readers know your domain.

### 3. Not Updating Docs
Outdated documentation is worse than no documentation. Update docs when code changes.

### 4. Over-Explaining Basics
Don't explain what JavaScript is in a Node.js library's docs. Trust readers know the fundamentals.

### 5. No Examples
Abstract explanations without examples are hard to follow. Show what you mean.

## Checklist

Before publishing documentation, ask:

- [ ] Is it clear what this is and what it does?
- [ ] Can someone follow the quick start without prior knowledge?
- [ ] Are all code examples tested and working?
- [ ] Are technical details accurate and specific?
- [ ] Have I removed filler words and AI-generated fluff?
- [ ] Are errors and edge cases documented?
- [ ] Is it scannable (headings, lists, not walls of text)?
- [ ] Have I explained "why" for non-obvious decisions?

## Resources

- [Hemingway Editor](http://hemingwayapp.com/) - Highlights complex sentences
- [Vale](https://vale.sh/) - Linting for prose
- [Write the Docs](https://www.writethedocs.org/) - Community for technical writers

## Remember

Good documentation is:
- **Clear**: Easy to understand
- **Concise**: Respects the reader's time
- **Accurate**: Technically correct
- **Current**: Kept up to date
- **Honest**: Acknowledges limitations

Write documentation you'd want to read.
