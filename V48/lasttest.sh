#!/bin/bash
# lasttest.sh - Belastar CPU:n pa en webbserver sa att Auto Scaling-gruppen skalar ut.
# Kor pa VARJE server i gruppen (via bastion), annars hamnar snittet nara malet och inget hander:
#   bash lasttest.sh          (standard 15 minuter)
#   bash lasttest.sh 10       (10 minuter)
# Avbryt i forvag med:  pkill yes

MINUTER="${1:-15}"
KARNOR=$(nproc)
echo "Startar $KARNOR yes-processer i $MINUTER minuter pa $(hostname)..."
for i in $(seq 1 "$KARNOR"); do
  timeout "$((MINUTER * 60))" yes > /dev/null &
done
echo "Lasten kors i bakgrunden. Folj forloppet i Auto Scaling-gruppens Monitoring och Activity."
echo "Avbryt med:  pkill yes"
