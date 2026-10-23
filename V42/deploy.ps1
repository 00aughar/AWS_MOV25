# deploy.ps1 - Skapar Novatrix webbserver i AWS (EC2 + Apache + webbsida)
# Kör från mappen där user-data.sh ligger: .\deploy.ps1

$region  = "eu-north-1"
$keyName = "aws_webserver"   # Befintligt key pair i AWS (C:\Users\augus\.ssh\aws_webserver.pem)

$myip    = "DIN.IP.ADRESS.HÄR"  # Din dators IP (från https://checkip.amazonaws.com)

# Security group: använd befintlig om den finns, annars skapa ny med regler
$sg = aws ec2 describe-security-groups --group-names novatrix-web-sg --region $region `
  --query "SecurityGroups[0].GroupId" --output text 2>$null

if (-not $sg) {
    Write-Host "Skapar security group novatrix-web-sg..."
    $sg = aws ec2 create-security-group --group-name novatrix-web-sg `
      --description "Novatrix web" --region $region --query GroupId --output text

    # Regler: SSH bara från min IP, HTTP från alla
    aws ec2 authorize-security-group-ingress --group-id $sg --protocol tcp --port 22 --cidr "$myip/32" --region $region
    aws ec2 authorize-security-group-ingress --group-id $sg --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $region
} else {
    Write-Host "Använder befintlig security group: $sg"
}

# Starta instansen med user data
$instanceId = aws ec2 run-instances `
  --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 `
  --instance-type t3.micro `
  --key-name $keyName `
  --security-group-ids $sg `
  --user-data file://user-data.sh `
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=novatrix-web}]" `
  --region $region `
  --query "Instances[0].InstanceId" --output text

Write-Host "Instans startad: $instanceId. Väntar på att den ska bli running..."
aws ec2 wait instance-running --instance-ids $instanceId --region $region

# Hämta publik IP
$ip = aws ec2 describe-instances --instance-ids $instanceId --region $region `
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text

Write-Host "Klar! Vänta 1-2 minuter och surfa sedan till: http://$ip"
Write-Host "SSH: ssh -i C:\Users\augus\.ssh\aws_webserver.pem ec2-user@$ip"