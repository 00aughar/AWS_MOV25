#!/bin/bash
# riv-allt.sh - Tar bort WordPress-stacken som bygg-allt.sh skapade
# Backup-bucketen töms först, eftersom CloudFormation inte kan ta bort en bucket med filer i.
# IAM från v43 lämnas kvar.

REGION="eu-north-1"
STACK="novatrix-wordpress"

BUCKET=$(aws cloudformation describe-stacks --stack-name "$STACK" --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='BackupBucket'].OutputValue" --output text 2>/dev/null | tr -d '\r')

if [ -n "$BUCKET" ] && [ "$BUCKET" != "None" ]; then
  echo "Tömmer bucketen $BUCKET..."
  aws s3 rm "s3://$BUCKET" --recursive --region "$REGION"
fi

aws cloudformation delete-stack --stack-name "$STACK" --region "$REGION"
echo "Tar bort stacken $STACK, det tar ca 10 minuter (RDS och EFS)..."
aws cloudformation wait stack-delete-complete --stack-name "$STACK" --region "$REGION" \
  && echo "Klar. Allt i stacken är borttaget."
