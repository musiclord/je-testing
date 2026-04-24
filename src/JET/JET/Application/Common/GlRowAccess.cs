using System.Globalization;

namespace JET.Application.Common
{
    /// <summary>
    /// Shared helpers for reading logical fields from a raw GL row using the
    /// user-defined logical-to-physical column mapping. Mirrors the frontend
    /// helpers getGLVal / getEntryAmount in docs/jet-template.html so that
    /// validation and prescreen handlers operate on the same projection rules.
    /// </summary>
    internal static class GlRowAccess
    {
        public static string GetGlVal(
            IReadOnlyDictionary<string, object?> row,
            string logicalKey,
            IReadOnlyDictionary<string, string> mapping)
        {
            if (!mapping.TryGetValue(logicalKey, out var column) || string.IsNullOrEmpty(column))
            {
                return string.Empty;
            }

            return GetVal(row, column);
        }

        public static string GetVal(IReadOnlyDictionary<string, object?> row, string column)
        {
            if (string.IsNullOrEmpty(column)) return string.Empty;
            if (!row.TryGetValue(column, out var value) || value is null) return string.Empty;
            return value switch
            {
                string s => s,
                IFormattable f => f.ToString(null, CultureInfo.InvariantCulture),
                _ => value.ToString() ?? string.Empty
            };
        }

        public static decimal ParseDecimal(string? raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return 0m;
            return decimal.TryParse(raw, NumberStyles.Any, CultureInfo.InvariantCulture, out var parsed) ? parsed : 0m;
        }

        public static decimal GetAmount(
            IReadOnlyDictionary<string, object?> row,
            IReadOnlyDictionary<string, string> mapping)
        {
            if (TryReadDecimal(row, mapping, "amount", out var amount))
            {
                if (TryReadMappedString(row, mapping, "dcField", out var dc) &&
                    TryReadMappedString(row, mapping, "dcDebitCode", out var debitCode) &&
                    !string.IsNullOrEmpty(debitCode))
                {
                    var dcValue = dc.Trim().ToUpperInvariant();
                    return string.Equals(dcValue, debitCode.Trim().ToUpperInvariant(), StringComparison.Ordinal)
                        ? amount
                        : -amount;
                }

                return amount;
            }

            var hasDebit = TryReadDecimal(row, mapping, "debitAmount", out var debit);
            var hasCredit = TryReadDecimal(row, mapping, "creditAmount", out var credit);
            if (hasDebit || hasCredit)
            {
                return debit - credit;
            }

            return 0m;
        }

        private static bool TryReadDecimal(
            IReadOnlyDictionary<string, object?> row,
            IReadOnlyDictionary<string, string> mapping,
            string logicalKey,
            out decimal value)
        {
            value = 0m;
            if (!mapping.TryGetValue(logicalKey, out var column) || string.IsNullOrEmpty(column))
            {
                return false;
            }

            if (!row.TryGetValue(column, out var raw) || raw is null)
            {
                return false;
            }

            switch (raw)
            {
                case decimal dec:
                    value = dec;
                    return true;
                case double dbl:
                    value = (decimal)dbl;
                    return true;
                case float flt:
                    value = (decimal)flt;
                    return true;
                case long lng:
                    value = lng;
                    return true;
                case int i:
                    value = i;
                    return true;
                case string s when decimal.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out var parsed):
                    value = parsed;
                    return true;
                default:
                    return false;
            }
        }

        private static bool TryReadMappedString(
            IReadOnlyDictionary<string, object?> row,
            IReadOnlyDictionary<string, string> mapping,
            string logicalKey,
            out string value)
        {
            value = GetGlVal(row, logicalKey, mapping);
            return !string.IsNullOrEmpty(value);
        }
    }
}
