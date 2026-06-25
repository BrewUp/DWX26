# DWX26 — Spec-Driven Development Demo

> Demo repository for the DWX 2026 talk
> **Spec-Driven Development — Redefining the Software Architect in the AI Era**

This repository contains the code, specifications, and Spec Kit custom agents used for the DWX 2026 session about **Spec-Driven Development**, Domain-Driven Design, and AI-assisted software architecture.

The goal of this repository is not to show how to make an AI agent generate more code.

The goal is to show how to make domain decisions explicit, durable, inspectable, and reusable across the AI-assisted development workflow.

---

## Talk thesis

AI can generate code, tests, plans, and architectural sketches faster than ever.

That is not the hard part anymore.

The hard part is preserving **domain intent** while AI systems generate plausible but subtly wrong artifacts.

In this demo, we use Spec-Driven Development to show how specifications can become a durable reasoning environment for both humans and AI agents.

> A prompt asks for output.
> A specification records decisions that future outputs must respect.

---

## The domain: BrewUp

The demo uses **BrewUp**, a brewery domain.

The running story is about confirming a Sales Order.

At first glance, the feature seems simple:

```text
A Sales Order can be confirmed when:
- the customer payment has been authorized;
- all requested beers have been reserved in the warehouse.
```

However, this simple requirement hides a critical architectural question:

```text
Who owns each decision?
```

For this story, BrewUp has three separate domain authorities:

```text
Sales        — commercial commitment
Payment      — payment authorization
Warehouse    — physical stock
```

Sales depends on Payment and Warehouse outcomes, but it does not own the processes that produce them.

This distinction is the core of the demo.

---

## The problem shown in the demo

A plausible AI-generated model may produce something like this:

```text
Sales Order
 ├── Payment
 └── WarehouseReservation
```

and a method such as:

```csharp
public void Confirm()
{
    Payment.Authorize(Total);

    foreach (var line in Lines)
        WarehouseReservation.Reserve(line.BeerId, line.Quantity);

    Status = OrderStatus.Confirmed;
}
```

The code may compile.

The tests may be green.

The demo may even work.

But the model is still wrong.

It assigns Payment and Warehouse decisions to the Sales Order aggregate.

The problem is not class size.

The problem is **decision authority**.

---

## What Spec-Driven Development adds

This repository demonstrates a workflow where domain decisions are captured before implementation planning starts.

The specification records:

* ubiquitous language;
* bounded-context ownership;
* external decision references;
* confirmation invariants;
* forbidden responsibilities;
* open questions;
* architectural guardrails.

The important concept is that uncertainty should not be hidden.

If a business decision is missing, the agent must preserve it as an explicit question instead of silently choosing a default.

---

## Core design idea

Sales does not embed Payment or Warehouse models.

Instead, Sales stores references to external decisions:

```text
PaymentAuthorizationId
StockReservationId
```

These references are evidence that another bounded context made a decision Sales depends on.

They are not a way to load or manipulate another aggregate.

> Dependency on a decision is not ownership of the decision.

---

## Repository structure

```text
.
├── .github/
│   ├── agents/
│   │   ├── speckit.*.agent.md
│   │   └── speckit.brewup.*.agent.md
│   ├── prompts/
│   └── copilot-instructions.md
│
├── .specify/
│   ├── memory/
│   │   ├── constitution.md
│   │   └── domain-carriers/
│   │       └── brewup-sales-order-confirmation.md
│   ├── extensions.yml
│   └── ...
│
├── src/
│   └── demo source code
│
├── README.md
└── LICENSE
```

---

## Spec Kit workflow

The demo follows the Spec Kit flow:

```text
specify  →  clarify  →  plan  →  tasks  →  analyze
```

In this repository, the standard Spec Kit workflow is extended with BrewUp-specific guardrails.

The goal is not to make the AI deterministic.

The goal is to make the non-negotiable domain decisions explicit and verifiable.

---

## Custom BrewUp Spec Kit agents

The repository includes custom Spec Kit agents under:

```text
.github/agents/
```

These agents act as domain-specific quality gates.

### `speckit.brewup.load-domain-context`

Runs before specification.

It loads the BrewUp Sales Order domain context and makes the domain rules explicit before `/speckit.specify` creates the feature specification.

It prepares the reasoning environment.

It does not generate code.

---

### `speckit.brewup.domain-guard`

Runs after specification.

It validates that the generated specification respects Sales, Payment, and Warehouse ownership.

It checks that Sales does not embed Payment or Warehouse models and that unresolved business decisions remain visible.

---

### `speckit.brewup.plan-readiness`

Runs before planning.

It checks whether the specification contains enough domain authority, external references, confirmation invariants, and open questions to generate a technical plan safely.

It prevents the plan from being generated from an underspecified domain model.

---

### `speckit.brewup.plan-guard`

Runs after planning.

It detects architectural drift in the generated implementation plan.

The main failure it catches is the plan reintroducing the original wrong design: Sales Order containing Payment or WarehouseReservation, or a `Confirm()` method that authorizes payment and reserves stock directly.

---

### `speckit.brewup.task-guard`

Runs after task generation.

It validates that generated tasks do not turn external decisions or unresolved business policies into implementation work inside Sales.

It protects the implementation backlog from architectural drift.

---

## Hook configuration

The Spec Kit hooks are configured in:

```text
.specify/extensions.yml
```

The intended workflow is:

```text
before_specify  -> speckit.brewup.load-domain-context
after_specify   -> speckit.brewup.domain-guard
before_plan     -> speckit.brewup.plan-readiness
after_plan      -> speckit.brewup.plan-guard
after_tasks     -> speckit.brewup.task-guard
```

The hooks are deliberately visible in the workflow.

For the conference demo, the important part is not automation magic.

The important part is showing that every stage can be checked against explicit domain rules.

---

## Domain carrier

The initial domain rules live in:

```text
.specify/memory/domain-carriers/brewup-sales-order-confirmation.md
```

This file exists before the feature specification is generated.

It solves the bootstrap problem:

```text
/specify creates the feature folder
but the first specification already needs domain rules
```

The domain carrier contains the pre-specification domain input:

* Sales, Payment, and Warehouse authority;
* ubiquitous language;
* bounded-context rules;
* external decision references;
* forbidden responsibilities;
* confirmation invariant;
* unresolved questions.

The generated feature specification must preserve these rules inside `spec.md`.

---

## Bounded Context rules

The demo uses explicit bounded-context rules, identified as `BC-001`, `BC-002`, and so on.

Examples:

```text
BC-003 — Payment owns authorization outcomes.
BC-007 — Warehouse owns stock mutation.
BC-009 — External decision references, not embedded models.
```

This allows generated artifacts to be reviewed against named architectural decisions.

Instead of saying:

```text
This plan feels wrong.
```

we can say:

```text
This plan violates BC-003, BC-007, and BC-009.
```

That is the point of Spec-Driven Development in this demo.

---

## Running the demo

Clone the repository:

```bash
git clone https://github.com/BrewUp/DWX26.git
cd DWX26
```

Open the repository with an environment that supports the installed Spec Kit agent integration.

The expected demo flow is:

```text
1. Load domain context
2. Create the feature specification
3. Run clarification
4. Generate the technical plan
5. Detect plan drift
6. Generate tasks
7. Guard the implementation backlog
8. Analyze consistency across artifacts
```

The demo can be run live or from prepared checkpoints.

For a conference talk, prepared outputs are recommended.

The message is the workflow, not the unpredictability of a live model.

---

## Demo narrative

The talk follows this progression:

1. A plausible AI-generated aggregate looks correct.
2. The model compiles and tests pass.
3. The model is still wrong because it assigns decision authority to the wrong bounded context.
4. The domain language is made explicit.
5. External decision references replace embedded external models.
6. The specification records the decisions.
7. The plan may still drift.
8. The guardrails make the drift inspectable.

The key message is:

> SDD does not guarantee obedience.
> It makes architectural drift inspectable.

---

## What this repository is

This repository is:

* a conference demo;
* a Spec Kit workflow experiment;
* a DDD and SDD teaching artifact;
* a controlled example of AI-assisted architectural governance.

It is not:

* a complete ERP;
* a production-ready BrewUp implementation;
* a general-purpose Spec Kit extension;
* a claim that AI agents become deterministic.

---

## Key takeaways

* AI accelerates ambiguity unless the domain is explicit.
* A longer prompt is still a conversation.
* A specification is an authoritative artifact.
* Reacting to an external decision is not owning that decision.
* External references are evidence, not embedded models.
* The architect’s job is shifting toward designing reasoning environments.

---

## Speakers

**Alberto Acerbis**
Software Architect, trainer, Microsoft MVP, co-author of *Domain-Driven Refactoring*.

**Alessandro Colla**
Software Architect, trainer, co-author of *Domain-Driven Refactoring*.

---

## License

This repository is licensed under the MIT License.
