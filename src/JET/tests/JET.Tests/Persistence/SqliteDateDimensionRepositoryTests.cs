using Dapper;
using JET.Domain.Abstractions.Persistence;
using JET.Infrastructure.Persistence.Schema;
using JET.Infrastructure.Persistence.Sqlite;
using JET.Infrastructure.Persistence.Sqlite.Repositories;
using Microsoft.Data.Sqlite;
using Xunit;

namespace JET.Tests.Persistence;

public sealed class SqliteDateDimensionRepositoryTests
{
    private const string ProjectId = "00000000-0000-0000-0000-000000000001";
    private static readonly ISchemaNames Names = new SqliteSchemaNames();

    [Fact]
    public async Task ReplaceCalendarInputAsync_ShouldPersistBatchAndDays()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("date-dim-persist");
        await using var _ = keepAlive;

        var repository = new SqliteDateDimensionRepository(connectionString, Names);
        var dates = new[] { "2025-01-01", "2025-02-28", "2025-10-10" };

        var batchId = await repository.ReplaceCalendarInputAsync(ProjectId, "holiday", dates, CancellationToken.None);

        Assert.False(string.IsNullOrWhiteSpace(batchId));

        await using var probe = new SqliteConnection(connectionString);
        await probe.OpenAsync();

        var batchRow = await probe.QuerySingleAsync<(string batch_id, string project_id, string dataset_kind, long row_count)>(
            $"SELECT batch_id, project_id, dataset_kind, row_count FROM {Names.Resolve(JetTable.ConfigImportBatch)};");
        Assert.Equal(batchId, batchRow.batch_id);
        Assert.Equal(ProjectId, batchRow.project_id);
        Assert.Equal("calendar:holiday", batchRow.dataset_kind);
        Assert.Equal(3L, batchRow.row_count);

        var dayDates = (await probe.QueryAsync<string>(
            $"SELECT date_iso FROM {Names.Resolve(JetTable.StagingCalendarRawDay)} WHERE batch_id = @id ORDER BY date_iso;",
            new { id = batchId })).ToArray();
        Assert.Equal(new[] { "2025-01-01", "2025-02-28", "2025-10-10" }, dayDates);
    }

    [Fact]
    public async Task ReplaceCalendarInputAsync_ShouldReplacePriorBatchForSameProjectAndKind()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("date-dim-replace");
        await using var _ = keepAlive;

        var repository = new SqliteDateDimensionRepository(connectionString, Names);

        var firstBatch = await repository.ReplaceCalendarInputAsync(ProjectId, "holiday", new[] { "2025-01-01", "2025-02-28" }, CancellationToken.None);
        var secondBatch = await repository.ReplaceCalendarInputAsync(ProjectId, "holiday", new[] { "2025-12-25" }, CancellationToken.None);

        Assert.NotEqual(firstBatch, secondBatch);

        await using var probe = new SqliteConnection(connectionString);
        await probe.OpenAsync();

        var batchCount = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.ConfigImportBatch)} WHERE project_id = @p AND dataset_kind = 'calendar:holiday';",
            new { p = ProjectId });
        Assert.Equal(1L, batchCount);

        var dayCount = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.StagingCalendarRawDay)};");
        Assert.Equal(1L, dayCount);

        var remainingDate = await probe.ExecuteScalarAsync<string>(
            $"SELECT date_iso FROM {Names.Resolve(JetTable.StagingCalendarRawDay)} WHERE batch_id = @id;",
            new { id = secondBatch });
        Assert.Equal("2025-12-25", remainingDate);
    }

    [Fact]
    public async Task ReplaceCalendarInputAsync_ShouldKeepDifferentKindsIndependent()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("date-dim-kinds");
        await using var _ = keepAlive;

        var repository = new SqliteDateDimensionRepository(connectionString, Names);

        await repository.ReplaceCalendarInputAsync(ProjectId, "holiday", new[] { "2025-01-01" }, CancellationToken.None);
        await repository.ReplaceCalendarInputAsync(ProjectId, "makeupDay", new[] { "2025-02-08" }, CancellationToken.None);

        await using var probe = new SqliteConnection(connectionString);
        await probe.OpenAsync();

        var holidayCount = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.ConfigImportBatch)} WHERE dataset_kind = 'calendar:holiday';");
        var makeupCount = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.ConfigImportBatch)} WHERE dataset_kind = 'calendar:makeupDay';");

        Assert.Equal(1L, holidayCount);
        Assert.Equal(1L, makeupCount);
    }

    [Fact]
    public async Task ReplaceCalendarInputAsync_ShouldDedupeDatesWithinSameCall()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("date-dim-dedupe");
        await using var _ = keepAlive;

        var repository = new SqliteDateDimensionRepository(connectionString, Names);

        var batchId = await repository.ReplaceCalendarInputAsync(
            ProjectId, "holiday",
            new[] { "2025-01-01", "2025-01-01", " 2025-01-01 ", "2025-02-28", "" },
            CancellationToken.None);

        await using var probe = new SqliteConnection(connectionString);
        await probe.OpenAsync();

        var dayCount = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.StagingCalendarRawDay)} WHERE batch_id = @id;",
            new { id = batchId });
        Assert.Equal(2L, dayCount);
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
