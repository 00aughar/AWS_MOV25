#!/bin/bash
dnf update -y
dnf install -y httpd
systemctl enable --now httpd
cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>
<html lang="sv"><head><meta charset="UTF-8"><title>Novatrix AB</title></head>
<body><h1>Novatrix AB</h1><p>Denna websidan ska användas som en tjänst för Novatrix ärendeformulär och ska byggas upp med en Wordpress stack</p></body></html>
EOF