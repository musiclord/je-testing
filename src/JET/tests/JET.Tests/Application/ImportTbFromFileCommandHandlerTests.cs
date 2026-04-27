using System.Data;
using System.Reflection;
using Dapper;
using JET.Application.Commands.ImportData;
using JET.Domain.Abstractions;
using JET.Domain.Abstractions.Persistence;
using JET.Domain.Entities;
using JET.Infrastructure.IO.Excel;
using JET.Infrastructure.Persistence.Schema;
using JET.Infrastructure.Persistence.Sqlite;
using JET.Infrastructure.Persistence.Sqlite.Repositories;
using Microsoft.Data.Sqlite;
using Sylvan.Data.Excel;
using Xunit;

namespace JET.Tests.Application;

/// <summary>
/// End-to-end integration test for the §3.1.c TB ingest pipeline:
/// xlsx file → <see cref="SylvanGlFileReader"/> → <see cref="SqliteTbRepository"/>
/// without ever loading the full row set into memory.
/// </summary>
public sealed class ImportTbFromFileCommandHandlerTests : IDisposable
{
    private const string ProjectId = "00000000-0000-0000-0000-0000000000dd";
    private static readonly ISchemaNames Names = new SqliteSchemaNames();
    private readonly string _tempPath;

    public ImportTbFromFileCommandHandlerTests()
    {
        _tempPath = Path.Combine(Path.GetTempPath(), $"jet-tb-import-{Guid.NewGuid():N}.xlsx");
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
    public async Task HandleAsync_streams_file_into_staging_and_returns_summary()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("tb-handler");
        await using var _ = keepAlive;

        var session = new StubSessionStore { CurrentProjectId = ProjectId };
        var handler = new ImportTbFromFileCommandHandler(
            session,
            new SylvanGlFileReader(),
            new SqliteTbRepository(connectionString, Names));

        var response = await handler.HandleAsync(_tempPath, fileName: null, mode: null, CancellationToken.None);

        var batchId = (string)Read(response, "batchId")!;
        var rowCount = (int)Read(response, "rowCount")!;
        var columns = (IReadOnlyList<string>)Read(response, "columns")!;

        Assert.False(string.IsNullOrWhiteSpace(batchId));
        Assert.Equal(3, rowCount);
        Assert.Equal(new[] { "Account", "Balance" }, columns);

        await using var probe = new SqliteConnection(connectionString);
        await probe.OpenAsync();
        var rawRowCount = await probe.ExecuteScalarAsync<long>(
            $"SELECT COUNT(1) FROM {Names.Resolve(JetTable.StagingTbRawRow)} WHERE batch_id = @id;",
            new { id = batchId });
        Assert.Equal(3L, rawRowCount);
    }

    [Fact]
    public async Task HandleAsync_throws_when_no_active_project()
    {
        var (connectionString, keepAlive) = await OpenSharedMemoryAsync("tb-handler-no-project");
        await using var _ = keepAlive;

        var session = new StubSessionStore { CurrentProjectId = null };
        var handler = new ImportTbFromFileCommandHandler(
            session,
            new SylvanGlFileReader(),
            new SqliteTbRepository(connectionString, Names));

        await Assert.ThrowsAsync<InvalidOperationException>(async () =>
            await handler.HandleAsync(_tempPath, null, null, CancellationToken.None));
    }

    private static object? Read(object source, string name)
    {
        var prop = source.GetType().GetProperty(name, BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
        return prop?.GetValue(source);
    }

    private static void WriteFixture(string path)
    {
        using var table = new DataTable("TB");
        table.Columns.Add("Account", typeof(string));
        table.Columns.Add("Balance", typeof(string));
        table.Rows.Add("1101", "100");
        table.Rows.Add("1102", "200");
        table.Rows.Add("1103", "300");

        using var writer = ExcelDataWriter.Create(path);
        using var dataReader = table.CreateDataReader();
        writer.Write(dataReader);
    }

    private static async Task<(string ConnectionString, SqliteConnection KeepAlive)> OpenSharedMemoryAsync(string name)
    {
        var connectionString = $"Data Source={name};Mode=Memory;Cache=Shared";
        var keepAlive = new SqliteConnection(connectionString);
        await keepAlive.OpenAsync();
        await new SqliteSchemaInitializer(connectionString, Names).EnsureAsync(CancellationToken.None);
        return (connectionString, keepAlive);
    }

    private sealed class StubSessionStore : IProjectSessionStore
    {
        public ProjectInfo? Project => null;
        public string? CurrentProjectId { get; set; }
        public Dictionary<string, string> GlMapping => new();
        public Dictionary<string, string> TbMapping => new();
        public IReadOnlyList<string> Holidays => Array.Empty<string>();
        public IReadOnlyList<string> MakeupDays => Array.Empty<string>();
        public IReadOnlyList<int> Weekends => Array.Empty<int>();

        public void SetProject(ProjectInfo project) { }
        public void SetCurrentProjectId(string projectId) => CurrentProjectId = projectId;
        public void SetGlMapping(Dictionary<string, string> mapping) { }
        public void SetTbMapping(Dictionary<string, string> mapping) { }
        public void SetHolidays(IReadOnlyList<string> dates) { }
        public void SetMakeupDays(IReadOnlyList<string> dates) { }
        public void SetWeekends(IReadOnlyList<int> weekends) { }
    }
}
