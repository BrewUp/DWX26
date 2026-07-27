using BrewUp.Payment.Domain.CommandHandlers;
using BrewUp.Payment.Facade;
using BrewUp.Payment.Facade.EventHandlers;
using BrewUp.Payment.Infrastructure;
using BrewUp.Payment.ReadModel.Dtos;
using BrewUp.Payment.ReadModel.EventHandlers;
using BrewUp.Payment.ReadModel.Queries;
using BrewUp.Payment.ReadModel.Services;
using BrewUp.Shared.ReadModel;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace BrewUp.Payment.Tests.Infrastructure;

public sealed class PaymentPersistenceWiring
{
    [Fact]
    public void PaymentCompositionRegistersOwnedBehaviorWithoutGlobalInfrastructure()
    {
        IServiceCollection services = new ServiceCollection();

        services.AddPaymentFacade(new ConfigurationManager());

        var paymentPersisters = services
            .Where(descriptor =>
                descriptor.ServiceType == typeof(IPersister) &&
                Equals(descriptor.ServiceKey, "payment"))
            .ToArray();

        var persister = Assert.Single(paymentPersisters);
        Assert.Equal(typeof(PaymentPersister), persister.KeyedImplementationType);
        Assert.Contains(services, IsRegistration<IPaymentAuthorizationService, PaymentAuthorizationService>);
        Assert.Contains(services, IsRegistration<IQueries<PaymentAuthorization>, PaymentAuthorizationQueries>);
        Assert.Contains(services, HasImplementation<RequestPaymentAuthorizationCommandHandler>);
        Assert.Contains(services, HasImplementation<RecordPaymentAuthorizedCommandHandler>);
        Assert.Contains(services, HasImplementation<PaymentAuthorizationRequestedEventHandler>);
        Assert.Contains(services, HasImplementation<PaymentAuthorizedEventHandler>);
        Assert.Contains(services, IsRegistration<IPaymentFacade, PaymentFacade>);
        Assert.Contains(services, HasImplementation<PaymentAuthorizedIntegrationEventPublisher>);

        Assert.DoesNotContain(services, descriptor =>
            descriptor.ServiceType.FullName is
                "MongoDB.Driver.IMongoClient" or
                "Muflone.Persistence.IRepository" or
                "Muflone.IEventBus");
    }

    private static bool IsRegistration<TService, TImplementation>(
        ServiceDescriptor descriptor) =>
        descriptor.ServiceType == typeof(TService) &&
        descriptor.ImplementationType == typeof(TImplementation);

    private static bool HasImplementation<TImplementation>(
        ServiceDescriptor descriptor) =>
        descriptor.ImplementationType == typeof(TImplementation);
}
