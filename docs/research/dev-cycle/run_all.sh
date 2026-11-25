#!/usr/bin/env bash
# Rebuild every table of docs/research/dev-cycle-time.md from the transcripts (about 10 s).
set -e
cd "$(dirname "$0")"
REPO=/c/Users/Gripe/personal/repositories/it-socks-to-be-a-washing-machine
git -C "$REPO" log --first-parent --merges --format='%H|%cI|%aI|%s' refs/heads/main -- > merges.txt
git -C "$REPO" log --diff-filter=A --format='C|%cI' --name-only refs/heads/main -- 'docs/llm/' > ticket_adds.txt
python3 -W ignore parse_agents.py
python3 -W ignore parse_lead.py
for a in a1_activity a1b_latency a2_tests a3_flow a4_suite_trend a5_misc a6_recent a7_hourly a8_contention; do python3 -W ignore $a.py > $a.out; done
echo "tables: a1.md a1b.txt a2.md a3.md a4.md a5.md a6.md a7.md a8.md"
