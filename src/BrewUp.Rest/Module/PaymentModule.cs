using BrewUp.Payment.Facade;

namespace BrewUp.Rest.Module;

public class PaymentModule : IModule
{
    public bool IsEnabled => true;

    public int Order => 0;

    public IServiceCollection Register(WebApplicationBuilder builder)
    {
        builder.Services.AddPaymentFacade(builder.Configuration);
        return builder.Services;
    }

    public WebApplication Configure(WebApplication app) => app;
}
