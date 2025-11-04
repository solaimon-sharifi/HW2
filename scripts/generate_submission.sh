#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORTS_DIR="$ROOT_DIR/reports"
SUB_DIR="$ROOT_DIR/submission"
TEMPLATE="$SUB_DIR/template.md"
OUT_MD="$SUB_DIR/submission.md"
OUT_PDF="$SUB_DIR/submission.pdf"

mkdir -p "$SUB_DIR"

if [ ! -f "$TEMPLATE" ]; then
  echo "Template missing: $TEMPLATE"
  exit 1
fi

echo "Generating submission markdown at $OUT_MD"

cp "$TEMPLATE" "$OUT_MD"

replace_or_insert(){
  local placeholder="$1"
  local file="$2"
  local tmpfile="$OUT_MD.tmp"

  if [ -f "$file" ]; then
    content="$(sed 's/\/\//\\/g' "$file" | sed 's/$/\n/g')"
  else
    content="(file not found: $file)"
  fi

  # Use awk to replace placeholder token with fenced code block containing content
  awk -v ph="$placeholder" -v cont="$content" 'BEGIN{RS=""; ORS="\n\n"} {gsub(ph, "\n\n```"); gsub(ph, cont); gsub(ph, "``\n\n"); print}' "$OUT_MD" > "$tmpfile" || true
  mv "$tmpfile" "$OUT_MD"
}

# Simpler approach: append report contents by replacing tokens using perl
perl -0777 -pe "s/\{\{STEP_A_CREATE_USERS\}\}/`(cat $REPORTS_DIR/step_A_create_users.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{STEP_A_CREATE_CALCULATIONS\}\}/`(cat $REPORTS_DIR/step_A_create_calculations.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true

perl -0777 -pe "s/\{\{STEP_B_INSERT_USERS\}\}/`(cat $REPORTS_DIR/step_B_insert_users.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{STEP_B_INSERT_CALCULATIONS\}\}/`(cat $REPORTS_DIR/step_B_insert_calculations.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true

perl -0777 -pe "s/\{\{STEP_C_SELECT_USERS\}\}/`(cat $REPORTS_DIR/step_C_select_users.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{STEP_C_SELECT_CALCULATIONS\}\}/`(cat $REPORTS_DIR/step_C_select_calculations.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{STEP_C_JOIN\}\}/`(cat $REPORTS_DIR/step_C_join.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true

perl -0777 -pe "s/\{\{STEP_D_UPDATE\}\}/`(cat $REPORTS_DIR/step_D_update.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{STEP_D_SELECT_UPDATED\}\}/`(cat $REPORTS_DIR/step_D_select_updated.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true

perl -0777 -pe "s/\{\{STEP_E_DELETE\}\}/`(cat $REPORTS_DIR/step_E_delete.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{STEP_E_SELECT_AFTER_DELETE\}\}/`(cat $REPORTS_DIR/step_E_select_after_delete.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true

# API reports
perl -0777 -pe "s/\{\{API_1_HEALTH\}\}/`(cat $REPORTS_DIR/api_1_health.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{API_2_LIST_USERS_BEFORE\}\}/`(cat $REPORTS_DIR/api_2_list_users_before.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{API_3_CREATE_USER_CAROL\}\}/`(cat $REPORTS_DIR/api_3_create_user_carol.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{API_4_LIST_USERS_AFTER\}\}/`(cat $REPORTS_DIR/api_4_list_users_after.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{API_5_LIST_CALCULATIONS_BEFORE\}\}/`(cat $REPORTS_DIR/api_5_list_calculations_before.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{API_6_CREATE_CALCULATION\}\}/`(cat $REPORTS_DIR/api_6_create_calculation.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{API_7_LIST_CALCULATIONS_AFTER\}\}/`(cat $REPORTS_DIR/api_7_list_calculations_after.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{API_8_CALCULATIONS_JOIN\}\}/`(cat $REPORTS_DIR/api_8_calculations_join.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{API_9_UPDATE_CALC_1\}\}/`(cat $REPORTS_DIR/api_9_update_calc_1.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{API_9_SELECT_CALC_1\}\}/`(cat $REPORTS_DIR/api_9_select_calc_1.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{API_10_DELETE_CALC_2\}\}/`(cat $REPORTS_DIR/api_10_delete_calc_2.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{API_10_SELECT_AFTER_DELETE\}\}/`(cat $REPORTS_DIR/api_10_select_after_delete.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{API_11_UPDATE_USER_3\}\}/`(cat $REPORTS_DIR/api_11_update_user_3.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{API_11_SELECT_USER_LIST\}\}/`(cat $REPORTS_DIR/api_11_select_user_list.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{API_12_DELETE_USER_3\}\}/`(cat $REPORTS_DIR/api_12_delete_user_3.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true
perl -0777 -pe "s/\{\{API_12_SELECT_USER_LIST_AFTER_DELETE\}\}/`(cat $REPORTS_DIR/api_12_select_user_list_after_delete.txt 2>/dev/null || echo '(missing)')`/egs" -i "$OUT_MD" || true

echo "Generated: $OUT_MD"

if command -v pandoc >/dev/null 2>&1; then
  echo "Pandoc found — generating PDF at $OUT_PDF"
  pandoc "$OUT_MD" -o "$OUT_PDF" || echo "pandoc failed to generate PDF"
else
  echo "Pandoc not found. To generate PDF run: pandoc $OUT_MD -o $OUT_PDF"
fi

echo "Submission generation complete. Check $SUB_DIR"
