namespace JET.Application.Contracts
{
    public sealed record AppBootstrapDto(
        string ApplicationName,
        string StartPage,
        string[] SupportedActions,
        DatabaseBootstrapDto Database);

    public sealed record DatabaseBootstrapDto(
        string Provider,
        bool IsAvailable,
        string ConnectionTarget,
        string Mode);
}
