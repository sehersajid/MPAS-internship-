#! /bin/bash


#PREFIX_GUIX="guix shell gcc-toolchain gfortran-toolchain openmpi netcdf netcdf-fortran pnetcdf  -- "
PREFIX_GUIX="guix shell gcc-toolchain gfortran-toolchain openmpi netcdf netcdf-fortran pnetcdf  -- "
echo "PREFIX_GUIX: $PREFIX_GUIX"

EXEC=bash

if [[ $# -ne 0 ]]; then
    EXEC="$@"
fi

set -e

$PREFIX_GUIX "$EXEC"

