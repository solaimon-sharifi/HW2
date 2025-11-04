SHELL := /bin/bash

.PHONY: up down build ps logs sql-run clean restart

up:
	@echo "Starting services..."
	docker compose up --build -d

down:
	@echo "Stopping services..."
	docker compose down

build:
	@echo "Building images..."
	docker compose build --pull --no-cache

ps:
	@docker compose ps

logs:
	@docker compose logs -f --tail=200

sql-run:
	@chmod +x ./scripts/run_sql_steps.sh
	@./scripts/run_sql_steps.sh

api-run:
	@chmod +x ./scripts/run_api_examples.sh
	@./scripts/run_api_examples.sh

restart: down up

clean:
	@echo "Removing docker volumes (will delete DB data)."
	docker compose down -v
