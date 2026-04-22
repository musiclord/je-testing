using JET.Domain.Entities;

namespace JET.Domain.Abstractions
{
    public interface IProjectSessionStore
    {
        ProjectInfo? Project { get; }
        IReadOnlyList<Dictionary<string, object?>> GlData { get; }
        IReadOnlyList<Dictionary<string, object?>> TbData { get; }
        IReadOnlyList<Dictionary<string, object?>> AccountMappingData { get; }
        IReadOnlyList<string> GlColumns { get; }
        IReadOnlyList<string> TbColumns { get; }
        string GlFileName { get; }
        string TbFileName { get; }
        string AccountMappingFileName { get; }
        Dictionary<string, string> GlMapping { get; }
        Dictionary<string, string> TbMapping { get; }
        IReadOnlyList<string> Holidays { get; }
        IReadOnlyList<string> MakeupDays { get; }
        IReadOnlyList<int> Weekends { get; }

        void SetProject(ProjectInfo project);
        void SetGlData(string fileName, IReadOnlyList<Dictionary<string, object?>> rows, IReadOnlyList<string> columns);
        void SetTbData(string fileName, IReadOnlyList<Dictionary<string, object?>> rows, IReadOnlyList<string> columns);
        void SetAccountMappingData(string fileName, IReadOnlyList<Dictionary<string, object?>> rows);
        void SetGlMapping(Dictionary<string, string> mapping);
        void SetTbMapping(Dictionary<string, string> mapping);
        void SetHolidays(IReadOnlyList<string> dates);
        void SetMakeupDays(IReadOnlyList<string> dates);
        void SetWeekends(IReadOnlyList<int> weekends);
    }
}
