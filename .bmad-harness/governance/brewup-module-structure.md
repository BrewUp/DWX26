# BrewUp Module Structure Governance

## Numbered rules

### AR-000 — Architecture rules are authoritative

These rules are authoritative for BrewUp's physical module structure and constrain specifications, clarifications, plans, tasks, source code, tests, and architecture fitness functions. Do not invent ad-hoc project structures where these rules define the structure.

### AR-001 — Bounded contexts must be explicit modules

Every in-scope bounded context or business authority must be an explicit `src/<ModuleName>/` module, never loose folders or classes in another module. If Payment behavior is in scope, create `src/Payment/` and its solution folder.

### AR-002 — Standard module project structure

Every business module contains `BrewUp.<ModuleName>.SharedKernel`, `.Domain`, `.ReadModel`, `.Infrastructure`, `.Facade`, and `.Tests` under `src/<ModuleName>/`. Do not substitute names such as Application, Api, Contracts, Core, or Persistence without an explicit architecture decision.

### AR-003 — Optional Entities project

`BrewUp.<ModuleName>.Entities` is optional and may be introduced only for value objects or internal shared structures that should not belong directly to Domain. Do not create it by default; explain why it is needed.

### AR-004 — SharedKernel owns module contracts

Each module owns contracts and shared types in its `SharedKernel`, using `DomainIds`, `CustomTypes`, `Enums`, and `Messages/Commands` and `Messages/Events` when needed. Do not create empty folders unless repository convention requires them.

### AR-005 — Domain IDs live in module SharedKernel

Module-specific strongly typed IDs belong in `BrewUp.<ModuleName>.SharedKernel/DomainIds/`. Payment IDs include `PaymentAuthorizationId`, `PaymentId`, and `PaymentTermsApprovalId`; they derive from `Muflone.Core.DomainId` (for example, `public sealed class PaymentAuthorizationId(string value) : DomainId(value);`). Do not use raw `Guid`, `string`, or primitives across module boundaries.

### AR-006 — Commands live in module SharedKernel messages

Module-owned commands belong in `BrewUp.<ModuleName>.SharedKernel/Messages/Commands/`. Payment examples are `RequestPaymentAuthorization`, `VoidPaymentAuthorization`, `RequestPaymentRefund`, and `ApprovePaymentTerms`. Create only commands explicitly required by a decision; do not invent refund, void, retry, timeout, or payment-terms commands.

### AR-007 — Domain events live in module SharedKernel messages

Module-owned events belong in `BrewUp.<ModuleName>.SharedKernel/Messages/Events/`. Payment examples are `PaymentAuthorizationRequested`, `PaymentAuthorized`, `PaymentDeclined`, `PaymentOutcomeUnknown`, `PaymentAuthorizationVoided`, `PaymentRefundIssued`, and `PaymentTermsApproved`. Events must correspond to explicit outcomes and not silently decide unresolved policy.

### AR-008 — Domain project owns business behavior

`Domain` contains aggregates, module-owned entities, direct domain value objects, command handlers, domain services, behavior, and helper registration. Business rules belong in aggregate methods or domain services; command handlers only load aggregate, call domain method, and save aggregate. Facades and endpoints contain no business logic.

### AR-009 — ReadModel project owns queries and projections

`ReadModel` contains read-model documents, query services, projection-updating event handlers, and helper registration. Queries belong in `ReadModel`, not `Domain`; read models may be denormalized and rebuilt from events.

### AR-010 — Infrastructure project owns persistence and technical wiring

`Infrastructure` owns EventStore persister wiring, MongoDB setup, technical adapters, configuration, and helper registration. Domain must not reference EventStore, MongoDB, RabbitMQ, ASP.NET Core, or another infrastructure framework.

### AR-011 — Facade project is the module entry point

`Facade` owns Minimal API endpoint maps, ACL integration-event handlers, public module facade, and module registration. Other modules must not call another module's Domain project directly; cross-module interaction uses shared messages, ACL handlers, integration events, a module facade, or explicit integration contracts.

### AR-012 — Tests project is mandatory

Every implemented module has a `Tests` project with `Architecture` and `Domain` tests, including architecture tests, command specifications, aggregate invariant tests, command-handler tests when behavior exists, and relevant integration or boundary tests. New behavior starts with failing tests.

### AR-013 — REST host must register modules explicitly

Every module is registered in the REST host through the `IModule` pattern at `src/BrewUp.Rest/Module/<ModuleName>Module.cs`. The host composes modules and contains no business logic.

### AR-014 — Solution file must include all module projects

When creating a module, add every module project to the solution. Payment therefore includes SharedKernel, Domain, ReadModel, Infrastructure, Facade, and Tests `.csproj` files beneath `src/Payment/`; it must not exist only outside the solution.

### AR-015 — Project references must preserve layer boundaries

Allowed direction is Facade → Domain, ReadModel, Infrastructure, SharedKernel; Domain → SharedKernel; ReadModel → SharedKernel; Infrastructure → Domain, SharedKernel; Tests → layers as needed. Forbidden references include Domain → Infrastructure, ReadModel, Facade, ASP.NET Core, MongoDB, RabbitMQ, or EventStore, and Module A → Module B Domain or Infrastructure. Cross-module behavior uses explicit contracts and integration boundaries.

### AR-016 — Business authority must not be collapsed into another module

Do not implement a separate authority inside another module for convenience. Payment authorization, commands, events, command handlers, endpoints, and queries must be respectively in the Payment module's Domain, SharedKernel messages, Facade, and ReadModel—not in Sales. Valid direction is Payment authority → Payment module.

### AR-017 — Cross-context contracts must be explicit

Dependencies on another module's outcome use explicit contracts such as `PaymentAuthorized`, `PaymentDeclined`, `PaymentOutcomeUnknown`, `StockReserved`, and `StockReservationFailed`. A consumer may store `PaymentAuthorizationId` and `StockReservationId`, but must not embed the producing module's domain model.

### AR-018 — Sagas coordinate; they do not steal authority

Sagas may collect evidence, request Payment Authorization or Stock Reservation, react to `PaymentAuthorized` and `StockReserved`, and raise a gate event when evidence exists. A saga must not authorize payment, decrement stock, decide refunds without a domain decision, or interpret a provider timeout without a Payment-domain decision.
