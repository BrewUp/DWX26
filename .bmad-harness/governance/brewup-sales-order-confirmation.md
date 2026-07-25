# BrewUp Sales Order Confirmation Governance

## Authority

- Sales owns the Sales Order lifecycle.
- Payment owns payment authorization outcomes.
- Warehouse owns stock availability and reservation outcomes.

Sales may depend on decisions produced by Payment and Warehouse, but must not own the models or processes that produce those decisions.

## Numbered rules

### BC-000 — Domain rules are authoritative

These rules are authoritative for Sales Order Confirmation and constrain clarification, plans, tasks, implementation, tests, and reviews. A violating artifact is architecturally misaligned. Do not override the rules for completeness, convenience, or technical coherence. Keep unknown business decisions as open questions or `[NEEDS CLARIFICATION]`.

### BC-001 — Sales owns Sales Order lifecycle

Sales owns the Sales Order lifecycle, commercial status, customer demand, and the transition to `Confirmed` once required external evidence is present. Sales does not own the decisions that produce the external evidence.

### BC-002 — Sales Order is the aggregate owned by Sales

Sales owns the Sales Order aggregate and must not embed Payment or Warehouse domain models in it. `SalesOrder contains Payment`, `SalesOrder contains WarehouseReservation`, `SalesOrder owns StockReservation`, and `SalesOrder owns PaymentAuthorization` are invalid because they violate decision authority.

### BC-003 — Payment owns authorization outcomes

Payment owns payment authorization, authorization outcome, payment-provider timeout interpretation, void behavior, and refund behavior. Sales must not authorize payment, interpret provider timeouts without an explicit Payment-domain decision, issue refunds, or void payment authorizations unless an explicit domain decision assigns that responsibility.

### BC-004 — Payment Authorization is an external decision

Sales may store `PaymentAuthorizationId` as evidence that Payment produced an authorization outcome, react to that outcome, and request authorization through an integration boundary. Sales must not produce the outcome. A valid model stores `PaymentAuthorizationId?`; a Sales Order containing `Payment.Authorize()` is invalid.

### BC-005 — Warehouse owns physical stock

Warehouse owns physical stock, stock availability, stock reservation, stock release, and reservation expiration. Sales must not be the authority of truth for physical stock or decide whether stock is physically available.

### BC-006 — Stock Reservation is an external decision

Sales may store `StockReservationId` as evidence that Warehouse produced a reservation outcome, react to it, and request a reservation through an integration boundary. Sales must not produce the outcome. A valid model stores `StockReservationId?`; a Sales Order containing `WarehouseReservation.Reserve()` is invalid.

### BC-007 — Warehouse owns stock mutation

Sales must not decrement stock, reserve stock, release stock, mutate Warehouse stock, or decide stock availability as the authority of truth. Availability is not a durable fact; only a Stock Reservation is durable enough to support Sales Order confirmation.

### BC-008 — Reacting is not owning

Sales may react to Payment and Warehouse outcomes but must not produce them. Dependency on a decision is not ownership: `Sales reacts to PaymentAuthorized` and `Sales reacts to StockReserved` are valid; `Sales authorizes the payment` and `Sales reserves stock` are invalid.

### BC-009 — External decision references, not embedded models

Sales may store `PaymentAuthorizationId`, `StockReservationId`, and `PaymentTermsApprovalId` only when pre-approved payment terms are supported. These are evidence that another bounded context made a decision, not a way to load, modify, or own another aggregate. Sales must not embed Payment or Warehouse domain models.

### BC-010 — Confirmed requires evidence

A Sales Order must not become `Confirmed` unless required external decision references are present. In the base scenario both `PaymentAuthorizationId` and `StockReservationId` are required. References may be empty during the lifecycle, but `Confirmed` with either reference missing is invalid.

### BC-011 — Clarification preserves authority

When business behavior is unclear, preserve it as an open question or `[NEEDS CLARIFICATION]`; never silently decide. This includes payment-authorized/stock-unavailable handling, reservation duration, provider timeout semantics, partial reservations, confirmation evidence, partial-failure notifications, coordination mechanism, and payment-terms approval scope, validity, revocation, and evidence. The agent may identify ambiguity; the domain expert resolves it and the resolution must be preserved.

## Non-negotiable boundaries

Sales must not authorize payments; interpret payment-provider timeouts as declined, authorized, or pending without a decision; void authorizations; issue refunds; own physical-stock truth; reserve, release, or decrement stock; create shipments; issue invoices; or invent retry, cancellation, notification, or reservation-expiration policy.

Do not assume stock failure cancels an order, refunds or voids payment, triggers retry, that authorization or submission confirms an order, that availability equals reservation, that shipment starts after confirmation, that invoicing belongs to Sales, that provider timeout has a defined outcome, that stock release has a default timeout, or that payment terms apply without an explicit rule. Model any needed behavior as external responsibility, out of scope, or an explicit open question.
