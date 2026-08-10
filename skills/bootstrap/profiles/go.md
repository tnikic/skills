# Go Language Profile

Minimum `go 1.24`.

## Tools

All managed via `go tool` directive. Research latest stable version for each at generation time.

- golangci-lint
- gofumpt
- govulncheck
- go vet

## Command runner

Makefile

## Targets

| Target | Runs |
|--------|------|
| `lint` | `go tool golangci-lint run ./...` |
| `fmt` | `gofumpt -w .` |
| `vet` | `go vet ./...` |
| `vulncheck` | `go tool govulncheck ./...` |
| `tidy` | `go mod tidy -diff` |
| `gitleaks` | `gitleaks detect --no-git` |
| `check` | `fmt` → `vet` → `lint` → `gitleaks` |
| `test` | `go test -race -cover ./...` → `vulncheck` |
| `build` | `go build -trimpath -o bin/ ./...` |
| `clean` | `rm -rf bin/` |
| `help` | Self-documenting — list targets with descriptions |

## Layout

- `cmd/` — one subdirectory per binary
- `internal/` — private packages
- No `pkg/`

## CI

Generate a GitHub Actions pipeline that runs `make test`. Resolve `actions/setup-go` version at generation time.

## Pre-commit hook

`make check`
