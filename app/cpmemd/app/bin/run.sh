#!/bin/bash

set -x
echo CPMEMD_HOME=$( ${DIRNAME} $0 )
echo cd ${CPMEMD_HOME}

# wget rencici-01alpha.zip
# unzip rencici-01alpha.zip
echo export RENCI_HOME=~/dev/rencici/bin
echo . ${RENCI_HOME}/environment.sh

echo GRID_HOST=brgw1.renci.org
echo job_run --host=${GRID_HOST} --app=. --clean

echo ${CAT} ${CPMEMD_HOME}/runs/${RUN_ID}/out/app/run-*/test.out
