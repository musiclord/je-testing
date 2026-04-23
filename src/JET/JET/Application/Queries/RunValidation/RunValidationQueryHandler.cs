using JET.Application.Common;
using JET.Domain.Abstractions;

namespace JET.Application.Queries.RunValidation
{
    public sealed class RunValidationQueryHandler
    {
        private readonly IProjectSessionStore _session;

        public RunValidationQueryHandler(IProjectSessionStore session)
        {
            _session = session;
        }

        public Task<object> HandleAsync(CancellationToken cancellationToken)
        {
            var gl = _session.GlData;
            var tb = _session.TbData;
            var glMapping = _session.GlMapping;
            var tbMapping = _session.TbMapping;

            var stats = ComputeGlStats(gl, glMapping);

            var v1NullAccounts = gl.Count(r => string.IsNullOrWhiteSpace(GlRowAccess.GetGlVal(r, "accNum", glMapping)));
            var v2NullDocNums = gl.Count(r => string.IsNullOrWhiteSpace(GlRowAccess.GetGlVal(r, "docNum", glMapping)));
            var v3NullDescriptions = gl.Count(r => string.IsNullOrWhiteSpace(GlRowAccess.GetGlVal(r, "description", glMapping)));

            var periodStart = _session.Project?.PeriodStart ?? string.Empty;
            var periodEnd = _session.Project?.PeriodEnd ?? string.Empty;
            var v4OutOfPeriod = 0;
            if (!string.IsNullOrEmpty(periodStart) && !string.IsNullOrEmpty(periodEnd))
            {
                var pStart = DateTime.Parse(periodStart);
                var pEnd = DateTime.Parse(periodEnd);
                v4OutOfPeriod = gl.Count(r =>
                {
                    var dateStr = GlRowAccess.GetGlVal(r, "docDate", glMapping);
                    if (string.IsNullOrEmpty(dateStr)) dateStr = GlRowAccess.GetGlVal(r, "postDate", glMapping);
                    if (string.IsNullOrEmpty(dateStr) || !DateTime.TryParse(dateStr, out var dt)) return false;
                    return dt < pStart || dt > pEnd;
                });
            }

            var diffAccounts = ComputeCompletenessDiff(gl, tb, glMapping, tbMapping);
            var outOfBalanceDocs = ComputeOutOfBalanceDocs(gl, glMapping);
            var infSampleSize = Math.Min(60, gl.Count);

            return Task.FromResult<object>(new
            {
                stats,
                summary = new
                {
                    completenessDiffAccounts = diffAccounts.Count,
                    outOfBalanceDocuments = outOfBalanceDocs,
                    infSampleSize,
                    nullRecordCount = v1NullAccounts + v2NullDocNums + v3NullDescriptions + v4OutOfPeriod,
                },
                v1 = v1NullAccounts,
                v2 = v2NullDocNums,
                v3 = v3NullDescriptions,
                v4 = v4OutOfPeriod,
                diffAccounts,
            });
        }

        private static object ComputeGlStats(IReadOnlyList<Dictionary<string, object?>> gl, Dictionary<string, string> mapping)
        {
            decimal totalDebit = 0, totalCredit = 0;
            var docSet = new HashSet<string>();

            foreach (var r in gl)
            {
                var amt = GlRowAccess.GetAmount(r, mapping);
                if (amt >= 0) totalDebit += amt; else totalCredit += Math.Abs(amt);
                var doc = GlRowAccess.GetGlVal(r, "docNum", mapping);
                if (!string.IsNullOrEmpty(doc)) docSet.Add(doc);
            }

            return new { total = gl.Count, docs = docSet.Count, totalDebit, totalCredit, net = totalDebit - totalCredit };
        }

        private static List<object> ComputeCompletenessDiff(
            IReadOnlyList<Dictionary<string, object?>> gl,
            IReadOnlyList<Dictionary<string, object?>> tb,
            Dictionary<string, string> glMapping,
            Dictionary<string, string> tbMapping)
        {
            var tbAccAmt = new Dictionary<string, decimal>();
            foreach (var r in tb)
            {
                var acc = GetVal(r, tbMapping.GetValueOrDefault("accNum") ?? "")?.Trim();
                if (string.IsNullOrEmpty(acc)) continue;
                var amt = ParseDecimal(GetVal(r, tbMapping.GetValueOrDefault("amount") ?? ""));
                tbAccAmt[acc] = tbAccAmt.GetValueOrDefault(acc) + amt;
            }

            var glAccAmt = new Dictionary<string, decimal>();
            foreach (var r in gl)
            {
                var acc = GlRowAccess.GetGlVal(r, "accNum", glMapping)?.Trim();
                if (string.IsNullOrEmpty(acc)) continue;
                glAccAmt[acc] = glAccAmt.GetValueOrDefault(acc) + GlRowAccess.GetAmount(r, glMapping);
            }

            var diffs = new List<object>();
            foreach (var (acc, tbAmt) in tbAccAmt)
            {
                var glAmt = glAccAmt.GetValueOrDefault(acc);
                var diff = tbAmt - glAmt;
                if (Math.Abs(diff) > 0.01m)
                {
                    diffs.Add(new { acc, tbAmt, glAmt, diff });
                }
            }
            return diffs;
        }

        private static int ComputeOutOfBalanceDocs(IReadOnlyList<Dictionary<string, object?>> gl, Dictionary<string, string> mapping)
        {
            var docBalance = new Dictionary<string, decimal>();
            foreach (var r in gl)
            {
                var doc = (GlRowAccess.GetGlVal(r, "docNum", mapping) ?? "_").Trim();
                docBalance[doc] = docBalance.GetValueOrDefault(doc) + GlRowAccess.GetAmount(r, mapping);
            }
            return docBalance.Values.Count(v => Math.Abs(v) > 0.01m);
        }

    }
}
