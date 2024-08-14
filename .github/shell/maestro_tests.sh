#! /bin/bash
export MAESTRO_DRIVER_STARTUP_TIMEOUT=60000
$HOME/.maestro/bin/maestro -v
i=0
while [ $i -le 9 ]; do
pgrep -lf maestro | awk '{print $1}' | xargs -r kill
sleep 1
export MAESTRO_DRIVER_STARTUP_TIMEOUT=60000
$HOME/.maestro/bin/maestro test .maestro/ && break
let i=i+1
done