#!/bin/bash
# testa-alb.sh - Visar vilken server och zon som svarar via lastbalanseraren.
# Kor i Git Bash pa din dator:
#   bash V47/testa-alb.sh            (10 anrop)
#   bash V47/testa-alb.sh 60 2       (60 anrop, 2 sekunder mellan, bra under failover)

ANTAL="${1:-10}"
PAUS="${2:-1}"
REGION="eu-north-1"
URL=$(aws cloudformation describe-stacks --stack-name novatrix-skala --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='SiteUrl'].OutputValue" --output text | tr -d '\r')
echo "Lastbalanserare: $URL"
for i in $(seq 1 "$ANTAL"); do
  SVAR=$(curl -s -m 5 "$URL/version.html" || echo "INGET SVAR")
  KOD=$(curl -s -m 5 -o /dev/null -w '%{http_code}' "$URL/wp-login.php")
  echo "$(date +%H:%M:%S)  wp-login: $KOD  |  ${SVAR:-INGET SVAR}"
  sleep "$PAUS"
done
