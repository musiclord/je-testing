using JET.Application.Queries.RunPrescreen;
using JET.Domain.Abstractions;
using JET.Domain.Entities;
using Xunit;

namespace JET.Tests.Prescreen;

/// <summary>
/// Tests for RunPrescreenQueryHandler R3 rule:
/// jet-guide.md §5 R3: A voucher is flagged when the SAME DocumentNumber has
/// BOTH a credit-Revenue line (Amount &lt; 0) AND a debit-AR/Cash/Advance line (Amount &gt; 0).
/// </summary>
public sealed class PrescreenR3Tests
{
    private static Dictionary<string, object?> MakeRow(string docNum, string accNum, decimal amount) =>
        new()
        {
            ["DocNum"]  = docNum,
            ["AccNum"]  = accNum,
            ["Amount"]  = amount.ToString("F2"),
            ["Desc"]    = "test",
            ["DocDate"] = "2024-01-15",
        };

    private static Dictionary<string, string> GlMapping() => new()
    {
        ["docNum"]      = "DocNum",
        ["accNum"]      = "AccNum",
        ["amount"]      = "Amount",
        ["description"] = "Desc",
        ["docDate"]     = "DocDate",
    };

    private static List<Dictionary<string, object?>> RevenueAccountMapping() =>
    [
        new() { ["Code"] = "4100", ["Name"] = "Sales Revenue",      ["Category"] = "Revenue"     },
        new() { ["Code"] = "1200", ["Name"] = "Accounts Receivable", ["Category"] = "Receivables" },
        new() { ["Code"] = "1100", ["Name"] = "Cash",                ["Category"] = "Cash"        },
    ];

    private static RunPrescreenQueryHandler BuildHandler(
        IReadOnlyList<Dictionary<string, object?>> gl,
        IReadOnlyList<Dictionary<string, object?>> accMap)
    {
        var session = new FakeSessionStore(gl, accMap, GlMapping());
        return new RunPrescreenQueryHandler(session);
    }

    private static IReadOnlyList<Dictionary<string, object?>> GetR3(object result)
    {
        var prop = result.GetType().GetProperty("r3")!;
        return (IReadOnlyList<Dictionary<string, object?>>)prop.GetValue(result)!;
    }

    // ─── Positive: voucher WITH both Revenue-credit AND Receivables-debit → flagged ───

    [Fact]
    public async Task R3_ShouldFlag_VoucherWithRevenueCredit_And_ReceivablesDebit()
    {
        var gl = new List<Dictionary<string, object?>>
        {
            MakeRow("JE001", "4100", -1000m),  // Credit Revenue
            MakeRow("JE001", "1200",  1000m),  // Debit Receivables
        };

        var handler = BuildHandler(gl, RevenueAccountMapping());
        var result  = await handler.HandleAsync(CancellationToken.None);
        var r3      = GetR3(result);

        Assert.Equal(2, r3.Count);
        Assert.All(r3, row => Assert.Equal("JE001", row["DocNum"]?.ToString()));
    }

    // ─── Negative: voucher with ONLY Revenue credit, no expected-debit → not flagged ───

    [Fact]
    public async Task R3_ShouldNotFlag_VoucherWithOnlyRevenueCredit()
    {
        var gl = new List<Dictionary<string, object?>>
        {
            MakeRow("JE002", "4100", -500m),   // Credit Revenue
            MakeRow("JE002", "9999",  500m),   // Debit unknown account (not AR/Cash/Advance)
        };

        var handler = BuildHandler(gl, RevenueAccountMapping());
        var result  = await handler.HandleAsync(CancellationToken.None);
        var r3      = GetR3(result);

        Assert.Empty(r3);
    }

    // ─── Negative: voucher with ONLY debit-Receivables, no Revenue credit → not flagged ───

    [Fact]
    public async Task R3_ShouldNotFlag_VoucherWithOnlyReceivablesDebit()
    {
        var gl = new List<Dictionary<string, object?>>
        {
            MakeRow("JE003", "1200",  800m),   // Debit Receivables
            MakeRow("JE003", "2100", -800m),   // Credit Liabilities (not Revenue)
        };

        var handler = BuildHandler(gl, RevenueAccountMapping());
        var result  = await handler.HandleAsync(CancellationToken.None);
        var r3      = GetR3(result);

        Assert.Empty(r3);
    }

    // ─── Mixed: two vouchers, only one should be flagged ───

    [Fact]
    public async Task R3_ShouldFlagOnly_VouchersMatchingBothConditions()
    {
        var gl = new List<Dictionary<string, object?>>
        {
            // JE004: Revenue credit + Cash debit → SHOULD be flagged
            MakeRow("JE004", "4100", -2000m),
            MakeRow("JE004", "1100",  2000m),
            // JE005: Revenue credit only, no expected debit → NOT flagged
            MakeRow("JE005", "4100",  -300m),
            MakeRow("JE005", "3300",   300m),
        };

        var handler = BuildHandler(gl, RevenueAccountMapping());
        var result  = await handler.HandleAsync(CancellationToken.None);
        var r3      = GetR3(result);

        Assert.Equal(2, r3.Count);
        Assert.All(r3, row => Assert.Equal("JE004", row["DocNum"]?.ToString()));
    }
}

/// <summary>Minimal fake session store for unit tests.</summary>
internal sealed class FakeSessionStore : IProjectSessionStore
{
    private readonly IReadOnlyList<Dictionary<string, object?>> _gl;
    private readonly IReadOnlyList<Dictionary<string, object?>> _accMap;
    private readonly Dictionary<string, string> _glMapping;

    public FakeSessionStore(
        IReadOnlyList<Dictionary<string, object?>> gl,
        IReadOnlyList<Dictionary<string, object?>> accMap,
        Dictionary<string, string> glMapping)
    {
        _gl        = gl;
        _accMap    = accMap;
        _glMapping = glMapping;
    }

    public ProjectInfo? Project                                          => null;
    public IReadOnlyList<Dictionary<string, object?>> GlData            => _gl;
    public IReadOnlyList<Dictionary<string, object?>> TbData            => [];
    public IReadOnlyList<Dictionary<string, object?>> AccountMappingData=> _accMap;
    public IReadOnlyList<string>                      GlColumns         => [];
    public IReadOnlyList<string>                      TbColumns         => [];
    public string                                     GlFileName        => string.Empty;
    public string                                     TbFileName        => string.Empty;
    public string                                     AccountMappingFileName => string.Empty;
    public Dictionary<string, string>                 GlMapping         => _glMapping;
    public Dictionary<string, string>                 TbMapping         => [];
    public IReadOnlyList<string>                      Holidays          => [];
    public IReadOnlyList<string>                      MakeupDays        => [];
    public IReadOnlyList<int>                         Weekends          => [];

    public void SetProject(ProjectInfo project) { }
    public void SetGlData(string fileName, IReadOnlyList<Dictionary<string, object?>> rows, IReadOnlyList<string> columns) { }
    public void SetTbData(string fileName, IReadOnlyList<Dictionary<string, object?>> rows, IReadOnlyList<string> columns) { }
    public void SetAccountMappingData(string fileName, IReadOnlyList<Dictionary<string, object?>> rows) { }
    public void SetGlMapping(Dictionary<string, string> mapping) { }
    public void SetTbMapping(Dictionary<string, string> mapping) { }
    public void SetHolidays(IReadOnlyList<string> dates) { }
    public void SetMakeupDays(IReadOnlyList<string> dates) { }
    public void SetWeekends(IReadOnlyList<int> weekends) { }
}
