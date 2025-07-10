using Amazon.Lambda.Core;
using Amazon.S3;
using Amazon.S3.Model;
using StackExchange.Redis;
using System.Text.Json;
using System.Text;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

public class Function
{
    private static readonly string redisHost = Environment.GetEnvironmentVariable("REDIS_HOST");
    private static readonly string redisPort = Environment.GetEnvironmentVariable("REDIS_PORT");
    private static readonly string redisUser = Environment.GetEnvironmentVariable("REDIS_USER");
    private static readonly string redisPassword = Environment.GetEnvironmentVariable("REDIS_PASSWORD");
    private static readonly string bucket = Environment.GetEnvironmentVariable("S3_BUCKET");
    private static readonly string dynamoTable = Environment.GetEnvironmentVariable("DYNAMODB_TABLE");

    private static readonly ConnectionMultiplexer redis = ConnectionMultiplexer.Connect(new ConfigurationOptions
    {
        EndPoints = { $"{redisHost}:{redisPort}" },
        User = redisUser,
        Password = redisPassword,
        Ssl = true,
        AbortOnConnectFail = false
    });

    private readonly IAmazonS3 s3Client = new AmazonS3Client();
    private readonly IAmazonDynamoDB dynamoDb = new AmazonDynamoDBClient();

    public async Task FunctionHandler(ILambdaContext context)
    {
        var db = redis.GetDatabase();
        var keys = redis.GetServer(redis.GetEndPoints()[0]).Keys(pattern: "fila:*").Take(1);
        
        foreach (var key in keys)
        {
            var hash = key.ToString().Split(':')[1];
            var json = await db.StringGetAsync(key);
            if (string.IsNullOrEmpty(json)) continue;

            var relatorio = JsonSerializer.Deserialize<RelatorioRequest>(json);

            var service = new FakeReportService();
            byte[] relatorioBytes = service.GerarRelatorioSimulado(relatorio.ClienteId, relatorio.DataInicial, relatorio.DataFinal, relatorio.Tipo);

            var s3Key = $"relatorios/{hash}.json";
            await s3Client.PutObjectAsync(new PutObjectRequest
            {
                BucketName = bucket,
                Key = s3Key,
                InputStream = new MemoryStream(relatorioBytes),
                ContentType = "application/json"
            });

            await db.StringSetAsync($"status:{hash}", "concluido");
            await db.KeyDeleteAsync(key);

            await dynamoDb.PutItemAsync(new PutItemRequest
            {
                TableName = dynamoTable,
                Item = new Dictionary<string, AttributeValue>
                {
                    { "RelatorioId", new AttributeValue(hash) },
                    { "ClienteId", new AttributeValue(relatorio.ClienteId) },
                    { "Periodo", new AttributeValue($"{relatorio.DataInicial} - {relatorio.DataFinal}") },
                    { "Tipo", new AttributeValue(relatorio.Tipo) },
                    { "S3Key", new AttributeValue(s3Key) },
                    { "Status", new AttributeValue("concluido") },
                    { "GeradoEm", new AttributeValue(DateTime.UtcNow.ToString("o")) }
                }
            });

            context.Logger.LogLine($"Relatório {hash} processado com sucesso.");
        }
    }
}
