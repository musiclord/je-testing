using JET.Application.Commands.CommitMapping;
using JET.Domain.Abstractions.Repositories;
using JET.Infrastructure.Persistence;
using Xunit;

namespace JET.Tests.Application;

public sealed class CommitMappingCommandHandlerTests
{
    [Fact]
    public async Task HandleCommitGlAsync_saves_mapping_and_returns_projection_result()
    {
        var session = new InMemoryProjectSessionStore();
        session.SetCurrentProjectId("project-1");
        var projection = new StubGlProjectionRepository(new ProjectionResult("batch-1", 2));
        var handler = new CommitMappingCommandHandler(session, projection, null);
        var mapping = new Dictionary<string, string> { ["docNum"] = "Document Number" };

        var result = await handler.HandleCommitGlAsync(mapping, CancellationToken.None);

        Assert.Same(mapping, session.GlMapping);
        Assert.Contains("projectedRowCount = 2", result.ToString());
    }

    [Fact]
    public async Task HandleCommitTbAsync_saves_mapping_and_returns_projection_result()
    {
        var session = new InMemoryProjectSessionStore();
        session.SetCurrentProjectId("project-1");
        var projection = new StubTbProjectionRepository(new ProjectionResult("batch-1", 1));
        var handler = new CommitMappingCommandHandler(session, null, projection);
        var mapping = new Dictionary<string, string> { ["accNum"] = "Account Number" };

        var result = await handler.HandleCommitTbAsync(mapping, CancellationToken.None);

        Assert.Same(mapping, session.TbMapping);
        Assert.Contains("projectedRowCount = 1", result.ToString());
    }

    private sealed class StubGlProjectionRepository : IGlProjectionRepository
    {
        private readonly ProjectionResult _result;

        public StubGlProjectionRepository(ProjectionResult result)
        {
            _result = result;
        }

        public Task<ProjectionResult> ProjectLatestBatchAsync(string projectId, IReadOnlyDictionary<string, string> mapping, CancellationToken cancellationToken)
        {
            return Task.FromResult(_result);
        }
    }

    private sealed class StubTbProjectionRepository : ITbProjectionRepository
    {
        private readonly ProjectionResult _result;

        public StubTbProjectionRepository(ProjectionResult result)
        {
            _result = result;
        }

        public Task<ProjectionResult> ProjectLatestBatchAsync(string projectId, IReadOnlyDictionary<string, string> mapping, CancellationToken cancellationToken)
        {
            return Task.FromResult(_result);
        }
    }
}
