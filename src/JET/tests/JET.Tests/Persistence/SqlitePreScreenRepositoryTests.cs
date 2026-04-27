using Dapper;
using JET.Domain.Abstractions.Persistence;
using JET.Infrastructure.Persistence.Schema;
using JET.Infrastructure.Persistence.Sqlite;
using JET.Infrastructure.Persistence.Sqlite.Repositories;
using Microsoft.Data.Sqlite;
using Xunit;

namespace JET.Tests.Persistence;

public sealed class SqlitePreScreenRepositoryTests
{
    private const string ProjectId = "00000000-0000-0000-0000-0000000000dd";
    private static readonly ISchemaNames Names = new SqliteSchemaNames();

    [Fact]
    public async Task RunAsync_returns_summary_counts_without_rows_payload()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("prescreen-run");
        await using var _ = keepAlive;
        await SeedAsync(connectionString);

        var repository = new SqlitePreScreenRepository(connectionString, Names);
        var result = await repository.RunAsync(ProjectId, CancellationToken.None);

        Assert.False(string.IsNullOrWhiteSpace(result.RunId));
        Assert.Equal(2, result.R1);
        Assert.Equal(1, result.R2);
        Assert.Equal(2, result.R4);
        Assert.Equal(3, result.R5Summary.Sum(x => x.Count));
        Assert.Equal(1, result.DescNullCount);
    }

    [Fact]
    public async Task QueryPageAsync_returns_keyset_pages()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("prescreen-page");
        await using var _ = keepAlive;
        await SeedAsync(connectionString);

        var repository = new SqlitePreScreenRepository(connectionString, Names);
        await repository.RunAsync(ProjectId, CancellationToken.None);

        var first = await repository.QueryPageAsync(ProjectId, "r5", null, 1, CancellationToken.None);
        var second = await repository.QueryPageAsync(ProjectId, "r5", first.NextCursor, 1, CancellationToken.None);

        Assert.Single(first.Rows);
        Assert.NotNull(first.NextCursor);
        Assert.Single(second.Rows);
        Assert.True(second.Rows[0].RowNo > first.Rows[0].RowNo);
    }

    private static async Task SeedAsync(string connectionString)
    {
        await using var connection = new SqliteConnection(connectionString);
        await connection.OpenAsync();
        await connection.ExecuteAsync($"""
            INSERT INTO {Names.Resolve(JetTable.ConfigProject)}
                (project_id, project_code, entity_name, operator_id, industry, period_start, period_end, last_period_start, created_utc)
            VALUES
                (@ProjectId, 'P', 'E', 'O', 'I', '2024-01-01', '2024-12-31', '2024-12-20', '2024-01-01T00:00:00Z');

            INSERT INTO {Names.Resolve(JetTable.TargetGlEntry)}
                (project_id, batch_id, doc_num, line_id, post_date, doc_date, acc_num, acc_name, description, je_source, create_by, approve_by, manual, dr_amount, cr_amount, amount)
            VALUES
                (@ProjectId, 'b1', 'D1', '1', '2024-12-21', '2024-12-21', '1001', 'Cash', 'adj close', 'GL', 'amy', 'mgr', 1, 1000, 0, 1000),
                (@ProjectId, 'b1', 'D1', '2', '2024-12-21', '2024-12-21', '4001', 'Revenue', 'normal', 'GL', 'amy', 'mgr', 1, 0, 1000, -1000),
                (@ProjectId, 'b1', 'D2', '1', '2024-01-05', '2024-01-05', '2001', 'AP', '', 'GL', 'bob', 'mgr', 0, 123, 0, 123);
            """, new { ProjectId });
    }

    private static async Task<(string ConnectionString, SqliteConnection KeepAlive)> OpenSharedMemoryAsync(string name)
    {
        var connectionString = $"Data Source={name};Mode=Memory;Cache=Shared";
        var keepAlive = new SqliteConnection(connectionString);
        await keepAlive.OpenAsync();
        await new SqliteSchemaInitializer(connectionString, Names).EnsureAsync(CancellationToken.None);
        return (connectionString, keepAlive);
    }
}
