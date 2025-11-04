#!/usr/bin/env bash
# Run the assignment SQL steps (A-E) inside the postgres container and save outputs

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Load env
if [ -f .env ]; then
  # export variables from .env (simple parser)
  export $(grep -v '^#' .env | xargs)
fi

REPORTS_DIR="$ROOT_DIR/reports"
mkdir -p "$REPORTS_DIR"

echo "Waiting for Postgres to be ready..."
until docker compose exec -T db pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" >/dev/null 2>&1; do
  printf '.'
  sleep 1
done
echo "\nPostgres is ready. Running SQL steps..."

run_sql() {
  local sql="$1"
  local outfile="$2"
  echo "Running: $sql"
  docker compose exec -T db psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "$sql" > "$outfile" 2>&1 || true
}

# A) CREATE TABLES (will be no-op if already created)
run_sql "CREATE TABLE users (id SERIAL PRIMARY KEY, username VARCHAR(50) NOT NULL UNIQUE, email VARCHAR(100) NOT NULL UNIQUE, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);" "$REPORTS_DIR/step_A_create_users.txt"
run_sql "CREATE TABLE calculations (id SERIAL PRIMARY KEY, operation VARCHAR(20) NOT NULL, operand_a FLOAT NOT NULL, operand_b FLOAT NOT NULL, result FLOAT NOT NULL, timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP, user_id INTEGER NOT NULL, FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE);" "$REPORTS_DIR/step_A_create_calculations.txt"

# B) INSERT RECORDS
run_sql "INSERT INTO users (username, email) VALUES ('alice', 'alice@example.com'), ('bob', 'bob@example.com') ON CONFLICT DO NOTHING;" "$REPORTS_DIR/step_B_insert_users.txt"
run_sql "INSERT INTO calculations (operation, operand_a, operand_b, result, user_id) VALUES ('add', 2, 3, 5, 1), ('divide', 10, 2, 5, 1), ('multiply', 4, 5, 20, 2) ON CONFLICT DO NOTHING;" "$REPORTS_DIR/step_B_insert_calculations.txt"

# C) QUERY DATA
run_sql "SELECT * FROM users;" "$REPORTS_DIR/step_C_select_users.txt"
run_sql "SELECT * FROM calculations;" "$REPORTS_DIR/step_C_select_calculations.txt"
run_sql "SELECT u.username, c.operation, c.operand_a, c.operand_b, c.result FROM calculations c JOIN users u ON c.user_id = u.id;" "$REPORTS_DIR/step_C_join.txt"

# D) UPDATE A RECORD
run_sql "UPDATE calculations SET result = 6 WHERE id = 1;" "$REPORTS_DIR/step_D_update.txt"
run_sql "SELECT * FROM calculations WHERE id = 1;" "$REPORTS_DIR/step_D_select_updated.txt"

# E) DELETE A RECORD
run_sql "DELETE FROM calculations WHERE id = 2;" "$REPORTS_DIR/step_E_delete.txt"
run_sql "SELECT * FROM calculations;" "$REPORTS_DIR/step_E_select_after_delete.txt"

echo "SQL steps complete. Reports saved in: $REPORTS_DIR"

echo "Example: cat $REPORTS_DIR/step_C_select_users.txt"

exit 0
