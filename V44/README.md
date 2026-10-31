# V.44 Nätverk och säkerhet

**Repo: https://github.com/00aughar/AWS_MOV25**

**August Hartwig**
**MOV25**
**x/x**

# Godkänt

- Du har byggt ett VPC med subnät och routing

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



- Du har placerat lösningen säkert i rätt subnät

- Du har verifierat vilken trafik som släpps eller blockeras

- Allt dokumenterat med skiss, PDF med repo-länk

## Nätverksskissen:
![alt text](Nätverksskiss.png)