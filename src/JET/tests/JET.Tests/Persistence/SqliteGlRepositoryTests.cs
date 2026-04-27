using System.Text.Json;
using Dapper;
using JET.Domain.Abstractions.Persistence;
using JET.Domain.Entities;
using JET.Infrastructure.Persistence.Schema;
using JET.Infrastructure.Persistence.Sqlite;
using JET.Infrastructure.Persistence.Sqlite.Repositories;
using Microsoft.Data.Sqlite;
using Xunit;

namespace JET.Tests.Persistence;

public sealed class SqliteGlRepositoryTests
{
    private const string ProjectId = "00000000-0000-0000-0000-0000000000aa";
    private static readonly ISchemaNames Names = new SqliteSchemaNames();

    [Fact]
    public async Task BulkInsertStagingAsync_persists_batch_columns_and_rows()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("gl-repo-persist");
        await using var _ = keepAlive;

        var repository = new SqliteGlRepository(connectionString, Names);
        var stream = AsAsync(new[]
        {
            new GlRawRow(0, new string?[] { "DocNum", "Amount" }),
            new GlRawRow(1, new string?[] { "V001", "100" }),
            new GlRawRow(2, new string?[] { "V002", "200" }),
        });

        var result = await repository.BulkInsertStagingAsync(ProjectId, "gl.xlsx", stream, "replace", CancellationToken.None);

        Assert.False(string.IsNullOrWhiteSpace(result.BatchId));
        Assert.Equal(2, result.RowCount);
        Assert.Equal(new[] { "DocNum", "Amount" }, result.Columns);

        await using var probe = new SqliteConnection(connectionString);
        await probe.OpenAsync();

        var batchRow = await probe.QuerySingleAsync<(string batch_id, string project_id, string dataset_kind, long row_count, string file_name)>(
            $"SELECT batch_id, project_id, dataset_kind, row_count, file_name FROM {Names.Resolve(JetTable.ConfigImportBatch)};");
        Assert.Equal(result.BatchId, batchRow.batch_id);
        Assert.Equal(ProjectId, batchRow.project_id);
        Assert.Equal("gl", batchRow.dataset_kind);
        Assert.Equal(2L, batchRow.row_count);
        Assert.Equal("gl.xlsx", batchRow.file_name);

        var columns = (await probe.QueryAsync<(long column_index, string column_name)>(
            $"SELECT column_index, column_name FROM {Names.Resolve(JetTable.ConfigImportColumn)} WHERE batch_id = @id ORDER BY column_index;",
            new { id = result.BatchId })).ToArray();
        Assert.Equal(2, columns.Length);
        Assert.Equal("DocNum", columns[0].column_name);
        Assert.Equal("Amount", columns[1].column_name);

        var dataRows = (await probe.QueryAsync<(long row_index, string payload)>(
            $"SELECT row_index, payload FROM {Names.Resolve(JetTable.StagingGlRawRow)} WHERE batch_id = @id ORDER BY row_index;",
            new { id = result.BatchId })).ToArray();
        Assert.Equal(2, dataRows.Length);
        Assert.Equal(1L, dataRows[0].row_index);
        var firstPayload = JsonSerializer.Deserialize<string?[]>(dataRows[0].payload)!;
        Assert.Equal(new[] { "V001", "100" }, firstPayload);
    }

    [Fact]
    public async Task BulkInsertStagingAsync_replace_mode_clears_prior_batch()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("gl-repo-replace");
        await using var _ = keepAlive;

        var repository = new SqliteGlRepository(connectionString, Names);

        await repository.BulkInsertStagingAsync(ProjectId, "first.xlsx", AsAsync(new[]
        {
            new GlRawRow(0, new string?[] { "DocNum" }),
            new GlRawRow(1, new string?[] { "V001" }),
        }), "replace", CancellationToken.None);

        var second = await repository.BulkInsertStagingAsync(ProjectId, "second.xlsx", AsAsync(new[]
        {
            new GlRawRow(0, new string?[] { "DocNum", "Amount" }),
            new GlRawRow(1, new string?[] { "V900", "9000" }),
        }), "replace", CancellationToken.None);

        await using var probe = new SqliteConnection(connectionString);
        await probe.OpenAsync();

        var batchCount = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.ConfigImportBatch)} WHERE project_id = @p AND dataset_kind = 'gl';",
            new { p = ProjectId });
        Assert.Equal(1L, batchCount);

        var rawRowCount = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.StagingGlRawRow)};");
        Assert.Equal(1L, rawRowCount);

        var remainingBatchId = await probe.ExecuteScalarAsync<string>(
            $"SELECT batch_id FROM {Names.Resolve(JetTable.ConfigImportBatch)};");
        Assert.Equal(second.BatchId, remainingBatchId);
    }

    [Fact]
    public async Task BulkInsertStagingAsync_append_mode_keeps_prior_batch()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("gl-repo-append");
        await using var _ = keepAlive;

        var repository = new SqliteGlRepository(connectionString, Names);

        await repository.BulkInsertStagingAsync(ProjectId, "first.xlsx", AsAsync(new[]
        {
            new GlRawRow(0, new string?[] { "DocNum" }),
            new GlRawRow(1, new string?[] { "V001" }),
        }), "replace", CancellationToken.None);

        await repository.BulkInsertStagingAsync(ProjectId, "second.xlsx", AsAsync(new[]
        {
            new GlRawRow(0, new string?[] { "DocNum" }),
            new GlRawRow(1, new string?[] { "V002" }),
        }), "append", CancellationToken.None);

        await using var probe = new SqliteConnection(connectionString);
        await probe.OpenAsync();

        var batchCount = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.ConfigImportBatch)};");
        Assert.Equal(2L, batchCount);

        var rawRowCount = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.StagingGlRawRow)};");
        Assert.Equal(2L, rawRowCount);
    }

    [Fact]
    public async Task BulkInsertStagingAsync_throws_when_no_header_row()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("gl-repo-empty");
        await using var _ = keepAlive;

        var repository = new SqliteGlRepository(connectionString, Names);

        await Assert.ThrowsAsync<InvalidOperationException>(async () =>
            await repository.BulkInsertStagingAsync(ProjectId, "empty.xlsx", AsAsync(Array.Empty<GlRawRow>()), "replace", CancellationToken.None));
    }

    [Fact]
    public async Task BulkInsertStagingAsync_rejects_unknown_mode()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("gl-repo-mode");
        await using var _ = keepAlive;

        var repository = new SqliteGlRepository(connectionString, Names);

        await Assert.ThrowsAsync<ArgumentException>(async () =>
            await repository.BulkInsertStagingAsync(ProjectId, "file.xlsx", AsAsync(new[]
            {
                new GlRawRow(0, new string?[] { "DocNum" }),
            }), "merge", CancellationToken.None));
    }

    private static async IAsyncEnumerable<GlRawRow> AsAsync(IEnumerable<GlRawRow> rows)
    {
        foreach (var r in rows)
        {
            yield return r;
        }
        await Task.CompletedTask;
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
