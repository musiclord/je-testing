using JET.Application.DemoData;
using Xunit;

namespace JET.Tests.DemoData;

public sealed class DemoProjectDataGeneratorTests
{
    [Fact]
    public void Generate_ShouldReturnLargeDemoDataset()
    {
        var generator = new DeterministicDemoProjectDataGenerator();

        var bundle = generator.Generate();

        Assert.NotNull(bundle.Project);
        Assert.True(bundle.Project.GlRows.Count >= 2000, $"Expected at least 2000 GL rows, got {bundle.Project.GlRows.Count}.");
        Assert.True(bundle.Project.TbRows.Count >= 100, $"Expected at least 100 TB rows, got {bundle.Project.TbRows.Count}.");
        Assert.True(bundle.InvalidGlRows.Count is >= 18 and <= 30, $"Expected about 20 invalid GL rows, got {bundle.InvalidGlRows.Count}.");
    }

    [Fact]
    public void Generate_ShouldKeepBaseDemoGlBalancedByVoucher()
    {
        var generator = new DeterministicDemoProjectDataGenerator();

        var bundle = generator.Generate();
        var glRows = bundle.Project.GlRows.Except(bundle.InvalidGlRows).ToList();
        var docColumn = bundle.Project.GlMapping["docNum"];
        var amountColumn = bundle.Project.GlMapping["amount"];

        var imbalanced = glRows
            .GroupBy(row => row[docColumn]?.ToString() ?? string.Empty)
            .Select(group => new
            {
                DocumentNumber = group.Key,
                Amount = group.Sum(row => Convert.ToDecimal(row[amountColumn] ?? 0m))
            })
            .Where(item => Math.Abs(item.Amount) > 0.0001m)
            .ToList();

        Assert.Empty(imbalanced);
    }

    [Fact]
    public void Generate_ShouldReturnTbThatMatchesBaseGlByAccount()
    {
        var generator = new DeterministicDemoProjectDataGenerator();

        var bundle = generator.Generate();
        var glRows = bundle.Project.GlRows.Except(bundle.InvalidGlRows).ToList();
        var glAccountColumn = bundle.Project.GlMapping["accNum"];
        var glAmountColumn = bundle.Project.GlMapping["amount"];
        var tbAccountColumn = bundle.Project.TbMapping["accNum"];
        var tbAmountColumn = bundle.Project.TbMapping["amount"];

        var glSums = glRows
            .GroupBy(row => row[glAccountColumn]?.ToString() ?? string.Empty)
            .ToDictionary(group => group.Key, group => group.Sum(row => Convert.ToDecimal(row[glAmountColumn] ?? 0m)));

        var tbSums = bundle.Project.TbRows
            .ToDictionary(
                row => row[tbAccountColumn]?.ToString() ?? string.Empty,
                row => Convert.ToDecimal(row[tbAmountColumn] ?? 0m));

        foreach (var (account, glAmount) in glSums)
        {
            Assert.True(tbSums.ContainsKey(account), $"TB is missing account {account}.");
            Assert.Equal(glAmount, tbSums[account]);
        }
    }

    [Fact]
    public void Generate_ShouldIncludeInvalidRowsThatTriggerValidationCases()
    {
        var generator = new DeterministicDemoProjectDataGenerator();

        var bundle = generator.Generate();
        var docColumn = bundle.Project.GlMapping["docNum"];
        var accountColumn = bundle.Project.GlMapping["accNum"];
        var descriptionColumn = bundle.Project.GlMapping["description"];

        Assert.Contains(bundle.InvalidGlRows, row => string.IsNullOrWhiteSpace(row[accountColumn]?.ToString()));
        Assert.Contains(bundle.InvalidGlRows, row => string.IsNullOrWhiteSpace(row[docColumn]?.ToString()));
        Assert.Contains(bundle.InvalidGlRows, row => string.IsNullOrWhiteSpace(row[descriptionColumn]?.ToString()));
    }
}
