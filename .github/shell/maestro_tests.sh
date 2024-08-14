#! /bin/bash
export MAESTRO_DRIVER_STARTUP_TIMEOUT=60000
$HOME/.maestro/bin/maestro -v
$HOME/.maestro/bin/maestro test .maestro/ --format junit