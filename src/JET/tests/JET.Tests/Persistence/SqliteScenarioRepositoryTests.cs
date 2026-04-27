using Dapper;
using JET.Application.Commands.FilterScenario.Rules;
using JET.Domain.Abstractions.Persistence;
using JET.Infrastructure.Persistence.Schema;
using JET.Infrastructure.Persistence.Sqlite;
using JET.Infrastructure.Persistence.Sqlite.Repositories;
using Microsoft.Data.Sqlite;
using Xunit;

namespace JET.Tests.Persistence;

public sealed class SqliteScenarioRepositoryTests
{
    private const string ProjectId = "00000000-0000-0000-0000-0000000000fc";
    private static readonly ISchemaNames Names = new SqliteSchemaNames();

    [Fact]
    public async Task PreviewAsync_text_rule_returns_summary_and_preview_rows()
    {
        var (cs, keep) = await OpenAsync("scenario-text");
        await using var _ = keep;
        await SeedAsync(cs);

        var scenario = new ScenarioDefinition
        {
            Name = "Adj keyword",
            Groups = new[]
            {
                new ScenarioGroup
                {
                    Join = "AND",
                    Rules = new[]
                    {
                        new ScenarioRule { Type = "text", Field = "description", Keywords = "adj", Mode = "contains" }
                    }
                }
            }
        };

        var repo = new SqliteScenarioRepository(cs, Names, ScenarioGroupComposer.Default());
        var result = await repo.PreviewAsync(ProjectId, scenario, CancellationToken.None);

        Assert.Equal("Adj keyword", result.Label);
        Assert.Equal(2, result.Count);
        Assert.Equal(1, result.VoucherCount);
        Assert.Equal(2, result.PreviewRows.Count);
        Assert.False(string.IsNullOrWhiteSpace(result.RunId));
    }

    [Fact]
    public async Task PreviewAsync_combines_groups_with_or()
    {
        var (cs, keep) = await OpenAsync("scenario-or");
        await using var _ = keep;
        await SeedAsync(cs);

        var scenario = new ScenarioDefinition
        {
            Name = "Either",
            Groups = new[]
            {
                new ScenarioGroup
                {
                    Join = "AND",
                    Rules = new[] { new ScenarioRule { Type = "text", Field = "description", Keywords = "adj", Mode = "contains" } }
                },
                new ScenarioGroup
                {
                    Join = "OR",
                    Rules = new[] { new ScenarioRule { Type = "drCrOnly", DrCr = "credit" } }
                }
            }
        };

        var repo = new SqliteScenarioRepository(cs, Names, ScenarioGroupComposer.Default());
        var result = await repo.PreviewAsync(ProjectId, scenario, CancellationToken.None);

        // adj keyword vouchers (JE001 lines) UNION credit lines from any voucher
        Assert.True(result.Count >= 2);
    }

    [Fact]
    public async Task QueryPageAsync_returns_keyset_pages()
    {
        var (cs, keep) = await OpenAsync("scenario-page");
        await using var _ = keep;
        await SeedAsync(cs);

        var scenario = new ScenarioDefinition
        {
            Name = "All credits",
            Groups = new[]
            {
                new ScenarioGroup { Join = "AND", Rules = new[] { new ScenarioRule { Type = "drCrOnly", DrCr = "credit" } } }
            }
        };

        var repo = new SqliteScenarioRepository(cs, Names, ScenarioGroupComposer.Default());
        var preview = await repo.PreviewAsync(ProjectId, scenario, CancellationToken.None);
        Assert.True(preview.Count >= 2);

        var page1 = await repo.QueryPageAsync(ProjectId, preview.RunId, null, 1, CancellationToken.None);
        Assert.Single(page1.Rows);
        Assert.NotNull(page1.NextCursor);

        var page2 = await repo.QueryPageAsync(ProjectId, preview.RunId, page1.NextCursor, 1, CancellationToken.None);
        Assert.Single(page2.Rows);
        Assert.True(page2.Rows[0].RowNo > page1.Rows[0].RowNo);
    }

    [Fact]
    public async Task PreviewAsync_empty_scenario_returns_empty_result()
    {
        var (cs, keep) = await OpenAsync("scenario-empty");
        await using var _ = keep;
        await SeedAsync(cs);

        var repo = new SqliteScenarioRepository(cs, Names, ScenarioGroupComposer.Default());
        var result = await repo.PreviewAsync(ProjectId, new ScenarioDefinition(), CancellationToken.None);

        Assert.Equal(0, result.Count);
        Assert.Empty(result.PreviewRows);
    }

    private static async Task SeedAsync(string cs)
    {
        await using var conn = new SqliteConnection(cs);
        await conn.OpenAsync();
        await conn.ExecuteAsync($"""
            INSERT INTO {Names.Resolve(JetTable.ConfigProject)}
                (project_id, project_code, entity_name, operator_id, industry, period_start, period_end, last_period_start, created_utc)
            VALUES (@P, 'P', 'E', 'O', 'I', '2024-01-01', '2024-12-31', '2024-12-20', '2024-01-01T00:00:00Z');

            INSERT INTO {Names.Resolve(JetTable.TargetGlEntry)}
                (project_id, batch_id, doc_num, line_id, post_date, doc_date, acc_num, acc_name, description, je_source, create_by, approve_by, manual, dr_amount, cr_amount, amount)
            VALUES
                (@P, 'b1', 'JE001', '1', '2024-06-01', '2024-06-01', '4100', 'Rev', 'adj close', 'GL', 'amy', 'mgr', 1, 0, 1000, -1000),
                (@P, 'b1', 'JE001', '2', '2024-06-01', '2024-06-01', '1200', 'AR',  'adj close', 'GL', 'amy', 'mgr', 1, 1000, 0,  1000),
                (@P, 'b1', 'JE002', '1', '2024-06-02', '2024-06-02', '4100', 'Rev', 'normal',    'GL', 'bob', 'mgr', 0, 0, 500,   -500),
                (@P, 'b1', 'JE002', '2', '2024-06-02', '2024-06-02', '1100', 'Cash','normal',    'GL', 'bob', 'mgr', 0, 500, 0,    500);
        """, new { P = ProjectId });
    }

    private static async Task<(string ConnectionString, SqliteConnection KeepAlive)> OpenAsync(string name)
    {
        var cs = $"Data Source=fc-{name};Mode=Memory;Cache=Shared";
        var keep = new SqliteConnection(cs);
        await keep.OpenAsync();
        await new SqliteSchemaInitializer(cs, Names).EnsureAsync(CancellationToken.None);
        return (cs, keep);
    }
}
