#!/bin/bash
# bygg-allt.sh - Bygger hela Novatrix-miljön från repot (v42-v44)
# Ligger i V44/. Kör i Git Bash med din publika IP som argument:
#   bash V44/bygg-allt.sh $(curl -s https://checkip.amazonaws.com)
# eller skriv in IP:n själv:  bash V44/bygg-allt.sh 1.2.3.4
# IP:n skickas med vid körning, så den hamnar aldrig i det publika repot.
#   1. IAM från v43 (grupper, policyer, roller)
#   2. Nätverk, bastion och webbserver från v44 (CloudFormation, inkl. webbservern från v42)

MYIP="$(echo "$1" | tr -d '[:space:]')"   # Första argumentet: din publika IP
REGION="eu-north-1"
STACK="novatrix-miljo"

# Hitta mapparna utifrån skriptets egen plats, så att det går att köra från vilken mapp som helst
V44_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$V44_DIR")"

if [ -z "$MYIP" ]; then
  echo "FEL: ange din publika IP, t.ex.:  bash V44/bygg-allt.sh \$(curl -s https://checkip.amazonaws.com)"
  exit 1
fi
echo "Admin-IP: $MYIP"

echo "=== 1/2 IAM (v43) ==="
(cd "$REPO_DIR/V43" && bash iam-setup.sh) || { echo "FEL: iam-setup.sh misslyckades"; exit 1; }

echo ""
echo "=== 2/2 Nätverk och servrar (v44) ==="
aws cloudformation deploy \
  --template-file "$V44_DIR/novatrix-miljo.yaml" \
  --stack-name "$STACK" \
  --region "$REGION" \
  --parameter-overrides MyIp="$MYIP/32" KeyName=aws_webserver \
  || { echo "FEL: CloudFormation misslyckades. Se Events på stacken i konsolen."; exit 1; }

echo ""
echo "=== Klar ==="
aws cloudformation describe-stacks --stack-name "$STACK" --region "$REGION" \
  --query "Stacks[0].Outputs[].[OutputKey,OutputValue]" --output table
echo "Vänta 1-2 minuter så att user data hinner installera Apache innan du öppnar webbsidan."
