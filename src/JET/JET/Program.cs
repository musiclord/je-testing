using JET.Bridge;
using JET.Domain.Abstractions;
using JET.Domain.Enums;
using JET.Infrastructure.Configuration;
using JET.Infrastructure.Persistence;
using JET.Infrastructure.Persistence.SqlServer;
using JET.Infrastructure.Persistence.Sqlite;

namespace JET
{
    internal static class Program
    {
        [STAThread]
        static void Main()
        {
            ApplicationConfiguration.Initialize();

            var options = JetAppOptionsLoader.LoadWithEnvironment(Path.Combine(AppContext.BaseDirectory, "appsettings.json"), null);
            var appStateStore = CreateAppStateStore(options);
            var sessionStore = new InMemoryProjectSessionStore();
            var actionDispatcher = new ActionDispatcher(options, appStateStore, sessionStore);

            System.Windows.Forms.Application.Run(new Form1(options, actionDispatcher));
        }

        private static IAppStateStore CreateAppStateStore(JetAppOptions options)
        {
            return options.Database.Provider switch
            {
                DatabaseProvider.SqlServer => new SqlServerAppStateStore(options.Database),
                _ => new SqliteAppStateStore(options.Database)
            };
        }
    }
}
