# V.44 AWS Uppgift 3, Nätverk och säkerhet

**Repo: https://github.com/00aughar/AWS_MOV25**

**August Hartwig**
**MOV25**
**3/11**

# Godkänt

- Du har byggt ett VPC med subnät och routing

## Förklaring av lösningen:

Lösningen bygger på defense in depth där flera lager an nätverkskompontenter, routing, security groups & NACL bygger en trygg och säkrad IT miljö, om ett av lagren briste står de andra kvar. Syftet med lösningen är att skydda de privata subnäten och i sin tur skydda webbservern och den framtida databasen som Novatrix ska bygga. 

Besökaren besöker serverns publika IP > Trafkien går igenom "novatrix-igw" > Routing tabellen "novatrix-public-rt" leder vidare till subnätet "novatrix-public" > NACL "novatrix-public-nacl" släpper vidare på port 80 > Security group "novatrix-web-sg" släpper vidare på port 80 > websidan visas för besökaren

Administratörens anslutning > SSH via terminalen mot serverns publika IP på port 22 > NACL "novatrix-public-nacl" tillåter trafik på port 22 endast från hostens publika IP adress > Security group "novatrix-web-sg" tillåter trafik på port 22 endast från hostens publika IP adress > SSH nyckeln avgör om anslutningen tillåts



## Lösningen

## Nätverkskomponenter

| Komponent | Namn | Värde | Syfte |
|---|---|---|---|
| VPC | `novatrix-vpc` | `10.0.0.0/16` | Novatrix eget isolerade nätverk i eu-north-1 |
| Publikt subnät | `novatrix-public` | `10.0.1.0/24`, eu-north-1b | Webbservern, nåbar från internet |
| Privat subnät | `novatrix-private-a` | `10.0.2.0/24`, eu-north-1a | Förberett för känsliga komponenter, ingen väg till internet |
| Privat subnät | `novatrix-private-b` | `10.0.4.0/24`, eu-north-1b | Förberett för känsliga komponenter, ingen väg till internet |
| Internet Gateway | `novatrix-igw` | Kopplad till `novatrix-vpc` | VPC:ts enda väg till och från internet |

## Routing

| Route table | Kopplad till | Destination | Mål | Effekt |
|---|---|---|---|---|
| `novatrix-public-rt` | `novatrix-public` | `10.0.0.0/16` | local | Trafik inom VPC:t |
| `novatrix-public-rt` | `novatrix-public` | `0.0.0.0/0` | `novatrix-igw` | Gör subnätet publikt |
| Main route table | `novatrix-private-a`, `novatrix-private-b` | `10.0.0.0/16` | local | Bara intern trafik, subnäten är privata |

## Security group – `novatrix-web-sg` (instansnivå, stateful)

| Riktning | Port | Protokoll | Källa | Syfte |
|---|---|---|---|---|
| Inbound | 80 | TCP | `0.0.0.0/0` | HTTP för besökare |
| Inbound | 443 | TCP | `0.0.0.0/0` | HTTPS för besökare |
| Inbound | 22 | TCP | Egen IP `/32` | SSH endast för administratören |
| Outbound | Alla | Alla | `0.0.0.0/0` | Standard. Svar och uppdateringar (`dnf`) |

## NACL – `novatrix-public-nacl` (subnätnivå, stateless)

| Riktning | Regel | Port | Källa/mål | Tillåt/Neka | Syfte |
|---|---|---|---|---|---|
| Inbound | 100 | 80 | `0.0.0.0/0` | Tillåt | HTTP |
| Inbound | 110 | 443 | `0.0.0.0/0` | Tillåt | HTTPS |
| Inbound | 120 | 22 | Egen IP `/32` | Tillåt | SSH för admin |
| Inbound | 130 | 1024–65535 | `0.0.0.0/0` | Tillåt | Svar på trafik som servern startat, t.ex. `dnf update` |
| Inbound | * | Alla | `0.0.0.0/0` | Neka | Allt annat |
| Outbound | 100 | 80 | `0.0.0.0/0` | Tillåt | Uppdateringar via HTTP |
| Outbound | 110 | 443 | `0.0.0.0/0` | Tillåt | Uppdateringar via HTTPS |
| Outbound | 120 | 22 | Egen IP `/32` | Tillåt | SSH för admin |
| Outbound | 130 | 1024–65535 | `0.0.0.0/0` | Tillåt | Svar till besökare och SSH-klient |
| Outbound | * | Alla | `0.0.0.0/0` | Neka | Allt annat |

De privata subnäten använder VPC:ts standard-NACL.

## Instans

| Namn | Subnät | Typ | Säkerhetsgrupp | IAM-roll | Källa |
|---|---|---|---|---|---|
| `novatrix-web` | `novatrix-public` | t3.micro | `novatrix-web-sg` | `novatrix-ec2-s3-read` | AMI av den gamla instansen, eftersom en instans inte kan flyttas mellan VPC:er |


## Skapa VPC genom portalen
Konfiguration:
![alt text](<VPC Konfiguration Portalen.png>)

VPC CLI Konfiguration:
```
aws ec2 create-vpc --no-amazon-provided-ipv6-cidr-block --instance-tenancy 'default' --cidr-block '10.0.0.0/16' --tag-specifications '{"ResourceType":"vpc","Tags":[{"Key":"Name","Value":"novatrix-vpc"}]}' 
```

## Skapa subnät genom portalen
Konfiguration "novatrix-public":
![alt text](<Subnät Novatrix-public Konfiguration Portalen.png>)

Konfiguration "novatrix-private-a":
![alt text](<Subnät novatrix-private-a Konfiguration Portalen.png>)

Konfiguration "novatrix-private-b":
![alt text](<Subnät novatrix-private-b Konfiguration Portalen.png>)

## Skapa Internet Gateway och Route Table genom portalen
# 1. Internet Gateway
Konfiguration Internet Gateway "novatrix-igw":
![alt text](<Internet Gateway novatrix-igw Portalen.png>)

# 2. Koppla till VPC
Anslut novatrix-igw till VPC novatrix-vpc Portalen:
![alt text](<Anslut novatrix-igw till VPC novatrix-vpc Portalen.png>)

CLI anslut novatrix-igw till VPC novatrix-vpc:
```
aws ec2 attach-internet-gateway --vpc-id "vpc-05084284692c4fecc" --internet-gateway-id "igw-0dd681971aa62eec6" --region eu-north-1
```

# 3. Route Table
Konfigruation Route Table "novatrix-public-rt":
![alt text](<Route Table konfiguration Portalen.png>)

# 4. Koppla route table till internet gateway portalen
![alt text](<Koppla route table till internet gateway portalen.png>)
- Security groups och NACL:er begränsar trafiken

# 5. Anslut route table till subnät novatrix-publik portalen
![alt text](<Anslut route table till subnät novatrix-publik portalen.png>)


- Security groups/NACL som begränsar trafiken till det nödvändiga
Webben nåbar på 80 och 443, admin begränsad

## Skapa säkerhetsgrupp via portalen
Konfiguration "novatrix-web-sg"
![alt text](<Säkerhetsgrupp novatrix-web-sg Portalen.png>)

## Skapa AMI image av "novatrix-web-gammal"
![alt text](<Skapa Image AMI novatrix-web-v44 portalen.png>)

## Starta Instans från AMI image Portalen
![alt text](<Starta Instans från AMI image Portalen.png>)

Starta Instans från AMI image CLI:
```
aws ec2 run-instances --image-id 'ami-0905273365bf5833c' --instance-type 't3.micro' --key-name 'aws_webserver' --ebs-optimized --network-interfaces '{"SubnetId":"subnet-0d52766ffcba51d29","AssociatePublicIpAddress":true,"DeviceIndex":0,"Groups":["sg-0ceee709423ffa088"]}' --credit-specification '{"CpuCredits":"unlimited"}' --tag-specifications '{"ResourceType":"instance","Tags":[{"Key":"Name","Value":"novatrix-web"}]}' --iam-instance-profile '{"Arn":"arn:aws:iam::176884785988:instance-profile/novatrix-ec2-s3-read"}' --private-dns-name-options '{"HostnameType":"ip-name","EnableResourceNameDnsARecord":false,"EnableResourceNameDnsAAAARecord":false}' --count '1' 
```

## Skapa network ACL (NACL) "novatrix-public-nacl"
![alt text](<Network ACL Konfiguration Portalen.png>)

## Skapa Inbound rules "novatrix-public-nacl"
![alt text](<NACL Inbound.png>)

## Skapa Outbound rules "novatrix-public-nacl"
![alt text](<NACL Outbound.png>)

## Upprensing

Efter att instansen har startats och verifierats att websidan går att nå terminera den gammla instansen "novatrix-web-gammal". Deregister AMI imagen "novatrix-web-v44" och snapshots.
![alt text](<Instans skapad från AMI image.png>)
![alt text](<Derigister AMI portalen.png>)



- Du har placerat lösningen säkert i rätt subnät

- Du har verifierat vilken trafik som släpps eller blockeras

## Besök websidan lokal host IP
![alt text](<Besök websidan från lokal host IP.png>)

## SSH från hostens publika IP
![alt text](<SSH Hostens Publika IP.png>)

## SSH från okänd IP
![alt text](<SSH anslutning Okänd IP.png>)

## Testa Portarna

## Verifiering av trafikflöden

| Test | Från | Port | Förväntat | Resultat | Förklaring |
|---|---|---|---|---|---|
| Besöka webbsidan | Egen dator | 80 | Sidan visas | Visas | Tillåten för alla i både `novatrix-public-nacl` och `novatrix-web-sg`, och Apache svarar |
| SSH | Egen IP | 22 | Anslutning lyckas | Ansluten | Port 22 är bara öppen för administratörens IP i både NACL och SG |
| SSH | Okänd IP | 22 | Anslutning nekas | Timeout | IP-adressen finns inte i reglerna och stoppas redan i NACL:en |
| `Test-NetConnection` | Egen dator | 22 | `True` | `True` | Samma regel som SSH-testet ovan |
| `Test-NetConnection` | Egen dator | 80 | `True` | `True` | HTTP är öppet för alla |
| `Test-NetConnection` | Egen dator | 443 | `False` | `False` | Porten är öppen i NACL och SG, men ingen HTTPS-tjänst körs på servern, så ingenting svarar |
| `Test-NetConnection` | Egen dator | 3306 | `False` | `False` | Blockeras av både NACL (`* Deny`) och SG, där regeln saknas |


Kommandon som användes:

```
Test-NetConnection <novatrix-web Publika IP> -Port 22
Test-NetConnection <novatrix-web Publika IP> -Port 80
Test-NetConnection <novatrix-web Publika IP> -Port 443
Test-NetConnection <novatrix-web Publika IP> -Port 3306
```

![alt text](<Test portar.png>)


- Allt dokumenterat med skiss, PDF med repo-länk

## Nätverksskissen:
![alt text](Nätverksskissen.png)


## Resurskarta:
![alt text](Resurskarta.png)