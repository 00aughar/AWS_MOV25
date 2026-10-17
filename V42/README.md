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

User data scriptet innehåller vad den nya instansen ska göra vid uppstart. Den installerar webbservern och bygger upp websidan som sedan kan besökas via den publika IP adressen för instansen.

