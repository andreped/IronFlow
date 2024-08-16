#! /bin/bash
$HOME/.maestro/bin/maestro -v
i=0
while [ $i -le 9 ]; do
pgrep -lf maestro | awk '{print $1}' | xargs -r kill
sleep 1
export MAESTRO_DRIVER_STARTUP_TIMEOUT=120000
$HOME/.maestro/bin/maestro test .maestro/inputs_tab_CI_flow.yml && break
let i=i+1
done