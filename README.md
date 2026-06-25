# DWX26 — Spec-Driven Development Demo

> Demo repository for the DWX 2026 talk
> **Spec-Driven Development: Redefining the Software Architect in the AI Era**

This repository contains the demo code, specifications, prepared artifacts, and Spec Kit custom agents used for the DWX 2026 session about **Spec-Driven Development**, Domain-Driven Design, and AI-assisted software architecture.

The goal of this repository is not to show how to make an AI agent generate more code.

The goal is to show how to make domain decisions explicit, durable, inspectable, and reusable across an AI-assisted development workflow.

---

## Talk thesis

LLMs can generate code, tests, plans, and architectural sketches faster than ever.

That is no longer the hard part.

The hard part is preserving **domain intent** while AI systems generate artifacts that may look plausible, fluent, and technically correct, but still violate domain ownership.

Spec-Driven Development addresses this by turning domain language, ownership decisions, constraints, rejected assumptions, and open questions into durable specifications.

> A prompt asks for output.
> A specification records decisions that future outputs must respect.

The core message of the talk is:

> SDD does not make an LLM deterministic.
> It makes domain decisions explicit, persistent, and verifiable.

Or, more simply:

> Not deterministic output — verifiable decisions.

---

## What this repository demonstrates

This repository demonstrates how an AI-assisted development workflow can be constrained by explicit domain rules.

It shows how a model can still drift, and how that drift can be detected before it silently becomes implementation.

The important point is not that AI becomes perfect.

The important point is that violations become visible.

Instead of saying:

```text
This architecture feels wrong.
```

we can say:

```text
This plan violates BC-003, BC-007, and BC-009.
```

That is the shift from prompting to engineering discipline.

---

## The domain: BrewUp

The demo uses **BrewUp**, a brewery domain.

The running story is about confirming a Sales Order.

At first glance, the feature seems simple:

```text
Implement order confirmation for BrewUp.

An order can be confirmed when:
- the customer payment has been authorized;
- all requested beers are available in the warehouse.

When the order is confirmed, reserve the stock.
```

The request is deliberately plausible, but underspecified.

The central question is:

```text
Who owns each decision?
```

---

## BrewUp authorities in this scenario

For this demo, BrewUp has three separate authorities:

```text
Sales        — commercial commitment
Payment      — payment authorization
Warehouse    — physical stock
```

Sales and Warehouse are existing BrewUp contexts.

Payment is introduced for this talk scenario as a third separate authority, so the ownership problem is visible and explicit.

Sales owns the Sales Order lifecycle.

Payment owns payment authorization outcomes.

Warehouse owns physical stock and stock reservation outcomes.

Sales may depend on Payment and Warehouse decisions.

Sales must not own the models or processes that produce those decisions.

---

## The initial generated model

A plausible AI-generated model may produce something like this:

```text
Order
 ├── OrderLines
 ├── Payment
 └── WarehouseReservation
```

and a method such as:

```csharp
public void Confirm()
{
    Payment.Authorize(Total);

    foreach (var line in Lines)
        WarehouseReservation.Reserve(
            line.BeerId,
            line.Quantity);

    Status = OrderStatus.Confirmed;
}
```

This code may compile.

The tests may be green.

The demo may even work.

But the model is still wrong.

The problem is not class size.

The problem is not syntax.

The problem is **decision authority**.

The model assigns Payment and Warehouse decisions to the Sales Order aggregate.

---

## The key DDD distinction

Sales owns the commercial commitment.

Payment owns payment authorization.

Warehouse owns physical stock.

The Sales Order may need evidence from Payment and Warehouse, but needing evidence from another context does not mean owning that context.

> Dependency on a decision is not ownership of the decision.

This is the core DDD lesson of the demo.

---

## Corrected model direction

Sales does not embed Payment or Warehouse models.

Instead, Sales stores references to external decisions:

```text
PaymentAuthorizationId
StockReservationId
```

These references are evidence that another bounded context made a decision Sales depends on.

They are not handles for loading or mutating another aggregate.

A corrected Sales model points in this direction:

```text
Sales
┌─────────────────────────────┐
│ Sales Order                 │
│                             │
│ PaymentAuthorizationId?     │
│ StockReservationId?         │
│ Status                      │
└─────────────────────────────┘

Payment                       Warehouse
┌──────────────────────┐      ┌──────────────────────┐
│ Payment Authorization│      │ Stock Reservation    │
│                      │      │                      │
│ owns payment outcome │      │ owns stock outcome   │
└──────────────────────┘      └──────────────────────┘
```

A Sales Order may become `Confirmed` only when the required external decision references are present.

For the baseline scenario:

```text
PaymentAuthorizationId is required.
StockReservationId is required.
```

A confirmed Sales Order without evidence is an invalid state.

---

## Why this matters

The initial model is attractive because it appears to protect a strong invariant:

```text
An order must not be confirmed without payment and stock.
```

But this is not one local invariant involving three objects owned by Sales.

It is a commercial policy that depends on outcomes produced by three different authorities.

Crossing a boundary does not make the rule less important.

It changes how the rule must be represented.

---

## Spec-Driven Development in this repository

In this repository, Spec-Driven Development means:

1. Make domain language explicit.
2. Make decision ownership explicit.
3. Preserve unclear decisions as open questions.
4. Generate specifications, plans, and tasks from durable context.
5. Check generated artifacts against named rules.
6. Detect architectural drift before implementation.

The goal is not to replace architectural judgment.

The goal is to make architectural judgment durable enough for AI-assisted workflows.

---

## Spec Kit’s role

Spec Kit is the practical thread of the demo.

It is not the main subject of the talk.

The talk focuses on three visible moments:

```text
/speckit.specify
/speckit.clarify
/speckit.analyze
```

### `/speckit.specify`

Turns the feature request into a persistent specification.

The specification records:

* ubiquitous language;
* domain ownership;
* bounded-context rules;
* external decision references;
* domain invariants;
* failure semantics;
* acceptance scenarios;
* out-of-scope responsibilities.

### `/speckit.clarify`

Exposes missing domain decisions before planning.

The agent may identify ambiguity.

The domain expert must resolve it.

The specification must preserve the resolution.

### `/speckit.analyze`

Checks consistency across specification, plan, and tasks.

It turns architectural discomfort into named rule violations.

For example:

```text
CRITICAL — Bounded-context ownership violation

The implementation plan assigns payment authorization
and physical stock mutation to the Sales Order aggregate.

Conflicts:

BC-003
Payment owns authorization outcomes.

BC-007
Warehouse owns physical stock and stock reservations.

BC-009
Sales may store external decision references but must not
embed Payment or Warehouse domain models.
```

---

## Repository take-home workflow

The talk does not teach every command in depth.

The repository contains a more complete take-home workflow for people who want to inspect or replay the full loop.

The standard Spec Kit flow is extended with BrewUp-specific guardrail agents:

```text
before_specify  -> speckit.brewup.load-domain-context
after_specify   -> speckit.brewup.domain-guard
before_plan     -> speckit.brewup.plan-readiness
after_plan      -> speckit.brewup.plan-guard
after_tasks     -> speckit.brewup.task-guard
```

These custom agents are not product features of the talk.

They are a practical way to show how domain-specific rules can be checked across specification, plan, and tasks.

---

## Custom BrewUp agents

Custom agents live under:

```text
.github/agents/
```

### `speckit.brewup.load-domain-context`

Loads the BrewUp Sales Order domain context before `/speckit.specify`.

It prepares the reasoning environment by making language, ownership, external decision references, forbidden responsibilities, and open questions explicit.

It does not generate code.

It does not create the implementation plan.

Its job is to prevent the first specification from starting with generic e-commerce assumptions.

---

### `speckit.brewup.domain-guard`

Runs after `/speckit.specify`.

It validates that the generated specification respects Sales, Payment, and Warehouse ownership.

It checks that:

* Sales owns Sales Order lifecycle;
* Payment owns payment authorization outcomes;
* Warehouse owns stock reservation outcomes;
* Sales stores external decision references;
* Sales does not embed Payment or Warehouse models;
* unresolved domain decisions remain visible.

---

### `speckit.brewup.plan-readiness`

Runs before `/speckit.plan`.

It checks whether the specification contains enough domain information to generate a technical plan safely.

It blocks planning if the plan would need to invent business policy, ownership, or failure behavior.

Open questions do not automatically block planning.

They block planning only when the plan would have to resolve them silently in order to proceed.

---

### `speckit.brewup.plan-guard`

Runs after `/speckit.plan`.

It detects architectural drift in the generated plan.

The main failure it catches is the plan reintroducing the original wrong design:

```text
SalesOrder contains Payment.
SalesOrder contains WarehouseReservation.
SalesOrder.Confirm() authorizes payment and reserves stock.
```

The plan may choose a coordination mechanism.

The plan must not move decision authority into the wrong bounded context.

---

### `speckit.brewup.task-guard`

Runs after `/speckit.tasks`.

It validates that generated tasks do not turn external decisions or unresolved business policies into implementation work inside Sales.

A valid task may say:

```markdown
- [ ] Add `PaymentAuthorizationId` to SalesOrder as an external decision reference.
```

An invalid task would say:

```markdown
- [ ] Authorize payment from SalesOrder.Confirm().
```

This command protects the implementation backlog from architectural drift.

---

## Constitution and domain carrier

The repository separates global principles from feature-specific domain rules.

### Constitution

The constitution contains project-level principles.

It belongs under:

```text
.specify/memory/constitution.md
```

Examples of global principles:

```text
Do not invent business policy.
Respect bounded-context ownership.
If a decision is unclear, preserve it as an open question.
A technical plan must not introduce new domain ownership.
```

The constitution is short and global.

It is not a full domain model.

---

### Domain carrier

The domain carrier contains feature-specific domain rules.

It belongs under:

```text
.specify/memory/domain-carriers/brewup-sales-order-confirmation.md
```

This file exists before `/speckit.specify` creates the feature folder.

It solves the bootstrap problem:

```text
/specify creates the feature folder,
but the first specification already needs domain context.
```

The domain carrier contains:

* BrewUp authorities;
* ubiquitous language;
* bounded-context rules;
* external decision references;
* forbidden responsibilities;
* confirmation invariant;
* policy invention rules;
* open questions.

After `/speckit.specify`, the generated `spec.md` must preserve the numbered bounded-context rules.

---

## Bounded-context rules

The demo uses named bounded-context rules.

Examples:

```text
BC-003 — Payment owns authorization outcomes.
BC-007 — Warehouse owns stock mutation.
BC-009 — External decision references, not embedded models.
```

The numbering is intentional.

It allows generated artifacts to be reviewed against explicit architectural decisions.

Instead of saying:

```text
The plan feels wrong.
```

we can say:

```text
The plan violates BC-003, BC-007, and BC-009.
```

That is the practical value of SDD in this repository.

---

## Expected repository structure

```text
.
├── .github/
│   ├── agents/
│   │   ├── speckit.*.agent.md
│   │   └── *.brewup.speckit.agent.md
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
├── specs/
│   └── 001-sales-order-confirmation/
│       ├── spec.md
│       ├── clarify-log.md
│       ├── checklists/
│       │   └── requirements.md
│       ├── plan.md
│       ├── tasks.md
│       └── analyze-report.md
│
├── src/
│   └── demo source code
│
├── README.md
└── LICENSE
```

Some generated files may appear only after running the Spec Kit workflow.

---

## Suggested demo flow

Clone the repository:

```bash
git clone https://github.com/BrewUp/DWX26.git
cd DWX26
```

Open the repository with an environment that supports the installed Spec Kit agent integration.

A possible take-home flow is:

```text
1. Load the BrewUp domain context.
2. Create the Sales Order Confirmation specification.
3. Clarify unresolved domain decisions.
4. Generate the technical plan.
5. Check the plan for architectural drift.
6. Generate implementation tasks.
7. Check the task list before implementation.
8. Analyze consistency across artifacts.
```

The conference talk uses prepared outputs.

This repository exists so the full loop can be inspected after the session.

---

## What the talk shows

The talk is structured as an architecture review conducted in public.

It does not try to prove that AI is useless.

It does not try to prove that AI is deterministic.

It shows a more practical point:

```text
AI is useful when the reasoning environment is explicit enough
to prevent fluent guesses from becoming architecture.
```

The narrative progression is:

```text
Plausible generated solution
        ↓
Ambiguous language
        ↓
Wrong decision ownership
        ↓
Non-existent transaction boundary
        ↓
Missing failure policies
        ↓
Prompt is not durable governance
        ↓
Specification records authority
        ↓
Clarification exposes missing decisions
        ↓
External references preserve boundaries
        ↓
Analysis exposes implementation drift
        ↓
The architect becomes a context governor
```

---

## What this repository is

This repository is:

* a conference demo;
* a Spec-Driven Development experiment;
* a DDD teaching artifact;
* a take-home workflow for the talk;
* a small example of AI-assisted architectural governance.

It is not:

* a full Spec Kit tutorial;
* a benchmark of coding agents;
* a complete ERP;
* a production-ready BrewUp implementation;
* a claim that AI-generated output becomes deterministic;
* a formal verification system;
* a general-purpose Spec Kit extension package.

---

## Key takeaways

* Fluent output is not necessarily correct.
* Generic language gives the model room to make generic decisions.
* A prompt asks for output; a rule constrains future output.
* A specification records decisions that subsequent outputs must respect.
* Reacting to an external decision is not owning that decision.
* External references are evidence, not embedded models.
* Unknown business decisions must remain visible.
* SDD does not guarantee obedience; it makes architectural drift inspectable.
* The architect’s role expands to designing the reasoning environment in which AI operates.

---

## Speakers

**Alberto Acerbis**
Software Architect, trainer, Microsoft MVP, co-author of *Domain-Driven Refactoring*.

**Alessandro Colla**
Software Architect, trainer, co-author of *Domain-Driven Refactoring*.

---

## License

This repository is licensed under the MIT License.
