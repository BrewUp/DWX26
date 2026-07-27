using BrewUp.Payment.Facade;
using BrewUp.Payment.Facade.Endpoints;
using BrewUp.Payment.SharedKernel.DomainIds;
using BrewUp.Payment.SharedKernel.Messages.Commands;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.DependencyInjection;
using Muflone.Messages.Commands;
using Muflone.Persistence;

namespace BrewUp.Payment.Tests.Facade;

public sealed class RecordAuthorizedCallbackBoundary
{
    [Fact]
    public async Task ProviderSuppliedOutcomeReachesRecordPaymentAuthorized()
    {
        var serviceBus = new CapturingServiceBus();
        IPaymentFacade facade = new PaymentFacade(serviceBus);
        var authorizationId = new PaymentAuthorizationId(Guid.CreateVersion7().ToString());

        var result = await facade.RecordAuthorizedAsync(
            authorizationId,
            "provider-auth-123",
            CancellationToken.None);

        Assert.True(result.IsSuccess);
        var command = Assert.IsType<RecordPaymentAuthorized>(serviceBus.Command);
        Assert.Equal(authorizationId, command.AggregateId);
        Assert.Equal("provider-auth-123", command.ProviderReference);
        Assert.Equal(7, command.MessageId.Version);

        var builder = WebApplication.CreateBuilder();
        builder.Services.AddSingleton(facade);
        var app = builder.Build();
        app.MapPaymentEndpoints();

        var endpoint = Assert.Single(
            ((IEndpointRouteBuilder)app).DataSources
                .SelectMany(source => source.Endpoints)
                .OfType<RouteEndpoint>(),
            candidate =>
                candidate.RoutePattern.RawText ==
                "/v1/payment/authorizations/{authorizationId}/authorized");
        Assert.Contains("POST", endpoint.Metadata.GetMetadata<HttpMethodMetadata>()!.HttpMethods);
    }

    private sealed class CapturingServiceBus : IServiceBus
    {
        public Command? Command { get; private set; }

        public Task SendAsync<T>(T command, CancellationToken cancellationToken)
            where T : class, ICommand
        {
            Command = Assert.IsAssignableFrom<Command>(command);
            return Task.CompletedTask;
        }
    }
}
