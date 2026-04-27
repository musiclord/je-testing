using Dapper;
using JET.Domain.Abstractions.Persistence;
using JET.Infrastructure.Persistence.Schema;
using JET.Infrastructure.Persistence.Sqlite;
using Microsoft.Data.Sqlite;
using Xunit;

namespace JET.Tests.Persistence;

public sealed class SqliteSchemaInitializerTests
{
    private static readonly JetTable[] AllTables = Enum.GetValues<JetTable>();

    [Fact]
    public async Task EnsureAsync_ShouldCreateAllJetTablesOnEmptyDatabase()
    {
        // SQLite shared-cache in-memory DB so initializer + assertions share the same store.
        var connectionString = "Data Source=schema-init-test;Mode=Memory;Cache=Shared";
        await using var keepAlive = new SqliteConnection(connectionString);
        await keepAlive.OpenAsync();

        var names = new SqliteSchemaNames();
        var initializer = new SqliteSchemaInitializer(connectionString, names);

        var result = await initializer.EnsureAsync(CancellationToken.None);

        Assert.True(result.IsAvailable);
        await using var probe = new SqliteConnection(connectionString);
        await probe.OpenAsync();
        var tableNames = (await probe.QueryAsync<string>(
            "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name;"))
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        foreach (var table in AllTables)
        {
            var physical = names.Resolve(table);
            Assert.Contains(physical, tableNames);
        }

        await AssertColumnsAsync(probe, names.Resolve(JetTable.TargetGlEntry),
            "project_id", "batch_id", "doc_num", "line_id", "post_date", "doc_date", "acc_num", "acc_name", "description", "je_source", "create_by", "approve_by", "manual", "dr_amount", "cr_amount", "amount");
        await AssertColumnsAsync(probe, names.Resolve(JetTable.TargetTbBalance),
            "project_id", "batch_id", "acc_num", "acc_name", "change_amount", "opening_balance", "closing_balance");
    }

    [Fact]
    public async Task EnsureAsync_ShouldBeIdempotent()
    {
        var connectionString = "Data Source=schema-init-idempotent;Mode=Memory;Cache=Shared";
        await using var keepAlive = new SqliteConnection(connectionString);
        await keepAlive.OpenAsync();

        var initializer = new SqliteSchemaInitializer(connectionString, new SqliteSchemaNames());

        var first = await initializer.EnsureAsync(CancellationToken.None);
        var second = await initializer.EnsureAsync(CancellationToken.None);

        Assert.True(first.IsAvailable);
        Assert.True(second.IsAvailable);
    }

    private static async Task AssertColumnsAsync(SqliteConnection connection, string tableName, params string[] expected)
    {
        var columns = (await connection.QueryAsync<string>($"SELECT name FROM pragma_table_info('{tableName}') ORDER BY cid;"))
            .ToArray();
        Assert.Equal(expected, columns);
    }
}
