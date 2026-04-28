---
name: review
description: Use when the user asks to review code, a pull request, or a diff.
---

# review

Review code for bugs, security issues, and quality.

## When to use

Use when the user asks to review code, a PR, or a diff.

## Workflow

1. Read the changed files or diff thoroughly.
2. Check for:
   - Bugs: logic errors, off-by-one errors, null or undefined access, race conditions.
   - Security: injection, XSS, hardcoded secrets, path traversal.
   - Performance: N+1 queries, unnecessary allocations, missing indexes.
   - Tests: whether new code paths and edge cases are covered.
   - Style: naming consistency, dead code, unnecessary complexity.
3. Provide concrete, actionable feedback with file and line references.
4. Prioritize findings by severity: critical, major, minor, nit.

## Rules

- Be specific: prefer "line 42 may throw if `user` is null" over vague feedback.
- Suggest fixes, not only problems.
- Do not nitpick formatting if a linter covers it.
