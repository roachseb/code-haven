# Go

**Workflow:** [`_build-go.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_build-go.yml)  
**Triggered by:** `*.go` files

## Jobs

| Job | Description |
|-----|-------------|
| `golang-build` | `go build ./...` |
| `golang-test` | gotestsum with race detection + coverage (HTML, JUnit) |
| `golang-lint` | golangci-lint (soft-fail) |
| `golang-fmt` | `gofmt -l .` check (soft-fail) |
| `golang-vet` | `go vet ./...` (soft-fail) |

## Configuration

```yaml
with:
  golang_version: '1.22'
```
