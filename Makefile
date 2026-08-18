.PHONY: check test contracts gitleaks links taxonomy help

check: gitleaks links taxonomy contracts
	@echo "check: ok"

test:
	@if [ -x scripts/test.sh ]; then \
		./scripts/test.sh; \
	else \
		printf 'test: no executable test suite found at scripts/test.sh\n' >&2; \
		exit 1; \
	fi

contracts:
	bash scripts/validate-pr-contracts.sh

gitleaks:
	gitleaks detect --no-git

links:
	lychee --offline --no-progress --exclude-path 'skills/generated/' skills

taxonomy:
	@valid=$$(awk -F'|' '/^\| `[a-z]+` \| `[a-z-]+` \|/ {gsub(/[ `]/, "", $$2); gsub(/[ `]/, "", $$3); print $$2 ":" $$3}' skills/shared/label-taxonomy.md); \
	errors=0; \
	while IFS= read -r file; do \
		while IFS=: read -r lineno label; do \
			[ -z "$$label" ] && continue; \
			echo "$$valid" | grep -qxF "$$label" || { echo "taxonomy: $$file:$$lineno: unknown label $$label"; errors=1; }; \
		done < <(grep -noP '\b(triage|type|kind|wayfinder|impact):[a-z-]+' "$$file" 2>/dev/null || true); \
	done < <(find skills -name '*.md' -not -path 'skills/generated/*' -not -path 'skills/shared/label-taxonomy.md'); \
	[ "$$errors" -eq 0 ] || exit 1

help:
	@echo "check      Run gitleaks secrets scan, lychee link check, taxonomy, and contract validation"
	@echo "test       Run the executable repository test suite"
	@echo "contracts  Validate shared PR delivery contracts"
	@echo "gitleaks   Run gitleaks secrets scan"
	@echo "links      Run lychee link check (local-only, offline)"
	@echo "taxonomy   Check scope:value labels against shared/label-taxonomy.md"
