var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => new { message = "Hello from Code Haven .NET demo!", version = "1.0.0" });
app.MapGet("/health", () => new { status = "healthy" });
app.MapGet("/add/{a}/{b}", (int a, int b) => new { result = a + b });

app.Run();

public partial class Program { }
