using Dapper;
using JET.Domain.Abstractions.Persistence;
using JET.Domain.Entities;
using JET.Infrastructure.Persistence.Schema;
using JET.Infrastructure.Persistence.Sqlite;
using JET.Infrastructure.Persistence.Sqlite.Repositories;
using Microsoft.Data.Sqlite;
using Xunit;

namespace JET.Tests.Persistence;

public sealed class SqliteProjectRepositoryTests
{
    private static readonly ISchemaNames Names = new SqliteSchemaNames();

    [Fact]
    public async Task CreateAsync_ShouldPersistProjectAndState()
    {
        var connectionString = "Data Source=project-repo-test;Mode=Memory;Cache=Shared";
        await using var keepAlive = new SqliteConnection(connectionString);
        await keepAlive.OpenAsync();

        await new SqliteSchemaInitializer(connectionString, Names).EnsureAsync(CancellationToken.None);
        var repository = new SqliteProjectRepository(connectionString, Names);

        var project = new ProjectInfo
        {
            ProjectCode = "JET-2025-001",
            EntityName = "Acme Audit Subject Co., Ltd.",
            OperatorId = "auditor-007",
            Industry = "manufacturing",
            PeriodStart = "2025-01-01",
            PeriodEnd = "2025-12-31",
            LastPeriodStart = "2024-01-01",
        };

        var projectId = await repository.CreateAsync(project, CancellationToken.None);

        Assert.False(string.IsNullOrWhiteSpace(projectId));

        await using var probe = new SqliteConnection(connectionString);
        await probe.OpenAsync();

        var projectRow = await probe.QuerySingleAsync<(string project_id, string project_code, string entity_name, string operator_id, string industry, string period_start, string period_end, string last_period_start, string created_utc)>(
            $"SELECT project_id, project_code, entity_name, operator_id, industry, period_start, period_end, last_period_start, created_utc FROM {Names.Resolve(JetTable.ConfigProject)} WHERE project_id = @id;",
            new { id = projectId });

        Assert.Equal(projectId, projectRow.project_id);
        Assert.Equal(project.ProjectCode, projectRow.project_code);
        Assert.Equal(project.EntityName, projectRow.entity_name);
        Assert.Equal(project.OperatorId, projectRow.operator_id);
        Assert.Equal(project.Industry, projectRow.industry);
        Assert.Equal(project.PeriodStart, projectRow.period_start);
        Assert.Equal(project.PeriodEnd, projectRow.period_end);
        Assert.Equal(project.LastPeriodStart, projectRow.last_period_start);
        Assert.False(string.IsNullOrWhiteSpace(projectRow.created_utc));

        var stateRow = await probe.QuerySingleAsync<(string project_id, long current_step, string updated_utc)>(
            $"SELECT project_id, current_step, updated_utc FROM {Names.Resolve(JetTable.ConfigProjectState)} WHERE project_id = @id;",
            new { id = projectId });

        Assert.Equal(projectId, stateRow.project_id);
        Assert.Equal(1L, stateRow.current_step);
        Assert.False(string.IsNullOrWhiteSpace(stateRow.updated_utc));
    }

    [Fact]
    public async Task CreateAsync_ShouldReturnDistinctIdsAcrossInvocations()
    {
        var connectionString = "Data Source=project-repo-distinct;Mode=Memory;Cache=Shared";
        await using var keepAlive = new SqliteConnection(connectionString);
        await keepAlive.OpenAsync();

        await new SqliteSchemaInitializer(connectionString, Names).EnsureAsync(CancellationToken.None);
        var repository = new SqliteProjectRepository(connectionString, Names);

        var project = new ProjectInfo { ProjectCode = "P-1", EntityName = "E", OperatorId = "O", Industry = "I", PeriodStart = "2025-01-01", PeriodEnd = "2025-12-31", LastPeriodStart = "2024-01-01" };

        var first = await repository.CreateAsync(project, CancellationToken.None);
        var second = await repository.CreateAsync(project, CancellationToken.None);

        Assert.NotEqual(first, second);

        var count = await keepAlive.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.ConfigProject)};");
        Assert.Equal(2L, count);
    }
}
