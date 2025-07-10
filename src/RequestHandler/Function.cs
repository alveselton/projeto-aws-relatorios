using Amazon.Lambda.Core;
using Amazon.Lambda.APIGatewayEvents;
using StackExchange.Redis;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace RequestHandler;

public class Function
{
    private static readonly ConnectionMultiplexer redis = 
        ConnectionMultiplexer.Connect($"{Environment.GetEnvironmentVariable("REDIS_HOST")}:{Environment.GetEnvironmentVariable("REDIS_PORT")}");

    public async Task<APIGatewayProxyResponse> FunctionHandler(APIGatewayProxyRequest request, ILambdaContext context)
    {
        var db = redis.GetDatabase();
        var hash = GenerateHash(request.Body);

        if (await db.KeyExistsAsync($"done:{hash}"))
        {
            var url = await db.StringGetAsync($"done:{hash}");
            return new APIGatewayProxyResponse
            {
                StatusCode = 200,
                Body = JsonSerializer.Serialize(new { status = "completed", url = url })
            };
        }

        if (await db.KeyExistsAsync($"pending:{hash}"))
        {
            return new APIGatewayProxyResponse
            {
                StatusCode = 202,
                Body = JsonSerializer.Serialize(new { status = "processing" })
            };
        }

        await db.StringSetAsync($"pending:{hash}", request.Body);
        return new APIGatewayProxyResponse
        {
            StatusCode = 202,
            Body = JsonSerializer.Serialize(new { status = "queued" })
        };
    }

    private string GenerateHash(string input)
    {
        using var sha = SHA256.Create();
        var bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(input));
        return Convert.ToHexString(bytes);
    }
}
