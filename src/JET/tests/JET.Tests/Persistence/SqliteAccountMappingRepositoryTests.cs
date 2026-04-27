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

public sealed class SqliteAccountMappingRepositoryTests
{
    private const string ProjectId = "00000000-0000-0000-0000-0000000000ee";
    private static readonly ISchemaNames Names = new SqliteSchemaNames();

    [Fact]
    public async Task BulkInsertStagingAsync_persists_batch_columns_and_rows()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("acctmap-repo-persist");
        await using var _ = keepAlive;

        var repository = new SqliteAccountMappingRepository(connectionString, Names);
        var stream = AsAsync(new[]
        {
            new GlRawRow(0, new string?[] { "AccountNo", "Category" }),
            new GlRawRow(1, new string?[] { "1101", "Cash" }),
            new GlRawRow(2, new string?[] { "1102", "Receivable" }),
        });

        var result = await repository.BulkInsertStagingAsync(ProjectId, "acctmap.xlsx", stream, "replace", CancellationToken.None);

        Assert.False(string.IsNullOrWhiteSpace(result.BatchId));
        Assert.Equal(2, result.RowCount);
        Assert.Equal(new[] { "AccountNo", "Category" }, result.Columns);

        await using var probe = new SqliteConnection(connectionString);
        await probe.OpenAsync();

        var batchRow = await probe.QuerySingleAsync<(string batch_id, string project_id, string dataset_kind, long row_count, string file_name)>(
            $"SELECT batch_id, project_id, dataset_kind, row_count, file_name FROM {Names.Resolve(JetTable.ConfigImportBatch)};");
        Assert.Equal(result.BatchId, batchRow.batch_id);
        Assert.Equal(ProjectId, batchRow.project_id);
        Assert.Equal("accountMapping", batchRow.dataset_kind);
        Assert.Equal(2L, batchRow.row_count);
        Assert.Equal("acctmap.xlsx", batchRow.file_name);

        var columns = (await probe.QueryAsync<(long column_index, string column_name)>(
            $"SELECT column_index, column_name FROM {Names.Resolve(JetTable.ConfigImportColumn)} WHERE batch_id = @id ORDER BY column_index;",
            new { id = result.BatchId })).ToArray();
        Assert.Equal(2, columns.Length);
        Assert.Equal("AccountNo", columns[0].column_name);
        Assert.Equal("Category", columns[1].column_name);

        var dataRows = (await probe.QueryAsync<(long row_index, string payload)>(
            $"SELECT row_index, payload FROM {Names.Resolve(JetTable.StagingAccountMappingRawRow)} WHERE batch_id = @id ORDER BY row_index;",
            new { id = result.BatchId })).ToArray();
        Assert.Equal(2, dataRows.Length);
        Assert.Equal(1L, dataRows[0].row_index);
        var firstPayload = JsonSerializer.Deserialize<string?[]>(dataRows[0].payload)!;
        Assert.Equal(new[] { "1101", "Cash" }, firstPayload);
    }

    [Fact]
    public async Task BulkInsertStagingAsync_replace_mode_clears_prior_batch()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("acctmap-repo-replace");
        await using var _ = keepAlive;

        var repository = new SqliteAccountMappingRepository(connectionString, Names);

        await repository.BulkInsertStagingAsync(ProjectId, "first.xlsx", AsAsync(new[]
        {
            new GlRawRow(0, new string?[] { "AccountNo" }),
            new GlRawRow(1, new string?[] { "1101" }),
        }), "replace", CancellationToken.None);

        var second = await repository.BulkInsertStagingAsync(ProjectId, "second.xlsx", AsAsync(new[]
        {
            new GlRawRow(0, new string?[] { "AccountNo", "Category" }),
            new GlRawRow(1, new string?[] { "1900", "Other" }),
        }), "replace", CancellationToken.None);

        await using var probe = new SqliteConnection(connectionString);
        await probe.OpenAsync();

        var batchCount = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.ConfigImportBatch)} WHERE project_id = @p AND dataset_kind = 'accountMapping';",
            new { p = ProjectId });
        Assert.Equal(1L, batchCount);

        var rawRowCount = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.StagingAccountMappingRawRow)};");
        Assert.Equal(1L, rawRowCount);

        var remainingBatchId = await probe.ExecuteScalarAsync<string>(
            $"SELECT batch_id FROM {Names.Resolve(JetTable.ConfigImportBatch)};");
        Assert.Equal(second.BatchId, remainingBatchId);
    }

    [Fact]
    public async Task BulkInsertStagingAsync_append_mode_keeps_prior_batch()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("acctmap-repo-append");
        await using var _ = keepAlive;

        var repository = new SqliteAccountMappingRepository(connectionString, Names);

        await repository.BulkInsertStagingAsync(ProjectId, "first.xlsx", AsAsync(new[]
        {
            new GlRawRow(0, new string?[] { "AccountNo" }),
            new GlRawRow(1, new string?[] { "1101" }),
        }), "replace", CancellationToken.None);

        await repository.BulkInsertStagingAsync(ProjectId, "second.xlsx", AsAsync(new[]
        {
            new GlRawRow(0, new string?[] { "AccountNo" }),
            new GlRawRow(1, new string?[] { "1102" }),
        }), "append", CancellationToken.None);

        await using var probe = new SqliteConnection(connectionString);
        await probe.OpenAsync();

        var batchCount = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.ConfigImportBatch)};");
        Assert.Equal(2L, batchCount);

        var rawRowCount = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.StagingAccountMappingRawRow)};");
        Assert.Equal(2L, rawRowCount);
    }

    [Fact]
    public async Task BulkInsertStagingAsync_throws_when_no_header_row()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("acctmap-repo-empty");
        await using var _ = keepAlive;

        var repository = new SqliteAccountMappingRepository(connectionString, Names);

        await Assert.ThrowsAsync<InvalidOperationException>(async () =>
            await repository.BulkInsertStagingAsync(ProjectId, "empty.xlsx", AsAsync(Array.Empty<GlRawRow>()), "replace", CancellationToken.None));
    }

    [Fact]
    public async Task BulkInsertStagingAsync_rejects_unknown_mode()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("acctmap-repo-mode");
        await using var _ = keepAlive;

        var repository = new SqliteAccountMappingRepository(connectionString, Names);

        await Assert.ThrowsAsync<ArgumentException>(async () =>
            await repository.BulkInsertStagingAsync(ProjectId, "file.xlsx", AsAsync(new[]
            {
                new GlRawRow(0, new string?[] { "AccountNo" }),
            }), "merge", CancellationToken.None));
    }

    [Fact]
    public async Task BulkInsertStagingAsync_isolates_gl_tb_and_accountMapping_dataset_kinds()
    {
        // Mission constraint sanity: GL/TB/AccountMapping share the import-batch/column tables
        // but must remain isolated by dataset_kind so replace-mode on AccountMapping never wipes GL or TB.
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("acctmap-repo-isolation");
        await using var _ = keepAlive;

        var glRepo = new SqliteGlRepository(connectionString, Names);
        var tbRepo = new SqliteTbRepository(connectionString, Names);
        var acctMapRepo = new SqliteAccountMappingRepository(connectionString, Names);

        await glRepo.BulkInsertStagingAsync(ProjectId, "gl.xlsx", AsAsync(new[]
        {
            new GlRawRow(0, new string?[] { "DocNum" }),
            new GlRawRow(1, new string?[] { "V001" }),
        }), "replace", CancellationToken.None);

        await tbRepo.BulkInsertStagingAsync(ProjectId, "tb.xlsx", AsAsync(new[]
        {
            new GlRawRow(0, new string?[] { "Account" }),
            new GlRawRow(1, new string?[] { "1101" }),
        }), "replace", CancellationToken.None);

        await acctMapRepo.BulkInsertStagingAsync(ProjectId, "acctmap.xlsx", AsAsync(new[]
        {
            new GlRawRow(0, new string?[] { "AccountNo" }),
            new GlRawRow(1, new string?[] { "1101" }),
        }), "replace", CancellationToken.None);

        await using var probe = new SqliteConnection(connectionString);
        await probe.OpenAsync();

        var glBatches = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.ConfigImportBatch)} WHERE dataset_kind = 'gl';");
        var tbBatches = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.ConfigImportBatch)} WHERE dataset_kind = 'tb';");
        var acctMapBatches = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.ConfigImportBatch)} WHERE dataset_kind = 'accountMapping';");
        Assert.Equal(1L, glBatches);
        Assert.Equal(1L, tbBatches);
        Assert.Equal(1L, acctMapBatches);

        var glRawCount = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.StagingGlRawRow)};");
        var tbRawCount = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.StagingTbRawRow)};");
        var acctMapRawCount = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.StagingAccountMappingRawRow)};");
        Assert.Equal(1L, glRawCount);
        Assert.Equal(1L, tbRawCount);
        Assert.Equal(1L, acctMapRawCount);
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
