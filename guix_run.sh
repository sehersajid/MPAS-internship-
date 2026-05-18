#! /bin/bash

echo "Running $@"

set -e

source guix_env.sh

GRIDDIR=global_240km

if [[ ! -d "$GRIDDIR" ]]; then
    wget https://www2.mmm.ucar.edu/people/duda/files/mpas/global_240km.tar.bz2
    tar -xvjf global_240km.tar.bz2

    echo "=== Linking executable into global_240km directory ==="
    pushd .
    cd "$GRIDDIR"
    ln -s ../atmosphere_model .
    popd
fi

cd "$GRIDDIR"

mpirun -n 1 ../guix.sh ./atmosphere_model
