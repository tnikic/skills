.PHONY: check gitleaks help

check: gitleaks
	@echo "check: ok"

gitleaks:
	gitleaks detect --no-git

help:
	@echo "check      Run gitleaks secrets scan"
