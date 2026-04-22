using JET.Domain.Abstractions;

namespace JET.Application.Commands.CommitMapping
{
    public sealed class CommitMappingCommandHandler
    {
        private readonly IProjectSessionStore _session;

        public CommitMappingCommandHandler(IProjectSessionStore session)
        {
            _session = session;
        }

        public Task<object> HandleCommitGlAsync(Dictionary<string, string> mapping, CancellationToken cancellationToken)
        {
            _session.SetGlMapping(mapping);
            return Task.FromResult<object>(new { ok = true, mapping });
        }

        public Task<object> HandleCommitTbAsync(Dictionary<string, string> mapping, CancellationToken cancellationToken)
        {
            _session.SetTbMapping(mapping);
            return Task.FromResult<object>(new { ok = true, mapping });
        }
    }
}
