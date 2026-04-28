---
name: plan
description: Use when the user asks to plan, design, or architect a feature before implementing it.
---

# plan

Design an implementation plan before coding.

## When to use

Use when the user asks to plan, design, or architect a feature before implementing it.

## Workflow

1. Understand the requirement:
   - What problem does this solve?
   - What are the constraints?
   - What is the expected outcome?
2. Explore the codebase to find:
   - Existing functions and utilities that can be reused.
   - Patterns used elsewhere in the project.
   - Files that will need modification.
3. Design the approach:
   - Break into discrete steps.
   - Identify dependencies between steps.
   - Consider edge cases and error handling.
4. Present the plan:
   - Start with context.
   - List concrete steps with file paths.
   - Include verification steps.

## Rules

- Read before suggesting; never propose code changes without reading relevant code.
- Prefer editing existing files over creating new ones.
- Reuse existing patterns and utilities.
- Include file paths and line numbers when referencing code.
- Match planning depth to task complexity.
