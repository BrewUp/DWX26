---
title: "Story 1.1: Establish the Payment Module and Authorization Domain"
storyId: "1.1"
storyKey: "1-1-order-confirmation"
status: ready-for-dev
created: 2026-07-27
updated: 2026-07-27
epic: "Evidence-Backed Sales Order Confirmation"
---

# Story 1.1: Establish the Payment Module and Authorization Domain

Status: ready-for-dev

## Story

As a BrewUp operator,
I want an independently valid Payment module with its authorization domain,
so that Payment authority exists as a complete architectural increment before
later projection and provider-boundary behavior is added.

## Acceptance Criteria

1. Given no authorization exists for a stable `PaymentAuthorizationId`, when
   `RequestPaymentAuthorization` is handled, then Payment emits one
   `PaymentAuthorizationRequested` and restores its Payment ID,
   `SalesOrderReference`, and pending state. Correlation ID remains
   command/event metadata and is not retained as aggregate business state.
2. Given the same stable authorization request was already applied, when it is
   replayed, then Payment emits no second `PaymentAuthorizationRequested`.
3. Given a pending authorization and an externally supplied provider reference,
   when `RecordPaymentAuthorized` is handled, then Payment emits one
   `PaymentAuthorized`; replaying the outcome emits no second event.
4. Given Payment becomes an implemented authority, when this story completes,
   then all six exact Payment projects exist and build:
   SharedKernel, Domain, ReadModel, Infrastructure, Facade, and Tests.
5. Given the six projects exist, when solution/host composition is inspected,
   then all six are under `/50 Modules/Payment/` in `src/BrewUp.slnx`,
   `PaymentModule` is present in the REST composition root, and the REST host
   references only Payment Facade.
6. Given architecture fitness tests run, then they prove module/contract
   placement, solution and host membership, allowed references, and absence of
   Payment Domain references to Facade, ReadModel, Infrastructure, ASP.NET,
   MongoDB, RabbitMQ, Sales Domain, or Warehouse Domain.
7. Given minimal six-project/test-harness shells compile but Payment behavior
   and composition are absent, the four domain specifications and architecture
   fitness test are written and run to meaningful RED before production
   behavior; all pass after the minimum implementation.
8. Given Story 1.1 changed production code creates GUIDs or awaits tasks,
   `Story11ImplementationConventionReview` confirms new GUIDs use
   `Guid.CreateVersion7()` and awaited tasks use `ConfigureAwait(false)` unless
   an explicit architecture exception exists.
9. No amount/currency, real provider execution, decline, timeout
   interpretation, void, refund, retry, notification, expiry, reservation,
   confirmation, shipment, or invoicing behavior is introduced.

## Tasks / Subtasks

- [ ] Task 1 — Create a compilable six-project/test harness shell (AC: 4, 7)
  - [ ] Create the exact SharedKernel, Domain, ReadModel, Infrastructure,
    Facade, Tests `.csproj` files at the six AD-3 paths.
  - [ ] Wire only AD-4 project references and repository-pinned test packages.
    The Tests project must be runnable and reference the empty Domain and
    SharedKernel shells.
  - [ ] Do not add domain contracts, aggregate behavior, helpers, solution
    membership, or host registration yet. Building the shells is setup, not
    GREEN.

- [ ] Task 2 — Write and run meaningful RED architecture coverage (AC: 4–7)
  - [ ] Create `Architecture/PaymentModuleStructureAndComposition.cs`.
  - [ ] Assert solution membership, `PaymentModule`/Program registration,
    contract placement, and AD-4 allowed/forbidden references.
  - [ ] Run it immediately after the shells compile, while solution/host
    composition and contracts are absent; record an executed behavior/structure
    assertion failure before any compile-failing domain specifications exist.

- [ ] Task 3 — Write and run meaningful RED domain specifications (AC: 1–3, 7)
  - [ ] Create `RequestPaymentAuthorizationSuccessfully`.
  - [ ] Create `DoNotRequestPaymentAuthorizationTwice`.
  - [ ] Create `RecordPaymentAuthorizedSuccessfully`.
  - [ ] Create `DoNotAuthorizePaymentTwice`.
  - [ ] Seed request/outcome history for both replay tests.
  - [ ] Run the four tests from the existing Tests project and record RED due to
    missing Payment contracts/domain behavior, not project-not-found.

- [ ] Task 4 — Implement Payment-owned contracts (AC: 1–3, 9)
  - [ ] Create
    `SharedKernel/DomainIds/PaymentAuthorizationId.cs` deriving from
    `Muflone.Core.DomainId`.
  - [ ] Create `SharedKernel/CustomTypes/SalesOrderReference.cs`.
  - [ ] Create
    `SharedKernel/Messages/Commands/RequestPaymentAuthorization.cs` and
    `RecordPaymentAuthorized.cs`.
  - [ ] Create
    `SharedKernel/Messages/Events/PaymentAuthorizationRequested.cs`,
    `PaymentAuthorized.cs`, and the contract
    `PaymentAuthorizedIntegrationEvent.cs`; Story 1.2 owns publishing it.
  - [ ] Contracts contain only approved IDs, Sales Order reference, provider
    reference, and correlation metadata. Correlation ID stays on command/events,
    not aggregate business state.

- [ ] Task 5 — Implement the event-sourced aggregate and handlers (AC: 1–3)
  - [ ] Create `Domain/Entities/PaymentAuthorization.cs`.
  - [ ] `Request(...)` raises `PaymentAuthorizationRequested`; apply restores
    ID, Sales Order reference, and pending state. Replaying the stable request
    is a no-op.
  - [ ] `RecordAuthorized(...)` raises `PaymentAuthorized` once; an
    already-authorized aggregate returns without raising an event.
  - [ ] Create
    `Domain/CommandHandlers/RequestPaymentAuthorizationCommandHandler.cs` and
    `RecordPaymentAuthorizedCommandHandler.cs`.
  - [ ] Handlers perform only load/create -> aggregate method -> repository
    save and use `ConfigureAwait(false)`.
  - [ ] Use stable IDs from commands; use `Guid.CreateVersion7()` only where a
    new technical GUID is actually required.

- [ ] Task 6 — Add minimal helpers, solution, and REST composition (AC: 4–6)
  - [ ] Add only minimal compiling `DomainHelper`,
    `PaymentReadModelHelper`, `InfrastructureHelper`, and
    `PaymentFacadeHelper`; Story 1.2 completes their behavior.
  - [ ] Add all six project paths beneath `/50 Modules/Payment/` in
    `src/BrewUp.slnx`.
  - [ ] Create `src/BrewUp.Rest/Module/PaymentModule.cs` implementing `IModule`.
  - [ ] Add `new PaymentModule()` to `src/BrewUp.Rest/Program.cs`.
  - [ ] Add only the Payment Facade project reference to
    `src/BrewUp.Rest/BrewUp.Rest.csproj`.
  - [ ] Minimal `PaymentModule` registration may compose the empty
    Story-1.1-safe Facade shell; it must not expose a callback endpoint or
    publish integration events. Story 1.2 owns those behaviors.

- [ ] Task 7 — Verify GREEN and conventions (AC: 1–9)
  - [ ] Run the four targeted Payment domain specifications.
  - [ ] Run `PaymentModuleStructureAndComposition`.
  - [ ] Run the full Payment Tests project.
  - [ ] Run affected REST architecture tests without starting
    infrastructure-dependent fixtures.
  - [ ] Build `src/BrewUp.slnx`.
  - [ ] Run `Story11ImplementationConventionReview` over only Story 1.1 changed
    production files for `Guid.CreateVersion7()` and `ConfigureAwait(false)`.
  - [ ] Confirm the changed-file list contains no Sales, Warehouse, Sagas, real
    provider, compensation, retry, timeout, shipment, or invoice behavior.

## Dev Notes

### Developer context

This is the architecture-foundation and Payment-domain story, not the complete
Payment integration story. It must leave Payment independently valid under
AR-001/AR-002 while keeping Story 1.2's projection, EventStore/Mongo
persistence, facade endpoint, provider callback, and integration publisher
unimplemented.

Payment alone owns authorization state and events. The caller supplies the
authorized outcome; neither the REST shell nor saga exists in this story to
decide it. Sales Order references are correlation data, not embedded Sales
models.

### Current brownfield state

- `src/BrewUp.Rest/Program.cs` registers modules explicitly through
  `builder.RegisterModules([...])`; insert `new PaymentModule()` with other
  business modules.
- `src/BrewUp.Rest/BrewUp.Rest.csproj` references module Facades only; add
  Payment Facade and no other Payment layer.
- `src/BrewUp.slnx` groups module projects beneath `/50 Modules/<Module>/`;
  add one `/50 Modules/Payment/` folder containing exactly six projects.
- Existing projects target `net10.0`. Existing module contracts use Muflone
  10.2.1; tests use Muflone.SpecificationTests 10.0.0, xUnit 2.9.3, and
  NetArchTest.Rules 1.3.2. Use repository-pinned versions rather than
  introducing alternatives.

### Architecture compliance

```text
Facade         -> Domain, ReadModel, Infrastructure, SharedKernel
Domain         -> SharedKernel
ReadModel      -> SharedKernel
Infrastructure -> Domain, SharedKernel
Tests          -> owned layers as needed
REST host      -> Facade only
```

Cross-module references may target explicit SharedKernel contracts only. No
Payment project may reference Sales/Warehouse Domain or Infrastructure.

The six required paths are:

```text
src/Payment/BrewUp.Payment.SharedKernel/BrewUp.Payment.SharedKernel.csproj
src/Payment/BrewUp.Payment.Domain/BrewUp.Payment.Domain.csproj
src/Payment/BrewUp.Payment.ReadModel/BrewUp.Payment.ReadModel.csproj
src/Payment/BrewUp.Payment.Infrastructure/BrewUp.Payment.Infrastructure.csproj
src/Payment/BrewUp.Payment.Facade/BrewUp.Payment.Facade.csproj
src/Payment/BrewUp.Payment.Tests/BrewUp.Payment.Tests.csproj
```

### Required contract shape

```csharp
public sealed class PaymentAuthorizationId(string value) : DomainId(value);
public sealed record SalesOrderReference(string Value);

public sealed class RequestPaymentAuthorization(
    PaymentAuthorizationId aggregateId,
    SalesOrderReference salesOrder,
    Guid correlationId) : Command(aggregateId, correlationId)
{
    public SalesOrderReference SalesOrder { get; } = salesOrder;
}
```

`RecordPaymentAuthorized` carries the Payment ID, externally supplied provider
reference, and correlation/message ID. Correlation is message/event metadata,
not retained aggregate business state. `PaymentAuthorized` carries the approved
owned evidence and metadata. Do not add policy fields not present upstream.

### Testing requirements

- TDD order is mandatory: create compilable project/test shells; write and
  execute the architecture fitness test to assertion RED; then write/run the
  four domain specifications against missing behavior to compile/test RED;
  implement the minimum behavior, then capture GREEN.
- Command handlers contain no business policy.
- Architecture coverage must check file/project placement, project references,
  contract placement, solution membership, and REST registration.
- Static/code review covers NFR-005 only across Story 1.1 changed production
  files; every later story owns its own convention verification.
- Infrastructure-dependent integration fixtures are not required for this
  story; Story 1.2 adds persistence/boundary tests.

### Stop conditions

Stop and report a blocking policy conflict if implementation would require:

- Payment amount/currency or a real-provider decision;
- decline, unknown, or timeout interpretation;
- void, refund, compensation, retry, notification, or expiry behavior;
- partial Payment module composition;
- a cross-module Domain/Infrastructure reference;
- Payment behavior under Sales, Warehouse, Sagas, or the REST host.

Do not invent a workaround.

### Project structure notes

No starter template or database migration is required. The new module follows
the existing brownfield module and composition patterns. The optional Entities
project is explicitly not used.

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 1, Story 1.1]
- [Source: `_bmad-output/planning-artifacts/prd.md` — FR-001–FR-004,
  FR-016–FR-019, NFR-001, NFR-002, NFR-005]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — AD-1 through
  AD-5, AD-10, AD-11]
- [Source:
  `docs/superpowers/specs/2026-07-27-brewup-order-confirmation-with-bmad-harness-design.md`
  — Payment module, Contracts, Testing Strategy, Out of Scope]
- [Source:
  `.bmad-harness/governance/brewup-sales-order-confirmation.md` — BC-000,
  BC-003, BC-004, BC-008, BC-011]
- [Source: `.bmad-harness/governance/brewup-module-structure.md` — AR-000
  through AR-017]
- [Source: `_bmad-output/project-context.md` — Technology and architecture;
  Implementation discipline]

## Governance traceability

| Story concern | Requirements/decisions | Rules |
|---|---|---|
| Complete Payment authority/module | FR-001, FR-016, FR-017; AD-3 | BC-003; BC-004; AR-001; AR-002; AR-013; AR-014; AR-016 |
| Contract and ID ownership | FR-001–FR-003; AD-2, AD-5 | BC-003; BC-004; AR-004–AR-007; AR-017 |
| Event-sourced pending/authorized behavior | FR-002–FR-004; AD-1, AD-5 | BC-003; BC-004; BC-008; AR-008; AR-012 |
| Dependencies and composition | FR-018; AD-4 | AR-011; AR-013–AR-017 |
| TDD and conventions | FR-019; NFR-005; AD-10, AD-11 | AR-000; AR-012 |
| Excluded policy | AC9; approved design Out of Scope | BC-000; BC-003; BC-011 |

## Completion status

Ultimate context engine analysis completed - comprehensive developer guide
created.

## Dev Agent Record

### Agent Model Used

To be recorded by the implementation agent.

### Debug Log References

### Completion Notes List

### File List
