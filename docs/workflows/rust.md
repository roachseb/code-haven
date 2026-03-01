# Rust

**Workflow:** [`_build-rust.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_build-rust.yml)  
**Triggered by:** `Cargo.lock`

## Jobs

| Job | Description |
|-----|-------------|
| `rust-build` | `cargo build` + `cargo test` with summary |
| `rust-fmt` | `cargo fmt -- --check` (soft-fail) |
| `rust-clippy` | `cargo clippy -- -D warnings` (soft-fail) |
| `rust-doc` | `cargo +nightly doc` with index page (soft-fail) |

## Configuration

```yaml
with:
  rust_toolchain: 'stable'
```
