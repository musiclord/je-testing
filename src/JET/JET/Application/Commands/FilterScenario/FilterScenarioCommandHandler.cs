using System.Text.Json;
using JET.Domain.Abstractions;

namespace JET.Application.Commands.FilterScenario
{
    public sealed class FilterScenarioCommandHandler
    {
        private readonly IProjectSessionStore _session;

        public FilterScenarioCommandHandler(IProjectSessionStore session)
        {
            _session = session;
        }

        public Task<object> HandlePreviewAsync(object scenario, CancellationToken cancellationToken)
        {
            return Task.FromResult<object>(new { scenario = EvaluateScenario(scenario) });
        }

        public Task<object> HandleCommitAsync(object scenarios, CancellationToken cancellationToken)
        {
            return Task.FromResult<object>(new { ok = true });
        }

        private object EvaluateScenario(object scenario)
        {
            if (scenario is not JsonElement json || json.ValueKind != JsonValueKind.Object)
            {
                return new { label = "未命名情境", resultRows = Array.Empty<object>(), count = 0, voucherCount = 0, summary = Array.Empty<string>() };
            }

            var gl = _session.GlData;
            var groups = ReadGroups(json);
            if (groups.Count == 0)
            {
                var emptyLabel = GetString(json, "name", "未命名情境");
                return new { label = emptyLabel, resultRows = Array.Empty<object>(), count = 0, voucherCount = 0, summary = Array.Empty<string>() };
            }

            var current = EvaluateRuleSequence(gl, groups[0].Rules);
            for (var i = 1; i < groups.Count; i++)
            {
                var rows = EvaluateRuleSequence(gl, groups[i].Rules);
                current = string.Equals(groups[i].Join, "OR", StringComparison.OrdinalIgnoreCase)
                    ? UnionRows(current, rows)
                    : IntersectRows(current, rows);
            }

            var summary = groups.SelectMany(g => g.Rules.Select(DescribeRule)).ToArray();
            var label = GetString(json, "name", "未命名情境");

            return new
            {
                label,
                resultRows = current,
                count = current.Count,
                voucherCount = CountVouchers(current),
                summary
            };
        }

        private List<Dictionary<string, object?>> EvaluateRuleSequence(IReadOnlyList<Dictionary<string, object?>> gl, IReadOnlyList<ScenarioRule> rules)
        {
            if (rules.Count == 0) return [];
            var current = ApplyRule(gl, rules[0]);
            for (var i = 1; i < rules.Count; i++)
            {
                var rows = ApplyRule(gl, rules[i]);
                current = string.Equals(rules[i].Join, "OR", StringComparison.OrdinalIgnoreCase)
                    ? UnionRows(current, rows)
                    : IntersectRows(current, rows);
            }
            return current;
        }

        private List<Dictionary<string, object?>> ApplyRule(IReadOnlyList<Dictionary<string, object?>> gl, ScenarioRule rule)
        {
            return rule.Type switch
            {
                "prescreen" => ApplyPrescreenRule(rule),
                "text" => ApplyTextRule(gl, rule),
                "dateRange" => ApplyDateRangeRule(gl, rule),
                "numRange" => ApplyNumRangeRule(gl, rule),
                "accountPair" => ApplyAccountPairRule(rule),
                "drCrOnly" => gl.Where(row => rule.DrCr == "debit" ? GetEntryAmount(row) >= 0 : GetEntryAmount(row) < 0).ToList(),
                "manualAuto" => ApplyManualAutoRule(gl, rule),
                _ => []
            };
        }

        private List<Dictionary<string, object?>> ApplyPrescreenRule(ScenarioRule rule)
        {
            var key = rule.PrescreenKey?.ToLowerInvariant();
            if (string.IsNullOrWhiteSpace(key)) return [];

            var gl = _session.GlData;
            return key switch
            {
                "r1" => gl.Where(row =>
                {
                    var threshold = ParseDate(_session.Project?.LastPeriodStart);
                    var date = ParseDate(GetGlValue(row, "docDate"));
                    if (date is null) date = ParseDate(GetGlValue(row, "postDate"));
                    return threshold is not null && date is not null && date >= threshold;
                }).ToList(),
                "r2" => gl.Where(row =>
                {
                    var desc = GetGlValue(row, "description").ToLowerInvariant();
                    return PrescreenKeywords.Any(keyword => desc.Contains(keyword, StringComparison.OrdinalIgnoreCase));
                }).ToList(),
                "r3" => ApplyDefaultAccountPairRule(gl),
                "r4" => gl.Where(row => TrailingZeros(Math.Abs(GetEntryAmount(row))) >= 3).ToList(),
                "r5" => gl.ToList(),
                "r6" => ApplyRareAccountRule(gl),
                "descnull" => gl.Where(row => string.IsNullOrWhiteSpace(GetGlValue(row, "description"))).ToList(),
                _ => []
            };
        }

        private List<Dictionary<string, object?>> ApplyTextRule(IReadOnlyList<Dictionary<string, object?>> gl, ScenarioRule rule)
        {
            var keywords = (rule.Keywords ?? string.Empty)
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .Select(x => x.ToLowerInvariant())
                .ToArray();
            if (string.IsNullOrWhiteSpace(rule.Field) || keywords.Length == 0) return [];

            return gl.Where(row =>
            {
                var value = GetRowValue(row, rule.Field).ToLowerInvariant();
                var matched = keywords.Any(keyword =>
                    string.Equals(rule.Mode, "exact", StringComparison.OrdinalIgnoreCase) || string.Equals(rule.Mode, "notExact", StringComparison.OrdinalIgnoreCase)
                        ? value == keyword
                        : value.Contains(keyword, StringComparison.OrdinalIgnoreCase));

                return string.Equals(rule.Mode, "notContains", StringComparison.OrdinalIgnoreCase) || string.Equals(rule.Mode, "notExact", StringComparison.OrdinalIgnoreCase)
                    ? !matched
                    : matched;
            }).ToList();
        }

        private List<Dictionary<string, object?>> ApplyDateRangeRule(IReadOnlyList<Dictionary<string, object?>> gl, ScenarioRule rule)
        {
            if (string.IsNullOrWhiteSpace(rule.Field)) return [];
            var from = ParseDate(rule.From);
            var to = ParseDate(rule.To);
            return gl.Where(row =>
            {
                var date = ParseDate(GetRowValue(row, rule.Field));
                if (date is null) return false;
                if (from is not null && date < from) return false;
                if (to is not null && date > to) return false;
                return true;
            }).ToList();
        }

        private List<Dictionary<string, object?>> ApplyNumRangeRule(IReadOnlyList<Dictionary<string, object?>> gl, ScenarioRule rule)
        {
            if (string.IsNullOrWhiteSpace(rule.Field)) return [];
            var from = ParseNullableDecimal(rule.From);
            var to = ParseNullableDecimal(rule.To);
            return gl.Where(row =>
            {
                var value = ParseDecimal(GetRowValue(row, rule.Field));
                if (from.HasValue && value < from.Value) return false;
                if (to.HasValue && value > to.Value) return false;
                return true;
            }).ToList();
        }

        private List<Dictionary<string, object?>> ApplyManualAutoRule(IReadOnlyList<Dictionary<string, object?>> gl, ScenarioRule rule)
        {
            if (!_session.GlMapping.TryGetValue("manual", out var manualField) || string.IsNullOrWhiteSpace(manualField)) return gl.ToList();
            return gl.Where(row =>
            {
                var value = GetRowValue(row, manualField);
                var isManual = value == "1" || value.Equals("true", StringComparison.OrdinalIgnoreCase) || value.Equals("y", StringComparison.OrdinalIgnoreCase) || value.Equals("yes", StringComparison.OrdinalIgnoreCase);
                return string.Equals(rule.IsManual, "true", StringComparison.OrdinalIgnoreCase) ? isManual : !isManual;
            }).ToList();
        }

        private List<Dictionary<string, object?>> ApplyAccountPairRule(ScenarioRule rule)
        {
            var lookup = GetAccountCategoryLookup();
            var vouchers = GetVoucherRows();
            var matched = new List<Dictionary<string, object?>>();
            foreach (var rows in vouchers.Values)
            {
                var debitCategories = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                var creditCategories = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                foreach (var row in rows)
                {
                    var account = GetGlValue(row, "accNum");
                    if (!lookup.TryGetValue(account, out var category)) continue;
                    var amount = GetEntryAmount(row);
                    if (amount >= 0) debitCategories.Add(category);
                    if (amount <= 0) creditCategories.Add(category);
                }
                if (debitCategories.Contains(rule.DebitCategory ?? string.Empty) && creditCategories.Contains(rule.CreditCategory ?? string.Empty))
                {
                    matched.AddRange(rows);
                }
            }
            return matched;
        }

        private List<Dictionary<string, object?>> ApplyDefaultAccountPairRule(IReadOnlyList<Dictionary<string, object?>> gl)
        {
            var lookup = GetAccountCategoryLookup();
            if (lookup.Count == 0) return [];
            return ApplyAccountPairRule(new ScenarioRule { Type = "accountPair", DebitCategory = "Receivables", CreditCategory = "Revenue" });
        }

        private List<Dictionary<string, object?>> ApplyRareAccountRule(IReadOnlyList<Dictionary<string, object?>> gl)
        {
            var frequency = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            foreach (var row in gl)
            {
                var account = GetGlValue(row, "accNum");
                if (string.IsNullOrWhiteSpace(account)) account = "?";
                frequency[account] = frequency.GetValueOrDefault(account) + 1;
            }

            var avg = frequency.Count == 0 ? 1d : frequency.Values.Average();
            var rareAccounts = frequency.Where(kv => kv.Value < avg * 0.25d).Select(kv => kv.Key).ToHashSet(StringComparer.OrdinalIgnoreCase);
            return gl.Where(row => rareAccounts.Contains(string.IsNullOrWhiteSpace(GetGlValue(row, "accNum")) ? "?" : GetGlValue(row, "accNum"))).ToList();
        }

        private Dictionary<string, string> GetAccountCategoryLookup()
        {
            var lookup = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            if (_session.AccountMappingData.Count == 0) return lookup;
            var sample = _session.AccountMappingData[0];
            var keys = sample.Keys.ToList();
            var accountKey = keys.FirstOrDefault(key => key.Contains("Account", StringComparison.OrdinalIgnoreCase) || key.Contains("編號", StringComparison.OrdinalIgnoreCase)) ?? keys.First();
            var categoryKey = keys.FirstOrDefault(key => key.Contains("Category", StringComparison.OrdinalIgnoreCase) || key.Contains("分類", StringComparison.OrdinalIgnoreCase)) ?? keys.ElementAtOrDefault(2) ?? keys.Last();
            foreach (var row in _session.AccountMappingData)
            {
                var account = GetRowValue(row, accountKey);
                var category = GetRowValue(row, categoryKey);
                if (!string.IsNullOrWhiteSpace(account) && !string.IsNullOrWhiteSpace(category)) lookup[account] = category;
            }
            return lookup;
        }

        private Dictionary<string, List<Dictionary<string, object?>>> GetVoucherRows()
        {
            var groups = new Dictionary<string, List<Dictionary<string, object?>>>(StringComparer.OrdinalIgnoreCase);
            var docColumn = _session.GlMapping.GetValueOrDefault("docNum") ?? string.Empty;
            for (var i = 0; i < _session.GlData.Count; i++)
            {
                var row = _session.GlData[i];
                var key = string.IsNullOrWhiteSpace(docColumn) ? $"ROW-{i}" : GetRowValue(row, docColumn);
                if (string.IsNullOrWhiteSpace(key)) key = $"ROW-{i}";
                if (!groups.TryGetValue(key, out var list))
                {
                    list = new List<Dictionary<string, object?>>();
                    groups[key] = list;
                }
                list.Add(row);
            }
            return groups;
        }

        private List<ScenarioGroup> ReadGroups(JsonElement scenario)
        {
            var result = new List<ScenarioGroup>();
            if (!scenario.TryGetProperty("groups", out var groups) || groups.ValueKind != JsonValueKind.Array) return result;
            foreach (var group in groups.EnumerateArray())
            {
                var rules = new List<ScenarioRule>();
                if (group.TryGetProperty("rules", out var rulesJson) && rulesJson.ValueKind == JsonValueKind.Array)
                {
                    foreach (var rule in rulesJson.EnumerateArray())
                    {
                        rules.Add(new ScenarioRule
                        {
                            Join = GetString(rule, "join", "AND"),
                            Type = GetString(rule, "type", string.Empty),
                            PrescreenKey = GetString(rule, "prescreenKey", string.Empty),
                            Field = GetString(rule, "field", string.Empty),
                            Keywords = GetString(rule, "keywords", string.Empty),
                            Mode = GetString(rule, "mode", "contains"),
                            From = GetString(rule, "from", string.Empty),
                            To = GetString(rule, "to", string.Empty),
                            DebitCategory = GetString(rule, "debitCategory", string.Empty),
                            CreditCategory = GetString(rule, "creditCategory", string.Empty),
                            DrCr = GetString(rule, "drCr", "debit"),
                            IsManual = GetString(rule, "isManual", "true"),
                        });
                    }
                }
                result.Add(new ScenarioGroup { Join = GetString(group, "join", "AND"), Rules = rules });
            }
            return result;
        }

        private string DescribeRule(ScenarioRule rule)
        {
            return rule.Type switch
            {
                "prescreen" => $"預篩選：{rule.PrescreenKey}",
                "text" => $"文字條件：{rule.Field}",
                "dateRange" => $"日期條件：{rule.Field}",
                "numRange" => $"數值條件：{rule.Field}",
                "accountPair" => $"借貸組合：借方 {rule.DebitCategory} / 貸方 {rule.CreditCategory}",
                "drCrOnly" => $"借貸限定：{rule.DrCr}",
                "manualAuto" => $"分錄性質：{rule.IsManual}",
                _ => rule.Type ?? "rule"
            };
        }

        private List<Dictionary<string, object?>> UnionRows(List<Dictionary<string, object?>> left, List<Dictionary<string, object?>> right)
        {
            var seen = new HashSet<Dictionary<string, object?>>(left);
            return [.. left, .. right.Where(row => !seen.Contains(row))];
        }

        private List<Dictionary<string, object?>> IntersectRows(List<Dictionary<string, object?>> left, List<Dictionary<string, object?>> right)
        {
            var rightSet = new HashSet<Dictionary<string, object?>>(right);
            return left.Where(row => rightSet.Contains(row)).ToList();
        }

        private int CountVouchers(List<Dictionary<string, object?>> rows)
        {
            var docColumn = _session.GlMapping.GetValueOrDefault("docNum") ?? string.Empty;
            if (string.IsNullOrWhiteSpace(docColumn)) return rows.Count;
            return rows.Select(row => GetRowValue(row, docColumn)).Where(value => !string.IsNullOrWhiteSpace(value)).Distinct(StringComparer.OrdinalIgnoreCase).Count();
        }

        private string GetGlValue(Dictionary<string, object?> row, string logicalKey)
        {
            return !_session.GlMapping.TryGetValue(logicalKey, out var column) || string.IsNullOrWhiteSpace(column)
                ? string.Empty
                : GetRowValue(row, column);
        }

        private decimal GetEntryAmount(Dictionary<string, object?> row)
        {
            if (_session.GlMapping.TryGetValue("amount", out var amountColumn) && !string.IsNullOrWhiteSpace(amountColumn))
            {
                return ParseDecimal(GetRowValue(row, amountColumn));
            }

            if (_session.GlMapping.TryGetValue("debitAmount", out var debitColumn) && !string.IsNullOrWhiteSpace(debitColumn)
                && _session.GlMapping.TryGetValue("creditAmount", out var creditColumn) && !string.IsNullOrWhiteSpace(creditColumn))
            {
                return ParseDecimal(GetRowValue(row, debitColumn)) - ParseDecimal(GetRowValue(row, creditColumn));
            }

            return 0m;
        }

        private static string GetRowValue(Dictionary<string, object?> row, string key)
        {
            return row.TryGetValue(key, out var value) ? value?.ToString() ?? string.Empty : string.Empty;
        }

        private static string GetString(JsonElement element, string propertyName, string fallback)
        {
            return element.TryGetProperty(propertyName, out var property) ? property.GetString() ?? fallback : fallback;
        }

        private static DateTime? ParseDate(string? value)
        {
            return DateTime.TryParse(value, out var date) ? date : null;
        }

        private static decimal ParseDecimal(string? value)
        {
            return decimal.TryParse(value, out var number) ? number : 0m;
        }

        private static decimal? ParseNullableDecimal(string? value)
        {
            return decimal.TryParse(value, out var number) ? number : null;
        }

        private static int TrailingZeros(decimal number)
        {
            if (number == 0) return 0;
            var text = Math.Abs(decimal.Truncate(number)).ToString();
            var count = 0;
            for (var i = text.Length - 1; i >= 0 && text[i] == '0'; i--) count++;
            return count;
        }

        private static readonly string[] PrescreenKeywords = ["adj", "rev", "reclass", "suspense", "error", "wrong", "調整", "迴轉", "沖銷", "重分類", "避險", "重編", "錯誤", "計畫外", "預算外"];

        private sealed class ScenarioGroup
        {
            public string Join { get; set; } = "AND";
            public List<ScenarioRule> Rules { get; set; } = [];
        }

        private sealed class ScenarioRule
        {
            public string Join { get; set; } = "AND";
            public string Type { get; set; } = string.Empty;
            public string PrescreenKey { get; set; } = string.Empty;
            public string Field { get; set; } = string.Empty;
            public string Keywords { get; set; } = string.Empty;
            public string Mode { get; set; } = "contains";
            public string From { get; set; } = string.Empty;
            public string To { get; set; } = string.Empty;
            public string DebitCategory { get; set; } = string.Empty;
            public string CreditCategory { get; set; } = string.Empty;
            public string DrCr { get; set; } = "debit";
            public string IsManual { get; set; } = "true";
        }
    }
}
