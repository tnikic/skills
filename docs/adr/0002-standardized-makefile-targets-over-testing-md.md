# Standardized Makefile/justfile targets over docs/TESTING.md

`docs/TESTING.md` was our own convention — a single file listing tool commands, consumed by `implement`, `code-review`, and `tdd`. We dropped it in favor of standardized ecosystem-native targets: `make check`, `make test`, `make lint`, `make fmt` (Go: Makefile; Rust: justfile).

The Makefile/justfile is the single source of truth. It is executable — a broken command fails immediately — whereas `docs/TESTING.md` could silently drift. Standardized target names make parsing unnecessary: skills run targets by convention, not by reading a file. Ecosystem research confirmed neither Go nor Rust uses anything like `docs/TESTING.md`; self-documenting Makefiles (`make help`) and justfiles (`just --list`) serve the same role natively.
