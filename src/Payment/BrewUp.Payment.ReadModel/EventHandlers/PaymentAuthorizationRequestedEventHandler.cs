using BrewUp.Payment.ReadModel.Services;
using BrewUp.Payment.SharedKernel.DomainIds;
using BrewUp.Payment.SharedKernel.Messages.Events;
using Microsoft.Extensions.Logging;
using Muflone.Messages.Events;

namespace BrewUp.Payment.ReadModel.EventHandlers;

public sealed class PaymentAuthorizationRequestedEventHandler(
    IPaymentAuthorizationService service,
    ILoggerFactory loggerFactory)
    : DomainEventHandlerAsync<PaymentAuthorizationRequested>(loggerFactory)
{
    public override async Task HandleAsync(
        PaymentAuthorizationRequested @event,
        CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();

        await service
            .CreatePendingAsync(
                new PaymentAuthorizationId(@event.AggregateId.Value),
                @event.SalesOrder,
                cancellationToken)
            .ConfigureAwait(false);
    }
}
