# V.42 Compute

**Repo: https://github.com/00aughar/AWS_MOV25**

**August Hartwig**
**MOV25**
**x/x**

## Delmoment 2, Provisionera en EC2-instans
Starta en EC2-instans åt Novatrix. Använd Amazon Linux. Skapa ett key pair och en security group. Välj en
lämplig instanstyp (tänk kostnad, håll dig inom free tier).

EC2 > Launch Instance > "webserver", amazon linux, t3 micro > new key pair > konfigurera säkerhetsregel > launch instance

## Delmoment 3, Konfigurera värdmiljön
Anslut via SSH och installera en webbserver.

Navigera till mappen där nyckel lagras. Anslut sedan med:

```
ssh -i .\aws_webserver.pem ec2-user@(webserverns publika ip)
```

## Delmoment 4, Driftsätt applikationen
Skapa en enkel webbsida som presenterar Novatrix namn och en kort text om tjänsten. Driftsätt den så att den
visas när man surfar till instansens publika IP.

Installation och uppstart av HTTPD
```
sudo yum update -y
sudo yum install httpd -y
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl status httdp
```
Testa besök websida:
http://(webservens publika IP)

Bygg upp HTML sidan
```
sudo tee /var/www/html/index.html > /dev/null <<'EOF'
<!DOCTYPE html>
<html lang="sv">
<head><meta charset="UTF-8"><title>Novatrix AB</title></head>
<body>
  <h1>Novatrix AB</h1>
  <p>Kort text om tjänsten här.</p>
</body>
</html>
EOF
```

## Delmoment 5, Verifiera och dokumentera
Visa att sidan går att nå. Dokumentera stegen i text, bild och kod.



## Delmoment 6, Kostnadskontroll
Sätt upp en månadsbudget i AWS Budgets med larm till din e-post, både på faktisk och på prognostiserad
kostnad. Visa inställningarna i dokumentationen.

# VG

User data scriptet *user-data.sh* innehåller vad den nya instansen ska göra vid uppstart. Den installerar webbservern och bygger upp websidan som sedan kan besökas via den publika IP adressen för instansen. Deploy scriptet *deploy.ps1* automatiserar konfigurationsstegen för instansen. I scriptet defineras vilken region, namn, säkerhetsgrupp (*novatrix-web-sg*) & nyckelparet.

Jag valde att ladda upp scripten i cloud shell via AWS portalen för att sedan köra dem med kommando: ```pwsh ./deploy.ps1```


*deploy.ps1*

```
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
```

*user-data.sh*

```
#!/bin/bash
dnf update -y
dnf install -y httpd
systemctl enable --now httpd
cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>
<html lang="sv"><head><meta charset="UTF-8"><title>Novatrix AB</title></head>
<body><h1>Novatrix AB</h1><p>Kort text om tjänsten.</p></body></html>
EOF
```

*Reslutat körning*

![alt text](<IaC körning.png>)

*Anslutning via terminal*

![alt text](<Ansluten till server efter IaC script.png>)
