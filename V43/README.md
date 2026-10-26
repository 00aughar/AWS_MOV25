# V.43 IAM

**Repo: https://github.com/00aughar/AWS_MOV25**

**August Hartwig**
**MOV25**
**x/x**

## Delmoment 2, Användare och grupper
Skapa IAM-användare och/eller grupper som representerar Novatrix roller, t.ex. drift och utveckling.

Skapa två IAM user groups och ge attached policies. Via portalen under IAM user groups.
- Utveckling - AmazonS3ReadOnlyAccess
- Drift - AmazonS3FullAccess

Två IAM användare skapas och tilldelas till rätt user groups:
- dev-erik - Utveckling
- ops-anna - Drift

| Användare | User Groups | Attached Policy |
| :--- | :---: | ---: |
| dev-erik | Utveckling | AmazonS3ReadOnlyAccess |
| ops-anna | Drift | AmazonS3FullAccess |


## Delmoment 3, Policies enligt least privilege
Skapa och koppla policies så att varje roll får precis den åtkomst den behöver, inte mer.

Motivering 
Drift har *AmazonS3FullAccess* då dem ska sköta om lagringen.
Utveckling har *AmazonS3ReadOnlyAccess* då dem endast ska kunna läsa filinnehållet i lagringen.

## Delmoment 4, Behörigheter mellan tjänster
Skapa en IAM-roll som ger en AWS-tjänst behörighet att nå en annan (t.ex. att en EC2-instans får läsa från en
S3-bucket).

| Instans | S3 Bucket | IAM Roll | Attached policy
| :--- | :---: | :---: | ---: |
| novatrix-web | novatrix-data-00aughar-01 | novatrix-ec2-s3-read | AmazonS3ReadOnlyAccess


1. Skapa en S3-bucket via portalen under S3 Buckets. Namn global namespace "novatrix-data-00aughar-01". Testa ladda upp en fil som via kan läsa i bucketen.

2. Skapa IAM-roll under IAM Roles i portalen. 
*novatrix-ec2-s3-read* Konfiguration:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```
3. Koppla rollen till EC2 *novatrix-web*. Markera instansen och modify IAM role och koppla *novatrix-ec2-s3-read*.

4. Verifiera att instansen kan läsa innehåll i bucketen. Anslut via terminal och testa läs innehållet med kommando:
```
aws s3 ls s3://novatrix-data-00aughar-01/
```
![alt text](<läs innehåll bucket.png>)

Testa även att ta bort filen med (ska bli nekat då rollen endast ska kunna läsa):
```
aws s3 rm s3://novatrix-data-00aughar-01/test.txt
```
![alt text](<nekad borttagning av fil.png>)


## Delmoment 5, Verifiera och dokumentera
Visa att behörigheterna fungerar som avsett. Redovisa vilka roller/policies du skapat och varför.

1. Verifiera att attached policies gäller för user groups via användarna i portalen.

- dev-erik - testa ladda upp en fil i bucket (reslutat nekad): ![alt text](<uppladdning av fil Erik.png>)
- ops-anna - testa ladda upp en fil i bucket (reslutat godkänd): ![alt text](<uppladdning av fil Anna.png>)

Kontrollera att filen laddats upp via konsolen:
![alt text](<kontrollera uppladdad fil konsol.png>)

Att tänka på
Least privilege är kärnan, motivera varje val. Målet handlar särskilt om att definiera behörigheter mellan
tjänster. Kod i monospace, kopierbar.
Krav för Godkänt (G)
Du har konfigurerat IAM för att definiera behörigheter mellan tjänster inom AWS, verifierat att de fungerar
och dokumenterat lösningen i ditt repo.

Utmaning för Väl godkänt (VG)
Designa en mer komplex behörighetslösning med flera samverkande IAM-roller, t.ex. flera tjänster som når
varandra i en kedja med least privilege genom hela, och motivera designen. Tilldela gärna via CLI/IaC så att
uppsättningen är reproducerbar.