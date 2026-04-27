using Dapper;
using JET.Domain.Abstractions.Persistence;
using JET.Infrastructure.Persistence.Schema;
using JET.Infrastructure.Persistence.Sqlite;
using JET.Infrastructure.Persistence.Sqlite.Repositories;
using Microsoft.Data.Sqlite;
using Xunit;

namespace JET.Tests.Persistence;

/// <summary>
/// SQL-pushdown variant of the prior PrescreenR3Tests. Verifies that R3 — voucher
/// containing both a revenue-credit line AND a debit AR/Cash/Advance line — is
/// computed by the repository (target_gl_entry + staging_account_mapping_raw_row),
/// not by Application-layer LINQ. plan §3.3.c / G3.
/// </summary>
public sealed class SqlitePreScreenRepositoryR3Tests
{
    private const string ProjectId = "00000000-0000-0000-0000-0000000000r3";
    private static readonly ISchemaNames Names = new SqliteSchemaNames();

    [Fact]
    public async Task R3_flags_voucher_with_revenue_credit_and_receivables_debit()
    {
        var (cs, keep) = await OpenAsync("r3-flag");
        await using var _ = keep;
        await SeedAsync(cs, new[]
        {
            ("JE001", "1", "4100",  -1000m), // credit revenue
            ("JE001", "2", "1200",   1000m), // debit AR
        });

        var repo = new SqlitePreScreenRepository(cs, Names);
        var result = await repo.RunAsync(ProjectId, CancellationToken.None);

        Assert.Equal(2, result.R3);
    }

    [Fact]
    public async Task R3_does_not_flag_voucher_without_expected_debit()
    {
        var (cs, keep) = await OpenAsync("r3-noflag");
        await using var _ = keep;
        await SeedAsync(cs, new[]
        {
            ("JE002", "1", "4100",  -500m),
            ("JE002", "2", "9999",   500m), // unknown account category
        });

        var repo = new SqlitePreScreenRepository(cs, Names);
        var result = await repo.RunAsync(ProjectId, CancellationToken.None);

        Assert.Equal(0, result.R3);
    }

    [Fact]
    public async Task R3_isolates_per_voucher()
    {
        var (cs, keep) = await OpenAsync("r3-mixed");
        await using var _ = keep;
        await SeedAsync(cs, new[]
        {
            ("JE004", "1", "4100", -2000m),
            ("JE004", "2", "1100",  2000m), // cash
            ("JE005", "1", "4100",  -300m),
            ("JE005", "2", "3300",   300m), // not a flagged category
        });

        var repo = new SqlitePreScreenRepository(cs, Names);
        var result = await repo.RunAsync(ProjectId, CancellationToken.None);

        Assert.Equal(2, result.R3);
    }

    private static async Task SeedAsync(string cs, IEnumerable<(string Doc, string Line, string Acc, decimal Amount)> rows)
    {
        await using var conn = new SqliteConnection(cs);
        await conn.OpenAsync();
        await conn.ExecuteAsync($"""
            INSERT INTO {Names.Resolve(JetTable.ConfigProject)}
                (project_id, project_code, entity_name, operator_id, industry, period_start, period_end, last_period_start, created_utc)
            VALUES (@P, 'P', 'E', 'O', 'I', '2024-01-01', '2024-12-31', '2024-12-20', '2024-01-01T00:00:00Z');

            INSERT INTO {Names.Resolve(JetTable.ConfigImportBatch)}
                (batch_id, project_id, dataset_kind, file_name, row_count, imported_utc)
            VALUES ('am1', @P, 'accountMapping', 'demo.xlsx', 3, '2024-02-01T00:00:00Z');

            INSERT INTO {Names.Resolve(JetTable.StagingAccountMappingRawRow)} (batch_id, row_index, payload) VALUES
                ('am1', 1, '["4100","Sales Revenue","Revenue"]'),
                ('am1', 2, '["1200","Accounts Receivable","Receivables"]'),
                ('am1', 3, '["1100","Cash","Cash"]');
        """, new { P = ProjectId });

        foreach (var (doc, line, acc, amount) in rows)
        {
            await conn.ExecuteAsync($"""
                INSERT INTO {Names.Resolve(JetTable.TargetGlEntry)}
                    (project_id, batch_id, doc_num, line_id, post_date, doc_date, acc_num, acc_name, description, je_source, create_by, approve_by, manual, dr_amount, cr_amount, amount)
                VALUES (@P, 'g1', @Doc, @Line, '2024-06-01', '2024-06-01', @Acc, '', '', 'GL', 'amy', 'mgr', 0, 0, 0, @Amt);
            """, new { P = ProjectId, Doc = doc, Line = line, Acc = acc, Amt = amount });
        }
    }

    private static async Task<(string ConnectionString, SqliteConnection KeepAlive)> OpenAsync(string name)
    {
        var cs = $"Data Source=r3-{name};Mode=Memory;Cache=Shared";
        var keep = new SqliteConnection(cs);
        await keep.OpenAsync();
        await new SqliteSchemaInitializer(cs, Names).EnsureAsync(CancellationToken.None);
        return (cs, keep);
    }
}
