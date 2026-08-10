# Rust Language Profile

Edition 2024 (Rust ≥ 1.85.0).

## Tools

- clippy (bundled)
- rustfmt (bundled)
- cargo-nextest (install separately, research latest version)
- cargo-deny (install separately, research latest version — subsumes cargo-audit)

## Command runner

justfile

## Targets

| Target | Runs |
|--------|------|
| `lint` | `cargo clippy -- -D warnings && cargo fmt --check` |
| `fmt` | `cargo fmt` |
| `fix` | `cargo clippy --fix --allow-dirty && cargo fmt` |
| `check` | `cargo check --workspace` |
| `test` | `cargo nextest run` |
| `test-all` | `cargo nextest run --all-targets` |
| `audit` | `cargo deny check` |
| `build` | `cargo build --release` |
| `clean` | `cargo clean` |
| `help` | Self-documenting — list targets with descriptions |

## Layout

```
.
├── Cargo.toml / Cargo.lock
├── src/
├── tests/
├── benches/
├── examples/
├── .config/nextest.toml
├── deny.toml
└── justfile
```

## Workspace

Members inherit shared config via `workspace = true`:

- `[workspace.package]` — version, edition, license
- `[workspace.dependencies]` — shared dependency versions
- `[workspace.lints]` — shared rustc and clippy lint config

## CI

Generate a GitHub Actions pipeline that runs `just test-all audit`. Resolve `actions-rust-lang/setup-rust-toolchain` version at generation time.

## Pre-commit hook

`just check`
