---
name: diagnose
description: Use when the user asks why an agent run failed, regressed, or produced unexpected output.
---

# diagnose

Diagnose why an agent run failed, regressed, or produced unexpected output using structured evidence instead of intuition.

## When to use

Use when the user asks:

- "Why did this run fail?"
- "What changed between this run and the last one?"
- "The output looks wrong. What happened?"
- "Why is this run worse than before?"

## Workflow

1. Locate the run artifacts. Check `artifacts/runs/<run_id>/` or the latest run directory for:
   - `manifest.json`: run metadata, task type, input hash, timestamps.
   - `execution_trace.jsonl`: the full tool-call chain, one event per line.
   - `verification_report.json`: what was verified and whether it passed.
   - `failure_signature.json`: which stage failed and why, if present.
2. Read the failure signature first if it exists.
3. Trace the execution chain forward to find where output diverged from expectation.
4. Compare with a passing run, if one exists, by diffing manifests and traces.
5. Identify the failure layer: routing, execution, verification, or governance.
6. Report with evidence: cite specific file paths, line numbers in the trace, or field values.

## Rules

- Evidence before intuition: always read the trace before forming a hypothesis.
- Localize before explaining: identify which stage failed before describing why.
- Compare, do not guess: if a previous run succeeded, diff it.
- If no artifacts exist, say so clearly and ask the user to rerun with archive mode enabled.
