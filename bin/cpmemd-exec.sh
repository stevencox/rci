#!/bin/bash

ROOT_URL=$1

/home/scox/dev/rencici/bin/environment.sh \
    -r one \
    -d /home/scox/cpmemd/run \
    -j job \
    -b gsiftp://engage-submit/home/scox/cpmemd \
    -e rencici/bin/cpmemd-launch.sh

