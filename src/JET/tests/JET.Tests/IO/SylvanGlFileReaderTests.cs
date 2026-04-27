using System.Data;
using JET.Domain.Entities;
using JET.Infrastructure.IO.Excel;
using Sylvan.Data.Excel;
using Xunit;

namespace JET.Tests.IO
{
    /// <summary>
    /// Validates the streaming Excel reader introduced in plan.md Phase 3 §3.1.a.
    /// Generates a tiny xlsx fixture at runtime via Sylvan's writer to avoid
    /// committing binary fixtures.
    /// </summary>
    public sealed class SylvanGlFileReaderTests : IDisposable
    {
        private readonly string _tempPath;

        public SylvanGlFileReaderTests()
        {
            _tempPath = Path.Combine(Path.GetTempPath(), $"jet-gl-{Guid.NewGuid():N}.xlsx");
            WriteFixture(_tempPath);
        }

        public void Dispose()
        {
            if (File.Exists(_tempPath))
            {
                try { File.Delete(_tempPath); } catch { /* best effort */ }
            }
        }

        [Fact]
        public async Task ReadAsync_yields_header_row_first_then_data_rows_in_order()
        {
            var reader = new SylvanGlFileReader();

            var rows = new List<GlRawRow>();
            await foreach (var row in reader.ReadAsync(_tempPath, CancellationToken.None))
            {
                rows.Add(row);
            }

            Assert.Equal(4, rows.Count); // 1 header + 3 data rows

            // Header at RowIndex 0
            Assert.Equal(0, rows[0].RowIndex);
            Assert.Equal(new[] { "VoucherNo", "AccountCode", "Amount" }, rows[0].Values);

            // Data rows
            Assert.Equal(1, rows[1].RowIndex);
            Assert.Equal(new[] { "V001", "1101", "100" }, rows[1].Values);

            Assert.Equal(2, rows[2].RowIndex);
            Assert.Equal(new[] { "V002", "1102", "200" }, rows[2].Values);

            Assert.Equal(3, rows[3].RowIndex);
            Assert.Equal(new[] { "V003", "1103", "300" }, rows[3].Values);
        }

        [Fact]
        public async Task ReadAsync_throws_FileNotFoundException_for_missing_file()
        {
            var reader = new SylvanGlFileReader();
            var missing = Path.Combine(Path.GetTempPath(), $"jet-missing-{Guid.NewGuid():N}.xlsx");

            await Assert.ThrowsAsync<FileNotFoundException>(async () =>
            {
                await foreach (var _ in reader.ReadAsync(missing, CancellationToken.None))
                {
                }
            });
        }

        [Fact]
        public async Task ReadAsync_throws_ArgumentException_for_blank_path()
        {
            var reader = new SylvanGlFileReader();

            await Assert.ThrowsAsync<ArgumentException>(async () =>
            {
                await foreach (var _ in reader.ReadAsync(" ", CancellationToken.None))
                {
                }
            });
        }

        private static void WriteFixture(string path)
        {
            using var table = new DataTable("GL");
            table.Columns.Add("VoucherNo", typeof(string));
            table.Columns.Add("AccountCode", typeof(string));
            table.Columns.Add("Amount", typeof(string));
            table.Rows.Add("V001", "1101", "100");
            table.Rows.Add("V002", "1102", "200");
            table.Rows.Add("V003", "1103", "300");

            using var writer = ExcelDataWriter.Create(path);
            using var dataReader = table.CreateDataReader();
            writer.Write(dataReader);
        }
    }
}
