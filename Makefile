.PHONY: help setup dev-frontend dev-backend prod stop clean logs

.DEFAULT_GOAL := help

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

help: ## Show available commands
	@echo "$(BLUE)Available commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

setup: ## Run initial setup script (installs everything)
	@echo "$(BLUE)🚀 Running setup script...$(NC)"
	@chmod +x setup.sh
	@./setup.sh
	@echo "$(GREEN)✅ Setup complete!$(NC)"

dev-frontend: ## Start React development server
	@echo "$(BLUE)🚀 Starting React dev server...$(NC)"
	cd software/frontend && npm run dev

dev-backend: ## Show backend logs
	@echo "$(BLUE)📋 Backend logs:$(NC)"
	cd software/backend/symfony-api && docker compose -p e-goodies-api logs -f

stop: ## Stop all Docker containers
	@echo "$(YELLOW)⏹️  Stopping containers...$(NC)"
	cd software/backend/symfony-api && docker compose -p e-goodies-api down
	@echo "$(GREEN)✓ Containers stopped$(NC)"

restart: ## Restart backend containers
	@echo "$(BLUE)🔄 Restarting backend...$(NC)"
	cd software/backend/symfony-api && docker compose -p e-goodies-api restart
	@echo "$(GREEN)✓ Backend restarted$(NC)"

logs: ## Show all backend logs
	cd software/backend/symfony-api && docker compose -p e-goodies-api logs -f

logs-php: ## Show PHP container logs
	cd software/backend/symfony-api && docker compose -p e-goodies-api logs -f php

logs-api: ## Show API/Nginx logs
	cd software/backend/symfony-api && docker compose -p e-goodies-api logs -f api

ps: ## Show running containers
	cd software/backend/symfony-api && docker compose -p e-goodies-api ps

clean: ## Stop containers and remove volumes
	@echo "$(YELLOW)🧹 Cleaning up...$(NC)"
	cd software/backend/symfony-api && docker compose -p e-goodies-api down -v
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

db-migrate: ## Run Symfony database migrations
	cd software/backend/symfony-api && docker compose exec php php bin/console doctrine:migrations:migrate --no-interaction

db-reset: ## Reset database (DROP + CREATE + MIGRATE)
	@echo "$(YELLOW)⚠️  Resetting database...$(NC)"
	cd software/backend/symfony-api && \
		docker compose exec php php bin/console doctrine:database:drop --force --if-exists && \
		docker compose exec php php bin/console doctrine:database:create && \
		docker compose exec php php bin/console doctrine:migrations:migrate --no-interaction
	@echo "$(GREEN)✓ Database reset complete$(NC)"

shell-php: ## Open PHP container shell
	cd software/backend/symfony-api && docker compose exec php sh

shell-db: ## Open MySQL shell
	cd software/backend/symfony-api && docker compose exec database mysql -u root -p

composer-install: ## Install Composer dependencies
	cd software/backend/symfony-api && docker compose exec php composer install

composer-update: ## Update Composer dependencies
	cd software/backend/symfony-api && docker compose exec php composer update

npm-install: ## Install npm dependencies (frontend)
	cd software/frontend && npm install

npm-build: ## Build React app for production
	@echo "$(BLUE)🔨 Building React app...$(NC)"
	cd software/frontend && npm run build
	@echo "$(GREEN)✓ Build complete$(NC)"

status: ## Show project status
	@echo "$(BLUE)📊 Project Status:$(NC)"
	@echo ""
	@echo "$(GREEN)Git:$(NC)"
	@git --version 2>/dev/null || echo "Not installed"
	@echo ""
	@echo "$(GREEN)Node.js:$(NC)"
	@node --version 2>/dev/null || echo "Not installed"
	@echo ""
	@echo "$(GREEN)npm:$(NC)"
	@npm --version 2>/dev/null || echo "Not installed"
	@echo ""
	@echo "$(GREEN)Docker:$(NC)"
	@docker --version 2>/dev/null || echo "Not installed"
	@echo ""
	@echo "$(GREEN)Backend Containers:$(NC)"
	@cd software/backend/symfony-api && docker compose -p e-goodies-api ps 2>/dev/null || echo "Not running"