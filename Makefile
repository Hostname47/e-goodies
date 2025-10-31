.PHONY: help setup dev-frontend dev-backend prod stop clean logs

.DEFAULT_GOAL := help

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

enter: ## Enter a running service container (e.g., make enter service=php)
	@if [ -n "$(service)" ]; then \
		docker compose exec $(service) bash; \
	fi