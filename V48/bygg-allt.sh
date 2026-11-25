#!/bin/bash
# bygg-allt.sh - Bygger Novatrix WordPress-stack: backup -> nat -> data -> webb -> skala -> overvakning
# Backupstacken skapas bara forsta gangen, darefter finns den kvar mellan rivningarna.
# Kor i Git Bash med din publika IP som argument:
#   bash V48/bygg-allt.sh $(curl -s https://checkip.amazonaws.com) din@epost.se
# Andra argumentet: e-postadressen som far larmen (ligger inte i repot).
# Valfritt tredje argument: miljo (test eller prod), standard test.

MYIP="$(echo "$1" | tr -d '[:space:]')"
ALARM_EMAIL="$2"
ENV="${3:-test}"
REGION="eu-north-1"
PREFIX="novatrix"

V48_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$V48_DIR" || exit 1

if [ -z "$MYIP" ] || [ -z "$ALARM_EMAIL" ]; then
  echo "FEL: ange din publika IP och e-postadress, t.ex.:"
  echo "  bash V48/bygg-allt.sh \$(curl -s https://checkip.amazonaws.com) din@epost.se"
  exit 1
fi
echo "Admin-IP: $MYIP   Larm till: $ALARM_EMAIL   Miljo: $ENV"

# Validera alla mallar innan nagot byggs
echo "=== Validerar mallarna ==="
for t in novatrix-backup.yaml novatrix-nat.yaml novatrix-data.yaml novatrix-webb.yaml novatrix-skala.yaml novatrix-overvakning.yaml; do
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
deploy nat    novatrix-nat.yaml    --parameter-overrides Prefix="$PREFIX" MyIp="$MYIP/32"
deploy data   novatrix-data.yaml   --parameter-overrides Prefix="$PREFIX" Environment="$ENV"
deploy webb   novatrix-webb.yaml   --parameter-overrides Prefix="$PREFIX" --capabilities CAPABILITY_NAMED_IAM
echo "Skalstacken vantar tills bada servrarna har installerat WordPress, det tar 5-10 minuter."
deploy skala  novatrix-skala.yaml  --parameter-overrides Prefix="$PREFIX"
deploy overvakning novatrix-overvakning.yaml --parameter-overrides Prefix="$PREFIX" AlarmEmail="$ALARM_EMAIL" --capabilities CAPABILITY_IAM

echo ""
echo "=== Klar ==="
aws cloudformation describe-stacks --stack-name "$PREFIX-skala" --region "$REGION" \
  --query "Stacks[0].Outputs[].[OutputKey,OutputValue]" --output table
aws cloudformation describe-stacks --stack-name "$PREFIX-webb" --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='BastionPublicIp'].[OutputKey,OutputValue]" --output table
aws cloudformation describe-stacks --stack-name "$PREFIX-overvakning" --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='DashboardUrl'].[OutputKey,OutputValue]" --output table
echo "WordPress ar redan installerat. Admin-inloggningen finns i Secrets Manager: $PREFIX-wp-admin"
echo "VIKTIGT: bekrafta prenumerationen i mailet fran AWS Notifications, annars kommer inga larm fram."
