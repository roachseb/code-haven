# Demo Projects

This directory contains minimal "hello world" projects for each supported language/framework. These serve as:

1. **Integration tests** — Validates that Code Haven pipelines work end-to-end
2. **Living documentation** — Shows real project structures that work with Code Haven
3. **Development fixtures** — Used for testing pipeline changes before releasing

## Project Index

| Directory | Language | Type | Tests | CI Workflow |
|-----------|----------|------|-------|-------------|
| `cpp-library/` | C++ | Library (Conan package) | GoogleTest | ✅ |
| `cpp-app/` | C++ | Binary (consumes cpp-library) | GoogleTest | ✅ |
| `java-spring/` | Java | Spring Boot microservice | JUnit 5 | ✅ |
| `java-quarkus/` | Java | Quarkus + GraalVM native | JUnit 5 + REST Assured | ✅ |
| `node-express/` | Node.js | Express.js API | Jest | ✅ |
| `node-nextjs/` | Node.js | Next.js dashboard | Jest + Testing Library | ✅ |
| `python-fastapi/` | Python | FastAPI service | pytest | ✅ |
| `go-service/` | Go | Go HTTP service | go test | ✅ |
| `rust-cli/` | Rust | CLI tool | cargo test | ✅ |
| `dotnet-api/` | .NET | ASP.NET Core API | xUnit | ✅ |
| `fullstack-monorepo/` | Node.js | React + Fastify API (monorepo) | Vitest + Jest | ✅ |

## How to Use

Each demo project has its own `.github/workflows/ci.yml` that calls Code Haven's orchestrator. To test the full pipeline:

```bash
# From repo root — run the demo project CI locally (via act)
cd demo-projects/cpp-library
act push -W .github/workflows/ci.yml

# Or push to a test branch and watch GitHub Actions
git checkout -b test/demo-cpp
git push origin test/demo-cpp
```

## Testing Pipeline Changes

When modifying Code Haven workflows, update the demo projects to reference your branch:

```yaml
# In demo project ci.yml — temporarily point to your branch
jobs:
  ci:
    uses: code-haven/code-haven/.github/workflows/devsecops.yml@my-feature-branch
```

After validation, merge your Code Haven changes and revert demo projects to `@main`.
