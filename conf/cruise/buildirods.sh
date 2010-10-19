#!/bin/bash

build_irods () {
    ./scripts/configure
    make clean
    make
}

build_irods > build.log 2>&1



