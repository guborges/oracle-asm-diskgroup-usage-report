# Oracle ASM Diskgroup Usage Report

## Overview
This repository contains a shell script that generates a usage report for Oracle ASM diskgroups, with a special focus on FRA / recovery diskgroups (for example `+RECO`, `+FRA`). The report shows total space, used space, free space and usage percentage, helping DBAs monitor capacity and plan growth in Exadata, ExaCC and on-prem environments.

The script is designed to be simple, portable and easy to integrate with cron, monitoring tools or email notifications.

## Features
- Collects ASM diskgroup usage information from `V$ASM_DISKGROUP`
- Shows, for each diskgroup:
  - Name
  - Total size (GB)
  - Used size (GB)
  - Free size (GB)
  - Usage percentage
- Can optionally filter only FRA / recovery diskgroups (by name pattern)
- Output is plain text / pipe-separated, easy to parse with other tools
- Suitable for scheduled execution via cron
- Safe to run in production environments (read-only views)

## Example query used
The core logic of the script is based on a query similar to:

    SELECT name,
           total_mb,
           free_mb,
           (total_mb - free_mb) AS used_mb,
           ROUND( (total_mb - free_mb) / total_mb * 100, 2 ) AS pct_used
      FROM v$asm_diskgroup
     ORDER BY name;

## Requirements
- Linux environment
- Bash
- SQL*Plus client installed
- Oracle Grid / ASM environment configured (ORACLE_HOME for Grid, ORACLE_SID for ASM instance)
- User with access to `V$ASM_DISKGROUP` (typically `sysasm` or OS authentication as grid/asm owner)

## Usage

1. Clone the repository:

       git clone https://github.com/guborges/oracle-asm-diskgroup-usage-report.git
       cd oracle-asm-diskgroup-usage-report

2. Edit the script configuration:
   - Set how you connect to ASM:
     - OS authentication (for example, running as grid user with `sqlplus / as sysasm`)
     - Or a connect string if you prefer
   - Optionally set a name pattern to focus on FRA / recovery diskgroups (for example `+RECO%`)

3. Make the script executable:

       chmod +x asm_diskgroup_usage.sh

4. Run the script:

       ./asm_diskgroup_usage.sh
       # or, with an explicit connect string:
       ./asm_diskgroup_usage.sh "+asm_user/password@+ASM as sysasm"

5. Example output:

       DISKGROUP|TOTAL_GB|USED_GB|FREE_GB|PCT_USED
       DATAC1   | 914.00 | 580.15| 333.85| 63.49
       RECOC1   | 228.00 |  25.88| 202.12| 11.35

This output can be sent by email, ingested by monitoring tools or stored for capacity trending.

## File structure

    oracle-asm-diskgroup-usage-report/
    ├── asm_diskgroup_usage.sh
    └── README.md

## Notes
- The script is intentionally minimal to keep it easy to read and adapt.
- You can extend it to:
  - Highlight diskgroups above a certain usage threshold (for example 80% or 90%)
  - Generate HTML or CSV reports
  - Send alerts by email or webhook when usage exceeds a limit
  - Store historical data in a table or file for trending

The approach works well in Exadata / ExaCC environments where FRA growth in ASM diskgroups must be monitored closely to avoid backup and archive log issues.

## License
MIT License
