using JET.Application.Queries.ProjectDemo;
using JET.Infrastructure.IO.Excel;
using Xunit;

namespace JET.Tests.Application
{
    public sealed class ExportDemoFilesQueryHandlerTests : IDisposable
    {
        private readonly List<string> _files = [];

        public void Dispose()
        {
            foreach (var file in _files)
            {
                if (File.Exists(file))
                {
                    try { File.Delete(file); } catch { /* best effort */ }
                }
            }
        }

        [Fact]
        public async Task ExportDemoGlFile_writes_xlsx_readable_by_streaming_reader()
        {
            var handler = new ExportDemoGlFileQueryHandler();

            var result = await handler.HandleAsync(new ExportDemoGlFileQuery(), CancellationToken.None);
            _files.Add(result.FilePath);

            Assert.Equal("demo-large-gl.xlsx", result.FileName);
            Assert.True(File.Exists(result.FilePath));

            var rows = await ReadRowsAsync(result.FilePath);
            Assert.Equal("Document Number", rows[0][0]);
            Assert.Equal("Amount", rows[0][^1]);
            Assert.True(rows.Count > 1000);
        }

        [Fact]
        public async Task ExportDemoTbFile_writes_xlsx_readable_by_streaming_reader()
        {
            var handler = new ExportDemoTbFileQueryHandler();

            var result = await handler.HandleAsync(new ExportDemoTbFileQuery(), CancellationToken.None);
            _files.Add(result.FilePath);

            Assert.Equal("demo-large-tb.xlsx", result.FileName);
            Assert.True(File.Exists(result.FilePath));

            var rows = await ReadRowsAsync(result.FilePath);
            Assert.Equal(new[] { "Account Number", "Account Name", "Change Amount" }, rows[0]);
            Assert.True(rows.Count > 1);
        }

        [Fact]
        public async Task ExportDemoAccountMappingFile_writes_xlsx_readable_by_streaming_reader()
        {
            var handler = new ExportDemoAccountMappingFileQueryHandler();

            var result = await handler.HandleAsync(new ExportDemoAccountMappingFileQuery(), CancellationToken.None);
            _files.Add(result.FilePath);

            Assert.Equal("demo-account-mapping.xlsx", result.FileName);
            Assert.True(File.Exists(result.FilePath));

            var rows = await ReadRowsAsync(result.FilePath);
            Assert.Equal(new[] { "Account Code", "Account Name", "Category" }, rows[0]);
            Assert.True(rows.Count > 1);
        }

        private static async Task<List<string[]>> ReadRowsAsync(string filePath)
        {
            var reader = new SylvanGlFileReader();
            var rows = new List<string[]>();
            await foreach (var row in reader.ReadAsync(filePath, CancellationToken.None))
            {
                rows.Add(row.Values.Select(value => value ?? string.Empty).ToArray());
            }

            return rows;
        }
    }
}
