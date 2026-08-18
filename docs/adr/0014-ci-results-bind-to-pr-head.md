# CI Results Bind to the PR Head

Readiness requires every forge-required check to pass for the exact current PR head SHA, with bounded automatic repair only for clear, in-scope branch failures. Older results, missing required protection, infrastructure failures, and ambiguous failures cannot silently authorize review or merge.
