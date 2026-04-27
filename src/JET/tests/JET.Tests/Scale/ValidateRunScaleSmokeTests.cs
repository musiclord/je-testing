using System.Diagnostics;
using System.Text.Json;
using Dapper;
using JET.Application.Queries.RunValidation;
using JET.Domain.Abstractions.Persistence;
using JET.Infrastructure.Persistence;
using JET.Infrastructure.Persistence.Schema;
using JET.Infrastructure.Persistence.Sqlite;
using JET.Infrastructure.Persistence.Sqlite.Repositories;
using Microsoft.Data.Sqlite;
using Xunit;

namespace JET.Tests.Scale;

public sealed class ValidateRunScaleSmokeTests
{
    private const int RowCount = 2_000_000;
    private const int MaxElapsedSeconds = 30;
    private const long MaxManagedMemoryDeltaBytes = 500L * 1024 * 1024;
    private const int MaxPayloadBytes = 100 * 1024;
    private const string ProjectId = "00000000-0000-0000-0000-000000200000";
    private static readonly ISchemaNames Names = new SqliteSchemaNames();

    [Fact]
    [Trait("Category", "ScaleSmoke")]
    public async Task ValidateRun_two_million_rows_stays_within_scale_thresholds()
    {
        var dbPath = Path.Combine(Path.GetTempPath(), $"jet-validate-scale-{Guid.NewGuid():N}.db");
        var connectionString = $"Data Source={dbPath}";
        try
        {
            await new SqliteSchemaInitializer(connectionString, Names).EnsureAsync(CancellationToken.None);
            await SeedProjectAsync(connectionString);
            await SeedGlAsync(connectionString, RowCount);

            var session = new InMemoryProjectSessionStore();
            session.SetCurrentProjectId(ProjectId);
            var repository = new SqliteValidationRepository(connectionString, Names);
            var handler = new RunValidationQueryHandler(session, repository);

            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();
            var beforeManagedBytes = GC.GetTotalMemory(forceFullCollection: true);
            var stopwatch = Stopwatch.StartNew();

            var result = await handler.HandleAsync(CancellationToken.None);

            stopwatch.Stop();
            var afterManagedBytes = GC.GetTotalMemory(forceFullCollection: true);
            var payloadBytes = JsonSerializer.SerializeToUtf8Bytes(result).Length;
            var managedDeltaBytes = Math.Max(0, afterManagedBytes - beforeManagedBytes);

            Assert.True(stopwatch.Elapsed <= TimeSpan.FromSeconds(MaxElapsedSeconds),
                $"validate.run elapsed {stopwatch.Elapsed.TotalSeconds:N1}s exceeded {MaxElapsedSeconds}s for {RowCount:N0} rows.");
            Assert.True(managedDeltaBytes < MaxManagedMemoryDeltaBytes,
                $"Managed memory delta {managedDeltaBytes / 1024 / 1024:N1} MB exceeded {MaxManagedMemoryDeltaBytes / 1024 / 1024:N0} MB.");
            Assert.True(payloadBytes < MaxPayloadBytes,
                $"Serialized validate.run payload {payloadBytes:N0} bytes exceeded {MaxPayloadBytes:N0} bytes.");

            var stats = result.GetType().GetProperty("stats")!.GetValue(result)!;
            var total = (int)stats.GetType().GetProperty("Total")!.GetValue(stats)!;
            Assert.Equal(RowCount, total);
        }
        finally
        {
            TryDelete(dbPath);
        }
    }

    private static async Task SeedProjectAsync(string connectionString)
    {
        await using var connection = new SqliteConnection(connectionString);
        await connection.OpenAsync();
        await connection.ExecuteAsync($"""
            INSERT INTO {Names.Resolve(JetTable.ConfigProject)}
                (project_id, project_code, entity_name, operator_id, industry, period_start, period_end, last_period_start, created_utc)
            VALUES
                (@ProjectId, 'SCALE', 'Scale Smoke Co.', 'scale', 'audit', '2024-01-01', '2024-12-31', '2023-01-01', '2024-01-01T00:00:00Z');
            """, new { ProjectId });
    }

    private static async Task SeedGlAsync(string connectionString, int rowCount)
    {
        await using var connection = new SqliteConnection(connectionString);
        await connection.OpenAsync();
        await connection.ExecuteAsync("PRAGMA journal_mode = OFF; PRAGMA synchronous = OFF; PRAGMA temp_store = FILE;", commandTimeout: 180);
        await connection.ExecuteAsync(new CommandDefinition($"""
            WITH digits(d) AS (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)),
            seq(n) AS (
                SELECT a.d + b.d * 10 + c.d * 100 + d.d * 1000 + e.d * 10000 + f.d * 100000 + g.d * 1000000 + 1
                FROM digits a
                CROSS JOIN digits b
                CROSS JOIN digits c
                CROSS JOIN digits d
                CROSS JOIN digits e
                CROSS JOIN digits f
                CROSS JOIN digits g
                LIMIT @RowCount
            )
            INSERT INTO {Names.Resolve(JetTable.TargetGlEntry)}
                (project_id, batch_id, doc_num, line_id, post_date, doc_date, acc_num, acc_name, description, je_source, create_by, approve_by, manual, dr_amount, cr_amount, amount)
            SELECT
                @ProjectId,
                'scale-batch',
                'D' || (((n - 1) % 100000) + 1),
                CAST(((n - 1) / 100000) + 1 AS TEXT),
                '2024-06-30',
                '2024-06-30',
                printf('%04d', 1000 + (n % 50)),
                'Scale Account',
                'scale smoke row',
                'GL',
                'system',
                'manager',
                CASE WHEN (n % 4) < 2 THEN 1 ELSE 0 END,
                CASE WHEN ((n - 1) / 100000) < 10 THEN 100.0 ELSE 0.0 END,
                CASE WHEN ((n - 1) / 100000) >= 10 THEN 100.0 ELSE 0.0 END,
                CASE WHEN ((n - 1) / 100000) < 10 THEN 100.0 ELSE -100.0 END
            FROM seq;
            """, new { ProjectId, RowCount = rowCount }, commandTimeout: 180));
    }

    private static void TryDelete(string dbPath)
    {
        foreach (var path in new[] { dbPath, dbPath + "-shm", dbPath + "-wal" })
        {
            try
            {
                if (File.Exists(path)) File.Delete(path);
            }
            catch (IOException)
            {
            }
            catch (UnauthorizedAccessException)
            {
            }
        }
    }
}
