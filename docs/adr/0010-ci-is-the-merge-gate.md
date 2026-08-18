# CI Is the Merge Gate

CI runs the project's `check` and `test` targets on every PR head and is the authoritative merge gate; local pre-commit checks remain fast feedback. This prevents a green local commit from being treated as sufficient when the forge must validate the exact code that will merge.
