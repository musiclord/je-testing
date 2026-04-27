using JET.Application.Queries.LoadProject;
using JET.Domain.Entities;
using JET.Infrastructure.Persistence;
using JET.Infrastructure.Persistence.Sqlite;
using JET.Infrastructure.Persistence.Sqlite.Repositories;
using JET.Infrastructure.Persistence.Schema;
using JET.Domain.Abstractions.Persistence;
using Microsoft.Data.Sqlite;
using Xunit;

namespace JET.Tests.Application;

public sealed class LoadProjectQueryHandlerTests
{
    private static readonly ISchemaNames Names = new SqliteSchemaNames();

    [Fact]
    public async Task LoadAsync_returns_project_metadata_and_sets_session_pointer()
    {
        var cs = "Data Source=load-project;Mode=Memory;Cache=Shared";
        await using var keep = new SqliteConnection(cs);
        await keep.OpenAsync();
        await new SqliteSchemaInitializer(cs, Names).EnsureAsync(CancellationToken.None);

        var repo = new SqliteProjectRepository(cs, Names);
        var pid = await repo.CreateAsync(new ProjectInfo
        {
            ProjectCode = "PJ-1",
            EntityName = "ACME",
            OperatorId = "op",
            Industry = "Tech",
            PeriodStart = "2024-01-01",
            PeriodEnd = "2024-12-31",
            LastPeriodStart = "2024-12-20"
        }, CancellationToken.None);

        var session = new InMemoryProjectSessionStore();
        var handler = new LoadProjectQueryHandler(session, repo);
        var result = await handler.HandleAsync(new LoadProjectQuery(pid), CancellationToken.None);

        Assert.Equal(pid, session.CurrentProjectId);
        var pidProp = result.GetType().GetProperty("projectId")!.GetValue(result) as string;
        Assert.Equal(pid, pidProp);
        var project = result.GetType().GetProperty("project")!.GetValue(result) as ProjectInfo;
        Assert.NotNull(project);
        Assert.Equal("PJ-1", project!.ProjectCode);
    }

    [Fact]
    public async Task LoadAsync_unknown_project_returns_empty_payload()
    {
        var cs = "Data Source=load-project-empty;Mode=Memory;Cache=Shared";
        await using var keep = new SqliteConnection(cs);
        await keep.OpenAsync();
        await new SqliteSchemaInitializer(cs, Names).EnsureAsync(CancellationToken.None);

        var repo = new SqliteProjectRepository(cs, Names);
        var session = new InMemoryProjectSessionStore();
        var handler = new LoadProjectQueryHandler(session, repo);
        var result = await handler.HandleAsync(new LoadProjectQuery("00000000-0000-0000-0000-000000000000"), CancellationToken.None);

        Assert.Null(session.CurrentProjectId);
        var pidProp = result.GetType().GetProperty("projectId")!.GetValue(result) as string;
        Assert.Equal(string.Empty, pidProp);
    }
}
