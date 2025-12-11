#!/usr/bin/env bash
#
# asm_diskgroup_usage.sh
#
# Generates an Oracle ASM diskgroup usage report (total, used, free, pct used).
# Focused on V$ASM_DISKGROUP and suitable for monitoring FRA/RECO capacity.
#
# Usage:
#   ./asm_diskgroup_usage.sh
#     -> uses "/ as sysasm" (requires ORACLE_SID of ASM instance set)
#
#   ./asm_diskgroup_usage.sh "+asm_user/password@+ASM as sysasm"
#     -> uses explicit connect string
#
#   ./asm_diskgroup_usage.sh "" "+RECO%"
#     -> OS auth, only diskgroups matching '+RECO%' (e.g. FRA/RECO)
#
#   ./asm_diskgroup_usage.sh "+asm_user/password@+ASM as sysasm" "+RECO%"
#     -> explicit connect string + FRA filter
#
# Created by: Gustavo Borges Evangelista
############################################################
# Configuration
############################################################

CONNECT_STRING="$1"     # optional: e.g. "+asm_user/password@+ASM as sysasm"
FRA_PATTERN="$2"        # optional: e.g. "+RECO%" to filter FRA/RECO diskgroups

############################################################
# Helper functions
############################################################

error_exit() {
  echo "ERROR: $1"
  exit 1
}

check_env() {
  if ! command -v sqlplus >/dev/null 2>&1; then
    error_exit "sqlplus not found in PATH. Configure ORACLE_HOME and PATH for ASM."
  fi

  if [ -z "$CONNECT_STRING" ] && [ -z "$ORACLE_SID" ]; then
    error_exit "ORACLE_SID not set and no connect string provided (ASM instance is required)."
  fi
}

run_sql() {
  if [ -n "$CONNECT_STRING" ]; then
    sqlplus -s "$CONNECT_STRING" <<EOF
SET PAGES 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF LINES 300 COLSEP '|' TRIMSPOOL ON
SELECT name,
       ROUND(total_mb/1024, 2) AS total_gb,
       ROUND((total_mb - free_mb)/1024, 2) AS used_gb,
       ROUND(free_mb/1024, 2) AS free_gb,
       ROUND((total_mb - free_mb) / total_mb * 100, 2) AS pct_used
  FROM v\$asm_diskgroup
 WHERE ( '$FRA_PATTERN' IS NULL OR name LIKE '$FRA_PATTERN' )
 ORDER BY name;
EXIT
EOF
  else
    sqlplus -s "/ as sysasm" <<EOF
SET PAGES 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF LINES 300 COLSEP '|' TRIMSPOOL ON
SELECT name,
       ROUND(total_mb/1024, 2) AS total_gb,
       ROUND((total_mb - free_mb)/1024, 2) AS used_gb,
       ROUND(free_mb/1024, 2) AS free_gb,
       ROUND((total_mb - free_mb) / total_mb * 100, 2) AS pct_used
  FROM v\$asm_diskgroup
 WHERE ( '$FRA_PATTERN' IS NULL OR name LIKE '$FRA_PATTERN' )
 ORDER BY name;
EXIT
EOF
  fi
}

############################################################
# Main
############################################################

check_env

RESULT="$(run_sql)"

# Remove empty lines
RESULT="$(echo "$RESULT" | sed '/^$/d')"

# If ORA- error, show and exit
if echo "$RESULT" | grep -q "ORA-"; then
  echo "$RESULT"
  error_exit "Oracle error while querying v\$asm_diskgroup."
fi

if [ -z "$RESULT" ]; then
  error_exit "No diskgroups found (check ASM instance and permissions)."
fi

echo "DISKGROUP|TOTAL_GB|USED_GB|FREE_GB|PCT_USED"
echo "$RESULT"
