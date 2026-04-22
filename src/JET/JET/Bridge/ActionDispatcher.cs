using System.Text.Json;
using JET.Application.Commands.CommitMapping;
using JET.Application.Commands.CreateProject;
using JET.Application.Commands.ExportReport;
using JET.Application.Commands.FilterScenario;
using JET.Application.Commands.ImportData;
using JET.Application.Queries.AppBootstrap;
using JET.Application.Queries.AutoSuggestMapping;
using JET.Application.Queries.ProjectDemo;
using JET.Application.Queries.RunPrescreen;
using JET.Application.Queries.RunValidation;
using JET.Application.Queries.SystemPing;
using JET.Domain.Abstractions;
using JET.Infrastructure.Configuration;

namespace JET.Bridge
{
    public sealed class ActionDispatcher : IActionDispatcher
    {
        private readonly Dictionary<string, Func<JsonElement, CancellationToken, Task<object?>>> _routes;
        private readonly IReadOnlyCollection<string> _supportedActions = Array.Empty<string>();

        public ActionDispatcher(JetAppOptions appOptions, IAppStateStore appStateStore, IProjectSessionStore sessionStore)
        {
            var pingQueryHandler = new SystemPingQueryHandler();
            var bootstrapQueryHandler = new GetAppBootstrapQueryHandler(appOptions, appStateStore);
            var demoQueryHandler = new GetProjectDemoQueryHandler();
            var createProjectHandler = new CreateProjectCommandHandler(sessionStore);
            var importDataHandler = new ImportDataCommandHandler(sessionStore);
            var autoSuggestHandler = new AutoSuggestMappingQueryHandler();
            var commitMappingHandler = new CommitMappingCommandHandler(sessionStore);
            var validationHandler = new RunValidationQueryHandler(sessionStore);
            var prescreenHandler = new RunPrescreenQueryHandler(sessionStore);
            var filterHandler = new FilterScenarioCommandHandler(sessionStore);
            var exportHandler = new ExportReportCommandHandler();

            _routes = new Dictionary<string, Func<JsonElement, CancellationToken, Task<object?>>>(StringComparer.OrdinalIgnoreCase)
            {
                ["system.ping"] = async (_, ct) => await pingQueryHandler.HandleAsync(new SystemPingQuery(), ct),
                ["app.bootstrap"] = async (_, ct) => await bootstrapQueryHandler.HandleAsync(new GetAppBootstrapQuery(_supportedActions), ct),
                ["project.loadDemo"] = async (_, ct) => await demoQueryHandler.HandleAsync(new GetProjectDemoQuery(), ct),

                ["project.create"] = async (payload, ct) =>
                {
                    var cmd = new CreateProjectCommand(
                        GetString(payload, "projectCode"),
                        GetString(payload, "entityName"),
                        GetString(payload, "operatorId"),
                        GetString(payload, "industry"),
                        GetString(payload, "periodStart"),
                        GetString(payload, "periodEnd"),
                        GetString(payload, "lastPeriodStart"));
                    return await createProjectHandler.HandleAsync(cmd, ct);
                },

                ["import.gl"] = async (payload, ct) =>
                {
                    var fileName = GetString(payload, "fileName");
                    var rows = DeserializeRows(payload, "rows");
                    var columns = DeserializeStringList(payload, "columns");
                    sessionStore.SetGlData(fileName, rows, columns);
                    return new { fileName, rows, columns };
                },

                ["import.tb"] = async (payload, ct) =>
                {
                    var fileName = GetString(payload, "fileName");
                    var rows = DeserializeRows(payload, "rows");
                    var columns = DeserializeStringList(payload, "columns");
                    sessionStore.SetTbData(fileName, rows, columns);
                    return new { fileName, rows, columns };
                },

                ["import.accountMapping"] = async (payload, ct) =>
                {
                    var fileName = GetString(payload, "fileName");
                    var rows = DeserializeRows(payload, "rows");
                    sessionStore.SetAccountMappingData(fileName, rows);
                    return new { fileName, rows };
                },

                ["import.holiday"] = async (payload, ct) =>
                {
                    var dates = DeserializeStringList(payload, "dates");
                    sessionStore.SetHolidays(dates);
                    return new { dates };
                },

                ["import.makeupDay"] = async (payload, ct) =>
                {
                    var dates = DeserializeStringList(payload, "dates");
                    sessionStore.SetMakeupDays(dates);
                    return new { dates };
                },

                ["mapping.autoSuggest"] = async (payload, ct) =>
                {
                    var fields = DeserializeFieldDefinitions(payload);
                    var columns = DeserializeStringList(payload, "columns");
                    return await autoSuggestHandler.HandleAsync(new AutoSuggestMappingQuery(fields, columns), ct);
                },

                ["mapping.commit.gl"] = async (payload, ct) =>
                {
                    var mapping = DeserializeMapping(payload, "mapping");
                    return await commitMappingHandler.HandleCommitGlAsync(mapping, ct);
                },

                ["mapping.commit.tb"] = async (payload, ct) =>
                {
                    var mapping = DeserializeMapping(payload, "mapping");
                    return await commitMappingHandler.HandleCommitTbAsync(mapping, ct);
                },

                ["validate.run"] = async (_, ct) => await validationHandler.HandleAsync(ct),

                ["prescreen.run"] = async (_, ct) => await prescreenHandler.HandleAsync(ct),

                ["filter.preview"] = async (payload, ct) =>
                {
                    var scenario = payload.GetProperty("scenario");
                    return await filterHandler.HandlePreviewAsync(scenario, ct);
                },

                ["filter.commit"] = async (payload, ct) =>
                {
                    var scenarios = payload.GetProperty("scenarios");
                    return await filterHandler.HandleCommitAsync(scenarios, ct);
                },

                ["export.validation"] = async (_, ct) => await exportHandler.HandleExportValidationAsync(ct),
                ["export.prescreen"] = async (_, ct) => await exportHandler.HandleExportPrescreenAsync(ct),
                ["export.criteria"] = async (_, ct) => await exportHandler.HandleExportCriteriaAsync(ct),
                ["export.workpaper"] = async (payload, ct) =>
                {
                    var selected = payload.GetProperty("selected");
                    return await exportHandler.HandleExportWorkpaperAsync(selected, ct);
                },
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

        private static string GetString(JsonElement element, string propertyName)
        {
            return element.TryGetProperty(propertyName, out var prop) ? prop.GetString() ?? string.Empty : string.Empty;
        }

        private static List<Dictionary<string, object?>> DeserializeRows(JsonElement element, string propertyName)
        {
            if (!element.TryGetProperty(propertyName, out var arr) || arr.ValueKind != JsonValueKind.Array)
                return [];

            var rows = new List<Dictionary<string, object?>>();
            foreach (var item in arr.EnumerateArray())
            {
                var row = new Dictionary<string, object?>();
                foreach (var prop in item.EnumerateObject())
                {
                    row[prop.Name] = prop.Value.ValueKind switch
                    {
                        JsonValueKind.Number => prop.Value.TryGetInt64(out var l) ? (object)l : prop.Value.GetDouble(),
                        JsonValueKind.True => true,
                        JsonValueKind.False => false,
                        JsonValueKind.Null => null,
                        _ => prop.Value.GetString()
                    };
                }
                rows.Add(row);
            }
            return rows;
        }

        private static List<string> DeserializeStringList(JsonElement element, string propertyName)
        {
            if (!element.TryGetProperty(propertyName, out var arr) || arr.ValueKind != JsonValueKind.Array)
                return [];

            return arr.EnumerateArray().Select(e => e.GetString() ?? string.Empty).ToList();
        }

        private static List<FieldDefinition> DeserializeFieldDefinitions(JsonElement element)
        {
            if (!element.TryGetProperty("fields", out var arr) || arr.ValueKind != JsonValueKind.Array)
                return [];

            return arr.EnumerateArray().Select(e => new FieldDefinition(
                e.TryGetProperty("key", out var k) ? k.GetString() ?? "" : "",
                e.TryGetProperty("label", out var l) ? l.GetString() ?? "" : "",
                e.TryGetProperty("req", out var r) && r.GetBoolean(),
                e.TryGetProperty("type", out var t) ? t.GetString() ?? "" : ""
            )).ToList();
        }

        private static Dictionary<string, string> DeserializeMapping(JsonElement element, string propertyName)
        {
            if (!element.TryGetProperty(propertyName, out var obj) || obj.ValueKind != JsonValueKind.Object)
                return new Dictionary<string, string>();

            var dict = new Dictionary<string, string>();
            foreach (var prop in obj.EnumerateObject())
            {
                dict[prop.Name] = prop.Value.GetString() ?? string.Empty;
            }
            return dict;
        }
    }
}

