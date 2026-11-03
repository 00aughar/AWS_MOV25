#!/bin/bash
# riv-allt.sh - Tar bort nätverket och servrarna som bygg-allt.sh skapade
# IAM från v43 och S3-bucketen lämnas kvar (de kostar inget).

REGION="eu-north-1"
STACK="novatrix-miljo"

aws cloudformation delete-stack --stack-name "$STACK" --region "$REGION"
echo "Tar bort stacken $STACK, det tar några minuter..."
aws cloudformation wait stack-delete-complete --stack-name "$STACK" --region "$REGION" \
  && echo "Klar. Allt i stacken är borttaget."
