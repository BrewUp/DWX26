using System.Reflection;
using System.Xml.Linq;

namespace BrewUp.Payment.Tests.Architecture;

public sealed class PaymentModuleStructureAndComposition
{
    private static readonly string[] PaymentProjects =
    [
        "Payment/BrewUp.Payment.SharedKernel/BrewUp.Payment.SharedKernel.csproj",
        "Payment/BrewUp.Payment.Domain/BrewUp.Payment.Domain.csproj",
        "Payment/BrewUp.Payment.ReadModel/BrewUp.Payment.ReadModel.csproj",
        "Payment/BrewUp.Payment.Infrastructure/BrewUp.Payment.Infrastructure.csproj",
        "Payment/BrewUp.Payment.Facade/BrewUp.Payment.Facade.csproj",
        "Payment/BrewUp.Payment.Tests/BrewUp.Payment.Tests.csproj"
    ];

    [Fact]
    public void ContractsAreOwnedByPaymentSharedKernel()
    {
        var sharedKernel = Assembly.Load("BrewUp.Payment.SharedKernel");
        string[] expectedTypes =
        [
            "BrewUp.Payment.SharedKernel.DomainIds.PaymentAuthorizationId",
            "BrewUp.Payment.SharedKernel.CustomTypes.SalesOrderReference",
            "BrewUp.Payment.SharedKernel.Messages.Commands.RequestPaymentAuthorization",
            "BrewUp.Payment.SharedKernel.Messages.Commands.RecordPaymentAuthorized",
            "BrewUp.Payment.SharedKernel.Messages.Events.PaymentAuthorizationRequested",
            "BrewUp.Payment.SharedKernel.Messages.Events.PaymentAuthorized",
            "BrewUp.Payment.SharedKernel.Messages.Events.PaymentAuthorizedIntegrationEvent"
        ];

        foreach (var expectedType in expectedTypes)
        {
            Assert.True(
                sharedKernel.GetType(expectedType) is not null,
                $"Expected Payment-owned contract '{expectedType}' in BrewUp.Payment.SharedKernel.");
        }
    }

    [Fact]
    public void ProjectReferencesFollowPaymentLayerBoundaries()
    {
        AssertProjectReferences(
            "Payment/BrewUp.Payment.SharedKernel/BrewUp.Payment.SharedKernel.csproj");
        AssertProjectReferences(
            "Payment/BrewUp.Payment.Domain/BrewUp.Payment.Domain.csproj",
            "../BrewUp.Payment.SharedKernel/BrewUp.Payment.SharedKernel.csproj");
        AssertProjectReferences(
            "Payment/BrewUp.Payment.ReadModel/BrewUp.Payment.ReadModel.csproj",
            "../BrewUp.Payment.SharedKernel/BrewUp.Payment.SharedKernel.csproj");
        AssertProjectReferences(
            "Payment/BrewUp.Payment.Infrastructure/BrewUp.Payment.Infrastructure.csproj",
            "../BrewUp.Payment.Domain/BrewUp.Payment.Domain.csproj",
            "../BrewUp.Payment.SharedKernel/BrewUp.Payment.SharedKernel.csproj");
        AssertProjectReferences(
            "Payment/BrewUp.Payment.Facade/BrewUp.Payment.Facade.csproj",
            "../BrewUp.Payment.Domain/BrewUp.Payment.Domain.csproj",
            "../BrewUp.Payment.Infrastructure/BrewUp.Payment.Infrastructure.csproj",
            "../BrewUp.Payment.ReadModel/BrewUp.Payment.ReadModel.csproj",
            "../BrewUp.Payment.SharedKernel/BrewUp.Payment.SharedKernel.csproj");
    }

    [Fact]
    public void DomainHasNoForbiddenLayerOrFrameworkDependencies()
    {
        string[] forbiddenDependencies =
        [
            "BrewUp.Payment.Facade",
            "BrewUp.Payment.ReadModel",
            "BrewUp.Payment.Infrastructure",
            "Microsoft.AspNetCore",
            "MongoDB",
            "RabbitMQ",
            "BrewUp.Sales.Domain",
            "BrewUp.Warehouse.Domain"
        ];

        var referencedAssemblies = Assembly.Load("BrewUp.Payment.Domain")
            .GetReferencedAssemblies()
            .Select(reference => reference.Name ?? string.Empty)
            .ToArray();

        foreach (var forbiddenDependency in forbiddenDependencies)
        {
            Assert.DoesNotContain(
                referencedAssemblies,
                reference => reference.StartsWith(forbiddenDependency, StringComparison.Ordinal));
        }
    }

    [Fact]
    public void SolutionContainsAllSixPaymentProjectsInPaymentFolder()
    {
        var solution = XDocument.Load(Path.Combine(RepositoryRoot, "src", "BrewUp.slnx"));
        var paymentFolder = solution
            .Descendants("Folder")
            .SingleOrDefault(folder => (string?)folder.Attribute("Name") == "/50 Modules/Payment/");

        Assert.True(paymentFolder is not null, "Expected /50 Modules/Payment/ in src/BrewUp.slnx.");

        var projectPaths = paymentFolder!
            .Elements("Project")
            .Select(project => Normalize((string?)project.Attribute("Path") ?? string.Empty))
            .Order(StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(PaymentProjects.Order(StringComparer.Ordinal), projectPaths);
    }

    [Fact]
    public void RestHostComposesPaymentThroughFacadeOnly()
    {
        var modulePath = Path.Combine(RepositoryRoot, "src", "BrewUp.Rest", "Module", "PaymentModule.cs");
        Assert.True(File.Exists(modulePath), "Expected PaymentModule in the REST composition root.");

        var module = File.ReadAllText(modulePath);
        Assert.Contains("class PaymentModule : IModule", module, StringComparison.Ordinal);
        Assert.Contains("AddPaymentFacade", module, StringComparison.Ordinal);
        Assert.DoesNotContain("MapPaymentEndpoints", module, StringComparison.Ordinal);

        var program = File.ReadAllText(Path.Combine(RepositoryRoot, "src", "BrewUp.Rest", "Program.cs"));
        Assert.Contains("new PaymentModule()", program, StringComparison.Ordinal);

        var restProject = XDocument.Load(
            Path.Combine(RepositoryRoot, "src", "BrewUp.Rest", "BrewUp.Rest.csproj"));
        var paymentReferences = restProject
            .Descendants("ProjectReference")
            .Select(reference => Normalize((string?)reference.Attribute("Include") ?? string.Empty))
            .Where(reference => reference.Contains("/Payment/", StringComparison.Ordinal))
            .ToArray();

        Assert.Equal(
            ["../Payment/BrewUp.Payment.Facade/BrewUp.Payment.Facade.csproj"],
            paymentReferences);
    }

    private static void AssertProjectReferences(string projectPath, params string[] expectedReferences)
    {
        var project = XDocument.Load(Path.Combine(RepositoryRoot, "src", projectPath));
        var references = project
            .Descendants("ProjectReference")
            .Select(reference => Normalize((string?)reference.Attribute("Include") ?? string.Empty))
            .Order(StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(expectedReferences.Select(Normalize).Order(StringComparer.Ordinal), references);
    }

    private static string RepositoryRoot
    {
        get
        {
            var directory = new DirectoryInfo(AppContext.BaseDirectory);
            while (directory is not null &&
                   !File.Exists(Path.Combine(directory.FullName, "src", "BrewUp.slnx")))
            {
                directory = directory.Parent;
            }

            return directory?.FullName
                   ?? throw new DirectoryNotFoundException("Could not locate the BrewUp repository root.");
        }
    }

    private static string Normalize(string path) => path.Replace('\\', '/');
}
