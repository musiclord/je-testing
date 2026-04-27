using Dapper;
using JET.Domain.Abstractions.Persistence;
using JET.Infrastructure.Persistence.Schema;
using JET.Infrastructure.Persistence.Sqlite;
using JET.Infrastructure.Persistence.Sqlite.Repositories;
using Microsoft.Data.Sqlite;
using Xunit;

namespace JET.Tests.Persistence;

public sealed class SqliteValidationRepositoryTests
{
    private const string ProjectId = "00000000-0000-0000-0000-0000000000cc";
    private static readonly ISchemaNames Names = new SqliteSchemaNames();

    [Fact]
    public async Task RunAsync_computes_v1_to_v4_and_persists_result_rows()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("validation-v");
        await using var _ = keepAlive;
        await SeedProjectAsync(connectionString);
        await SeedGlAsync(connectionString);

        var repository = new SqliteValidationRepository(connectionString, Names);
        var result = await repository.RunAsync(ProjectId, CancellationToken.None);

        Assert.False(string.IsNullOrWhiteSpace(result.RunId));
        Assert.Equal(4, result.Stats.Total);
        Assert.Equal(2, result.Stats.Docs);
        Assert.Equal(2, result.V1);
        Assert.Equal(1, result.V2);
        Assert.Equal(1, result.V3);
        Assert.Equal(1, result.V4);
        Assert.Equal(5, result.Summary.NullRecordCount);

        await using var probe = new SqliteConnection(connectionString);
        await probe.OpenAsync();
        Assert.Equal(2L, await CountAsync(probe, JetTable.ResultValidationV1, result.RunId));
        Assert.Equal(1L, await CountAsync(probe, JetTable.ResultValidationV2, result.RunId));
        Assert.Equal(1L, await CountAsync(probe, JetTable.ResultValidationV3, result.RunId));
        Assert.Equal(1L, await CountAsync(probe, JetTable.ResultValidationV4, result.RunId));
    }

    [Fact]
    public async Task RunAsync_computes_completeness_diff_and_out_of_balance_summary()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("validation-summary");
        await using var _ = keepAlive;
        await SeedProjectAsync(connectionString);
        await SeedGlAsync(connectionString);
        await SeedTbAsync(connectionString);

        var repository = new SqliteValidationRepository(connectionString, Names);
        var result = await repository.RunAsync(ProjectId, CancellationToken.None);

        Assert.Contains(result.DiffAccounts, row => row.Acc == "9999");
        Assert.Equal(result.DiffAccounts.Count, result.Summary.CompletenessDiffAccounts);
        Assert.Equal(2, result.Summary.OutOfBalanceDocuments);
        Assert.Equal(4, result.Summary.InfSampleSize);
    }

    [Fact]
    public async Task QueryDetailsPageAsync_returns_keyset_pages()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("validation-page");
        await using var _ = keepAlive;
        await SeedProjectAsync(connectionString);
        await SeedGlAsync(connectionString);

        var repository = new SqliteValidationRepository(connectionString, Names);
        await repository.RunAsync(ProjectId, CancellationToken.None);

        var first = await repository.QueryDetailsPageAsync(ProjectId, "v1", null, 1, CancellationToken.None);
        var second = await repository.QueryDetailsPageAsync(ProjectId, "v1", first.NextCursor, 1, CancellationToken.None);

        Assert.Single(first.Rows);
        Assert.NotNull(first.NextCursor);
        Assert.Single(second.Rows);
        Assert.Null(second.NextCursor);
        Assert.True(second.Rows[0].RowNo > first.Rows[0].RowNo);
    }

    private static async Task SeedProjectAsync(string connectionString)
    {
        await using var connection = new SqliteConnection(connectionString);
        await connection.OpenAsync();
        await connection.ExecuteAsync($"""
            INSERT INTO {Names.Resolve(JetTable.ConfigProject)}
                (project_id, project_code, entity_name, operator_id, industry, period_start, period_end, last_period_start, created_utc)
            VALUES
                (@ProjectId, 'P', 'E', 'O', 'I', '2024-01-01', '2024-12-31', '2024-12-01', '2024-01-01T00:00:00Z');
            """, new { ProjectId });
    }

    private static async Task SeedGlAsync(string connectionString)
    {
        await using var connection = new SqliteConnection(connectionString);
        await connection.OpenAsync();
        await connection.ExecuteAsync($"""
            INSERT INTO {Names.Resolve(JetTable.TargetGlEntry)}
                (project_id, batch_id, doc_num, line_id, post_date, doc_date, acc_num, acc_name, description, je_source, create_by, approve_by, manual, dr_amount, cr_amount, amount)
            VALUES
                (@ProjectId, 'b1', 'D1', '1', '2024-01-05', '2024-01-05', '1001', 'Cash', 'ok', 'GL', 'u', 'a', 1, 100, 0, 100),
                (@ProjectId, 'b1', 'D1', '2', '2024-01-05', '2024-01-05', '', 'Blank', '', 'GL', 'u', 'a', 1, 0, 50, -50),
                (@ProjectId, 'b1', 'D2', '1', '2025-01-05', '2025-01-05', NULL, 'Null', 'out', 'GL', 'u', 'a', 0, 10, 0, 10),
                (@ProjectId, 'b1', '', '1', '2024-02-01', '2024-02-01', '2001', 'AP', 'missing doc', 'GL', 'u', 'a', 0, 0, 10, -10);
            """, new { ProjectId });
    }

    private static async Task SeedTbAsync(string connectionString)
    {
        await using var connection = new SqliteConnection(connectionString);
        await connection.OpenAsync();
        await connection.ExecuteAsync($"""
            INSERT INTO {Names.Resolve(JetTable.TargetTbBalance)}
                (project_id, batch_id, acc_num, acc_name, change_amount)
            VALUES
                (@ProjectId, 'tb1', '1001', 'Cash', 100),
                (@ProjectId, 'tb1', '9999', 'Missing', 1);
            """, new { ProjectId });
    }

    private static async Task<long> CountAsync(SqliteConnection connection, JetTable table, string runId)
    {
        return await connection.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(table)} WHERE project_id = @ProjectId AND run_id = @RunId;",
            new { ProjectId, RunId = runId });
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
