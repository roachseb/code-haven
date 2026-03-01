# .NET

**Workflow:** [`_build-dotnet.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_build-dotnet.yml)  
**Triggered by:** `*.sln` or `*.csproj`

## Jobs

| Job | Description |
|-----|-------------|
| `dotnet-build` | `dotnet restore` + `dotnet build` |
| `dotnet-test` | `dotnet test` with TRX + XPlat Code Coverage |
| `dotnet-format` | `dotnet format --verify-no-changes` (soft-fail) |
| `dotnet-publish` | NuGet pack & push to GitHub Packages (tag push only) |

## Configuration

```yaml
with:
  dotnet_version: '8.0.x'
```
