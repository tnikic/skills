# Standardized Makefile/justfile targets over docs/TESTING.md

This decision governs repositories aligned by `bootstrap`, including the
standard command-runner interface consumed by `implement`, `code-review`, and
`tdd`. The exact target set comes from the selected language profile. This
skills repository is a documentation repository and intentionally exposes the
targets its own checks need rather than inventing `lint` and `fmt` targets.

`docs/TESTING.md` was our own convention — a single file listing tool commands.
We dropped it in favor of standardized ecosystem-native targets such as
`make check`, `make test`, `make lint`, and `make fmt` (Go: Makefile; Rust:
justfile).

The Makefile/justfile is the single source of truth. It is executable — a
broken command fails immediately — whereas `docs/TESTING.md` could silently
drift. Standardized target names make parsing unnecessary: skills run targets
by convention, not by reading a file. Ecosystem research confirmed neither Go
nor Rust uses anything like `docs/TESTING.md`; self-documenting Makefiles
(`make help`) and justfiles (`just --list`) serve the same role natively.
