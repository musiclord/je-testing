using System.Text.Json;
using System.Text.Json.Serialization;

namespace JET.Infrastructure.Configuration
{
    public static class JetAppOptionsLoader
    {
        private static readonly JsonSerializerOptions JsonOptions = new()
        {
            PropertyNameCaseInsensitive = true,
            ReadCommentHandling = JsonCommentHandling.Skip,
            AllowTrailingCommas = true,
            Converters = { new JsonStringEnumConverter() }
        };

        public static JetAppOptions Load(string filePath)
        {
            JetAppOptions options;

            if (!File.Exists(filePath))
            {
                options = new JetAppOptions();
            }
            else
            {
                var json = File.ReadAllText(filePath);
                options = JsonSerializer.Deserialize<JetAppOptions>(json, JsonOptions) ?? new JetAppOptions();
            }

            options.Database.SqliteConnectionString = Environment.ExpandEnvironmentVariables(options.Database.SqliteConnectionString);
            options.Database.SqlServerConnectionString = Environment.ExpandEnvironmentVariables(options.Database.SqlServerConnectionString);
            return options;
        }
    }
}
