using System.Linq.Expressions;
using BrewUp.Payment.ReadModel.EventHandlers;
using BrewUp.Payment.ReadModel.Services;
using BrewUp.Payment.SharedKernel.CustomTypes;
using BrewUp.Payment.SharedKernel.DomainIds;
using BrewUp.Payment.SharedKernel.Messages.Events;
using BrewUp.Shared.ReadModel;
using Lena.Core;
using Microsoft.Extensions.Logging.Abstractions;
using PaymentProjection = BrewUp.Payment.ReadModel.Dtos.PaymentAuthorization;

namespace BrewUp.Payment.Tests.ReadModel;

public sealed class ProjectPendingAuthorization
{
    [Fact]
    public async Task PaymentAuthorizationRequestedCreatesPendingProjection()
    {
        var persister = new RecordingPersister();
        var service = new PaymentAuthorizationService(persister);
        var handler = new PaymentAuthorizationRequestedEventHandler(
            service,
            NullLoggerFactory.Instance);
        var authorizationId = new PaymentAuthorizationId(Guid.CreateVersion7().ToString());
        var salesOrder = new SalesOrderReference(Guid.CreateVersion7().ToString());

        await handler.HandleAsync(
            new PaymentAuthorizationRequested(
                authorizationId,
                salesOrder,
                Guid.CreateVersion7()),
            CancellationToken.None);

        var projection = Assert.IsType<PaymentProjection>(persister.Inserted);
        Assert.Equal(authorizationId.Value, projection.Id);
        Assert.Equal(salesOrder.Value, projection.SalesOrderId);
        Assert.Equal("pending", projection.Status);
        Assert.Null(projection.ProviderReference);
    }

    private sealed class RecordingPersister : IPersister
    {
        public DtoBase? Inserted { get; private set; }

        public Task<Result<T>> GetByIdAsync<T>(string id, CancellationToken cancellationToken)
            where T : DtoBase =>
            Task.FromResult(Result<T>.Error("No projection stored."));

        public Task<Result<bool>> InsertAsync<T>(T entity, CancellationToken cancellationToken)
            where T : DtoBase
        {
            Inserted = entity;
            return Task.FromResult(Result<bool>.Success(true));
        }

        public Task<Result<bool>> UpdateAsync<T>(T entity, CancellationToken cancellationToken)
            where T : DtoBase =>
            Task.FromResult(Result<bool>.Success(true));

        public Task<Result<bool>> DeleteAsync<T>(T entity, CancellationToken cancellationToken)
            where T : DtoBase =>
            Task.FromResult(Result<bool>.Success(true));
    }
}
