using JET.Domain.Abstractions;
using JET.Domain.Entities;

namespace JET.Application.Commands.CreateProject
{
    public sealed class CreateProjectCommandHandler
    {
        private readonly IProjectSessionStore _session;

        public CreateProjectCommandHandler(IProjectSessionStore session)
        {
            _session = session;
        }

        public Task<object> HandleAsync(CreateProjectCommand command, CancellationToken cancellationToken)
        {
            _session.SetProject(new ProjectInfo
            {
                ProjectCode = command.ProjectCode,
                EntityName = command.EntityName,
                OperatorId = command.OperatorId,
                Industry = command.Industry,
                PeriodStart = command.PeriodStart,
                PeriodEnd = command.PeriodEnd,
                LastPeriodStart = command.LastPeriodStart,
            });

            return Task.FromResult<object>(new { projectId = $"local-{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}", ok = true });
        }
    }
}
