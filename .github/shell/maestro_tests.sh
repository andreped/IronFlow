#! /bin/bash
export MAESTRO_DRIVER_STARTUP_TIMEOUT=120000
$HOME/.maestro/bin/maestro -v
i=0
while [ $i -le 2 ]; do
#pgrep -lf maestro | awk '{print $1}' | xargs -r kill
#sleep 1
$HOME/.maestro/bin/maestro test .maestro/ && break
let i=i+1
done
