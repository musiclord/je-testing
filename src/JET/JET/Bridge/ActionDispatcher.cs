using System.Text.Json;
using JET.Application.Queries.AppBootstrap;
using JET.Application.Queries.ProjectDemo;
using JET.Application.Queries.SystemPing;
using JET.Domain.Abstractions;
using JET.Infrastructure.Configuration;

namespace JET.Bridge
{
    public sealed class ActionDispatcher : IActionDispatcher
    {
        private readonly Dictionary<string, Func<JsonElement, CancellationToken, Task<object?>>> _routes;
        private readonly IReadOnlyCollection<string> _supportedActions = Array.Empty<string>();

        public ActionDispatcher(JetAppOptions appOptions, IAppStateStore appStateStore)
        {
            var pingQueryHandler = new SystemPingQueryHandler();
            var bootstrapQueryHandler = new GetAppBootstrapQueryHandler(appOptions, appStateStore);
            var demoQueryHandler = new GetProjectDemoQueryHandler();

            _routes = new Dictionary<string, Func<JsonElement, CancellationToken, Task<object?>>>(StringComparer.OrdinalIgnoreCase)
            {
                ["system.ping"] = async (_, cancellationToken) => await pingQueryHandler.HandleAsync(new SystemPingQuery(), cancellationToken),
                ["app.bootstrap"] = async (_, cancellationToken) => await bootstrapQueryHandler.HandleAsync(new GetAppBootstrapQuery(_supportedActions), cancellationToken),
                ["project.loadDemo"] = async (_, cancellationToken) => await demoQueryHandler.HandleAsync(new GetProjectDemoQuery(), cancellationToken)
            };

            _supportedActions = _routes.Keys.OrderBy(static action => action).ToArray();
        }

        public IReadOnlyCollection<string> SupportedActions => _supportedActions;

        public async Task<object?> DispatchAsync(string action, JsonElement payload, CancellationToken cancellationToken)
        {
            if (!_routes.TryGetValue(action, out var routeHandler))
            {
                throw new KeyNotFoundException($"Unsupported action: {action}");
            }

            return await routeHandler(payload, cancellationToken);
        }
    }
}
