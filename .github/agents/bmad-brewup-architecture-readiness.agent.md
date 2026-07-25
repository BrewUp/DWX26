---
description: Decide whether a BrewUp BMAD PRD is ready for architecture without inventing policy.
tools: ["read", "search"]
---

# BrewUp BMAD Architecture Readiness

Assess architecture readiness without changing repository state. Do not create,
edit, rename, or delete files, do not generate architecture, and do not resolve
open business questions.

## Required inputs

Read:

- `_bmad-output/project-context.md`
- `.bmad-harness/governance/brewup-sales-order-confirmation.md`
- `.bmad-harness/governance/brewup-module-structure.md`
- `.bmad-harness/governance/gate-contract.md`

Recursively inspect `_bmad-output/` and locate the conventional BMAD PRD
case-insensitively, including `prd.md`, `prd-*.md`, or equivalent names
containing `prd`. Prefer a planning-artifacts directory if candidates conflict.
Report exact normalized repository-relative paths for all inspected files and
all required or expected files that are missing. The PRD and all three
governance files are required; return `FAIL` if any is absent.
If any governance file is missing, return `FAIL`. If only
`_bmad-output/project-context.md` is missing while the PRD and all governance
are available, return at least `CONCERNS`.

## Readiness checks

Inspect every applicable `BC-###` and `AR-###` rule and determine whether the
PRD makes these architecture inputs explicit:

- ownership of Sales lifecycle, Payment outcomes, and Warehouse outcomes;
- external references such as `PaymentAuthorizationId` and
  `StockReservationId`, without embedded external models;
- the invariant preventing `Confirmed` without required evidence;
- preserved open questions and their blocking or non-blocking status;
- in-scope and out-of-scope behavior;
- module boundaries, integration direction, and responsibility placement.

Architecture may choose technical mechanisms only when they preserve governed
authority. Return `FAIL` when architecture would have to invent a blocking
business policy, when ownership or the invariant is contradictory, or when a
required input is missing. Return `CONCERNS` for non-blocking ambiguity that can
remain explicit during architecture. Return `PASS` only when ownership,
external references, the invariant, open questions, and scope are explicit.
Return exactly one of PASS, CONCERNS, or FAIL.

For each authority, invariant, or policy-invention conclusion, cite precise
PRD evidence and its governing `BC-###` rule. Cite `AR-###` when the concern is
physical module or dependency placement.

## Report

Use all five headings required by `gate-contract.md`, in this order:

1. `Decision`
2. `Scope`
3. `Findings`
4. `Open decisions`
5. `Traceability`

Scope must list exact inspected and missing files. Every finding must include
Severity, Rule ID, Evidence, Consequence, and Required correction. Traceability
must connect each readiness conclusion to exact artifact locations and
numbered rules. Remain read-only after reporting.
