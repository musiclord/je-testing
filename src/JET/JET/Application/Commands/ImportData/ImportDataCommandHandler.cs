using JET.Domain.Abstractions;

namespace JET.Application.Commands.ImportData
{
    public sealed class ImportDataCommandHandler
    {
        private readonly IProjectSessionStore _session;

        public ImportDataCommandHandler(IProjectSessionStore session)
        {
            _session = session;
        }

        public Task<object> HandleImportGlAsync(string fileName, IReadOnlyList<Dictionary<string, object?>> rows, CancellationToken cancellationToken)
        {
            var columns = rows.Count > 0 ? rows[0].Keys.ToList() : new List<string>();
            _session.SetGlData(fileName, rows, columns);
            return Task.FromResult<object>(new { fileName, rows, columns });
        }

        public Task<object> HandleImportTbAsync(string fileName, IReadOnlyList<Dictionary<string, object?>> rows, CancellationToken cancellationToken)
        {
            var columns = rows.Count > 0 ? rows[0].Keys.ToList() : new List<string>();
            _session.SetTbData(fileName, rows, columns);
            return Task.FromResult<object>(new { fileName, rows, columns });
        }

        public Task<object> HandleImportAccountMappingAsync(string fileName, IReadOnlyList<Dictionary<string, object?>> rows, CancellationToken cancellationToken)
        {
            _session.SetAccountMappingData(fileName, rows);
            return Task.FromResult<object>(new { fileName, rows });
        }

        public Task<object> HandleImportHolidayAsync(IReadOnlyList<string> dates, CancellationToken cancellationToken)
        {
            _session.SetHolidays(dates);
            return Task.FromResult<object>(new { dates });
        }

        public Task<object> HandleImportMakeupDayAsync(IReadOnlyList<string> dates, CancellationToken cancellationToken)
        {
            _session.SetMakeupDays(dates);
            return Task.FromResult<object>(new { dates });
        }
    }
}
