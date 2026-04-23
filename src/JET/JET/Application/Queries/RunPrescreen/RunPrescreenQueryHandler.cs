using JET.Application.Common;
using JET.Domain.Abstractions;

namespace JET.Application.Queries.RunPrescreen
{
    public sealed class RunPrescreenQueryHandler
    {
        private static readonly string[] KeywordsR2 =
        [
            "adj", "rev", "reclass", "suspense", "error", "wrong",
            "調整", "迴轉", "沖銷", "重分類", "避險", "重編", "錯誤", "計畫外", "預算外"
        ];

        private readonly IProjectSessionStore _session;

        public RunPrescreenQueryHandler(IProjectSessionStore session)
        {
            _session = session;
        }

        public Task<object> HandleAsync(CancellationToken cancellationToken)
        {
            var gl = _session.GlData;
            var mapping = _session.GlMapping;
            var lastPeriodStart = _session.Project?.LastPeriodStart;
            var accMap = _session.AccountMappingData;

            var r1 = ComputeR1(gl, mapping, lastPeriodStart);
            var r2 = ComputeR2(gl, mapping);
            var r3 = ComputeR3(gl, mapping, accMap);
            var (r4, r4Threshold) = ComputeR4(gl, mapping);
            var r5Summary = ComputeR5(gl, mapping);
            var r6 = ComputeR6(gl, mapping);
            var descNull = gl.Where(r => string.IsNullOrWhiteSpace(GlRowAccess.GetGlVal(r, "description", mapping))).ToList();

            return Task.FromResult<object>(new
            {
                r1,
                r2,
                r3,
                r4,
                r4ZerosThreshold = r4Threshold,
                r5 = gl,
                r5Summary,
                r6,
                descNull,
            });
        }

        private static List<Dictionary<string, object?>> ComputeR1(
            IReadOnlyList<Dictionary<string, object?>> gl,
            Dictionary<string, string> mapping,
            string? lastPeriodStart)
        {
            if (string.IsNullOrEmpty(lastPeriodStart) || !DateTime.TryParse(lastPeriodStart, out var threshold))
                return [];

            return gl.Where(r =>
            {
                var dateStr = GlRowAccess.GetGlVal(r, "docDate", mapping);
                if (string.IsNullOrEmpty(dateStr)) dateStr = GlRowAccess.GetGlVal(r, "postDate", mapping);
                return DateTime.TryParse(dateStr, out var d) && d >= threshold;
            }).ToList();
        }

        private static List<Dictionary<string, object?>> ComputeR2(
            IReadOnlyList<Dictionary<string, object?>> gl,
            Dictionary<string, string> mapping)
        {
            return gl.Where(r =>
            {
                var desc = GlRowAccess.GetGlVal(r, "description", mapping).ToLowerInvariant();
                return KeywordsR2.Any(k => desc.Contains(k, StringComparison.OrdinalIgnoreCase));
            }).ToList();
        }

        private static List<Dictionary<string, object?>> ComputeR3(
            IReadOnlyList<Dictionary<string, object?>> gl,
            Dictionary<string, string> mapping,
            IReadOnlyList<Dictionary<string, object?>> accMap)
        {
            if (accMap.Count == 0) return [];

            var incomeAccs = new HashSet<string>();
            var arAccs = new HashSet<string>();
            var cashAccs = new HashSet<string>();
            var advanceAccs = new HashSet<string>();

            foreach (var row in accMap)
            {
                var values = row.Values.ToList();
                var code = (values.ElementAtOrDefault(0)?.ToString() ?? "").Trim();
                var category = (values.ElementAtOrDefault(2)?.ToString() ?? "").ToLowerInvariant();

                if (category.Contains("收入") || category.Contains("revenue") || category.Contains("income"))
                    incomeAccs.Add(code);
                if (category.Contains("應收") || category.Contains("receivable"))
                    arAccs.Add(code);
                if (category.Contains("現金") || category.Contains("cash") || category.Contains("bank"))
                    cashAccs.Add(code);
                if (category.Contains("預收") || category.Contains("advance") || category.Contains("deferred"))
                    advanceAccs.Add(code);
            }

            // R3 per-voucher logic (jet-guide.md §5):
            // A voucher is flagged when it simultaneously has:
            //   CreditSet: any line with Category=Revenue AND Amount<0
            //   DebitSet:  any line with Category∈{Receivables,Cash,Advance} AND Amount>0
            // All lines of such vouchers are returned.
            var byDoc = gl.GroupBy(r => (GlRowAccess.GetGlVal(r, "docNum", mapping) is { Length: > 0 } v ? v : "_"));
            var matched = new List<Dictionary<string, object?>>();
            foreach (var group in byDoc)
            {
                var hasCreditRevenue = group.Any(r =>
                {
                    var acc = GlRowAccess.GetGlVal(r, "accNum", mapping).Trim();
                    return GlRowAccess.GetAmount(r, mapping) < 0 && incomeAccs.Contains(acc);
                });
                if (!hasCreditRevenue) continue;

                var hasDebitExpected = group.Any(r =>
                {
                    var acc = GlRowAccess.GetGlVal(r, "accNum", mapping).Trim();
                    var amt = GlRowAccess.GetAmount(r, mapping);
                    return amt > 0 && (arAccs.Contains(acc) || cashAccs.Contains(acc) || advanceAccs.Contains(acc));
                });
                if (!hasDebitExpected) continue;

                matched.AddRange(group);
            }
            return matched;
        }

        private static (List<Dictionary<string, object?>> rows, int threshold) ComputeR4(
            IReadOnlyList<Dictionary<string, object?>> gl,
            Dictionary<string, string> mapping)
        {
            var debits = gl
                .Select(r => GlRowAccess.GetAmount(r, mapping))
                .Where(a => a > 0)
                .Select(a => (double)a)
                .ToList();

            var avg = debits.Count > 0 ? debits.Average() : 0;
            var avgLen = avg > 0 ? (int)Math.Floor(Math.Log10(avg)) : 3;
            var threshold = Math.Max(3, avgLen - 1);

            var rows = gl.Where(r =>
            {
                var amt = Math.Abs(GlRowAccess.GetAmount(r, mapping));
                return TrailingZeros(amt) >= threshold;
            }).ToList();

            return (rows, threshold);
        }

        private static Dictionary<string, object>? ComputeR5(
            IReadOnlyList<Dictionary<string, object?>> gl,
            Dictionary<string, string> mapping)
        {
            if (!mapping.TryGetValue("createBy", out var createByCol) || string.IsNullOrEmpty(createByCol))
                return null;

            var byCreator = new Dictionary<string, object>();
                var groups = gl.GroupBy(r => GlRowAccess.GetGlVal(r, "createBy", mapping) is { Length: > 0 } v ? v : "(未知)");

            foreach (var g in groups)
            {
                byCreator[g.Key] = new { count = g.Count(), rows = g.ToList() };
            }

            return byCreator;
        }

        private static List<Dictionary<string, object?>> ComputeR6(
            IReadOnlyList<Dictionary<string, object?>> gl,
            Dictionary<string, string> mapping)
        {
            var accFreq = new Dictionary<string, int>();
            foreach (var r in gl)
            {
                var acc = GlRowAccess.GetGlVal(r, "accNum", mapping) is { Length: > 0 } v ? v : "?";
                accFreq[acc] = accFreq.GetValueOrDefault(acc) + 1;
            }

            var freqValues = accFreq.Values.ToList();
            var avgFreq = freqValues.Count > 0 ? freqValues.Average() : 1;
            var rareAccs = accFreq.Where(kv => kv.Value < avgFreq * 0.25).Select(kv => kv.Key).ToHashSet();

            return gl.Where(r =>
            {
                var acc = GlRowAccess.GetGlVal(r, "accNum", mapping) is { Length: > 0 } v ? v : "?";
                return rareAccs.Contains(acc);
            }).ToList();
        }

        private static int TrailingZeros(decimal num)
        {
            if (num == 0) return 0;
            var s = Math.Abs(Math.Round(num)).ToString("F0");
            var count = 0;
            for (var i = s.Length - 1; i >= 0 && s[i] == '0'; i--) count++;
            return count;
        }
    }
}
