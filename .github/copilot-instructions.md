# BrewUp — Copilot Instructions

## Solution Overview

BrewUp is a **DDD Modular Monolith** built on **.NET 10 / C#** using CQRS and Event Sourcing.
The framework is **Muflone** (`AggregateRoot`, `CommandHandlerAsync<T>`, `IntegrationEvent`, `DomainEvent`).
The message bus is **RabbitMQ** (via `Muflone.Transport.RabbitMQ`).
The write store is **EventStore** (gRPC); the read store is **MongoDB**.

### Key Rules
- **Never** put business logic in command handlers or facades — only in aggregate methods.
- **Never** reference a module's `Domain` or `Infrastructure` from another module. Use `BrewUp.Shared` for cross-context contracts.
- **Strongly-typed IDs** always derive from `Muflone.Core.DomainId(string value)`.
- **Enumeration pattern** (Smart Enum) for status/type values — derive from `BrewUp.Shared.Helpers.Enumeration`.
- **Test-First**: write a failing `CommandSpecification<T>` (Given/When/Expect) before implementing aggregate logic.
- Use `Guid.CreateVersion7()` everywhere, never `Guid.NewGuid()`.
- Use `ConfigureAwait(false)` on every `await` in non-test code.

---

## Solution Structure

```
src/
├── BrewUp.Shared/               # Cross-context contracts, shared types, helpers
├── BrewUp.Shared.Tests/         # Architecture and shared-kernel tests
├── BrewUp.Infrastructure/       # Global EventStore + RabbitMQ + MongoDB wiring
├── BrewUp.Rest/                 # ASP.NET Core host — module registration only
├── BrewUp.Rest.Tests/           # Integration / architecture tests for the host
│
├── Sales/                       # Sales Bounded Context
├── Warehouse/                   # Warehouse Bounded Context
├── Purchases/                   # Purchases Bounded Context
├── Sagas/                       # Cross-context orchestration (Saga pattern)
├── MasterData/                  # Master data (Customers, Beers)
└── Dashboards/                  # Read-only reporting / dashboards
```

---

## Module Layer Pattern

Every Bounded Context (`Sales`, `Warehouse`, `Purchases`, `Sagas`, `MasterData`, `Dashboards`) follows this layer structure:

| Layer | Project | Responsibilities |
|---|---|---|
| **SharedKernel** | `BrewUp.<Module>.SharedKernel` | Commands, Domain Events, Enums, CustomTypes (strongly-typed IDs) |
| **Domain** | `BrewUp.<Module>.Domain` | Aggregate Roots, Command Handlers, Domain Services, `DomainHelper.cs` |
| **ReadModel** | `BrewUp.<Module>.ReadModel` | Domain Event Handlers → MongoDB projections, `<Module>ReadModelHelper.cs` |
| **Infrastructure** | `BrewUp.<Module>.Infrastructure` | EventStore persister, `InfrastructureHelper.cs` |
| **Facade** | `BrewUp.<Module>.Facade` | REST Endpoints, ACL integration-event handlers, `<Module>FacadeHelper.cs` |
| **Tests** | `BrewUp.<Module>.Tests` | `CommandSpecification<T>` aggregate tests, Architecture tests |

> **Entities** project (`BrewUp.<Module>.Entities`) exists only in `Warehouse`, `MasterData`, `Dashboards` for value objects shared inside that BC.

---

## BrewUp.Shared (Cross-context contracts)

```
BrewUp.Shared/
├── DomainIds/              # Strongly-typed IDs shared across BCs (CustomerId, WarehouseId, …)
├── CustomTypes/            # Value objects shared across BCs (ItemRequested, …)
├── ExternalContracts/      # JSON DTOs used in integration events (CustomerJson, SalesOrderRowJson, …)
│   ├── MasterData/
│   └── Sales/
├── Messages/
│   └── Events/
│       └── Sagas/          # All integration events consumed/emitted by the Saga orchestrator
├── Helpers/                # Enumeration base class
├── Validation/             # FluentValidation base types
└── SharedHelper.cs         # DI extension: services.AddShared()
```

New cross-context IDs → `BrewUp.Shared/DomainIds/<Name>Id.cs`:
```csharp
public sealed class FooId(string value) : DomainId(value);
```

New integration events → `BrewUp.Shared/Messages/Events/Sagas/<EventName>.cs`:
```csharp
public sealed class FooHappened(IntegrationId aggregateId, Guid correlationId,
    string somePayload) : IntegrationEvent(aggregateId, correlationId)
{
    public string SomePayload { get; private set; } = somePayload;
}
```

---

## Sales Module

```
src/Sales/
├── BrewUp.Sales.SharedKernel/
│   ├── CustomTypes/        # SalesOrderId, SalesOrderNumber, SalesOrderDate, Customer, …
│   ├── Enums/              # SalesOrderStatus (Enumeration pattern)
│   └── Messages/
│       ├── Commands/       # CreateSalesOrder, PlaceSalesOrder, AcceptSalesOrder, ConfirmSalesOrder, …
│       └── Events/         # SalesOrderCreated, SalesOrderPlaced, SalesOrderAccepted, SalesOrderConfirmed, …
│
├── BrewUp.Sales.Domain/
│   ├── Entities/
│   │   └── SalesOrder.cs   # Aggregate root — all business logic lives here
│   ├── CommandHandlers/    # One handler per command; load aggregate → call method → save
│   ├── DomainHelper.cs     # services.AddCommandHandler<…>() registrations
│   ├── ISalesDomainService.cs / SalesDomainService.cs
│   └── Mappers/
│
├── BrewUp.Sales.ReadModel/
│   ├── EventHandlers/      # DomainEventHandlerAsync<T> → MongoDB upserts / publishes integration events
│   ├── Queries/            # MongoDB query services
│   ├── Dtos/               # Read model documents
│   └── SalesReadModelHelper.cs  # services.AddDomainEventHandler<…>() registrations
│
├── BrewUp.Sales.Infrastructure/
│   └── InfrastructureHelper.cs  # EventStore persister + MongoDB collections
│
├── BrewUp.Sales.Facade/
│   ├── Acl/                # IntegrationEventHandlerAsync<T> → dispatch Sales commands
│   ├── Endpoints/          # Minimal API endpoint maps
│   ├── ISalesFacade.cs / SalesFacade.cs
│   └── SalesFacadeHelper.cs  # Wires Domain + ReadModel + Infrastructure + ACL handlers
│
└── BrewUp.Sales.Tests/
    ├── Architecture/       # NetArchTest fitness constraints
    └── Domain/             # CommandSpecification<T> aggregate specs (Given/When/Expect)
```

**Aggregate method pattern** (`SalesOrder.cs`):
```csharp
internal void AcceptOrder(Guid correlationId)
{
    RaiseEvent(new SalesOrderAccepted(new SalesOrderId(Id.Value), correlationId));
}

private void Apply(SalesOrderAccepted @event)
{
    _salesOrderStatus = SalesOrderStatus.Accepted;
}
```

**Command handler pattern**:
```csharp
public sealed class AcceptSalesOrderCommandHandler(IRepository repository, ILoggerFactory loggerFactory)
    : CommandHandlerAsync<AcceptSalesOrder>(repository, loggerFactory)
{
    public override async Task HandleAsync(AcceptSalesOrder command, CancellationToken cancellationToken = new())
    {
        var aggregate = await Repository.GetByIdAsync<SalesOrder>(command.AggregateId, cancellationToken)
            .ConfigureAwait(false);
        aggregate!.AcceptOrder(command.MessageId);
        await Repository.SaveAsync(aggregate, Guid.CreateVersion7(), cancellationToken).ConfigureAwait(false);
    }
}
```

**Test pattern** (`CommandSpecification<T>`):
```csharp
public sealed class AcceptSalesOrderSuccessfully : CommandSpecification<AcceptSalesOrder>
{
    protected override IEnumerable<DomainEvent> Given()
    {
        yield return new SalesOrderCreated(_id, _number, _date, _customer, _delivery, _rows, _correlationId);
    }
    protected override AcceptSalesOrder When() => new(_id, _correlationId);
    protected override ICommandHandlerAsync<AcceptSalesOrder> OnHandler() =>
        new AcceptSalesOrderCommandHandler(Repository, new NullLoggerFactory());
    protected override IEnumerable<DomainEvent> Expect()
    {
        yield return new SalesOrderAccepted(_id, _correlationId);
    }
}
```

---

## Warehouse Module

```
src/Warehouse/
├── BrewUp.Warehouse.SharedKernel/
│   ├── CustomTypes/        # ShipmentId, SalesOrderId (local record), DeliveryDate, …
│   ├── Enums/              # ShipmentState
│   └── Messages/
│       ├── Commands/       # CreateAvailability, AddItemStock, RequestBeersAvailability, ReserveStock, …
│       └── Events/         # AvailabilityCreated, ItemStockAdded, RequestAccepted, RequestRejected, …
│
├── BrewUp.Warehouse.Entities/
│   └── …                   # Value objects shared inside the Warehouse BC
│
├── BrewUp.Warehouse.Domain/
│   ├── Entities/
│   │   ├── Availability.cs # Aggregate — availability checks and stock management
│   │   └── Shipment.cs     # Aggregate — shipment preparation
│   ├── CommandHandlers/
│   └── DomainHelper.cs
│
├── BrewUp.Warehouse.ReadModel/
├── BrewUp.Warehouse.Infrastructure/
├── BrewUp.Warehouse.Facade/
│   ├── Endpoints/
│   └── WarehouseFacadeHelper.cs
└── BrewUp.Warehouse.Tests/
    ├── Architecture/
    └── Domain/
```

---

## Purchases Module

```
src/Purchases/
├── BrewUp.Purchases.SharedKernel/
│   ├── CustomTypes/
│   ├── Enums/
│   └── Messages/
│       ├── Commands/
│       └── Events/
│
├── BrewUp.Purchases.Domain/
│   ├── Entities/
│   ├── CommandHandlers/
│   └── DomainHelper.cs
│
├── BrewUp.Purchases.ReadModel/
├── BrewUp.Purchases.Infrastructure/
├── BrewUp.Purchases.Facade/
│   ├── Endpoints/
│   └── PurchasesFacadeHelper.cs
└── BrewUp.Purchases.Tests/
    ├── Architecture/
    └── Domain/
```

---

## Sagas Module

```
src/Sagas/
├── BrewUp.Sagas.SharedKernel/
│   ├── CustomTypes/        # SagaId
│   ├── Enums/              # SagaState
│   └── Messages/
│       ├── Commands/       # StartSalesOrderSaga, RejectSalesOrder, …
│       └── Events/         # SalesOrderSagaStarted, SagaCustomerBudgetVerified, SagaSalesOrderPlaced, …
│
├── BrewUp.Sagas.Domain/
│   ├── Entities/
│   │   └── SalesOrderSaga.cs   # Saga aggregate — collects evidence, raises ReadyToConfirm
│   ├── Orchestrators/
│   │   ├── ISalesOrderSagaOrchestrator.cs
│   │   └── SalesOrderSagaOrchestrator.cs  # implements ISagaStartedByAsync + IIntegrationEventHandlerAsync<T>
│   └── SagasDomainHelper.cs
│
├── BrewUp.Sagas.ReadModel/
│   ├── EventHandlers/      # DomainEventHandler → publish integration events to other BCs
│   └── SagaReadModelHelper.cs
│
├── BrewUp.Sagas.Infrastructure/
│   └── Hubs/               # SignalR hub for real-time saga state notifications
│
├── BrewUp.Sagas.Facade/
│   ├── Endpoints/
│   └── SagasFacadeHelper.cs
└── BrewUp.Sagas.Tests/
    ├── Architecture/
    └── Orchestrators/
```

**Saga orchestrator pattern** — implement `IIntegrationEventHandlerAsync<T>` for each incoming event; call aggregate `Mark*` methods; aggregate raises an evidence-gate event when all conditions are met:
```csharp
public async Task HandleAsync(PaymentAuthorized @event, CancellationToken cancellationToken = new())
{
    var correlationId = MessageHelpers.GetCorrelationId(@event);
    var aggregate = await repository
        .GetByIdAsync<SalesOrderSaga>(new SagaId(correlationId.ToString()), cancellationToken)
        .ConfigureAwait(false);
    aggregate!.MarkPaymentAuthorized(@event.PaymentAuthorizationId, correlationId);
    await repository.SaveAsync(aggregate, Guid.CreateVersion7(), cancellationToken).ConfigureAwait(false);
}
```

---

## MasterData Module

```
src/MasterData/
├── BrewUp.MasterData.SharedKernel/
│   ├── CustomTypes/
│   ├── Enums/
│   └── Messages/
│       ├── Commands/       # CreateCustomer, UpdateCustomer, CreateBeer, …
│       └── Events/         # CustomerCreated, CustomerUpdated, BeerCreated, …
│
├── BrewUp.MasterData.Entities/
│   └── …                   # Value objects shared inside the MasterData BC
│
├── BrewUp.MasterData.Domain/
│   ├── Entities/
│   ├── CommandHandlers/
│   └── DomainHelper.cs
│
├── BrewUp.MasterData.ReadModel/
├── BrewUp.MasterData.Infrastructure/
├── BrewUp.MasterData.Facade/
│   ├── Endpoints/
│   └── MasterDataFacadeHelper.cs
└── BrewUp.MasterData.Tests/
    ├── Architecture/
    └── Domain/
```

---

## Dashboards Module

```
src/Dashboards/
├── BrewUp.Dashboards.SharedKernel/
│   ├── CustomTypes/
│   └── Messages/
│       └── Events/
│
├── BrewUp.Dashboards.Entities/
├── BrewUp.Dashboards.Domain/
├── BrewUp.Dashboards.ReadModel/  # Primarily read aggregations from MongoDB
├── BrewUp.Dashboards.Infrastructure/
├── BrewUp.Dashboards.Facade/
│   ├── Endpoints/
│   └── DashboardsFacadeHelper.cs
└── BrewUp.Dashboards.Tests/
    └── Architecture/
```

---

## REST Host (`BrewUp.Rest`)

All modules are wired via the `IModule` pattern:

```csharp
// BrewUp.Rest/Module/SalesModule.cs
public class SalesModule : IModule
{
    public bool IsEnabled => true;
    public int Order => 0;
    public IServiceCollection Register(WebApplicationBuilder builder)
    {
        builder.Services.AddSalesFacade(builder.Configuration);
        return builder.Services;
    }
    public IEndpointRouteBuilder MapEndpoints(IEndpointRouteBuilder endpoints)
    {
        endpoints.MapSalesEndpoints();
        return endpoints;
    }
}
```

Each module has its own `<Module>Module.cs` in `BrewUp.Rest/Module/`.

---

## Infrastructure (`BrewUp.Infrastructure`)

Shared global infrastructure wiring:
- **EventStore** (gRPC) — write model via `Muflone.Eventstore.gRPC`
- **RabbitMQ** — message transport via `Muflone.Transport.RabbitMQ`
- **MongoDB** — read model via `MongoDB.Driver`

Configuration sections in `appsettings.json`:
```json
{
  "BrewUp": {
    "EventStoreSettings": { "ConnectionString": "esdb://..." },
    "MongoDbSettings": { "ConnectionString": "mongodb://...", "DatabaseName": "BrewUp" },
    "RabbitMQ": { "Host": "localhost", "Username": "guest", "Password": "guest" }
  }
}
```

---

## Cross-context Communication Flow

```
[External Event arrives via RabbitMQ]
        │
        ▼
[Facade ACL Handler: IntegrationEventHandlerAsync<T>]
        │ sends command via IServiceBus
        ▼
[CommandHandler: loads Aggregate, calls method, saves]
        │ RaiseEvent(new DomainEvent)
        ▼
[ReadModel EventHandler: DomainEventHandlerAsync<T>]
        │ publishes IntegrationEvent via IEventBus
        ▼
[Other BCs subscribe via RabbitMQ]
```

For **saga coordination**: the saga orchestrator (`IIntegrationEventHandlerAsync<T>`) collects evidence in the saga aggregate. When all conditions are met the aggregate raises a gate event (e.g., `SagaSalesOrderReadyToConfirm`). The ReadModel event handler publishes a cross-context integration event. The target BC's ACL handler dispatches the final command.

---

## Shell Commands

```powershell
# Build entire solution
dotnet build src/BrewUp.slnx

# Run all tests
dotnet test src/BrewUp.slnx

# Run tests for a single module
dotnet test src/Sales/BrewUp.Sales.Tests/BrewUp.Sales.Tests.csproj

# Run the REST API locally
dotnet run --project src/BrewUp.Rest/BrewUp.Rest.csproj
```

