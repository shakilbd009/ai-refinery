# README.md Writing Guide

## Purpose

The README is the front door to your project. It should help someone understand what the project does and get started quickly. Assume the reader knows nothing about your project.

## Structure

### 1. Project Title and Description (Required)
- Clear, descriptive title
- One-line description of what it does
- Optional: Badge/shields (build status, version, etc.)

### 2. Quick Start (Required)
- Installation instructions
- Minimal example to get something working
- Link to more detailed documentation if needed

### 3. Features (If Applicable)
- What can users do with this?
- Key capabilities (bulleted list)
- Don't list everything - highlight what matters

### 4. Usage (Required)
- Common use cases with examples
- Code snippets showing typical usage
- Screenshots/GIFs if it's a visual tool

### 5. Documentation (If Applicable)
- Link to full documentation
- API reference location
- Additional resources

### 6. Contributing (If Open Source)
- How to contribute
- Development setup
- Testing guidelines

### 7. License (If Applicable)
- License type
- Link to full license text

## Tone and Style

**DO**:
- Start with the most important information
- Use concrete examples
- Write for busy people who scan
- Make the first run experience smooth
- Show, don't just tell (use code examples)

**DON'T**:
- Bury important info below the fold
- Use marketing speak or hype
- Assume prior knowledge of your project
- Write walls of text without structure
- Include outdated examples or instructions

## Examples

### Good Example
```markdown
# json-validator

Fast JSON schema validation for Node.js

## Install

```bash
npm install json-validator
```

## Quick Start

```javascript
const { validate } = require('json-validator');

const schema = {
  type: 'object',
  properties: {
    name: { type: 'string' },
    age: { type: 'number' }
  },
  required: ['name']
};

const result = validate(data, schema);
if (!result.valid) {
  console.error(result.errors);
}
```

## Features

- JSON Schema draft-07 support
- Fast validation (benchmarked at 50k validations/sec)
- Clear error messages with paths
- TypeScript definitions included

## Documentation

Full API documentation: [docs/api.md](docs/api.md)

## License

MIT
```

### Bad Example
```markdown
# json-validator

Welcome to json-validator, the most amazing, revolutionary JSON validation library ever created! We've worked tirelessly to bring you the best possible experience...

[continues with marketing fluff]

## About This Project

This project started when I was frustrated with existing solutions...

[continues with unnecessary backstory]

## Installation

First, make sure you have Node.js installed. You can download it from nodejs.org. Then open your terminal and navigate to your project directory...

[continues with overly detailed generic instructions]
```

## Tips

1. **Test your Quick Start**: Can someone actually get it working from these instructions?
2. **Keep it current**: Outdated READMEs are worse than no README
3. **Link, don't duplicate**: Point to detailed docs instead of duplicating everything
4. **Use formatting**: Headers, code blocks, and lists improve scannability
5. **Show real examples**: Not `foo` and `bar`, but actual use cases

## Length

Aim for 100-300 lines for most projects. Users should be able to understand and start using your project in under 5 minutes of reading.

## Special Cases

### Library/Package
- Focus on installation and API examples
- Show common use cases first
- Link to full API reference

### Application/Tool
- Focus on what it does and how to run it
- Include screenshots if it has a UI
- Explain configuration options

### Framework/Starter
- Quick start is critical
- Show the fastest path to "hello world"
- Link to detailed guides for deeper topics
