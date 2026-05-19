#! /bin/bash


PREFIX_GUIX="guix shell gcc-toolchain@14.3.0 gfortran-toolchain@14.3.0 openmpi@4.1.6 netcdf@4.9.2 netcdf-fortran@4.5.3 pnetcdf@1.13.0  -- "
echo "PREFIX_GUIX: $PREFIX_GUIX"

EXEC=bash

if [[ $# -ne 0 ]]; then
    EXEC="$@"
fi

set -e

$PREFIX_GUIX "$EXEC"

