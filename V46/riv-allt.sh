#!/bin/bash
# riv-allt.sh - River stackarna i omvand ordning: webb -> data -> nat
# En stack kan inte tas bort sa lange en annan stack importerar dess exports.

REGION="eu-north-1"
PREFIX="novatrix"

riv () {
  echo "=== Tar bort $PREFIX-$1 ==="
  aws cloudformation delete-stack --stack-name "$PREFIX-$1" --region "$REGION"
  aws cloudformation wait stack-delete-complete --stack-name "$PREFIX-$1" --region "$REGION" \
    && echo "Borttagen: $PREFIX-$1" || { echo "FEL: kunde inte ta bort $PREFIX-$1"; exit 1; }
}

riv webb

# Backup-bucketen maste tommas innan datastacken kan tas bort
BUCKET=$(aws cloudformation describe-stacks --stack-name "$PREFIX-data" --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='BackupBucketName'].OutputValue" --output text 2>/dev/null | tr -d '\r')
if [ -n "$BUCKET" ] && [ "$BUCKET" != "None" ]; then
  echo "Tommer bucketen $BUCKET..."
  aws s3 rm "s3://$BUCKET" --recursive --region "$REGION"
fi

riv data
riv nat
echo "Klar. Alla tre stackar ar borttagna."
