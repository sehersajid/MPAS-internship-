#! /bin/bash

echo "Running $@"

set -e

source guix_env.sh

TARGETS=gfortran
if [[ -n "$1" ]]; then
    TARGETS="$1"
fi

make -j CORE=atmosphere AUTOCLEAN=true $TARGETS
