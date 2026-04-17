namespace JET.Application.Contracts
{
    public sealed record DemoProjectDto(
        string EntityName,
        string Industry,
        string PeriodStart,
        string PeriodEnd,
        string LastPeriodStart,
        string GlFileName,
        string TbFileName,
        string AccountMappingFileName,
        IReadOnlyList<Dictionary<string, object?>> GlRows,
        IReadOnlyList<Dictionary<string, object?>> TbRows,
        IReadOnlyList<Dictionary<string, object?>> AccountMappingRows,
        IReadOnlyDictionary<string, string> GlMapping,
        IReadOnlyDictionary<string, string> TbMapping,
        IReadOnlyList<string> Holidays,
        IReadOnlyList<string> MakeupDays,
        IReadOnlyList<int> Weekends);
}
