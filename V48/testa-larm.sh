#!/bin/bash
# testa-larm.sh - Testar hela larmkedjan: larm -> SNS -> e-post, utan att rora servrarna.
# Kor i Git Bash pa din dator:
#   bash V48/testa-larm.sh              (testar novatrix-cpu-hog)
#   bash V48/testa-larm.sh unhealthy    (testar novatrix-unhealthy)
# Larmet tvingas till ALARM och gar tillbaka till OK vid nasta utvardering.
# Da kommer tva mail: ett ALARM och ett OK.

REGION="eu-north-1"
LARM="novatrix-${1:-cpu-hog}"

aws cloudwatch set-alarm-state --alarm-name "$LARM" --state-value ALARM \
  --state-reason "Test av larmkedjan, inget fel i miljon" --region "$REGION" || exit 1
echo "$LARM ar satt till ALARM. Ett mail fran AWS Notifications kommer inom nagon minut."
echo "Vid nasta utvardering gar larmet tillbaka till OK och ett mail till kommer."
sleep 5
aws cloudwatch describe-alarm-history --alarm-name "$LARM" --region "$REGION" --max-items 3 \
  --query "AlarmHistoryItems[].[Timestamp,HistorySummary]" --output table
