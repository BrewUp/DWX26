using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace BrewUp.Payment.Facade;

public static class PaymentFacadeHelper
{
    public static IServiceCollection AddPaymentFacade(
        this IServiceCollection services,
        IConfiguration configuration) => services;
}
