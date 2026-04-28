---
name: debug
description: Use when the user reports a bug, error, or unexpected behavior and wants it diagnosed or fixed.
---

# debug

Diagnose and fix bugs systematically.

## When to use

Use when the user reports a bug, error, or unexpected behavior.

## Workflow

1. Reproduce: understand the exact steps that trigger the issue.
2. Read the error: stack traces, log messages, and error codes.
3. Locate: search for the relevant code path.
4. Hypothesize: form a theory about the root cause.
5. Verify: add logging or read surrounding code to confirm.
6. Fix: make the minimal change that addresses the root cause.
7. Test: verify the fix works and does not break other things.

## Rules

- Read the error message carefully before searching code.
- Do not guess; verify the hypothesis before changing code.
- Fix the root cause, not the symptom.
- Do not retry the same approach if it failed; investigate why.
- If stuck after three attempts, explain what was tried and ask for help.
