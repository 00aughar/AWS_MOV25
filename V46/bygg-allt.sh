#!/bin/bash
# bygg-allt.sh - Bygger hela WordPress-stacken från repot (v42-v45)
# Kör i Git Bash med din publika IP som argument:
#   bash V45/bygg-allt.sh $(curl -s https://checkip.amazonaws.com)
# Databaslösenordet frågas efter vid körning och sparas aldrig i repot.
#   1. IAM från v43 (grupper, policyer, roller)
#   2. Nätverk, bastion, RDS, EFS, S3 och webbserver med WordPress (CloudFormation)

MYIP="$(echo "$1" | tr -d '[:space:]')"
REGION="eu-north-1"
STACK="novatrix-wordpress"

V45_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$V45_DIR")"

if [ -z "$MYIP" ]; then
  echo "FEL: ange din publika IP, t.ex.:  bash V45/bygg-allt.sh \$(curl -s https://checkip.amazonaws.com)"
  exit 1
fi
echo "Admin-IP: $MYIP"

read -s -p "Välj databaslösenord (8-41 tecken, bara bokstäver och siffror): " DBPASS
echo ""
if ! [[ "$DBPASS" =~ ^[A-Za-z0-9]{8,41}$ ]]; then
  echo "FEL: lösenordet måste vara 8-41 tecken och bara innehålla bokstäver och siffror."
  exit 1
fi

echo "=== 1/2 IAM (v43) ==="
(cd "$REPO_DIR/V43" && bash iam-setup.sh) || { echo "FEL: iam-setup.sh misslyckades"; exit 1; }

echo ""
echo "=== 2/2 WordPress-stacken (v44-v45) - tar ca 15 minuter, RDS är långsammast ==="
aws cloudformation deploy \
  --template-file "$V45_DIR/novatrix-wordpress.yaml" \
  --stack-name "$STACK" \
  --region "$REGION" \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides MyIp="$MYIP/32" KeyName=aws_webserver DbPassword="$DBPASS" \
  || { echo "FEL: CloudFormation misslyckades. Se Events på stacken i konsolen."; exit 1; }

echo ""
echo "=== Klar ==="
aws cloudformation describe-stacks --stack-name "$STACK" --region "$REGION" \
  --query "Stacks[0].Outputs[].[OutputKey,OutputValue]" --output table
echo "Vänta 2-3 minuter så att user data hinner installera WordPress innan du öppnar webbsidan."
