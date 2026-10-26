#!/bin/bash
# iam-setup.sh - Sätter upp Novatrix IAM-kedja (v43)
# Kör i AWS CLI från mappen V43:  bash iam-setup.sh
# Kedja: ops-anna (Drift) -> novatrix-deploy-role -> EC2 med novatrix-ec2-s3-read -> läser S3

BUCKET="novatrix-data-00aughar-01"
REGION="eu-north-1"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text | tr -d '\r')
echo "Konto: $ACCOUNT"

# Byt ut ACCOUNT_ID i policyfilerna mot det riktiga konto-ID:t (sparas i mappen build/)
mkdir -p build
for f in policies/*.json; do
  sed "s/ACCOUNT_ID/$ACCOUNT/g" "$f" > "build/$(basename "$f")"
done

# Hjälpfunktion: skapa en egen policy om den inte redan finns
skapa_policy () {
  aws iam create-policy --policy-name "$1" --policy-document "file://build/$2" >/dev/null 2>&1 \
    && echo "Skapade policy $1" || echo "Policy $1 finns redan"
}

# 1. Bucket, grupper och användare (finns redan från G-delen, skapas annars)
aws s3 mb "s3://$BUCKET" --region $REGION 2>/dev/null || echo "Bucket finns redan"
aws iam create-group --group-name Utveckling >/dev/null 2>&1 || echo "Grupp Utveckling finns redan"
aws iam create-group --group-name Drift      >/dev/null 2>&1 || echo "Grupp Drift finns redan"
aws iam create-user --user-name dev-erik >/dev/null 2>&1 || echo "Användare dev-erik finns redan"
aws iam create-user --user-name ops-anna >/dev/null 2>&1 || echo "Användare ops-anna finns redan"
aws iam add-user-to-group --group-name Utveckling --user-name dev-erik
aws iam add-user-to-group --group-name Drift      --user-name ops-anna

# 2. Ta bort de breda AWS-hanterade policyerna från G-delen
aws iam detach-group-policy --group-name Utveckling --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess 2>/dev/null
aws iam detach-group-policy --group-name Drift      --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess 2>/dev/null

# 3. Egna, begränsade policyer för grupperna
skapa_policy NovatrixUtvecklingS3   utveckling-s3.json
skapa_policy NovatrixDriftS3        drift-s3.json
skapa_policy NovatrixDriftAssume    drift-assume-deploy.json
aws iam attach-group-policy --group-name Utveckling --policy-arn arn:aws:iam::$ACCOUNT:policy/NovatrixUtvecklingS3
aws iam attach-group-policy --group-name Drift      --policy-arn arn:aws:iam::$ACCOUNT:policy/NovatrixDriftS3
aws iam attach-group-policy --group-name Drift      --policy-arn arn:aws:iam::$ACCOUNT:policy/NovatrixDriftAssume

# 4. Webbrollen (EC2 -> S3): byt AmazonS3ReadOnlyAccess mot en policy för bara vår bucket
aws iam create-role --role-name novatrix-ec2-s3-read \
  --assume-role-policy-document file://build/web-trust.json >/dev/null 2>&1 || echo "Roll novatrix-ec2-s3-read finns redan"
aws iam detach-role-policy --role-name novatrix-ec2-s3-read --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess 2>/dev/null
skapa_policy NovatrixWebS3Read web-s3-read.json
aws iam attach-role-policy --role-name novatrix-ec2-s3-read --policy-arn arn:aws:iam::$ACCOUNT:policy/NovatrixWebS3Read

# Instance profile = det EC2 använder för att bära rollen
aws iam create-instance-profile --instance-profile-name novatrix-ec2-s3-read >/dev/null 2>&1 || echo "Instance profile finns redan"
aws iam add-role-to-instance-profile --instance-profile-name novatrix-ec2-s3-read --role-name novatrix-ec2-s3-read 2>/dev/null

# 5. Deploy-rollen (Drift -> EC2): får starta t3.micro och skicka ENDAST webbrollen
aws iam create-role --role-name novatrix-deploy-role \
  --assume-role-policy-document file://build/deploy-trust.json >/dev/null 2>&1 || echo "Roll novatrix-deploy-role finns redan"
skapa_policy NovatrixDeploy deploy-permissions.json
aws iam attach-role-policy --role-name novatrix-deploy-role --policy-arn arn:aws:iam::$ACCOUNT:policy/NovatrixDeploy

echo ""
echo "Klar. Kontroll:"
aws iam list-attached-group-policies --group-name Utveckling --query "AttachedPolicies[].PolicyName" --output text
aws iam list-attached-group-policies --group-name Drift      --query "AttachedPolicies[].PolicyName" --output text
aws iam list-attached-role-policies  --role-name novatrix-ec2-s3-read --query "AttachedPolicies[].PolicyName" --output text
aws iam list-attached-role-policies  --role-name novatrix-deploy-role --query "AttachedPolicies[].PolicyName" --output text
