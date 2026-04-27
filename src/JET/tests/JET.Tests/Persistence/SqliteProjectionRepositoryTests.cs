using Dapper;
using JET.Domain.Abstractions.Persistence;
using JET.Domain.Entities;
using JET.Infrastructure.Persistence.Schema;
using JET.Infrastructure.Persistence.Sqlite;
using JET.Infrastructure.Persistence.Sqlite.Repositories;
using Microsoft.Data.Sqlite;
using Xunit;

namespace JET.Tests.Persistence;

public sealed class SqliteProjectionRepositoryTests
{
    private const string ProjectId = "00000000-0000-0000-0000-0000000000bb";
    private static readonly ISchemaNames Names = new SqliteSchemaNames();

    [Fact]
    public async Task GlProjection_projects_latest_staging_batch_to_target_gl_entry()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("projection-gl");
        await using var _ = keepAlive;

        var import = new SqliteGlRepository(connectionString, Names);
        var imported = await import.BulkInsertStagingAsync(ProjectId, "gl.xlsx", AsAsync(new[]
        {
            new GlRawRow(0, new string?[] { "Document Number", "Line Item", "Post Date", "Approval Date", "Account Number", "Account Name", "Description", "Source Module", "Created By", "Approved By", "Manual", "Amount" }),
            new GlRawRow(1, new string?[] { "JE-1", "1", "2024-01-01", "2024-01-02", "1001", "Cash", "Debit row", "GL", "amy", "bob", "1", "125.50" }),
            new GlRawRow(2, new string?[] { "JE-1", "2", "2024-01-01", "2024-01-02", "4001", "Revenue", "Credit row", "GL", "amy", "bob", "1", "-125.50" }),
        }), "replace", CancellationToken.None);

        var repository = new SqliteGlProjectionRepository(connectionString, Names);
        var result = await repository.ProjectLatestBatchAsync(ProjectId, GlMapping(), CancellationToken.None);

        Assert.Equal(imported.BatchId, result.BatchId);
        Assert.Equal(2, result.ProjectedRowCount);

        await using var probe = new SqliteConnection(connectionString);
        await probe.OpenAsync();
        var rows = (await probe.QueryAsync<(string doc_num, string line_id, string acc_num, double dr_amount, double cr_amount, double amount)>(
            $"SELECT doc_num, line_id, acc_num, dr_amount, cr_amount, amount FROM {Names.Resolve(JetTable.TargetGlEntry)} ORDER BY line_id;")).ToArray();

        Assert.Equal(2, rows.Length);
        Assert.Equal(("JE-1", "1", "1001", 125.50, 0, 125.50), rows[0]);
        Assert.Equal(("JE-1", "2", "4001", 0, 125.50, -125.50), rows[1]);
    }

    [Fact]
    public async Task TbProjection_projects_latest_staging_batch_to_target_tb_balance()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("projection-tb");
        await using var _ = keepAlive;

        var import = new SqliteTbRepository(connectionString, Names);
        var imported = await import.BulkInsertStagingAsync(ProjectId, "tb.xlsx", AsAsync(new[]
        {
            new GlRawRow(0, new string?[] { "Account Number", "Account Name", "Change Amount" }),
            new GlRawRow(1, new string?[] { "1001", "Cash", "125.50" }),
        }), "replace", CancellationToken.None);

        var repository = new SqliteTbProjectionRepository(connectionString, Names);
        var result = await repository.ProjectLatestBatchAsync(ProjectId, TbMapping(), CancellationToken.None);

        Assert.Equal(imported.BatchId, result.BatchId);
        Assert.Equal(1, result.ProjectedRowCount);

        await using var probe = new SqliteConnection(connectionString);
        await probe.OpenAsync();
        var row = await probe.QuerySingleAsync<(string acc_num, string acc_name, double change_amount)>(
            $"SELECT acc_num, acc_name, change_amount FROM {Names.Resolve(JetTable.TargetTbBalance)};");

        Assert.Equal(("1001", "Cash", 125.50), row);
    }

    [Fact]
    public async Task GlProjection_replace_semantics_clears_prior_target_rows()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("projection-replace");
        await using var _ = keepAlive;

        var import = new SqliteGlRepository(connectionString, Names);
        var repository = new SqliteGlProjectionRepository(connectionString, Names);

        await import.BulkInsertStagingAsync(ProjectId, "first.xlsx", AsAsync(new[]
        {
            new GlRawRow(0, new string?[] { "Document Number", "Line Item", "Post Date", "Approval Date", "Account Number", "Account Name", "Description", "Source Module", "Created By", "Approved By", "Manual", "Amount" }),
            new GlRawRow(1, new string?[] { "JE-1", "1", "2024-01-01", "2024-01-02", "1001", "Cash", "First", "GL", "amy", "bob", "1", "10" }),
        }), "replace", CancellationToken.None);
        await repository.ProjectLatestBatchAsync(ProjectId, GlMapping(), CancellationToken.None);

        await import.BulkInsertStagingAsync(ProjectId, "second.xlsx", AsAsync(new[]
        {
            new GlRawRow(0, new string?[] { "Document Number", "Line Item", "Post Date", "Approval Date", "Account Number", "Account Name", "Description", "Source Module", "Created By", "Approved By", "Manual", "Amount" }),
            new GlRawRow(1, new string?[] { "JE-2", "1", "2024-01-01", "2024-01-02", "1002", "Bank", "Second", "GL", "amy", "bob", "1", "20" }),
        }), "replace", CancellationToken.None);
        await repository.ProjectLatestBatchAsync(ProjectId, GlMapping(), CancellationToken.None);

        await using var probe = new SqliteConnection(connectionString);
        await probe.OpenAsync();
        var docs = (await probe.QueryAsync<string>($"SELECT doc_num FROM {Names.Resolve(JetTable.TargetGlEntry)};")).ToArray();

        Assert.Equal(new[] { "JE-2" }, docs);
    }

    [Fact]
    public async Task GlProjection_rejects_mapping_column_missing_from_batch()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("projection-invalid");
        await using var _ = keepAlive;

        var import = new SqliteGlRepository(connectionString, Names);
        await import.BulkInsertStagingAsync(ProjectId, "gl.xlsx", AsAsync(new[]
        {
            new GlRawRow(0, new string?[] { "Document Number" }),
            new GlRawRow(1, new string?[] { "JE-1" }),
        }), "replace", CancellationToken.None);

        var repository = new SqliteGlProjectionRepository(connectionString, Names);

        await Assert.ThrowsAsync<InvalidOperationException>(async () =>
            await repository.ProjectLatestBatchAsync(ProjectId, GlMapping(), CancellationToken.None));
    }

    private static Dictionary<string, string> GlMapping() => new()
    {
        ["docNum"] = "Document Number",
        ["lineID"] = "Line Item",
        ["postDate"] = "Post Date",
        ["docDate"] = "Approval Date",
        ["accNum"] = "Account Number",
        ["accName"] = "Account Name",
        ["description"] = "Description",
        ["jeSource"] = "Source Module",
        ["createBy"] = "Created By",
        ["approveBy"] = "Approved By",
        ["manual"] = "Manual",
        ["amount"] = "Amount"
    };

    private static Dictionary<string, string> TbMapping() => new()
    {
        ["accNum"] = "Account Number",
        ["accName"] = "Account Name",
        ["amount"] = "Change Amount"
    };

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
