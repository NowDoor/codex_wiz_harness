---
name: test
description: Use when the user asks to write tests, verify behavior, or improve test coverage.
---

# test

Write and run tests for code.

## When to use

Use when the user asks to write tests, verify behavior, or improve test coverage.

## Workflow

1. Understand what needs testing:
   - New feature: write unit tests for the happy path and edge cases.
   - Bug fix: write a regression test that would have caught the bug.
   - Refactor: ensure existing tests still pass.
2. Follow the project's testing patterns:
   - Check existing tests for framework.
   - Match naming conventions and file organization.
   - Use the same fixtures and helpers.
3. Write tests that are:
   - Independent: each test can run alone.
   - Deterministic: same result every time.
   - Fast: mock external services and use in-memory stores where appropriate.
4. Run the tests and verify they pass.

## Rules

- Test behavior, not implementation details.
- Use descriptive test names that explain the scenario.
- Do not test framework or library code.
- Mock at system boundaries such as external APIs, filesystem, and network.
