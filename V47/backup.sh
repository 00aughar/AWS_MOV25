#!/bin/bash
# backup.sh - Tar en backup av WordPress-databasen och laddar upp den till S3.
# Kors pa novatrix-web (servern har mysqldump och en IAM-roll som far skriva i backup/):
#   DB_HOST=<endpoint> BUCKET=<backupbucket> bash backup.sh
# Losenordet hamtas fran Secrets Manager med serverns IAM-roll.

REGION="eu-north-1"
SECRET_ID="${SECRET_ID:-novatrix-db-secret}"
DB_NAME="${DB_NAME:-wordpress}"

if [ -z "$DB_HOST" ] || [ -z "$BUCKET" ]; then
  echo "Anvandning: DB_HOST=<endpoint> BUCKET=<backupbucket> bash backup.sh"
  exit 1
fi

# 1. Inloggningen fran Secrets Manager
SECRET=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ID" --region "$REGION" \
  --query SecretString --output text) || { echo "FEL: kunde inte lasa $SECRET_ID"; exit 1; }
DB_USER=$(echo "$SECRET" | python3 -c 'import sys, json; print(json.load(sys.stdin)["username"])')
export MYSQL_PWD=$(echo "$SECRET" | python3 -c 'import sys, json; print(json.load(sys.stdin)["password"])')

# 2. Dump over krypterad anslutning, komprimerad
FIL="wordpress-$(date +%Y%m%d-%H%M%S).sql.gz"
echo "Tar backup av $DB_NAME pa $DB_HOST..."
set -o pipefail
mysqldump -h "$DB_HOST" -u "$DB_USER" --ssl --single-transaction --routines "$DB_NAME" \
  | gzip > "/tmp/$FIL" || { echo "FEL: mysqldump misslyckades"; rm -f "/tmp/$FIL"; exit 1; }
unset MYSQL_PWD

# 3. Kontrollera att filen inte ar tom
STORLEK=$(stat -c %s "/tmp/$FIL")
if [ "$STORLEK" -lt 1000 ]; then
  echo "FEL: backupen ar bara $STORLEK byte, nagot gick fel"; rm -f "/tmp/$FIL"; exit 1
fi

# 4. Ladda upp till S3. Rollen far bara skriva i backup/, inte lista eller lasa
aws s3 cp "/tmp/$FIL" "s3://$BUCKET/backup/$FIL" --region "$REGION" \
  || { echo "FEL: uppladdningen misslyckades"; exit 1; }
rm -f "/tmp/$FIL"
echo "Klar: s3://$BUCKET/backup/$FIL ($STORLEK byte)"
echo "Kontrollera fran CloudShell:  aws s3 ls s3://$BUCKET/backup/"
