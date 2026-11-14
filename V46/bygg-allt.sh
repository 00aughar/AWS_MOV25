#!/bin/bash
# bygg-allt.sh - Bygger Novatrix WordPress-stack: backup -> nat -> data -> webb
# Backupstacken skapas bara forsta gangen, darefter finns den kvar mellan rivningarna.
# Kor i Git Bash med din publika IP som argument:
#   bash V46/bygg-allt.sh $(curl -s https://checkip.amazonaws.com)
# Valfritt andra argument: miljo (test eller prod), standard test.

MYIP="$(echo "$1" | tr -d '[:space:]')"
ENV="${2:-test}"
REGION="eu-north-1"
PREFIX="novatrix"

V46_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$V46_DIR" || exit 1

if [ -z "$MYIP" ]; then
  echo "FEL: ange din publika IP, t.ex.:  bash V46/bygg-allt.sh \$(curl -s https://checkip.amazonaws.com)"
  exit 1
fi
echo "Admin-IP: $MYIP   Miljo: $ENV"

# Validera alla mallar innan nagot byggs
echo "=== Validerar mallarna ==="
for t in novatrix-backup.yaml novatrix-nat.yaml novatrix-data.yaml novatrix-webb.yaml; do
  aws cloudformation validate-template --template-body "file://$t" --region "$REGION" >/dev/null \
    && echo "OK  $t" || { echo "FEL i $t"; exit 1; }
done

deploy () {
  echo ""
  echo "=== $1 ==="
  aws cloudformation deploy --region "$REGION" --stack-name "$PREFIX-$1" --template-file "$2" --no-fail-on-empty-changeset "${@:3}" \
    || { echo "FEL: stacken $PREFIX-$1 misslyckades. Se Events i CloudFormation-konsolen."; exit 1; }
}

deploy backup novatrix-backup.yaml --parameter-overrides Prefix="$PREFIX"
deploy nat  novatrix-nat.yaml  --parameter-overrides Prefix="$PREFIX" MyIp="$MYIP/32"
deploy data novatrix-data.yaml --parameter-overrides Prefix="$PREFIX" Environment="$ENV"
deploy webb novatrix-webb.yaml --parameter-overrides Prefix="$PREFIX" --capabilities CAPABILITY_NAMED_IAM

echo ""
echo "=== Klar ==="
aws cloudformation describe-stacks --stack-name "$PREFIX-webb" --region "$REGION" \
  --query "Stacks[0].Outputs[].[OutputKey,OutputValue]" --output table
echo "Vanta 2-3 minuter sa att user data hinner installera WordPress innan du oppnar webbsidan."
