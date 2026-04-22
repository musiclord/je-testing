using JET.Application.Contracts;

namespace JET.Application.DemoData
{
    public sealed record DemoProjectDataBundle(
        DemoProjectDto Project,
        IReadOnlyList<Dictionary<string, object?>> InvalidGlRows);
}
