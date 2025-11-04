#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REPORTS_DIR="$ROOT_DIR/reports"
mkdir -p "$REPORTS_DIR"

API_URL="http://localhost:8000"

echo "Waiting for API to be ready at $API_URL/health..."
for i in {1..60}; do
  if curl -sSf "$API_URL/health" >/dev/null 2>&1; then
    echo "API is ready"
    break
  fi
  printf '.'
  sleep 1
done

echo "Running API examples and saving outputs to $REPORTS_DIR"

run_cmd() {
  local name="$1"
  local method="$2"
  local url="$3"
  local data="$4"
  local outfile="$REPORTS_DIR/$name.txt"

  echo "---- $method $url ----" > "$outfile"
  if [ -z "$data" ]; then
    curl -sS -D - -X "$method" "$url" >> "$outfile" 2>&1 || true
  else
    curl -sS -D - -X "$method" -H "Content-Type: application/json" -d "$data" "$url" >> "$outfile" 2>&1 || true
  fi
  echo "" >> "$outfile"
  echo "Saved: $outfile"
}

# 1. Health
run_cmd "api_1_health" "GET" "$API_URL/health" ""

# 2. List users (initial)
run_cmd "api_2_list_users_before" "GET" "$API_URL/users/" ""

# 3. Create a user (carol)
run_cmd "api_3_create_user_carol" "POST" "$API_URL/users/" '{"username":"carol","email":"carol@example.com"}'

# 4. List users (after)
run_cmd "api_4_list_users_after" "GET" "$API_URL/users/" ""

# 5. List calculations (initial)
run_cmd "api_5_list_calculations_before" "GET" "$API_URL/calculations/" ""

# 6. Create a calculation (create a calc for carol; user_id=3 assumed)
run_cmd "api_6_create_calculation" "POST" "$API_URL/calculations/" '{"operation":"add","operand_a":7,"operand_b":8,"result":15,"user_id":3}'

# 7. List calculations (after)
run_cmd "api_7_list_calculations_after" "GET" "$API_URL/calculations/" ""

# 8. Join endpoint
run_cmd "api_8_calculations_join" "GET" "$API_URL/calculations/join" ""

# 9. Update calculation id=1 via API (set result=6)
run_cmd "api_9_update_calc_1" "PATCH" "$API_URL/calculations/1" '{"result":6}'
run_cmd "api_9_select_calc_1" "GET" "$API_URL/calculations/" ""

# 10. Delete calculation id=2 via API
run_cmd "api_10_delete_calc_2" "DELETE" "$API_URL/calculations/2" ""
run_cmd "api_10_select_after_delete" "GET" "$API_URL/calculations/" ""

# 11. Update user id=3 (carol) via API
run_cmd "api_11_update_user_3" "PATCH" "$API_URL/users/3" '{"email":"carol@newdomain.com"}'
run_cmd "api_11_select_user_list" "GET" "$API_URL/users/" ""

# 12. Delete user id=3 via API
run_cmd "api_12_delete_user_3" "DELETE" "$API_URL/users/3" ""
run_cmd "api_12_select_user_list_after_delete" "GET" "$API_URL/users/" ""

echo "API example run complete. Files saved in: $REPORTS_DIR"

exit 0
