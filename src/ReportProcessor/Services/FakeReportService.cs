using System.Text;
using System.Text.Json;

public class FakeReportService
{
    public string GerarJsonSimulado(string clienteId, string dataInicial, string dataFinal, string tipo)
    {
        var bytes = GerarRelatorioSimulado(clienteId, dataInicial, dataFinal, tipo);
        return Encoding.UTF8.GetString(bytes);
    }


    public byte[] GerarRelatorioSimulado(string clienteId, string dataInicial, string dataFinal, string tipo)
    {
        var random = new Random();
        var registros = new List<object>();

        for (int i = 0; i < 10; i++)
        {
            registros.Add(new
            {
                ClienteId = clienteId,
                Data = DateTime.Now.AddDays(-i).ToString("yyyy-MM-dd"),
                Ativo = $"ACAO{i + 1}",
                Tipo = (i % 2 == 0) ? "COMPRA" : "VENDA",
                Quantidade = random.Next(1, 100),
                ValorUnitario = Math.Round(random.NextDouble() * 100, 2)
            });
        }

        var relatorio = new
        {
            Cliente = clienteId,
            Periodo = new { Inicio = dataInicial, Fim = dataFinal },
            TipoRelatorio = tipo,
            GeradoEm = DateTime.UtcNow,
            Operacoes = registros
        };

        string json = JsonSerializer.Serialize(relatorio, new JsonSerializerOptions { WriteIndented = true });
        return Encoding.UTF8.GetBytes(json);
    }
}
